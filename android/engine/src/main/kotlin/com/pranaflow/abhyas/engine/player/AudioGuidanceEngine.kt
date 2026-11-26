package com.pranaflow.abhyas.engine.player

enum class AudioGuidanceLevel {
    STAGE_1_GUIDED,      // Pre-flight instruction + 1-word cues + earcons + pulse
    STAGE_2_CUED,        // Phase name cue + earcons (no verbal counting)
    STAGE_3_SONIC_TIMER, // Harmonic earcons only, zero spoken voice
    STAGE_4_SELF_LED,    // Start, halfway, and end bells only; silence during cycles
    STAGE_5_INDEPENDENT, // Silent self-assessment mode
}

enum class SoundPalette(val prefix: String) {
    SINGING_BOWL("singingBowl"),
    TEMPLE_BELL("templeBell"),
    WOODBLOCK("woodblock"),
    FLUTE_HARMONIC("fluteHarmonic"),
}

enum class AudioCueType {
    SETTLING_START,
    SETTLING_TICK,
    PRACTICE_START,
    PHASE_TRANSITION,
    PACING_PULSE,
    HALFWAY_POINT,
    CYCLE_COMPLETE,
    SESSION_ENDING,
    INTEGRATION_START,
    INTEGRATION_COMPLETE,
    EMERGENCY_GROUNDING,
}

enum class HandsFreeAction {
    TOGGLE_PLAY_PAUSE,
    NEXT_PHASE_OR_CYCLE,
    EMERGENCY_STOP,
    REPEAT_CUE,
}

data class AudioCueEvent(
    val type: AudioCueType,
    val phase: PracticePhase? = null,
    val spokenText: String? = null,
    val voiceAssetIdentifier: String? = null,
    val soundIdentifier: String,
    val triggerHaptic: Boolean = true,
)

/**
 * Pure Kotlin audio guidance planner and state coordinator.
 * Keeps practice hands-free with minimal disturbance and handles progressive 5-stage weaning (FR-WN-01).
 */
