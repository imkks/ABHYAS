package com.pranaflow.abhyas.engine.meditation

import com.pranaflow.abhyas.engine.player.AudioCueEvent
import com.pranaflow.abhyas.engine.player.AudioCueType
import kotlin.math.roundToInt

enum class JapaStage {
    VAIKHARI, // Audible / Spoken aloud
    UPAMSHU,  // Whispered / Subtle lip movement
    MANASIKA, // Silent mental repetition
    LAYA,     // Stillness / Absorption
    COMPLETE,
}

enum class BreathAnchor {
    NOSTRILS,          // Nasagra Drishti
    NAVEL,             // Nabhi
    CHEST,             // Hridaya
    SPONTANEOUS_PAUSE, // Kevala Kumbhaka
}

/**
 * Pure Kotlin state machine for Progressive 3-Stage Naam Japa Meditation.
 * Transitions through Vaikhari -> Upamshu -> Manasika -> Laya Stillness -> Complete.
 */
class ProgressiveJapaEngine(
    val totalDurationSeconds: Int = 900,
    val totalTargetBeads: Int? = null,
    val isCountBased: Boolean = false,
    val vaikhariRatio: Double = 0.33,
    val upamshuRatio: Double = 0.33,
    val manasikaRatio: Double = 0.34,
) {
    var currentStage: JapaStage = JapaStage.VAIKHARI
        private set
    private var secondsInCurrentStage: Int = 0
    private var beadsInCurrentStage: Int = 0

    val stageName: String
        get() = when (currentStage) {
            JapaStage.VAIKHARI -> "Vaikhari (Audible Chanting)"
            JapaStage.UPAMSHU -> "Upamshu (Whispered Chanting)"
            JapaStage.MANASIKA -> "Manasika (Mental Silence)"
            JapaStage.LAYA -> "Laya (Silent Absorption)"
            JapaStage.COMPLETE -> "Completed"
        }

    val stageInstruction: String
        get() = when (currentStage) {
            JapaStage.VAIKHARI -> "Chant aloud with clear voice to capture the physical senses."
            JapaStage.UPAMSHU -> "Lower voice to a whisper. Move only lips and feel the subtle vibration."
            JapaStage.MANASIKA -> "Still the lips and tongue completely. Let the mantra resonate mentally."
            JapaStage.LAYA -> "Release all repetition. Rest in the vibrating silence within."
            JapaStage.COMPLETE -> "Practice complete. Carry the inner peace into your day."
        }

    val vaikhariTargetSeconds: Int get() = (totalDurationSeconds * vaikhariRatio).roundToInt()
    val upamshuTargetSeconds: Int get() = (totalDurationSeconds * upamshuRatio).roundToInt()
    val manasikaTargetSeconds: Int get() = (totalDurationSeconds * manasikaRatio).roundToInt()
    val layaTargetSeconds: Int get() = 60

    val vaikhariTargetBeads: Int get() = ((totalTargetBeads ?: 108) * vaikhariRatio).roundToInt()
    val upamshuTargetBeads: Int get() = ((totalTargetBeads ?: 108) * upamshuRatio).roundToInt()
    val manasikaTargetBeads: Int get() = (totalTargetBeads ?: 108) - vaikhariTargetBeads - upamshuTargetBeads

    fun start(): AudioCueEvent {
        currentStage = JapaStage.VAIKHARI
        secondsInCurrentStage = 0
        beadsInCurrentStage = 0

        return AudioCueEvent(
            type = AudioCueType.PRACTICE_START,
            spokenText = "Begin chanting aloud with a clear voice.",
            voiceAssetIdentifier = "audio/voice/voice_japa_vaikhari.wav",
            soundIdentifier = "audio/singingBowl_practice_start_gong.wav",
            triggerHaptic = true,
        )
    }

    fun tickSecond(totalElapsedSeconds: Int): AudioCueEvent? {
        if (currentStage == JapaStage.COMPLETE) return null
        secondsInCurrentStage++

        return when {
            currentStage == JapaStage.VAIKHARI && secondsInCurrentStage >= vaikhariTargetSeconds ->
                advanceToNextStage()
            currentStage == JapaStage.UPAMSHU && secondsInCurrentStage >= upamshuTargetSeconds ->
                advanceToNextStage()
            currentStage == JapaStage.MANASIKA && secondsInCurrentStage >= manasikaTargetSeconds ->
                advanceToNextStage()
            currentStage == JapaStage.LAYA && secondsInCurrentStage >= layaTargetSeconds -> {
                currentStage = JapaStage.COMPLETE
                AudioCueEvent(
                    type = AudioCueType.SESSION_ENDING,
                    spokenText = "When you are ready, gently open your eyes.",
                    voiceAssetIdentifier = "audio/voice/voice_open_eyes.wav",
                    soundIdentifier = "audio/singingBowl_shanti_chime.wav",
                    triggerHaptic = true,
                )
            }
            else -> null
        }
    }

    fun advanceBead(currentTotalBead: Int): AudioCueEvent? {
        if (!isCountBased || currentStage == JapaStage.COMPLETE || currentStage == JapaStage.LAYA) return null
        beadsInCurrentStage++

        return when {
            currentStage == JapaStage.VAIKHARI && beadsInCurrentStage >= vaikhariTargetBeads ->
                advanceToNextStage()
            currentStage == JapaStage.UPAMSHU && beadsInCurrentStage >= upamshuTargetBeads ->
                advanceToNextStage()
            currentStage == JapaStage.MANASIKA && currentTotalBead >= (totalTargetBeads ?: 108) ->
                advanceToNextStage()
            else -> null
        }
    }

    fun advanceToNextStage(): AudioCueEvent {
        secondsInCurrentStage = 0
        beadsInCurrentStage = 0

        return when (currentStage) {
            JapaStage.VAIKHARI -> {
                currentStage = JapaStage.UPAMSHU
                AudioCueEvent(
                    type = AudioCueType.PHASE_TRANSITION,
                    spokenText = "Shift to Upamshu. Lower your voice to a gentle whisper, moving only your lips.",
                    voiceAssetIdentifier = "audio/voice/voice_japa_upamshu.wav",
                    soundIdentifier = "audio/singingBowl_kumbhaka_hold.wav",
                    triggerHaptic = true,
                )
            }
            JapaStage.UPAMSHU -> {
                currentStage = JapaStage.MANASIKA
                AudioCueEvent(
                    type = AudioCueType.PHASE_TRANSITION,
                    spokenText = "Shift to Manasika. Still the lips and tongue. Allow the mantra to repeat silently in the mind.",
                    voiceAssetIdentifier = "audio/voice/voice_japa_manasika.wav",
                    soundIdentifier = "audio/singingBowl_puraka_inhale.wav",
                    triggerHaptic = true,
                )
            }
            JapaStage.MANASIKA -> {
                currentStage = JapaStage.LAYA
                AudioCueEvent(
                    type = AudioCueType.SESSION_ENDING,
                    spokenText = "Release all repetition. Rest in the vibrating silence.",
                    voiceAssetIdentifier = "audio/voice/voice_japa_laya.wav",
                    soundIdentifier = "audio/singingBowl_session_complete_3bowls.wav",
                    triggerHaptic = true,
                )
            }
            JapaStage.LAYA, JapaStage.COMPLETE -> {
                currentStage = JapaStage.COMPLETE
                AudioCueEvent(
                    type = AudioCueType.INTEGRATION_COMPLETE,
                    spokenText = "When you are ready, gently open your eyes.",
                    voiceAssetIdentifier = "audio/voice/voice_open_eyes.wav",
                    soundIdentifier = "audio/singingBowl_shanti_chime.wav",
                    triggerHaptic = true,
                )
            }
        }
    }
}

