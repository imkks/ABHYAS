package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.models.SessionRecord
import com.pranaflow.abhyas.data.store.InMemoryKeyValueStore
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionRepositoryTest {

    @Test
    fun `logSession persists record, calmness delta, Tapas count, and enqueues offline sync`() = runTest {
        val store = InMemoryKeyValueStore()
        val outbox = SyncOutboxRepository(store)
        val repo = SessionRepository(store, outbox)

        assertEquals(0, repo.getTapasCount())
        repo.logSession(
            SessionRecord(
                practiceId = "nadi_shodhana",
                practiceName = "Nadi Shodhana",
                level = 2,
                durationSeconds = 600,
                timestampIso = "2026-11-25T06:30:00Z",
                epochDay = 100L,
                checkinRating = "calm",
                holdDurations = listOf(4.0, 6.0),
                preCalmnessScore = 3,
                calmnessScore = 8,
            ),
            todayEpochDay = 100L,
        )
        repo.logSession(
            SessionRecord(
                practiceId = "kapalbhati",
                practiceName = "Kapalbhati",
                level = 2,
                durationSeconds = 1200,
                timestampIso = "2026-11-26T06:30:00Z",
                epochDay = 101L,
                checkinRating = "calm",
                holdDurations = listOf(10.0),
                preCalmnessScore = 4,
                calmnessScore = 9,
            ),
            todayEpochDay = 101L,
        )

        assertEquals(2, repo.getTapasCount())
        assertEquals(30, repo.getTotalPracticeMinutes())
        assertEquals(5.0, repo.getAverageCalmnessDelta(), 0.01)
        assertEquals(2, repo.getComfortStreak())
        assertEquals(6.667, repo.getAverageHold(), 0.01)
        assertEquals(2, repo.getDailyPracticeStreak(todayEpochDay = 101L))

        // Outbox should have queued both sessions + check-ins offline
        val pending = outbox.getPending()
        assertEquals(4, pending.size)
        val flushed = outbox.flushWithTransport { items -> items.map { it.id }.toSet() }
        assertEquals(4, flushed)
        assertTrue(outbox.getPending().isEmpty())
    }

    @Test
    fun `strain flag gently steps ratio down locally without blocking retention`() = runTest {
        val store = InMemoryKeyValueStore()
        val repo = SessionRepository(store)
        repo.setRatioStepIndex(2)

        val decision = repo.logSession(
            SessionRecord(
                practiceId = "nadi_shodhana_full",
                practiceName = "Nadi Shodhana",
                level = 4,
                durationSeconds = 420,
                timestampIso = "2026-11-26T06:30:00Z",
                epochDay = 101L,
                checkinRating = "strained",
                dizziness = true,
            ),
            todayEpochDay = 101L,
        )

        assertTrue(decision.shouldAutoRegress)
        assertEquals(1, repo.getRatioStepIndex())
        assertFalse(repo.hasPendingTeacherStrainAlert())
        assertEquals(1, repo.getRecentStrainCount7Days(todayEpochDay = 101L))
        assertFalse(decision.lockRetentionForTeacherReview)
    }

    @Test
    fun `Vishrama day preserves streak without inflating Tapas practice count`() = runTest {
        val store = InMemoryKeyValueStore()
        val repo = SessionRepository(store)

        repo.logSession(
            SessionRecord(
                practiceId = "surya",
                practiceName = "Surya Abhyas",
                level = 1,
                durationSeconds = 900,
                timestampIso = "2026-11-24T06:30:00Z",
                epochDay = 100L,
                checkinRating = "calm",
            ),
            todayEpochDay = 100L,
        )
        repo.logVishramaDay(epochDay = 101L)
        repo.logSession(
            SessionRecord(
                practiceId = "surya",
                practiceName = "Surya Abhyas",
                level = 1,
                durationSeconds = 900,
                timestampIso = "2026-11-26T06:30:00Z",
                epochDay = 102L,
                checkinRating = "calm",
            ),
            todayEpochDay = 102L,
        )

        assertEquals(2, repo.getTapasCount())
        assertEquals(3, repo.getDailyPracticeStreak(todayEpochDay = 102L))
    }
}
