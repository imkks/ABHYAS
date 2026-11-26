package com.pranaflow.abhyas.core.audio

import com.pranaflow.abhyas.core.haptic.HapticService
import com.pranaflow.abhyas.engine.player.AudioCueEvent
import com.pranaflow.abhyas.engine.player.AudioCueType

/**
 * Dispatches [AudioCueEvent]s from [com.pranaflow.abhyas.engine.player.AudioGuidanceEngine]
 * to the native audio driver and haptic controller, preserving separate tone & voice channels.
 */
class PracticeAudioService(
    private val driver: AudioPlaybackDriver,
    private val hapticService: HapticService,
) {
    var isVoiceEnabled: Boolean = true
    var isAudioTonesEnabled: Boolean = true
    var isHapticsEnabled: Boolean
        get() = hapticService.isEnabled
        set(value) {
            hapticService.isEnabled = value
        }
    var volume: Float = 0.85f

    private val _eventHistory = mutableListOf<AudioCueEvent>()
    val eventHistory: List<AudioCueEvent> get() = _eventHistory.toList()

    fun clearHistory() {
        _eventHistory.clear()
    }

    fun dispatchCue(cue: AudioCueEvent, weaningStage: Int = 1) {
        _eventHistory.add(cue)

        if (hapticService.isEnabled && cue.triggerHaptic) {
            when (cue.type) {
                AudioCueType.SETTLING_TICK,
                AudioCueType.PACING_PULSE -> hapticService.pulseForMatra(weaningStage)
                AudioCueType.PHASE_TRANSITION -> hapticService.phaseTransitionPulse(weaningStage)
                AudioCueType.EMERGENCY_GROUNDING -> hapticService.safetyStopPulse()
                AudioCueType.SESSION_ENDING,
                AudioCueType.INTEGRATION_START,
                AudioCueType.INTEGRATION_COMPLETE -> hapticService.completionPulse()
                else -> hapticService.phaseTransitionPulse(weaningStage)
            }
        }

        if (isAudioTonesEnabled && cue.soundIdentifier != "silence") {
            if (cue.soundIdentifier.contains("tick")) {
                driver.playSystemTick()
            } else {
                driver.playBellAsset(cue.soundIdentifier, volume)
            }
        }

        if (isVoiceEnabled && cue.voiceAssetIdentifier != null) {
            driver.playVoiceAsset(cue.voiceAssetIdentifier!!, volume)
        }
    }

    fun stopAll() {
        driver.stopAll()
    }
}
