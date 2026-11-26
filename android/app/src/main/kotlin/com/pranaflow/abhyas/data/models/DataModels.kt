package com.pranaflow.abhyas.data.models

import com.pranaflow.abhyas.engine.player.CycleStepItem
import com.pranaflow.abhyas.engine.player.RoutineIntensity
import com.pranaflow.abhyas.engine.player.RoutinePreset
import com.pranaflow.abhyas.engine.player.SoundPalette
import com.pranaflow.abhyas.engine.progression.SessionSummary
import kotlinx.serialization.Serializable
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

@Serializable
data class SessionRecord(
    val id: String = "",
    val practiceId: String = "",
    val practiceName: String,
    val level: Int = 1,
    val durationSeconds: Int,
    val timestampIso: String,
    val epochDay: Long = parseEpochDay(timestampIso),
    val checkinRating: String, // calm | neutral | agitated | strained
    val holdDurations: List<Double> = emptyList(),
    val calmnessScore: Int? = null, // 1..10
    val preCalmnessScore: Int? = null, // 1..10
    val sensations: List<String> = emptyList(),
    val dizziness: Boolean = false,
    val note: String = "",
    val ratioUsed: List<Int>? = null,
    val capsApplied: Int? = null,
    val isVishrama: Boolean = false,
    val isSynced: Boolean = false,
) {
    val calmnessDelta: Int
        get() = if (calmnessScore != null && preCalmnessScore != null) {
            calmnessScore - preCalmnessScore
        } else {
            0
        }

    fun toSummary(): SessionSummary = SessionSummary(
        practiceName = practiceName,
        level = level,
        durationSeconds = durationSeconds,
        epochDay = epochDay,
        checkinRating = checkinRating,
        dizziness = dizziness,
        preCalmnessScore = preCalmnessScore,
        calmnessScore = calmnessScore,
        isVishrama = isVishrama,
    )

    companion object {
        fun parseEpochDay(timestampIso: String): Long = runCatching {
            Instant.parse(timestampIso).atZone(ZoneOffset.UTC).toLocalDate().toEpochDay()
        }.getOrElse {
            runCatching { LocalDate.parse(timestampIso.take(10)).toEpochDay() }
                .getOrDefault(LocalDate.now().toEpochDay())
        }
    }
}

@Serializable
data class CheckinEntry(
    val id: String,
    val timestampIso: String,
    val practiceName: String,
    val durationSeconds: Int,
    val feeling: String,
    val preCalmness: Int,
    val postCalmness: Int,
    val delta: Int,
    val dizziness: Boolean,
    val sensations: List<String> = emptyList(),
    val note: String = "",
)

@Serializable
data class ChtMeasurement(
    val id: String,
    val valueSeconds: Double,
    val recommendedLevel: Int,
    val safeCapSeconds: Int,
    val measuredAtIso: String,
)

@Serializable
data class CustomMantra(
    val id: String,
    val name: String,
    val text: String,
    val transliteration: String = "",
    val meaning: String? = null,
    val traditionTag: String = "all",
    val isCustom: Boolean = false,
)

@Serializable
data class SavedCustomRoutine(
    val id: String,
    val name: String,
    val preset: RoutinePreset,
    val targetMinutes: Int,
    val intensity: RoutineIntensity,
    val steps: List<CycleStepItem>,
)

@Serializable
data class ReminderSettings(
    val morningEnabled: Boolean = false,
    val morningHour: Int = 6,
    val morningMinute: Int = 30,
    val eveningEnabled: Boolean = false,
    val eveningHour: Int = 18,
    val eveningMinute: Int = 30,
    val bedtimeEnabled: Boolean = false,
    val bedtimeHour: Int = 21,
    val bedtimeMinute: Int = 30,
)

@Serializable
data class AudioPreferences(
    val voiceEnabled: Boolean = true,
    val audioTonesEnabled: Boolean = true,
    val hapticsEnabled: Boolean = false,
    val tanpuraDroneEnabled: Boolean = true,
    val masterVolume: Float = 0.85f,
    val voiceVolume: Float = 0.90f,
    val toneVolume: Float = 0.85f,
    val droneVolume: Float = 0.65f,
    val soundPalette: SoundPalette = SoundPalette.SINGING_BOWL,
)

@Serializable
data class UserProfileSettings(
    val displayName: String = "Practitioner",
    val tradition: String = "Smarta",
    val language: String = "en",
    val matraSeconds: Double = 1.0,
    val pilotConsentAccepted: Boolean = false,
    val shareWithTeacherConsent: Boolean = false,
    val teacherInviteCode: String? = null,
    val manualWeaningStageOverride: Int? = null,
    val activeSankalp: String = "Today my intention is to practice steadiness of breath and mind.",
)

@Serializable
data class SyncOutboxItem(
    val id: String,
    val entityType: String, // session | checkin | cht | unlock_request | safety_profile | audit
    val payloadJson: String,
    val createdAtEpochMs: Long,
    val synced: Boolean = false,
)
