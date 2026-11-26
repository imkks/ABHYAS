package com.pranaflow.abhyas.core.di

import android.content.Context
import com.pranaflow.abhyas.core.audio.AndroidAudioPlaybackDriver
import com.pranaflow.abhyas.core.audio.AudioPlaybackDriver
import com.pranaflow.abhyas.core.audio.AudioService
import com.pranaflow.abhyas.core.audio.PracticeAudioService
import com.pranaflow.abhyas.core.haptic.AndroidHapticDriver
import com.pranaflow.abhyas.core.haptic.HapticDriver
import com.pranaflow.abhyas.core.haptic.HapticService
import com.pranaflow.abhyas.data.repositories.ConfigRepository
import com.pranaflow.abhyas.data.repositories.ContentRepository
import com.pranaflow.abhyas.data.repositories.MantraAndRoutineRepository
import com.pranaflow.abhyas.data.repositories.SessionRepository
import com.pranaflow.abhyas.data.repositories.UserRepository
import com.pranaflow.abhyas.data.store.DataStoreKeyValueStore
import com.pranaflow.abhyas.data.store.KeyValueStore
import com.pranaflow.abhyas.engine.progression.ProgressionEngine
import com.pranaflow.abhyas.engine.progression.UserProgression
import com.pranaflow.abhyas.engine.safety.PracticeAccessResult
import com.pranaflow.abhyas.engine.safety.SafetyProfile
import com.pranaflow.abhyas.engine.safety.SafetyRulesEngine
import java.time.LocalDate

/**
 * Clean local dependency container wiring the pure Kotlin :engine and offline DataStore repositories/services.
 * Runs in open advisory mode without remote backend control.
 */
class AbhyasContainer(
    private val appContext: Context,
    val store: KeyValueStore = DataStoreKeyValueStore(appContext),
    val onAudioFocusInterrupted: (() -> Unit)? = null,
    private val customAudioDriver: AudioPlaybackDriver? = null,
    private val customHapticDriver: HapticDriver? = null,
) {
    val configRepository: ConfigRepository by lazy { ConfigRepository(store) }
    val userRepository: UserRepository by lazy { UserRepository(store) }
    val sessionRepository: SessionRepository by lazy { SessionRepository(store) }
    val mantraAndRoutineRepository: MantraAndRoutineRepository by lazy { MantraAndRoutineRepository(store) }
    val contentRepository: ContentRepository by lazy {
        ContentRepository(
            assetReader = { path ->
                runCatching {
                    appContext.assets.open(path).bufferedReader().use { it.readText() }
                }.getOrNull()
            },
            pilotMode = false,
        )
    }

    val hapticService: HapticService by lazy {
        HapticService(customHapticDriver ?: AndroidHapticDriver(appContext))
    }
    val audioDriver: AudioPlaybackDriver by lazy {
        customAudioDriver ?: AndroidAudioPlaybackDriver(appContext, onAudioFocusInterrupted)
    }
    val audioService: AudioService by lazy { AudioService(audioDriver) }
    val practiceAudioService: PracticeAudioService by lazy { PracticeAudioService(audioDriver, hapticService) }

    fun evaluatePracticeAccess(
        practiceId: String,
        userLevel: Int,
        requiredLevel: Int = 1,
        profile: SafetyProfile = SafetyProfile(),
    ): PracticeAccessResult = SafetyRulesEngine.evaluatePracticeAccess(
        practice = practiceId,
        profile = profile,
        userLevel = userLevel,
        requiredLevel = requiredLevel,
        openAccessMode = true,
        teacherGatingEnabled = false,
    )

    suspend fun computeUserProgression(
        todayEpochDay: Long = LocalDate.now().toEpochDay(),
    ): UserProgression {
        val config = configRepository.getActiveConfig()
        val sessions = sessionRepository.getSessions().map { it.toSummary() }
        val bonusTapas = userRepository.loadBonusTapas()
        val calibratedLevel = userRepository.loadCalibratedLevel()
        val profileSettings = userRepository.loadProfileSettings()

        return ProgressionEngine.computeProgression(
            sessions = sessions,
            todayEpochDay = todayEpochDay,
            bonusTapas = bonusTapas,
            calibratedLevel = calibratedLevel,
            teacherGatingEnabled = false,
            config = config,
            manualWeaningStage = profileSettings.manualWeaningStageOverride,
        )
    }
}