class AudioGuidanceEngine(
    val palette: SoundPalette = SoundPalette.SINGING_BOWL,
    val weaningStage: Int = 1,
    val settlingDurationSeconds: Int = 10,
    val integrationDurationSeconds: Int = 60,
) {
    var settlingSecondsLeft: Int = settlingDurationSeconds
        private set
    var integrationSecondsLeft: Int = integrationDurationSeconds
        private set
    var isSettling: Boolean = false
        private set
    var isIntegrating: Boolean = false
        private set

    val guidanceLevel: AudioGuidanceLevel
        get() = when (weaningStage) {
            1 -> AudioGuidanceLevel.STAGE_1_GUIDED
            2 -> AudioGuidanceLevel.STAGE_2_CUED
            3 -> AudioGuidanceLevel.STAGE_3_SONIC_TIMER
            4 -> AudioGuidanceLevel.STAGE_4_SELF_LED
            else -> AudioGuidanceLevel.STAGE_5_INDEPENDENT
        }

    fun startSettlingBuffer(): AudioCueEvent {
        isSettling = true
        settlingSecondsLeft = settlingDurationSeconds
        isIntegrating = false

        val spokenText = if (weaningStage <= 2) {
            "Take your seat, close your eyes, and settle into posture."
        } else {
            null
        }
        val voiceAsset = if (weaningStage <= 2) "audio/voice/voice_settle.wav" else null

        return AudioCueEvent(
            type = AudioCueType.SETTLING_START,
            spokenText = spokenText,
            voiceAssetIdentifier = voiceAsset,
            soundIdentifier = paletteSoundKey("settling_bell"),
            triggerHaptic = weaningStage < 5,
        )
    }

    fun tickSettlingBuffer(): AudioCueEvent? {
        if (!isSettling) return null
        if (settlingSecondsLeft > 0) {
            settlingSecondsLeft--
        }

        if (settlingSecondsLeft == 0) {
            isSettling = false
            return AudioCueEvent(
                type = AudioCueType.PRACTICE_START,
                spokenText = if (weaningStage <= 2) "Begin." else null,
                voiceAssetIdentifier = if (weaningStage <= 2) "audio/voice/voice_begin.wav" else null,
                soundIdentifier = paletteSoundKey("practice_start_gong"),
                triggerHaptic = weaningStage < 5,
            )
        }

        if (settlingSecondsLeft in 1..3) {
            return AudioCueEvent(
                type = AudioCueType.SETTLING_TICK,
                spokenText = if (weaningStage == 1) "$settlingSecondsLeft" else null,
                voiceAssetIdentifier = if (weaningStage == 1) "audio/voice/voice_count_$settlingSecondsLeft.wav" else null,
                soundIdentifier = paletteSoundKey("tick_soft"),
                triggerHaptic = weaningStage < 5,
            )
        }

        return null
    }

    fun getCueForPhaseTransition(
        phase: PracticePhase,
        cycleNumber: Int,
    ): AudioCueEvent {
        val level = guidanceLevel
        var soundKey: String
        var spokenText: String? = null
        var voiceAsset: String? = null

        when (phase) {
            PracticePhase.PURAKA -> {
                soundKey = paletteSoundKey("puraka_inhale")
                if (level == AudioGuidanceLevel.STAGE_1_GUIDED || level == AudioGuidanceLevel.STAGE_2_CUED) {
                    spokenText = "Inhale"
                    voiceAsset = "audio/voice/voice_puraka.wav"
                }
            }
            PracticePhase.ANTAR_KUMBHAKA -> {
                soundKey = paletteSoundKey("kumbhaka_hold")
                if (level == AudioGuidanceLevel.STAGE_1_GUIDED || level == AudioGuidanceLevel.STAGE_2_CUED) {
                    spokenText = "Hold"
                    voiceAsset = "audio/voice/voice_kumbhaka.wav"
                }
            }
            PracticePhase.RECHAKA -> {
                soundKey = paletteSoundKey("rechaka_exhale")
                if (level == AudioGuidanceLevel.STAGE_1_GUIDED || level == AudioGuidanceLevel.STAGE_2_CUED) {
                    spokenText = "Exhale"
                    voiceAsset = "audio/voice/voice_rechaka.wav"
                }
            }
            PracticePhase.BAHYA_KUMBHAKA -> {
                soundKey = paletteSoundKey("bahya_pause")
                if (level == AudioGuidanceLevel.STAGE_1_GUIDED || level == AudioGuidanceLevel.STAGE_2_CUED) {
                    spokenText = "Suspend"
                    voiceAsset = "audio/voice/voice_bahya.wav"
                }
            }
            PracticePhase.NATURAL_BREATH -> {
                soundKey = paletteSoundKey("grounding_bell")
                spokenText = "Ease your breath. Rest naturally."
                voiceAsset = "audio/voice/voice_rest.wav"
            }
        }

        if (level == AudioGuidanceLevel.STAGE_3_SONIC_TIMER) {
            spokenText = null
            voiceAsset = null
        } else if (level == AudioGuidanceLevel.STAGE_4_SELF_LED || level == AudioGuidanceLevel.STAGE_5_INDEPENDENT) {
            spokenText = null
            voiceAsset = null
            soundKey = "silence"
        }

        return AudioCueEvent(
            type = AudioCueType.PHASE_TRANSITION,
            phase = phase,
            spokenText = spokenText,
            voiceAssetIdentifier = voiceAsset,
            soundIdentifier = soundKey,
            triggerHaptic = level != AudioGuidanceLevel.STAGE_5_INDEPENDENT,
        )
    }

    /**
     * AC-9: Emergency exit audio cue returning immediately to natural breath.
     */
    fun getEmergencyGroundingCue(): AudioCueEvent {
        isSettling = false
        isIntegrating = false
        return AudioCueEvent(
            type = AudioCueType.EMERGENCY_GROUNDING,
            phase = PracticePhase.NATURAL_BREATH,
            spokenText = "Ease your breath. Rest naturally.",
            voiceAssetIdentifier = "audio/voice/voice_rest.wav",
            soundIdentifier = paletteSoundKey("grounding_bell"),
            triggerHaptic = true,
        )
    }

    fun startIntegrationBuffer(): AudioCueEvent {
        isIntegrating = true
        isSettling = false
        integrationSecondsLeft = integrationDurationSeconds

        return AudioCueEvent(
            type = AudioCueType.INTEGRATION_START,
            spokenText = if (weaningStage <= 2) "Practice complete. Remain still and observe the breath." else null,
            voiceAssetIdentifier = if (weaningStage <= 2) "audio/voice/voice_complete.wav" else null,
            soundIdentifier = paletteSoundKey("session_complete_3bowls"),
            triggerHaptic = weaningStage < 5,
        )
    }

    fun tickIntegrationBuffer(): AudioCueEvent? {
        if (!isIntegrating) return null
        if (integrationSecondsLeft > 0) {
            integrationSecondsLeft--
        }
        if (integrationSecondsLeft == 0) {
            isIntegrating = false
            return AudioCueEvent(
                type = AudioCueType.INTEGRATION_COMPLETE,
                spokenText = "When you are ready, gently open your eyes.",
                voiceAssetIdentifier = "audio/voice/voice_open_eyes.wav",
                soundIdentifier = paletteSoundKey("shanti_chime"),
                triggerHaptic = weaningStage < 5,
            )
        }
        return null
    }

    private fun paletteSoundKey(baseName: String): String =
        "audio/${palette.prefix}_$baseName.wav"
}
