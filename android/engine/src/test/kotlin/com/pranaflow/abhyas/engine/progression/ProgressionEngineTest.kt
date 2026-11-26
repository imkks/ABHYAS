package com.pranaflow.abhyas.engine.progression

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ProgressionEngineTest {

    @Test
    fun `all 7 Sopana ranks map to 3 phases and expected seals`() {
        assertEquals(7, ProgressionEngine.ranks.size)
        assertEquals("Foundation", ProgressionEngine.getLevelInfo(1).phaseName)
        assertEquals("Deepening", ProgressionEngine.getLevelInfo(3).phaseName)
        assertEquals("Advanced", ProgressionEngine.getLevelInfo(6).phaseName)
        assertTrue(ProgressionEngine.getLevelInfo(6).unlockedSeals.contains("Maha Bandha"))
        assertEquals(listOf(6, 24, 12, 0), ProgressionEngine.getLevelInfo(7).ratio)
    }

    @Test
    fun `calculateLevelFromCht maps comfort hold seconds accurately`() {
        assertEquals(1, ProgressionEngine.calculateLevelFromCht(10.0))
        assertEquals(2, ProgressionEngine.calculateLevelFromCht(20.0))
        assertEquals(3, ProgressionEngine.calculateLevelFromCht(30.0))
        assertEquals(4, ProgressionEngine.calculateLevelFromCht(48.0))
        assertEquals(5, ProgressionEngine.calculateLevelFromCht(75.0))
    }

    @Test
    fun `default open mode advances past level 2 freely without backend approval`() {
        val sessions = List(10) { idx ->
            SessionSummary(
                practiceName = "Morning Surya Abhyas",
                level = 2,
                durationSeconds = 1800,
                epochDay = 100L + idx,
                checkinRating = "calm",
            )
        }

        val openProgress = ProgressionEngine.computeProgression(
            sessions = sessions,
            todayEpochDay = 109L,
        )
        assertTrue(openProgress.level >= 3)

        // Optional pilot teacher gating remains supported when explicitly opted in
        val gated = ProgressionEngine.computeProgression(
            sessions = sessions,
            todayEpochDay = 109L,
            approvedLevels = setOf(1, 2),
            teacherGatingEnabled = true,
        )
        assertEquals(2, gated.level)
    }

    @Test
    fun `Vishrama rest day preserves streak without penalty`() {
        val practiced = setOf(97L, 98L, 100L) // skipped day 99 via Vishrama
        val vishrama = setOf(99L)
        val streak = ProgressionEngine.computeDailyStreakWithVishrama(
            practicedEpochDays = practiced,
            vishramaEpochDays = vishrama,
            todayEpochDay = 100L,
            vishramaAllowancePerWeek = 1,
        )
        assertEquals(4, streak)
    }

    @Test
    fun `open mode gently steps ratio back on strain without blocking retention`() {
        val oneStrain = listOf(
            SessionSummary("Nadi", 3, 600, 100L, "calm"),
            SessionSummary("Nadi", 3, 600, 101L, "strained", dizziness = true),
        )
        val decision1 = ProgressionEngine.evaluateRatioLadder(
            currentStepIndex = 2,
            maxStepIndex = 3,
            recentSessionsChronological = oneStrain,
            todayEpochDay = 101L,
        )
        assertTrue(decision1.shouldAutoRegress)
        assertEquals(1, decision1.nextStepIndex)
        assertFalse(decision1.notifyTeacher)
        assertFalse(decision1.lockRetentionForTeacherReview)

        val twoStrains = listOf(
            SessionSummary("Nadi", 3, 600, 99L, "strained"),
            SessionSummary("Nadi", 3, 600, 101L, "neutral", dizziness = true),
        )
        val decisionOpen = ProgressionEngine.evaluateRatioLadder(
            currentStepIndex = 1,
            maxStepIndex = 3,
            recentSessionsChronological = twoStrains,
            todayEpochDay = 101L,
        )
        assertTrue(decisionOpen.shouldAutoRegress)
        assertFalse(decisionOpen.lockRetentionForTeacherReview)
    }

    @Test
    fun `FR-GM-08 advances ratio ladder only after required consecutive calm sessions`() {
        val calm5 = List(5) { i -> SessionSummary("Nadi", 2, 600, 100L + i, "calm") }
        val advance = ProgressionEngine.evaluateRatioLadder(
            currentStepIndex = 0,
            maxStepIndex = 2,
            recentSessionsChronological = calm5,
            todayEpochDay = 104L,
            comfortStreakRequiredForStep = 5,
        )
        assertEquals(1, advance.nextStepIndex)
        assertFalse(advance.shouldAutoRegress)
    }

    @Test
    fun `GuruAnumatiWorkflow records immutable audit entries and enforces approval`() {
        val wf = GuruAnumatiWorkflow(teacherGatingEnabled = true)
        assertFalse(wf.isLevelApproved(3))

        val req = wf.requestUnlock("student-1", 3, 1_000L, "Ready for Antar Kumbhaka")
        assertTrue(wf.processRequest(req.id, UnlockStatus.APPROVED, "teacher-1", "Smooth breathing observed", 2_000L))
        assertTrue(wf.isLevelApproved(3))
        assertEquals(2, wf.auditLog.size)
        assertEquals("teacher-1", wf.auditLog[1].actorId)
    }
}
