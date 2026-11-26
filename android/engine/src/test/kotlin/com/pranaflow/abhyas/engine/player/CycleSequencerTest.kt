package com.pranaflow.abhyas.engine.player

import com.pranaflow.abhyas.engine.clock.FakeMonotonicClock
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CycleSequencerTest {

    @Test
    fun `initializes steps and calculates total cycle duration`() {
        val steps = listOf(
            CycleStepItem("sankalp", "Sankalp", "", 60),
            CycleStepItem("nadi_shodhana", "Nadi Shodhana", "", 120, ratio = listOf(4, 0, 4, 0), isPranayamaWithPacer = true),
        )
        val sequencer = CycleSequencer(steps)
        assertEquals(2, sequencer.steps.size)
        assertEquals(180, sequencer.totalCycleDurationSeconds)
        assertEquals(0, sequencer.currentStepIndex)
        assertEquals("sankalp", sequencer.currentStep.id)
    }

    @Test
    fun `transition buffer runs for 10 seconds between steps and advances cleanly`() {
        val clock = FakeMonotonicClock()
        val steps = listOf(
            CycleStepItem("kapalbhati", "Kapalbhati", "", 3, isPranayamaWithPacer = true),
            CycleStepItem("nadi_shodhana", "Nadi Shodhana", "", 3, ratio = listOf(4, 0, 4, 0), isPranayamaWithPacer = true),
        )
        val sequencer = CycleSequencer(steps, transitionDurationSeconds = 10, clock = clock)
        var cycleCompleted = false
        var transitionStarted = false

        sequencer.start(
            onTransitionStart = { _, _ -> transitionStarted = true },
            onCycleComplete = { cycleCompleted = true },
        )

        repeat(3) {
            clock.advanceBySeconds(1)
            sequencer.tickSecond()
        }

        assertTrue(transitionStarted)
        assertTrue(sequencer.isTransitioning)
        assertEquals(10, sequencer.transitionRemainingSeconds)
        assertFalse(cycleCompleted)

        // Tick through remaining transition gap
        repeat(10) {
            clock.advanceBySeconds(1)
            sequencer.tickSecond()
        }

        assertFalse(sequencer.isTransitioning)
        assertEquals(1, sequencer.currentStepIndex)
        assertEquals("nadi_shodhana", sequencer.currentStep.id)

        // Complete second step
        repeat(3) {
            clock.advanceBySeconds(1)
            sequencer.tickSecond()
        }
        assertTrue(cycleCompleted)
        assertTrue(sequencer.isCompleted)
    }

    @Test
    fun `skipStep and pause resume work reliably`() {
        val steps = listOf(
            CycleStepItem("step1", "Step 1", "", 60),
            CycleStepItem("step2", "Step 2", "", 60),
        )
        val sequencer = CycleSequencer(steps)
        var completed = false
        sequencer.start(onCycleComplete = { completed = true })
        assertTrue(sequencer.isRunning)

        sequencer.pause()
        assertFalse(sequencer.isRunning)
        assertTrue(sequencer.isPaused)

        sequencer.resume()
        assertTrue(sequencer.isRunning)

        sequencer.skipStep()
        assertEquals(1, sequencer.currentStepIndex)
        assertFalse(completed)

        sequencer.skipStep()
        assertTrue(completed)
        assertTrue(sequencer.isCompleted)
    }

    @Test
    fun `RoutineCatalog Surya and Chandra presets honor duration and ratio isolation`() {
        val surya30 = RoutineCatalog.buildPresetSteps(
            preset = RoutinePreset.SURYA,
            targetMinutes = 30,
            effectiveLevel = 3,
            levelRatio = listOf(4, 4, 8, 0),
            kapalbhatiStrokes = 60,
        )
        assertTrue(surya30.any { it.id == "kapalbhati" && it.strokes == 60 })
        val nadi = surya30.first { it.id == "nadi_shodhana" }
        assertEquals(listOf(4, 4, 8, 0), nadi.ratio)
        assertNull(surya30.first { it.id == "sankalp" }.ratio)

        val chandra25 = RoutineCatalog.buildPresetSteps(
            preset = RoutinePreset.CHANDRA,
            targetMinutes = 25,
            effectiveLevel = 2,
            levelRatio = listOf(4, 0, 8, 0),
            kapalbhatiStrokes = 45,
        )
        assertTrue(chandra25.any { it.id == "naam_jaap" })
        assertTrue(chandra25.any { it.id == "yoga_nidra" })
    }
}
