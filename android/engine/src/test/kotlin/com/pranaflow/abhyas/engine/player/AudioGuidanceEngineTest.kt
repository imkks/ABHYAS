package com.pranaflow.abhyas.engine.player

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioGuidanceEngineTest {

    @Test
    fun `correct guidance levels selected for all 5 weaning stages`() {
        assertEquals(AudioGuidanceLevel.STAGE_1_GUIDED, AudioGuidanceEngine(weaningStage = 1).guidanceLevel)
        assertEquals(AudioGuidanceLevel.STAGE_2_CUED, AudioGuidanceEngine(weaningStage = 2).guidanceLevel)
        assertEquals(AudioGuidanceLevel.STAGE_3_SONIC_TIMER, AudioGuidanceEngine(weaningStage = 3).guidanceLevel)
        assertEquals(AudioGuidanceLevel.STAGE_4_SELF_LED, AudioGuidanceEngine(weaningStage = 4).guidanceLevel)
        assertEquals(AudioGuidanceLevel.STAGE_5_INDEPENDENT, AudioGuidanceEngine(weaningStage = 5).guidanceLevel)
    }

    @Test
    fun `settling buffer counts down 3-2-1 and emits practiceStart`() {
        val engine = AudioGuidanceEngine(weaningStage = 1, settlingDurationSeconds = 4)
        val start = engine.startSettlingBuffer()
        assertEquals(AudioCueType.SETTLING_START, start.type)
        assertTrue(start.voiceAssetIdentifier!!.contains("voice_settle.wav"))

        val t3 = engine.tickSettlingBuffer()!!
        assertEquals("3", t3.spokenText)
        assertTrue(t3.voiceAssetIdentifier!!.contains("voice_count_3.wav"))

        val t2 = engine.tickSettlingBuffer()!!
        assertEquals("2", t2.spokenText)

        val t1 = engine.tickSettlingBuffer()!!
        assertEquals("1", t1.spokenText)

        val begin = engine.tickSettlingBuffer()!!
        assertEquals(AudioCueType.PRACTICE_START, begin.type)
        assertFalse(engine.isSettling)
    }

    @Test
    fun `AC-10 Stage 3 mutes voice and Stage 4-5 keep cycle silence`() {
        val stage3 = AudioGuidanceEngine(weaningStage = 3)
        val puraka3 = stage3.getCueForPhaseTransition(PracticePhase.PURAKA, 1)
        assertNull(puraka3.spokenText)
        assertNull(puraka3.voiceAssetIdentifier)
        assertTrue(puraka3.soundIdentifier.contains("puraka_inhale"))
        assertTrue(puraka3.triggerHaptic)

        val stage4 = AudioGuidanceEngine(weaningStage = 4)
        val puraka4 = stage4.getCueForPhaseTransition(PracticePhase.PURAKA, 1)
        assertNull(puraka4.spokenText)
        assertEquals("silence", puraka4.soundIdentifier)

        val stage5 = AudioGuidanceEngine(weaningStage = 5)
        val puraka5 = stage5.getCueForPhaseTransition(PracticePhase.PURAKA, 1)
        assertEquals("silence", puraka5.soundIdentifier)
        assertFalse(puraka5.triggerHaptic)
    }

    @Test
    fun `AC-9 emergency grounding and post-session integration cues`() {
        val engine = AudioGuidanceEngine(weaningStage = 1, integrationDurationSeconds = 2)
        val emergency = engine.getEmergencyGroundingCue()
        assertEquals(AudioCueType.EMERGENCY_GROUNDING, emergency.type)
        assertEquals(PracticePhase.NATURAL_BREATH, emergency.phase)
        assertTrue(emergency.soundIdentifier.contains("grounding_bell"))

        val integStart = engine.startIntegrationBuffer()
        assertEquals(AudioCueType.INTEGRATION_START, integStart.type)
        assertNull(engine.tickIntegrationBuffer())
        val integEnd = engine.tickIntegrationBuffer()
        assertNotNull(integEnd)
        assertEquals(AudioCueType.INTEGRATION_COMPLETE, integEnd?.type)
        assertTrue(integEnd!!.soundIdentifier.contains("shanti_chime"))
    }
}
