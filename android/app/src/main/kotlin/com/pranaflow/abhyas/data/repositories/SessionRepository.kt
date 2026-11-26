package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.models.CheckinEntry
import com.pranaflow.abhyas.data.models.SessionRecord
import com.pranaflow.abhyas.data.store.KeyValueStore
import com.pranaflow.abhyas.engine.progression.ProgressionEngine
import com.pranaflow.abhyas.engine.progression.RatioProgressionDecision
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.time.Instant
import java.time.LocalDate

/**
 * Offline-first repository for completed sessions, post-session check-ins ("See the Difference"),
 * Vishrama grace days, Tapas counts, comfort streaks, auto-regression state, and 7-day strain checks.
 */
class SessionRepository(
    private val store: KeyValueStore,
    private val syncOutbox: SyncOutboxRepository? = null,
) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun logSession(
        session: SessionRecord,
        maxStepIndex: Int = 2,
        comfortStreakRequiredForStep: Int = 5,
        todayEpochDay: Long = LocalDate.now().toEpochDay(),
    ): RatioProgressionDecision {
        val withId = if (session.id.isBlank()) {
            session.copy(id = "sess_${System.currentTimeMillis()}_${session.practiceName.hashCode()}")
        } else {
            session
        }

        val existing = store.getStringList(KEY_SESSIONS).toMutableList()
        existing.add(json.encodeToString(withId))
        store.putStringList(KEY_SESSIONS, existing)

        val checkin = CheckinEntry(
            id = "chk_${withId.id}",
            timestampIso = withId.timestampIso,
            practiceName = withId.practiceName,
            durationSeconds = withId.durationSeconds,
            feeling = withId.checkinRating,
            preCalmness = withId.preCalmnessScore ?: 5,
            postCalmness = withId.calmnessScore ?: 5,
            delta = withId.calmnessDelta,
            dizziness = withId.dizziness,
            sensations = withId.sensations,
            note = withId.note,
        )
        saveCheckin(checkin)

        syncOutbox?.enqueue(
            entityType = "session",
            payloadJson = json.encodeToString(withId),
        )

        val allSessions = getSessions().map { it.toSummary() }
        val currentStep = getRatioStepIndex()
        val decision = ProgressionEngine.evaluateRatioLadder(
            currentStepIndex = currentStep,
            maxStepIndex = maxStepIndex,
            recentSessionsChronological = allSessions,
            todayEpochDay = todayEpochDay,
            comfortStreakRequiredForStep = comfortStreakRequiredForStep,
        )
        store.putInt(KEY_RATIO_STEP_INDEX, decision.nextStepIndex)
        if (decision.notifyTeacher) {
            store.putBoolean(KEY_TEACHER_STRAIN_ALERT, true)
        }
        return decision
    }

    suspend fun logVishramaDay(epochDay: Long = LocalDate.now().toEpochDay()) {
        val restRecord = SessionRecord(
            id = "vishrama_$epochDay",
            practiceId = "vishrama",
            practiceName = "Vishrama (Rest Day)",
            level = 1,
            durationSeconds = 0,
            timestampIso = Instant.now().toString(),
            epochDay = epochDay,
            checkinRating = "calm",
            isVishrama = true,
        )
        val existing = store.getStringList(KEY_SESSIONS).toMutableList()
        existing.add(json.encodeToString(restRecord))
        store.putStringList(KEY_SESSIONS, existing)
    }

    suspend fun saveCheckin(checkin: CheckinEntry) {
        val existing = store.getStringList(KEY_CHECKINS).toMutableList()
        existing.add(json.encodeToString(checkin))
        store.putStringList(KEY_CHECKINS, existing)
        syncOutbox?.enqueue(
            entityType = "checkin",
            payloadJson = json.encodeToString(checkin),
        )
    }

    suspend fun getSessions(): List<SessionRecord> =
        store.getStringList(KEY_SESSIONS).mapNotNull { raw ->
            runCatching { json.decodeFromString<SessionRecord>(raw) }.getOrNull()
        }

    suspend fun getCheckins(): List<CheckinEntry> =
        store.getStringList(KEY_CHECKINS).mapNotNull { raw ->
            runCatching { json.decodeFromString<CheckinEntry>(raw) }.getOrNull()
        }

    suspend fun getTapasCount(): Int = getSessions().count { !it.isVishrama }

    suspend fun getTotalPracticeMinutes(): Int {
        val totalSecs = getSessions().filter { !it.isVishrama }.sumOf { it.durationSeconds }
        return totalSecs / 60
    }

    suspend fun getAverageCalmnessDelta(): Double {
        val valid = getSessions().filter { it.calmnessScore != null && it.preCalmnessScore != null }
        if (valid.isEmpty()) return 0.0
        return valid.sumOf { it.calmnessDelta }.toDouble() / valid.size
    }

    suspend fun getComfortStreak(): Int {
        val sessions = getSessions().filter { !it.isVishrama }.sortedByDescending { it.timestampIso }
        var streak = 0
        for (s in sessions) {
            if (s.checkinRating.equals("calm", ignoreCase = true) && !s.dizziness) {
                streak++
            } else {
                break
            }
        }
        return streak
    }

    suspend fun getAverageHold(): Double {
        val allHolds = getSessions().flatMap { it.holdDurations }
        if (allHolds.isEmpty()) return 0.0
        return allHolds.average()
    }

    suspend fun getDailyPracticeStreak(
        todayEpochDay: Long = LocalDate.now().toEpochDay(),
        vishramaAllowancePerWeek: Int = 1,
    ): Int {
        val sessions = getSessions()
        val practiced = sessions.filter { !it.isVishrama }.map { it.epochDay }.toSet()
        val vishrama = sessions.filter { it.isVishrama }.map { it.epochDay }.toSet()
        return ProgressionEngine.computeDailyStreakWithVishrama(
            practicedEpochDays = practiced,
            vishramaEpochDays = vishrama,
            todayEpochDay = todayEpochDay,
            vishramaAllowancePerWeek = vishramaAllowancePerWeek,
        )
    }

    suspend fun getRecentStrainCount7Days(todayEpochDay: Long = LocalDate.now().toEpochDay()): Int =
        getSessions().count {
            (it.dizziness || it.checkinRating.equals("strained", ignoreCase = true)) &&
                (todayEpochDay - it.epochDay) in 0..6
        }

    suspend fun getRatioStepIndex(): Int = store.getInt(KEY_RATIO_STEP_INDEX, 0)

    suspend fun setRatioStepIndex(index: Int) {
        store.putInt(KEY_RATIO_STEP_INDEX, index.coerceAtLeast(0))
    }

    suspend fun hasPendingTeacherStrainAlert(): Boolean =
        store.getBoolean(KEY_TEACHER_STRAIN_ALERT, false)

    suspend fun clearTeacherStrainAlert() {
        store.putBoolean(KEY_TEACHER_STRAIN_ALERT, false)
    }

    companion object {
        private const val KEY_SESSIONS = "session_records"
        private const val KEY_CHECKINS = "session_checkins"
        private const val KEY_RATIO_STEP_INDEX = "ratio_step_index"
        private const val KEY_TEACHER_STRAIN_ALERT = "teacher_strain_alert"
    }
}
