package com.pranaflow.abhyas.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.MusicNote
import androidx.compose.material.icons.outlined.NotificationsActive
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.pranaflow.abhyas.data.models.ReminderSettings
import com.pranaflow.abhyas.engine.player.SoundPalette
import com.pranaflow.abhyas.engine.progression.ProgressionEngine
import com.pranaflow.abhyas.ui.state.AbhyasUiState
import com.pranaflow.abhyas.ui.theme.SanctuaryColors
import kotlin.math.roundToInt

@Composable
fun PersonalGrowthScreen(
    state: AbhyasUiState,
    onOpenChtTest: () -> Unit,
    onLogVishrama: () -> Unit,
    onSelectPalette: (SoundPalette) -> Unit,
    onToggleVoice: () -> Unit,
    onToggleTones: () -> Unit,
    onToggleHaptics: () -> Unit,
    onToggleTanpura: () -> Unit,
    onSaveProfileSettings: (name: String, tradition: String, matraSeconds: Double) -> Unit,
    onSaveReminderSettings: (ReminderSettings) -> Unit,
    onRunSelfCheck: (targetHold: Int, recorded: List<Int>) -> Unit,
    onExportSnapshot: () -> Unit,
) {
    var nameDraft by remember(state.profileSettings.displayName) { mutableStateOf(state.profileSettings.displayName) }
    var traditionDraft by remember(state.profileSettings.tradition) { mutableStateOf(state.profileSettings.tradition) }
    var matraDraft by remember(state.profileSettings.matraSeconds) { mutableFloatStateOf(state.profileSettings.matraSeconds.toFloat()) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = "Personal Growth & Insights",
                    style = MaterialTheme.typography.headlineLarge,
                    color = SanctuaryColors.OnSurface,
                )
                Text(
                    text = "Track your steadiness, Sopana milestones, comfort breath capacity & personal preferences — never competitive.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SanctuaryColors.OnSurfaceVariant,
                )
            }
        }

        // 1. Safe Comfort Breath Threshold (CHT) & Retest
        item {
            Surface(
                color = SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(18.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.5f)),
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Comfort Hold Capacity", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.Primary)
                            Text(
                                text = state.chtBenchmarkSeconds?.let { "${it.roundToInt()}s Baseline" } ?: "Not Calibrated Yet",
                                style = MaterialTheme.typography.headlineMedium,
                                color = SanctuaryColors.OnSurface,
                            )
                        }
                        Icon(imageVector = Icons.Outlined.Timer, contentDescription = null, tint = SanctuaryColors.Primary)
                    }
                    val safeCap = state.chtBenchmarkSeconds?.let { (it * state.config.holdCapFractionOfCht).roundToInt() }
                    Text(
                        text = if (safeCap != null) {
                            "Recommended hold cap: ${safeCap}s (${(state.config.holdCapFractionOfCht * 100).roundToInt()}% of CHT) across Kumbhaka drills."
                        } else {
                            "Measure your effortless exhale-hold once to gently scale hold rhythms."
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )
                    Button(
                        onClick = onOpenChtTest,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SanctuaryColors.PrimaryContainer,
                            contentColor = SanctuaryColors.OnPrimaryContainer,
                        ),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text("Retake 1-Min Breath Capacity Test")
                    }
                }
            }
        }

        // 2. 7 Sopana Open Mastery Path (Advisory Roadmap - Never Blocking)
        item {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(18.dp),
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column {
                            Text("7 Sopana Mastery Path", style = MaterialTheme.typography.headlineSmall, color = SanctuaryColors.OnSurface)
                            Text(
                                text = "Current: Sopana ${state.progression.level} · ${state.progression.totalTapas} Tapas XP",
                                style = MaterialTheme.typography.labelMedium,
                                color = SanctuaryColors.Primary,
                            )
                        }
                        Surface(
                            color = SanctuaryColors.SurfaceHigh,
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.clickable(onClick = onLogVishrama),
                        ) {
                            Text(
                                text = "+ Vishrama Rest",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.Secondary,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            )
                        }
                    }

                    ProgressionEngine.ranks.forEach { rank ->
                        val isCurrent = rank.level == state.progression.level
                        val isCompleted = rank.level < state.progression.level
                        Surface(
                            color = if (isCurrent) SanctuaryColors.SurfaceHigh else SanctuaryColors.SurfaceLow,
                            shape = RoundedCornerShape(12.dp),
                            border = if (isCurrent) BorderStroke(1.dp, SanctuaryColors.Primary.copy(alpha = 0.6f)) else null,
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 14.dp, vertical = 10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.weight(1f),
                                ) {
                                    Icon(
                                        imageVector = if (isCompleted || isCurrent) Icons.Outlined.CheckCircle else Icons.Outlined.Explore,
                                        contentDescription = null,
                                        tint = if (isCurrent) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant,
                                        modifier = Modifier.size(18.dp),
                                    )
                                    Column {
                                        Text(
                                            text = "${rank.level}. ${rank.title}",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = if (isCurrent) SanctuaryColors.Primary else SanctuaryColors.OnSurface,
                                            maxLines = 1,
                                            overflow = TextOverflow.Ellipsis,
                                        )
                                        Text(
                                            text = rank.ratioDescription,
                                            style = MaterialTheme.typography.labelSmall,
                                            color = SanctuaryColors.OnSurfaceVariant,
                                        )
                                    }
                                }

                                val badgeText = when {
                                    isCurrent -> "Current"
                                    isCompleted -> "Reached"
                                    else -> "Open Guide · Up Next"
                                }
                                Surface(
                                    color = if (isCurrent) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceContainer,
                                    shape = RoundedCornerShape(6.dp),
                                ) {
                                    Text(
                                        text = badgeText,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = if (isCurrent) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. 108 Mala Progress & Mudra/Bandha Milestones
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(
                            text = "${state.progression.malaProgress.currentBeadInMala} / 108 Practice Mala Beads",
                            style = MaterialTheme.typography.titleMedium,
                            color = SanctuaryColors.Primary,
                        )
                        LinearProgressIndicator(
                            progress = { (state.progression.malaProgress.currentBeadInMala / 108f).coerceIn(0f, 1f) },
                            color = SanctuaryColors.PrimaryContainer,
                            trackColor = SanctuaryColors.SurfaceLowest,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(6.dp)
                                .clip(RoundedCornerShape(4.dp)),
                        )
                        Text(
                            text = "Completed Malas: ${state.progression.malaProgress.completedMalas} · Each session adds one bead.",
                            style = MaterialTheme.typography.bodySmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                        )
                    }
                }

                Text("Mudra & Bandha Milestones", style = MaterialTheme.typography.headlineSmall, color = SanctuaryColors.OnSurface)
                val allSeals = listOf(
                    "Gyan Mudra", "Chin Mudra", "Dhyana Mudra", "Nasika Mudra",
                    "Jalandhara Bandha", "Shanmukhi Mudra", "Mula Bandha", "Uddiyana Bandha", "Maha Bandha", "Shambhavi Mudra",
                )
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    allSeals.chunked(2).forEach { pair ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            pair.forEach { seal ->
                                val earned = seal in state.progression.earnedSeals
                                Surface(
                                    color = if (earned) SanctuaryColors.SurfaceHigh else SanctuaryColors.SurfaceLow,
                                    shape = RoundedCornerShape(12.dp),
                                    modifier = Modifier.weight(1f),
                                ) {
                                    Row(
                                        modifier = Modifier.padding(12.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    ) {
                                        Icon(
                                            imageVector = Icons.Outlined.AutoAwesome,
                                            contentDescription = null,
                                            tint = if (earned) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.6f),
                                            modifier = Modifier.size(18.dp),
                                        )
                                        Column {
                                            Text(seal, style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.OnSurface, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                            Text(
                                                text = if (earned) "Earned" else "Open Milestone",
                                                style = MaterialTheme.typography.labelSmall,
                                                color = if (earned) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant,
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. Recent Calmness Shift History & Self-Check Rhythm
        item {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(16.dp),
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text("Recent Calmness Shift", style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.OnSurface)
                        Surface(
                            color = SanctuaryColors.SurfaceHigh,
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.clickable {
                                val target = state.progression.ratio.getOrElse(1) { 4 }.coerceAtLeast(4)
                                onRunSelfCheck(target, state.recentSessions.take(3).map { it.durationSeconds.coerceAtMost(target) })
                            },
                        ) {
                            Row(modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Outlined.GraphicEq, contentDescription = null, tint = SanctuaryColors.Primary, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Self-Check Rhythm", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.Primary)
                            }
                        }
                    }

                    state.lastSelfCheck?.let { check ->
                        Text(check.steadinessMessage, style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.Secondary)
                    }

                    if (state.recentCheckins.isEmpty()) {
                        Text("Complete a practice to see pre-to-post stillness shifts.", style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.OnSurfaceVariant)
                    } else {
                        state.recentCheckins.take(4).forEach { chk ->
                            val sign = if (chk.delta >= 0) "+" else ""
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {
                                Text(chk.practiceName, style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.OnSurface, modifier = Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Text(
                                    text = "${chk.preCalmness} → ${chk.postCalmness} ($sign${chk.delta})",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = SanctuaryColors.Primary,
                                )
                            }
                        }
                    }
                }
            }
        }

        // 5. Sanctuary Preferences (Audio Palette, Matra, Reminders, Local Snapshot — NO Health Disclaimers)
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Sanctuary Preferences",
                    style = MaterialTheme.typography.headlineMedium,
                    color = SanctuaryColors.OnSurface,
                )

                // Audio Sound Palette & Channels
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text("AUDIO SOUND PALETTE", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.OnSurfaceVariant)
                            Icon(Icons.Outlined.MusicNote, contentDescription = null, tint = SanctuaryColors.Primary, modifier = Modifier.size(18.dp))
                        }

                        Row(
                            modifier = Modifier.horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            listOf(
                                SoundPalette.SINGING_BOWL to "Singing Bowl",
                                SoundPalette.TEMPLE_BELL to "Temple Bell",
                                SoundPalette.WOODBLOCK to "Woodblock",
                                SoundPalette.FLUTE_HARMONIC to "Flute Harmonic",
                            ).forEach { (palette, label) ->
                                val selected = state.audioPreferences.soundPalette == palette
                                Surface(
                                    color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceHigh,
                                    shape = RoundedCornerShape(10.dp),
                                    modifier = Modifier.clickable { onSelectPalette(palette) },
                                ) {
                                    Text(
                                        text = label,
                                        style = MaterialTheme.typography.labelMedium,
                                        color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    )
                                }
                            }
                        }

                        PreferenceToggleRow("Voice Guidance", state.audioPreferences.voiceEnabled, onToggleVoice)
                        PreferenceToggleRow("Bell & Phase Tones", state.audioPreferences.audioTonesEnabled, onToggleTones)
                        PreferenceToggleRow("Tactile Haptics", state.audioPreferences.hapticsEnabled, onToggleHaptics)
                        PreferenceToggleRow("Tanpura Drone Bed", state.audioPreferences.tanpuraDroneEnabled, onToggleTanpura)
                    }
                }

                // Matra & Profile Settings
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Text("PRACTITIONER & MATRA", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.OnSurfaceVariant)
                        OutlinedTextField(value = nameDraft, onValueChange = { nameDraft = it }, label = { Text("Display Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                        OutlinedTextField(value = traditionDraft, onValueChange = { traditionDraft = it }, label = { Text("Tradition / Lineage") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                        Text("Matra Pace: ${"%.2f".format(matraDraft)}s per count", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.Primary)
                        Slider(
                            value = matraDraft,
                            onValueChange = { matraDraft = it },
                            valueRange = 0.8f..1.5f,
                            colors = SliderDefaults.colors(
                                thumbColor = SanctuaryColors.PrimaryContainer,
                                activeTrackColor = SanctuaryColors.PrimaryContainer,
                            ),
                        )
                        Button(
                            onClick = { onSaveProfileSettings(nameDraft, traditionDraft, matraDraft.toDouble()) },
                            colors = ButtonDefaults.buttonColors(containerColor = SanctuaryColors.PrimaryContainer, contentColor = SanctuaryColors.OnPrimaryContainer),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text("Save Practitioner Settings")
                        }
                    }
                }

                // Local Daily Practice Reminders
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text("DAILY PRACTICE REMINDERS", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.OnSurfaceVariant)
                            Icon(Icons.Outlined.NotificationsActive, contentDescription = null, tint = SanctuaryColors.Primary, modifier = Modifier.size(18.dp))
                        }

                        val rem = state.reminderSettings
                        PreferenceToggleRow(
                            label = "Morning Surya (%02d:%02d)".format(rem.morningHour, rem.morningMinute),
                            checked = rem.morningEnabled,
                            onToggle = { onSaveReminderSettings(rem.copy(morningEnabled = !rem.morningEnabled)) },
                        )
                        PreferenceToggleRow(
                            label = "Evening Sandhya (%02d:%02d)".format(rem.eveningHour, rem.eveningMinute),
                            checked = rem.eveningEnabled,
                            onToggle = { onSaveReminderSettings(rem.copy(eveningEnabled = !rem.eveningEnabled)) },
                        )
                        PreferenceToggleRow(
                            label = "Bedtime Chandra (%02d:%02d)".format(rem.bedtimeHour, rem.bedtimeMinute),
                            checked = rem.bedtimeEnabled,
                            onToggle = { onSaveReminderSettings(rem.copy(bedtimeEnabled = !rem.bedtimeEnabled)) },
                        )
                    }
                }

                // Local Snapshot Export
                OutlinedButton(
                    onClick = onExportSnapshot,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Export Local Practice Snapshot JSON", color = SanctuaryColors.Primary)
                }

                state.exportedSnapshotJson?.let { exported ->
                    Surface(color = SanctuaryColors.SurfaceLowest, shape = RoundedCornerShape(10.dp)) {
                        Text(
                            text = exported.take(280) + if (exported.length > 280) "..." else "",
                            style = MaterialTheme.typography.bodySmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                            modifier = Modifier.padding(12.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PreferenceToggleRow(
    label: String,
    checked: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = label, style = MaterialTheme.typography.bodyMedium, color = SanctuaryColors.OnSurface)
        Switch(
            checked = checked,
            onCheckedChange = { onToggle() },
            colors = SwitchDefaults.colors(
                checkedThumbColor = SanctuaryColors.OnPrimaryContainer,
                checkedTrackColor = SanctuaryColors.PrimaryContainer,
            ),
        )
    }
}
