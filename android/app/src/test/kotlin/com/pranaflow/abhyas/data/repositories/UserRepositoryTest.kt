package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.models.AudioPreferences
import com.pranaflow.abhyas.data.models.ReminderSettings
import com.pranaflow.abhyas.data.store.InMemoryKeyValueStore
import com.pranaflow.abhyas.engine.player.SoundPalette
import com.pranaflow.abhyas.engine.safety.SafetyProfile
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UserRepositoryTest {

    @Test
    fun `saveProfile and loadProfile round-trip preserves all safety flags`() = runTest {
        val repo = UserRepository(InMemoryKeyValueStore())
        assertNull(repo.loadProfile())

        val profile = SafetyProfile(
            pregnancy = true,
            hypertension = false,
            heartCondition = true,
            epilepsy = false,
            glaucoma = true,
            hernia = false,
            recentSurgery = true,
            asthmaOrRespiratory = true,
            panicOrAnxiety = false,
            menstruation = true,
            emptyStomachConfirmed = true,
        )
        repo.saveProfile(profile)
        val loaded = repo.loadProfile()
        assertNotNull(loaded)
        assertEquals(profile, loaded)
    }

    @Test
    fun `saveChtBenchmark updates benchmark and appends CHT history`() = runTest {
        val repo = UserRepository(InMemoryKeyValueStore())
        assertNull(repo.loadChtBenchmark())

        repo.saveChtBenchmark(20.0, holdCapFraction = 0.6, measuredAtIso = "2026-11-26T06:00:00Z")
        repo.saveChtBenchmark(32.0, holdCapFraction = 0.6, measuredAtIso = "2026-11-27T06:00:00Z")

        assertEquals(32.0, repo.loadChtBenchmark()!!, 0.001)
        val history = repo.getChtHistory()
        assertEquals(2, history.size)
        assertEquals(12, history[0].safeCapSeconds)
        assertEquals(19, history[1].safeCapSeconds)
    }

    @Test
    fun `tradition, consent, audio prefs, reminders, and GDPR export delete work offline`() = runTest {
        val repo = UserRepository(InMemoryKeyValueStore())
        assertFalse(repo.hasCompletedOnboarding())
        assertNull(repo.loadTradition())

        repo.saveTradition("Shaiva")
        repo.saveConsent(true)
        repo.saveAudioPreferences(
            AudioPreferences(
                voiceEnabled = false,
                audioTonesEnabled = true,
                hapticsEnabled = true,
                soundPalette = SoundPalette.FLUTE_HARMONIC,
            ),
        )
        repo.saveReminderSettings(ReminderSettings(morningEnabled = true, morningHour = 5, morningMinute = 15))

        assertEquals("Shaiva", repo.loadTradition())
        assertTrue(repo.hasCompletedOnboarding())
        assertEquals(SoundPalette.FLUTE_HARMONIC, repo.loadAudioPreferences().soundPalette)
        assertTrue(repo.loadReminderSettings().morningEnabled)

        val exported = repo.exportProfileSnapshotJson()
        assertTrue(exported.contains("Shaiva"))

        repo.deleteAllUserData()
        assertFalse(repo.hasCompletedOnboarding())
        assertNull(repo.loadProfile())
    }
}
