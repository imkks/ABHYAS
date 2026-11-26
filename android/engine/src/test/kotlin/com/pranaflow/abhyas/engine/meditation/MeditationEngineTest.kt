package com.pranaflow.abhyas.engine.meditation

import com.pranaflow.abhyas.engine.clock.FakeMonotonicClock
import com.pranaflow.abhyas.engine.player.AudioCueType
import com.pranaflow.abhyas.engine.player.YogaNidraPlayer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MeditationEngineTest {

    @Test
    fun `ProgressiveJapaEngine transitions time-based through all 4 stages`() {
        val engine = ProgressiveJapaEngine(
            totalDurationSeconds = 300,
            vaikhariRatio = 0.33,
            upamshuRatio = 0.33,
            manasikaRatio = 0.34,
        )
        val start = engine.start()
        assertEquals(JapaStage.VAIKHARI, engine.currentStage)
        assertTrue(start.voiceAssetIdentifier!!.contains("voice_japa_vaikhari.wav"))

        var lastCue = start
        for (s in 1..100) {
            engine.tickSecond(s)?.let { lastCue = it }
        }
        assertEquals(JapaStage.UPAMSHU, engine.currentStage)
        assertTrue(lastCue.voiceAssetIdentifier!!.contains("voice_japa_upamshu.wav"))

        for (s in 101..200) {
            engine.tickSecond(s)?.let { lastCue = it }
        }
        assertEquals(JapaStage.MANASIKA, engine.currentStage)
        assertTrue(lastCue.voiceAssetIdentifier!!.contains("voice_japa_manasika.wav"))

        for (s in 201..305) {
            engine.tickSecond(s)?.let { lastCue = it }
        }
        assertEquals(JapaStage.LAYA, engine.currentStage)
        assertTrue(lastCue.voiceAssetIdentifier!!.contains("voice_japa_laya.wav"))

        for (s in 306..366) {
            engine.tickSecond(s)?.let { lastCue = it }
        }
        assertEquals(JapaStage.COMPLETE, engine.currentStage)
        assertTrue(lastCue.voiceAssetIdentifier!!.contains("voice_open_eyes.wav"))
    }

    @Test
    fun `ProgressiveJapaEngine bead-count mode advances on 108 beads`() {
        val engine = ProgressiveJapaEngine(
            totalTargetBeads = 108,
            isCountBased = true,
            vaikhariRatio = 0.333,
            upamshuRatio = 0.333,
            manasikaRatio = 0.334,
        )
        engine.start()
        for (b in 1..36) engine.advanceBead(b)
        assertEquals(JapaStage.UPAMSHU, engine.currentStage)

        for (b in 37..72) engine.advanceBead(b)
        assertEquals(JapaStage.MANASIKA, engine.currentStage)

        for (b in 73..108) engine.advanceBead(b)
        assertEquals(JapaStage.LAYA, engine.currentStage)
    }

    @Test
    fun `PranaDharanaEngine provides gentle spaced reminders and completion cue`() {
        val engine = PranaDharanaEngine(durationMinutes = 10, intervalReminderSeconds = 180)
        val start = engine.start()
        assertTrue(start.voiceAssetIdentifier!!.contains("voice_breath_intro.wav"))
        assertFalse(engine.isComplete)

        assertNull(engine.tickSecond(60))
        assertNull(engine.tickSecond(120))

        val r1 = engine.tickSecond(180)
        assertNotNull(r1)
        assertTrue(r1!!.voiceAssetIdentifier!!.contains("voice_breath_nostril.wav"))

        val r2 = engine.tickSecond(360)
        assertNotNull(r2)
        assertTrue(r2!!.voiceAssetIdentifier!!.contains("voice_breath_pause.wav"))

        val end = engine.tickSecond(600)
        assertNotNull(end)
        assertEquals(AudioCueType.SESSION_ENDING, end!!.type)
        assertTrue(engine.isComplete)
    }

    @Test
    fun `DigitalMalaEngine signals Meru at 108th bead and resets without crossing`() {
        val mala = DigitalMalaEngine(targetBeads = 108)
        repeat(107) {
            val res = mala.advanceBead()
            assertFalse(res.meruReached)
        }
        val meru = mala.advanceBead()
        assertTrue(meru.meruReached)
        assertEquals(0, meru.currentBead)
        assertEquals(1, meru.roundsCompleted)
    }

    @Test
    fun `YogaNidraPlayer tracks monotonic progress, seek, and 7 stages`() {
        val clock = FakeMonotonicClock()
        val nidra = YogaNidraPlayer(durationMinutes = 20, clock = clock)
        nidra.start()
        assertTrue(nidra.currentStageName().contains("Savasana"))

        clock.advanceBySeconds(400) // ~33%
        assertTrue(nidra.currentStageName().contains("Nyasa"))

        nidra.seekToSeconds(1200)
        assertEquals(1200, nidra.elapsedSeconds())
        assertTrue(nidra.isCompleted)
    }
}