/**
 * Pure Kotlin state machine for Breath Awareness Meditation (Prana Dharana / Anapana).
 */
class PranaDharanaEngine(
    val durationMinutes: Int = 10,
    val anchor: BreathAnchor = BreathAnchor.NOSTRILS,
    val intervalReminderSeconds: Int = 180,
) {
    private var lastReminderSecond: Int = 0
    private var reminderIndex: Int = 0

    var isComplete: Boolean = false
        private set

    val totalSeconds: Int
        get() = durationMinutes * 60

    fun start(): AudioCueEvent {
        lastReminderSecond = 0
        reminderIndex = 0
        isComplete = false
        return AudioCueEvent(
            type = AudioCueType.PRACTICE_START,
            spokenText = "Sit upright and ease the body. Allow the breath to flow naturally without any effort.",
            voiceAssetIdentifier = "audio/voice/voice_breath_intro.wav",
            soundIdentifier = "audio/singingBowl_practice_start_gong.wav",
            triggerHaptic = false,
        )
    }

    fun tickSecond(elapsedSeconds: Int): AudioCueEvent? {
        if (isComplete) return null

        if (elapsedSeconds >= totalSeconds) {
            isComplete = true
            return AudioCueEvent(
                type = AudioCueType.SESSION_ENDING,
                spokenText = "Meditation complete. Gently bring awareness back to the physical body and open your eyes.",
                voiceAssetIdentifier = "audio/voice/voice_breath_complete.wav",
                soundIdentifier = "audio/singingBowl_session_complete_3bowls.wav",
                triggerHaptic = false,
            )
        }

        if (elapsedSeconds > 0 &&
            (elapsedSeconds - lastReminderSecond) >= intervalReminderSeconds &&
            (totalSeconds - elapsedSeconds) > 60
        ) {
            lastReminderSecond = elapsedSeconds
            reminderIndex++
            return when (reminderIndex % 3) {
                1 -> AudioCueEvent(
                    type = AudioCueType.PHASE_TRANSITION,
                    spokenText = "Notice the cool touch of inhalation at the nostrils, and the warmth of exhalation.",
                    voiceAssetIdentifier = "audio/voice/voice_breath_nostril.wav",
                    soundIdentifier = "audio/singingBowl_kumbhaka_hold.wav",
                    triggerHaptic = false,
                )
                2 -> AudioCueEvent(
                    type = AudioCueType.PHASE_TRANSITION,
                    spokenText = "Rest your attention in the quiet space between the breaths.",
                    voiceAssetIdentifier = "audio/voice/voice_breath_pause.wav",
                    soundIdentifier = "audio/singingBowl_puraka_inhale.wav",
                    triggerHaptic = false,
                )
                else -> AudioCueEvent(
                    type = AudioCueType.PHASE_TRANSITION,
                    spokenText = "If the mind has wandered, gently bring awareness back to the natural breath.",
                    voiceAssetIdentifier = "audio/voice/voice_breath_return.wav",
                    soundIdentifier = "audio/singingBowl_tick_soft.wav",
                    triggerHaptic = false,
                )
            }
        }

        return null
    }
}

data class MalaAdvanceResult(
    val currentBead: Int,
    val roundsCompleted: Int,
    val meruReached: Boolean,
)

/**
 * Pure Kotlin 108-bead Digital Mala state machine (FR-DH-02).
 * Supports 27, 54, 108, or continuous (-1) bead targets and signals Meru completion without crossing the Meru bead.
 */
class DigitalMalaEngine(
    initialBeadCount: Int = 0,
    initialRoundsCompleted: Int = 0,
    val targetBeads: Int = 108,
) {
    var currentBead: Int = initialBeadCount
        private set
    var roundsCompleted: Int = initialRoundsCompleted
        private set

    fun advanceBead(): MalaAdvanceResult {
        val next = currentBead + 1
        return if (targetBeads > 0 && next >= targetBeads) {
            roundsCompleted++
            currentBead = 0
            MalaAdvanceResult(
                currentBead = 0,
                roundsCompleted = roundsCompleted,
                meruReached = true,
            )
        } else {
            currentBead = next
            MalaAdvanceResult(
                currentBead = currentBead,
                roundsCompleted = roundsCompleted,
                meruReached = false,
            )
        }
    }

    fun resetCurrentRound() {
        currentBead = 0
    }
}
