package com.pranaflow.abhyas.core

import com.pranaflow.abhyas.core.audio.AudioService
import com.pranaflow.abhyas.core.audio.BellType
import com.pranaflow.abhyas.core.audio.PracticeAudioService
import com.pranaflow.abhyas.core.audio.RecordingAudioPlaybackDriver
import com.pranaflow.abhyas.core.haptic.HapticPattern
import com.pranaflow.abhyas.core.haptic.HapticService
import com.pranaflow.abhyas.core.haptic.NoOpHapticDriver
import com.pranaflow.abhyas.engine.meditation.JapaStage
import com.pranaflow.abhyas.engine.player.AudioCueEvent
import com.pranaflow.abhyas.engine.player.AudioCueType
import com.pranaflow.abhyas.engine.player.PracticePhase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioAndHapticServiceTest {

    @Test
    fun `PracticeAudioService dispatches cues to driver, haptics, and event history`() {
        val audioDriver = RecordingAudioPlaybackDriver()
        val hapticDriver = NoOpHapticDriver()
        val hapticService = HapticService(hapticDriver).apply { isEnabled = true }
        val service = PracticeAudioService(audioDriver, hapticService)

        val cue = AudioCueEvent(
            type = AudioCueType.PHASE_TRANSITION,
            phase = PracticePhase.PURAKA,
            spokenText = "Inhale",
            voiceAssetIdentifier = "audio/voice/voice_puraka.wav",
            soundIdentifier = "audio/singingBowl_puraka_inhale.wav",
            triggerHaptic = true,
        )

        service.dispatchCue(cue, weaningStage = 1)
        assertEquals(1, service.eventHistory.size)
        assertEquals(listOf("audio/singingBowl_puraka_inhale.wav"), audioDriver.playedBells)
        assertEquals(listOf("audio/voice/voice_puraka.wav"), audioDriver.playedVoices)
        assertEquals(listOf(HapticPattern.PHASE_TRANSITION), hapticDriver.recordedPatterns)
    }

    @Test
    fun `AudioService routes Naam Japa stages, bells, ticks, and tracks properly`() {
        val driver = RecordingAudioPlaybackDriver()
        val audioService = AudioService(driver)

        audioService.playBell(BellType.START)
        audioService.playNaamJapaPhase(JapaStage.UPAMSHU)
        audioService.playTick()
        audioService.playTrack("audio/yoga_nidra_20min.mp3")

        assertTrue(driver.playedBells.any { it.contains("practice_start_gong") })
        assertTrue(driver.playedVoices.any { it.contains("voice_japa_upamshu") })
        assertEquals(1, driver.tickCount)
        assertTrue(audioService.isPlaying)

        audioService.pauseTrack()
        assertTrue(driver.paused)
        audioService.stopAll()
        assertEquals(1, driver.stoppedCount)
    }

    @Test
    fun `HapticService respects weaning stage silencing`() {
        val hapticDriver = NoOpHapticDriver()
        val service = HapticService(hapticDriver)
        service.isEnabled = true

        service.pulseForMatra(weaningStage = 5)
        service.phaseTransitionPulse(weaningStage = 5)
        service.roundCompletePulse(weaningStage = 5)
        assertTrue(hapticDriver.recordedPatterns.isEmpty())

        service.safetyStopPulse()
        assertEquals(listOf(HapticPattern.SAFETY_STOP), hapticDriver.recordedPatterns)
    }
}
