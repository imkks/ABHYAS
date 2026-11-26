package com.pranaflow.abhyas.core.reminder

import com.pranaflow.abhyas.data.models.ReminderSettings
import java.time.ZoneId
import java.time.ZonedDateTime

data class ScheduledReminder(
    val slot: String,
    val hour: Int,
    val minute: Int,
    val triggerAtEpochMillis: Long,
)

/**
 * Offline-first practice reminder scheduler (without Panchang/location dependencies).
 */
object ReminderScheduler {

    fun computeEnabledReminders(
        settings: ReminderSettings,
        now: ZonedDateTime = ZonedDateTime.now(ZoneId.systemDefault()),
    ): List<ScheduledReminder> = buildList {
        if (settings.morningEnabled) {
            add(
                ScheduledReminder(
                    slot = "morning",
                    hour = settings.morningHour,
                    minute = settings.morningMinute,
                    triggerAtEpochMillis = nextTriggerMillis(settings.morningHour, settings.morningMinute, now),
                ),
            )
        }
        if (settings.eveningEnabled) {
            add(
                ScheduledReminder(
                    slot = "evening",
                    hour = settings.eveningHour,
                    minute = settings.eveningMinute,
                    triggerAtEpochMillis = nextTriggerMillis(settings.eveningHour, settings.eveningMinute, now),
                ),
            )
        }
        if (settings.bedtimeEnabled) {
            add(
                ScheduledReminder(
                    slot = "bedtime",
                    hour = settings.bedtimeHour,
                    minute = settings.bedtimeMinute,
                    triggerAtEpochMillis = nextTriggerMillis(settings.bedtimeHour, settings.bedtimeMinute, now),
                ),
            )
        }
    }

    fun nextTriggerMillis(
        hour: Int,
        minute: Int,
        now: ZonedDateTime,
    ): Long {
        var candidate = now.withHour(hour.coerceIn(0, 23))
            .withMinute(minute.coerceIn(0, 59))
            .withSecond(0)
            .withNano(0)
        if (!candidate.isAfter(now)) {
            candidate = candidate.plusDays(1)
        }
        return candidate.toInstant().toEpochMilli()
    }
}
