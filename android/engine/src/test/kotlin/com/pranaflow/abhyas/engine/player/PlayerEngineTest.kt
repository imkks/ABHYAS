package com.pranaflow.abhyas.engine.player

import com.pranaflow.abhyas.engine.clock.FakeMonotonicClock
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PlayerEngineTest {

    @Test
    fun `AC-2 engine caps hold time at min of level cap and CHT fraction`() {
        val engine = PlayerEngine(
            holdCapFractionOfCht = 0.6,
            levelCapSeconds = 30,
            userChtSeconds = 20,
        )
        assertEquals(12, engine.calculateMaxHoldSeconds())
        assertEquals(12, engine.scheduleHold(16))
        assertEquals(8, engine.scheduleHold(8))
    }

    @Test
    fun `SR-05 scheduleBahyaHold never exceeds antar hold or caps`() {
        val engine = PlayerEngine(
            holdCapFractionOfCht = 0.6,
            levelCapSeconds = 24,
            userChtSeconds = 30, // 18s user cap
            bahyaCapSeconds = 10,
        )
        assertEquals(8, engine.scheduleBahyaHold(ratioRequiredBahyaSeconds = 12, scheduledAntarSeconds = 8))
        assertEquals(10, engine.scheduleBahyaHold(ratioRequiredBahyaSeconds = 16, scheduledAntarSeconds = 16))
    }

    @Test
    fun `property test - for any valid parameters player never schedules hold above cap`() {
        for (cht in 0..90 step 5) {
            for (levelCap in listOf(4, 8, 16, 24, 32)) {
                for (fraction in listOf(0.4, 0.5, 0.6, 0.8)) {
                    val engine = PlayerEngine(
                        holdCapFractionOfCht = fraction,
                        levelCapSeconds = levelCap,
                        userChtSeconds = cht,
                    )
                    val theoreticalMax = minOf(levelCap, (cht * fraction).toInt())
                    assertEquals(theoreticalMax, engine.calculateMaxHoldSeconds())

                    for (reqAntar in 0..60 step 4) {
                        for (reqBahya in 0..60 step 4) {
                            val safeRatio = engine.resolveSafeRatio(listOf(4, reqAntar, 8, reqBahya))
                            assertTrue(safeRatio[1] <= theoreticalMax)
                            assertTrue(safeRatio[3] <= safeRatio[1])
                            assertTrue(safeRatio[3] <= theoreticalMax)
                        }
                    }
                }
            }
        }
    }

    @Test
    fun `AC-9 returnToNaturalBreath stops timer and sets phase immediately`() {
        val clock = FakeMonotonicClock()
        val engine = PlayerEngine(
            holdCapFractionOfCht = 0.6,
            levelCapSeconds = 30,
            userChtSeconds = 20,
            clock = clock,
        )
        engine.startTimer()
        clock.advanceBySeconds(5)
        assertEquals(5, engine.elapsedSeconds())

        val phase = engine.returnToNaturalBreath()
        assertEquals(PracticePhase.NATURAL_BREATH, phase)
        assertFalse(engine.isRunning)
        assertEquals(0L, engine.elapsedMillis())
    }

    @Test
    fun `monotonic fake clock maintains zero drift across 45 minute session with pauses`() {
        val clock = FakeMonotonicClock(1_000L)
        val engine = PlayerEngine(0.6, 24, 40, clock = clock)

        engine.startTimer()
        clock.advanceByMillis(600_000L) // 10 min
        engine.pauseTimer()
        clock.advanceByMillis(120_000L) // 2 min paused (must not count)
        engine.resumeTimer()
        clock.advanceByMillis(2_100_000L) // 35 min

        // Total active = 45 min = 2,700,000 ms exactly (0 ms drift)
        assertEquals(2_700_000L, engine.elapsedMillis())
        assertEquals(2_700, engine.elapsedSeconds())
    }

    @Test
    fun `state machine cycles and skips zero-duration retentions`() {
        val engine = PlayerEngine(0.6, 30, 20)
        var phase = PracticePhase.PURAKA
        phase = engine.getNextPhase(phase)
        assertEquals(PracticePhase.ANTAR_KUMBHAKA, phase)
        phase = engine.getNextPhase(phase)
        assertEquals(PracticePhase.RECHAKA, phase)
        phase = engine.getNextPhase(phase)
        assertEquals(PracticePhase.BAHYA_KUMBHAKA, phase)
        phase = engine.getNextPhase(phase)
        assertEquals(PracticePhase.PURAKA, phase)
        assertEquals(2, engine.currentCycle)

        // When ratio is 4:0:8:0, holds are skipped
        val noHoldRatio = listOf(4, 0, 8, 0)
        var p2 = PracticePhase.PURAKA
        p2 = engine.getNextPhase(p2, noHoldRatio)
        assertEquals(PracticePhase.RECHAKA, p2)
        p2 = engine.getNextPhase(p2, noHoldRatio)
        assertEquals(PracticePhase.PURAKA, p2)
    }

    @Test
    fun `evaluateFrame maps Kapalbhati and Nadi Shodhana boundaries accurately`() {
        val engine = PlayerEngine(holdCapFractionOfCht = 0.6, levelCapSeconds = 30, userChtSeconds = 30)

        // Kapalbhati: 35 strokes + 10s bahir + 4s puraka + 6s rest = 55s round
        val fStroke = engine.evaluateFrame("kapalbhati", 0, listOf(0, 0, 0, 10), strokesPerRound = 35)
        assertEquals(PracticePhase.RECHAKA, fStroke.phase)
        assertEquals(1, fStroke.secondsInPhase)

        val fBahir = engine.evaluateFrame("kapalbhati", 35, listOf(0, 0, 0, 10), strokesPerRound = 35)
        assertEquals(PracticePhase.BAHYA_KUMBHAKA, fBahir.phase)
        assertEquals(1, fBahir.secondsInPhase)

        val fPuraka = engine.evaluateFrame("kapalbhati", 45, listOf(0, 0, 0, 10), strokesPerRound = 35)
        assertEquals(PracticePhase.PURAKA, fPuraka.phase)

        val fRest = engine.evaluateFrame("kapalbhati", 49, listOf(0, 0, 0, 10), strokesPerRound = 35)
        assertEquals(PracticePhase.NATURAL_BREATH, fRest.phase)

        // Nadi Shodhana: 4:8:8:4 = 24s cycle (CHT 30 * 0.6 = 18s cap, so 8s & 4s run uncapped)
        val nPuraka = engine.evaluateFrame("nadi_shodhana", 0, listOf(4, 8, 8, 4))
        assertEquals(PracticePhase.PURAKA, nPuraka.phase)
        assertTrue(nPuraka.cueText.contains("Left"))

        val nAntar = engine.evaluateFrame("nadi_shodhana", 4, listOf(4, 8, 8, 4))
        assertEquals(PracticePhase.ANTAR_KUMBHAKA, nAntar.phase)

        val nRechaka = engine.evaluateFrame("nadi_shodhana", 12, listOf(4, 8, 8, 4))
        assertEquals(PracticePhase.RECHAKA, nRechaka.phase)

        val nBahya = engine.evaluateFrame("nadi_shodhana", 20, listOf(4, 8, 8, 4))
        assertEquals(PracticePhase.BAHYA_KUMBHAKA, nBahya.phase)
    }
}
