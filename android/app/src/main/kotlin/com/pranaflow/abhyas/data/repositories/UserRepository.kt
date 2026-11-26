package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.models.AudioPreferences
import com.pranaflow.abhyas.data.models.ChtMeasurement
import com.pranaflow.abhyas.data.models.ReminderSettings
import com.pranaflow.abhyas.data.models.UserProfileSettings
import com.pranaflow.abhyas.data.store.KeyValueStore
import com.pranaflow.abhyas.engine.progression.ProgressionEngine
import com.pranaflow.abhyas.engine.safety.SafetyProfile
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.time.Instant

/**
 * Offline-first repository persisting user safety screening flags, CHT benchmarks & history,
 * audio/haptic/weaning preferences, tradition, consent, and data export/deletion (NFR-01, NFR-03).
 */
class UserRepository(
    private val store: KeyValueStore,
) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun saveProfile(profile: SafetyProfile) {
        store.putBoolean(KEY_PREGNANCY, profile.pregnancy)
        store.putBoolean(KEY_HYPERTENSION, profile.hypertension)
        store.putBoolean(KEY_HEART_CONDITION, profile.heartCondition)
        store.putBoolean(KEY_EPILEPSY, profile.epilepsy)
        store.putBoolean(KEY_GLAUCOMA, profile.glaucoma)
        store.putBoolean(KEY_HERNIA, profile.hernia)
        store.putBoolean(KEY_RECENT_SURGERY, profile.recentSurgery)
        store.putBoolean(KEY_ASTHMA, profile.asthmaOrRespiratory)
        store.putBoolean(KEY_PANIC, profile.panicOrAnxiety)
        store.putBoolean(KEY_MENSTRUATION, profile.menstruation)
        store.putBoolean(KEY_EMPTY_STOMACH, profile.emptyStomachConfirmed)
        store.putBoolean(KEY_PROFILE_SAVED, true)
    }

    suspend fun loadProfile(): SafetyProfile? {
        if (!store.getBoolean(KEY_PROFILE_SAVED, false)) {
            return null
        }
        return SafetyProfile(
            pregnancy = store.getBoolean(KEY_PREGNANCY, false),
            hypertension = store.getBoolean(KEY_HYPERTENSION, false),
            heartCondition = store.getBoolean(KEY_HEART_CONDITION, false),
            epilepsy = store.getBoolean(KEY_EPILEPSY, false),
            glaucoma = store.getBoolean(KEY_GLAUCOMA, false),
            hernia = store.getBoolean(KEY_HERNIA, false),
            recentSurgery = store.getBoolean(KEY_RECENT_SURGERY, false),
            asthmaOrRespiratory = store.getBoolean(KEY_ASTHMA, false),
            panicOrAnxiety = store.getBoolean(KEY_PANIC, false),
            menstruation = store.getBoolean(KEY_MENSTRUATION, false),
            emptyStomachConfirmed = store.getBoolean(KEY_EMPTY_STOMACH, false),
        )
    }

    suspend fun saveTradition(tradition: String) {
        store.putString(KEY_TRADITION, tradition)
        val current = loadProfileSettings()
        store.putString(KEY_PROFILE_SETTINGS, json.encodeToString(current.copy(tradition = tradition)))
    }

    suspend fun loadTradition(): String? = store.getString(KEY_TRADITION)

    suspend fun saveConsent(consent: Boolean) {
        store.putBoolean(KEY_CONSENT, consent)
    }

    suspend fun hasCompletedOnboarding(): Boolean = store.getBoolean(KEY_CONSENT, false)

    suspend fun saveChtBenchmark(
        valueSeconds: Double,
        holdCapFraction: Double = 0.6,
        measuredAtIso: String = Instant.now().toString(),
    ) {
        val safeVal = valueSeconds.coerceAtLeast(3.0)
        store.putDouble(KEY_CHT_BENCHMARK, safeVal)

        val recommended = ProgressionEngine.calculateLevelFromCht(safeVal)
        val safeCap = (safeVal * holdCapFraction).toInt()
        val entry = ChtMeasurement(
            id = "cht_${System.currentTimeMillis()}_${safeVal.toInt()}",
            valueSeconds = safeVal,
            recommendedLevel = recommended,
            safeCapSeconds = safeCap,
            measuredAtIso = measuredAtIso,
        )
        val history = store.getStringList(KEY_CHT_HISTORY).toMutableList()
        history.add(json.encodeToString(entry))
        store.putStringList(KEY_CHT_HISTORY, history)
    }

    suspend fun loadChtBenchmark(): Double? {
        val v = store.getDouble(KEY_CHT_BENCHMARK, -1.0)
        return if (v < 0.0) null else v
    }

    suspend fun getChtHistory(): List<ChtMeasurement> =
        store.getStringList(KEY_CHT_HISTORY).mapNotNull { raw ->
            runCatching { json.decodeFromString<ChtMeasurement>(raw) }.getOrNull()
        }

    suspend fun saveCalibratedLevel(level: Int) {
        store.putInt(KEY_CALIBRATED_LEVEL, level.coerceIn(1, 7))
        val targetMinTapas = ProgressionEngine.getLevelInfo(level).minTapas
        val currentBonus = store.getInt(KEY_BONUS_TAPAS, 0)
        if (currentBonus < targetMinTapas) {
            store.putInt(KEY_BONUS_TAPAS, targetMinTapas)
        }
    }

    suspend fun loadCalibratedLevel(): Int? {
        val v = store.getInt(KEY_CALIBRATED_LEVEL, -1)
        return if (v <= 0) null else v
    }

    suspend fun loadBonusTapas(): Int = store.getInt(KEY_BONUS_TAPAS, 0)

    suspend fun saveAudioPreferences(prefs: AudioPreferences) {
        store.putString(KEY_AUDIO_PREFS, json.encodeToString(prefs))
    }

    suspend fun loadAudioPreferences(): AudioPreferences {
        val raw = store.getString(KEY_AUDIO_PREFS) ?: return AudioPreferences()
        return runCatching { json.decodeFromString<AudioPreferences>(raw) }.getOrDefault(AudioPreferences())
    }

    suspend fun saveReminderSettings(settings: ReminderSettings) {
        store.putString(KEY_REMINDER_SETTINGS, json.encodeToString(settings))
    }

    suspend fun loadReminderSettings(): ReminderSettings {
        val raw = store.getString(KEY_REMINDER_SETTINGS) ?: return ReminderSettings()
        return runCatching { json.decodeFromString<ReminderSettings>(raw) }.getOrDefault(ReminderSettings())
    }

    suspend fun saveProfileSettings(settings: UserProfileSettings) {
        store.putString(KEY_PROFILE_SETTINGS, json.encodeToString(settings))
        store.putString(KEY_TRADITION, settings.tradition)
    }

    suspend fun loadProfileSettings(): UserProfileSettings {
        val raw = store.getString(KEY_PROFILE_SETTINGS) ?: return UserProfileSettings()
        return runCatching { json.decodeFromString<UserProfileSettings>(raw) }.getOrDefault(UserProfileSettings())
    }

    suspend fun getApprovedLevels(): Set<Int> {
        val list = store.getStringList(KEY_APPROVED_LEVELS)
        if (list.isEmpty()) return setOf(1, 2)
        return list.mapNotNull { it.toIntOrNull() }.toSet() + setOf(1, 2)
    }

    suspend fun approveLevel(level: Int) {
        val current = getApprovedLevels().toMutableSet()
        current.add(level.coerceIn(1, 7))
        store.putStringList(KEY_APPROVED_LEVELS, current.sorted().map { it.toString() })
    }

    suspend fun getTeacherClearedPractices(): Set<String> =
        store.getStringList(KEY_CLEARED_PRACTICES).map { it.lowercase() }.toSet()

    suspend fun setPracticeTeacherCleared(practiceId: String, cleared: Boolean) {
        val current = getTeacherClearedPractices().toMutableSet()
        val norm = practiceId.trim().lowercase()
        if (cleared) current.add(norm) else current.remove(norm)
        store.putStringList(KEY_CLEARED_PRACTICES, current.toList())
    }

    /**
     * NFR-03 GDPR / DPDP user data export.
     */
    suspend fun exportProfileSnapshotJson(): String {
        val snapshot = mapOf(
            "profile" to json.encodeToString(loadProfile() ?: SafetyProfile()),
            "tradition" to (loadTradition() ?: ""),
            "consent" to hasCompletedOnboarding().toString(),
            "settings" to json.encodeToString(loadProfileSettings()),
            "audioPreferences" to json.encodeToString(loadAudioPreferences()),
            "reminders" to json.encodeToString(loadReminderSettings()),
            "chtHistory" to json.encodeToString(getChtHistory()),
        )
        return json.encodeToString(snapshot)
    }

    /**
     * NFR-03 GDPR / DPDP data deletion on request.
     */
    suspend fun deleteAllUserData() {
        store.clearAll()
    }

    companion object {
        private const val KEY_PREGNANCY = "profile_pregnancy"
        private const val KEY_HYPERTENSION = "profile_hypertension"
        private const val KEY_HEART_CONDITION = "profile_heartCondition"
        private const val KEY_EPILEPSY = "profile_epilepsy"
        private const val KEY_GLAUCOMA = "profile_glaucoma"
        private const val KEY_HERNIA = "profile_hernia"
        private const val KEY_RECENT_SURGERY = "profile_recentSurgery"
        private const val KEY_ASTHMA = "profile_asthma"
        private const val KEY_PANIC = "profile_panic"
        private const val KEY_MENSTRUATION = "profile_menstruation"
        private const val KEY_EMPTY_STOMACH = "profile_emptyStomachConfirmed"
        private const val KEY_PROFILE_SAVED = "profile_saved"
        private const val KEY_TRADITION = "user_tradition"
        private const val KEY_CONSENT = "user_consent"
        private const val KEY_CHT_BENCHMARK = "user_cht_benchmark"
        private const val KEY_CHT_HISTORY = "user_cht_history"
        private const val KEY_CALIBRATED_LEVEL = "user_calibrated_sopana_level"
        private const val KEY_BONUS_TAPAS = "user_bonus_tapas_points"
        private const val KEY_AUDIO_PREFS = "user_audio_prefs"
        private const val KEY_REMINDER_SETTINGS = "user_reminder_settings"
        private const val KEY_PROFILE_SETTINGS = "user_profile_settings"
        private const val KEY_APPROVED_LEVELS = "user_approved_levels"
        private const val KEY_CLEARED_PRACTICES = "user_cleared_practices"
    }
}
