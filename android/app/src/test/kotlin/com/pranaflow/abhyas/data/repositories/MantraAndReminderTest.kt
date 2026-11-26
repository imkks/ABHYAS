package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.core.reminder.ReminderScheduler
import com.pranaflow.abhyas.data.models.CustomMantra
import com.pranaflow.abhyas.data.models.ReminderSettings
import com.pranaflow.abhyas.data.models.SavedCustomRoutine
import com.pranaflow.abhyas.data.store.InMemoryKeyValueStore
import com.pranaflow.abhyas.engine.player.CycleStepItem
import com.pranaflow.abhyas.engine.player.RoutineIntensity
import com.pranaflow.abhyas.engine.player.RoutinePreset
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

class MantraAndReminderTest {

    @Test
    fun `MantraAndRoutineRepository persists custom mantras, mala counts, sankalp, and routines`() = runTest {
        val repo = MantraAndRoutineRepository(InMemoryKeyValueStore())
        assertTrue(repo.defaultMantras.isNotEmpty())

        val custom = CustomMantra(
            id = "custom_1",
            name = "Shiva Sankalpa",
            text = "ॐ नमः शिवाय",
            meaning = "Peace",
        )
        repo.saveCustomMantra(custom)
        repo.setSelectedMantraId("custom_1")
        assertEquals("Shiva Sankalpa", repo.getSelectedMantra().name)

        repo.saveMalaBeadCount(54)
        repo.saveMalaRoundsCompleted(2)
        assertEquals(54, repo.getMalaBeadCount())
        assertEquals(2, repo.getMalaRoundsCompleted())

        repo.saveCustomRoutine(
            SavedCustomRoutine(
                id = "r1",
                name = "Morning 20m",
                preset = RoutinePreset.SURYA,
                targetMinutes = 20,
                intensity = RoutineIntensity.ADAPTIVE,
                steps = listOf(CycleStepItem("nadi_shodhana", "Nadi", "", 300, ratio = listOf(4, 0, 8, 0))),
            ),
        )
        assertEquals(1, repo.getSavedCustomRoutines().size)
    }

    @Test
    fun `ReminderScheduler computes next local alarm timestamps offline without location or panchang`() {
        val now = ZonedDateTime.of(2026, 11, 26, 7, 0, 0, 0, ZoneId.of("UTC"))
        val settings = ReminderSettings(
            morningEnabled = true,
            morningHour = 6,
            morningMinute = 30, // already passed today -> tomorrow 6:30
            eveningEnabled = true,
            eveningHour = 18,
            eveningMinute = 0, // later today 18:00
        )

        val reminders = ReminderScheduler.computeEnabledReminders(settings, now)
        assertEquals(2, reminders.size)
        val tomorrowMorning = ZonedDateTime.of(2026, 11, 27, 6, 30, 0, 0, ZoneId.of("UTC")).toInstant().toEpochMilli()
        val tonightEvening = ZonedDateTime.of(2026, 11, 26, 18, 0, 0, 0, ZoneId.of("UTC")).toInstant().toEpochMilli()
        assertEquals(tomorrowMorning, reminders[0].triggerAtEpochMillis)
        assertEquals(tonightEvening, reminders[1].triggerAtEpochMillis)
    }
}
