package com.pranaflow.abhyas.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Explore
import androidx.compose.material.icons.outlined.NotificationsActive
import androidx.compose.material.icons.outlined.SelfImprovement
import androidx.compose.material.icons.outlined.Spa
import androidx.compose.material.icons.outlined.Timeline
import androidx.compose.material.icons.outlined.WindPower
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.SelfImprovement
import androidx.compose.material.icons.rounded.Spa
import androidx.compose.material.icons.rounded.Timeline
import androidx.compose.material.icons.rounded.WindPower
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.pranaflow.abhyas.R
import com.pranaflow.abhyas.engine.clock.SystemMonotonicClock
import com.pranaflow.abhyas.engine.progression.ProgressionEngine
import com.pranaflow.abhyas.ui.theme.SanctuaryColors
import kotlinx.coroutines.delay
import kotlin.math.roundToInt

enum class SanctuaryTab(val route: String) {
    SANCTUARY("sanctuary"),
    PRANAYAMA("pranayama"),
    DHYAN("dhyan"),
    GROWTH("growth"),
}

@Composable
fun SanctuaryTopBar(
    displayName: String,
    sopanaLevel: Int,
    onRemindersClick: () -> Unit,
    onProfileClick: () -> Unit,
) {
    val initial = displayName.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "A"
    Surface(
        color = SanctuaryColors.Surface.copy(alpha = 0.94f),
        tonalElevation = 2.dp,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(
                        text = stringResource(R.string.app_name),
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.OnSurface,
                    )
                    Surface(
                        color = SanctuaryColors.SurfaceContainer,
                        shape = RoundedCornerShape(6.dp),
                    ) {
                        Text(
                            text = "SOPANA $sopanaLevel",
                            style = MaterialTheme.typography.labelSmall,
                            color = SanctuaryColors.Primary,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
                        )
                    }
                }
                Text(
                    text = stringResource(R.string.app_tagline),
                    style = MaterialTheme.typography.labelSmall,
                    color = SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.8f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                IconButton(onClick = onRemindersClick) {
                    Icon(
                        imageVector = Icons.Outlined.NotificationsActive,
                        contentDescription = "Reminders & Audio",
                        tint = SanctuaryColors.OnSurfaceVariant,
                    )
                }
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                listOf(SanctuaryColors.PrimaryContainer, SanctuaryColors.SecondaryContainer),
                            ),
                        )
                        .clickable(onClick = onProfileClick),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = initial,
                        style = MaterialTheme.typography.labelLarge,
                        color = SanctuaryColors.OnPrimaryContainer,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
        }
    }
}

@Composable
fun SanctuaryBottomBar(
    currentTab: SanctuaryTab,
    onTabSelected: (SanctuaryTab) -> Unit,
) {
    NavigationBar(
        containerColor = SanctuaryColors.SurfaceLowest,
        contentColor = SanctuaryColors.OnSurfaceVariant,
    ) {
        val items = listOf(
            Triple(SanctuaryTab.SANCTUARY, stringResource(R.string.nav_sanctuary), Icons.Rounded.Spa to Icons.Outlined.Spa),
            Triple(SanctuaryTab.PRANAYAMA, stringResource(R.string.nav_pranayama), Icons.Rounded.WindPower to Icons.Outlined.WindPower),
            Triple(SanctuaryTab.DHYAN, stringResource(R.string.nav_dhyan), Icons.Rounded.SelfImprovement to Icons.Outlined.SelfImprovement),
            Triple(SanctuaryTab.GROWTH, stringResource(R.string.nav_growth), Icons.Rounded.Timeline to Icons.Outlined.Timeline),
        )
        items.forEach { (tab, label, icons) ->
            val selected = tab == currentTab
            NavigationBarItem(
                selected = selected,
                onClick = { onTabSelected(tab) },
                icon = {
                    Icon(
                        imageVector = if (selected) icons.first else icons.second,
                        contentDescription = label,
                    )
                },
                label = {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelSmall,
                        maxLines = 1,
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = SanctuaryColors.Primary,
                    selectedTextColor = SanctuaryColors.Primary,
                    unselectedIconColor = SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.7f),
                    unselectedTextColor = SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.7f),
                    indicatorColor = SanctuaryColors.PrimaryContainer.copy(alpha = 0.16f),
                ),
            )
        }
    }
}

@Composable
fun AdvisoryGuidePill(
    text: String,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier,
        color = SanctuaryColors.SurfaceHigh,
        shape = RoundedCornerShape(8.dp),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Icon(
                imageVector = Icons.Outlined.Explore,
                contentDescription = null,
                tint = SanctuaryColors.Primary,
                modifier = Modifier.size(13.dp),
            )
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                color = SanctuaryColors.Primary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
fun DurationChipRow(
    optionsMinutes: List<Int>,
    selectedMinutes: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        optionsMinutes.forEach { mins ->
            val selected = mins == selectedMinutes
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceLow,
                border = if (selected) null else BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.5f)),
                modifier = Modifier.clickable { onSelect(mins) },
            ) {
                Text(
                    text = "${mins}m",
                    style = MaterialTheme.typography.labelMedium,
                    color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                    fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp),
                )
            }
        }
    }
}

@Composable
fun BreathCapacityTestDialog(
    currentChtSeconds: Double?,
    onDismiss: () -> Unit,
    onSaveCht: (Double) -> Unit,
) {
    var phase by remember { mutableStateOf("ready") } // ready | holding | recorded
    var elapsedSec by remember { mutableIntStateOf(currentChtSeconds?.roundToInt() ?: 0) }
    var startMs by remember { mutableStateOf(0L) }

    LaunchedEffect(phase) {
        if (phase == "holding") {
            startMs = SystemMonotonicClock.elapsedMillis()
            while (phase == "holding") {
                val secs = ((SystemMonotonicClock.elapsedMillis() - startMs) / 1000L).toInt()
                elapsedSec = secs
                delay(200L)
            }
        }
    }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = SanctuaryColors.SurfaceContainer,
            shape = RoundedCornerShape(20.dp),
            border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        imageVector = Icons.Rounded.AutoAwesome,
                        contentDescription = null,
                        tint = SanctuaryColors.Primary,
                    )
                    Text(
                        text = "Comfort Hold Test (CHT)",
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.OnSurface,
                    )
                }

                Text(
                    text = "Take 3 relaxed breaths, inhale comfortably, exhale softly, and hold effortlessly until your very first urge to breathe.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SanctuaryColors.OnSurfaceVariant,
                )

                Surface(
                    color = SanctuaryColors.SurfaceLowest,
                    shape = CircleShape,
                    modifier = Modifier.size(120.dp),
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "${elapsedSec}s",
                                style = MaterialTheme.typography.displayMedium,
                                color = SanctuaryColors.Primary,
                            )
                            Text(
                                text = if (phase == "holding") "Holding gently" else "Comfort Time",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                    }
                }

                val previewLevel = ProgressionEngine.calculateLevelFromCht(elapsedSec.toDouble().coerceAtLeast(3.0))
                val previewCap = (elapsedSec * 0.6).roundToInt()
                if (elapsedSec > 0) {
                    Text(
                        text = "Suggested Guide: Sopana $previewLevel · Smooth Cap ~${previewCap}s (60%)",
                        style = MaterialTheme.typography.labelMedium,
                        color = SanctuaryColors.Secondary,
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    when (phase) {
                        "ready" -> {
                            OutlinedButton(
                                onClick = onDismiss,
                                modifier = Modifier.weight(1f),
                            ) {
                                Text(stringResource(R.string.action_cancel))
                            }
                            Button(
                                onClick = {
                                    elapsedSec = 0
                                    phase = "holding"
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = SanctuaryColors.PrimaryContainer,
                                    contentColor = SanctuaryColors.OnPrimaryContainer,
                                ),
                                modifier = Modifier.weight(1f),
                            ) {
                                Text("Start Hold")
                            }
                        }
                        "holding" -> {
                            Button(
                                onClick = { phase = "recorded" },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = SanctuaryColors.SecondaryContainer,
                                    contentColor = SanctuaryColors.OnPrimaryContainer,
                                ),
                                modifier = Modifier.fillMaxWidth(),
                            ) {
                                Text("Stop at First Urge")
                            }
                        }
                        else -> {
                            OutlinedButton(
                                onClick = { phase = "ready" },
                                modifier = Modifier.weight(1f),
                            ) {
                                Text("Retest")
                            }
                            Button(
                                onClick = { onSaveCht(elapsedSec.toDouble().coerceAtLeast(3.0)) },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = SanctuaryColors.PrimaryContainer,
                                    contentColor = SanctuaryColors.OnPrimaryContainer,
                                ),
                                modifier = Modifier.weight(1f),
                            ) {
                                Text("Calibrate")
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun PostSessionCheckinDialog(
    practiceName: String,
    durationSeconds: Int,
    preCalmness: Int,
    onDismiss: () -> Unit,
    onSubmit: (feeling: String, postCalmness: Int, note: String) -> Unit,
) {
    var feeling by remember { mutableStateOf("calm") }
    var postCalmness by remember { mutableFloatStateOf((preCalmness + 2).coerceIn(1, 10).toFloat()) }
    var note by remember { mutableStateOf("") }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = SanctuaryColors.SurfaceContainer,
            shape = RoundedCornerShape(20.dp),
            border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
        ) {
            Column(
                modifier = Modifier.padding(22.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    text = "See the Difference",
                    style = MaterialTheme.typography.headlineMedium,
                    color = SanctuaryColors.Primary,
                )
                Text(
                    text = "$practiceName · ${(durationSeconds / 60).coerceAtLeast(1)} min completed",
                    style = MaterialTheme.typography.bodySmall,
                    color = SanctuaryColors.OnSurfaceVariant,
                )

                Text(
                    text = "How does the breath feel now?",
                    style = MaterialTheme.typography.labelLarge,
                    color = SanctuaryColors.OnSurface,
                )
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    listOf("calm" to "Calm", "neutral" to "Steady", "agitated" to "Restless", "strained" to "Effortful")
                        .forEach { (key, label) ->
                            val selected = feeling == key
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceLow,
                                modifier = Modifier.clickable { feeling = key },
                            ) {
                                Text(
                                    text = label,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                )
                            }
                        }
                }

                val postInt = postCalmness.roundToInt()
                val delta = postInt - preCalmness
                val deltaSign = if (delta >= 0) "+$delta" else "$delta"
                Text(
                    text = "Calmness Score: $postInt / 10 (Shift: $deltaSign from $preCalmness)",
                    style = MaterialTheme.typography.labelLarge,
                    color = SanctuaryColors.Primary,
                )
                Slider(
                    value = postCalmness,
                    onValueChange = { postCalmness = it },
                    valueRange = 1f..10f,
                    steps = 8,
                    colors = SliderDefaults.colors(
                        thumbColor = SanctuaryColors.PrimaryContainer,
                        activeTrackColor = SanctuaryColors.PrimaryContainer,
                    ),
                )

                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it },
                    label = { Text("Quiet reflection (optional)") },
                    maxLines = 2,
                    modifier = Modifier.fillMaxWidth(),
                )

                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Skip")
                    }
                    Button(
                        onClick = { onSubmit(feeling, postInt, note) },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SanctuaryColors.PrimaryContainer,
                            contentColor = SanctuaryColors.OnPrimaryContainer,
                        ),
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Save Reflection")
                    }
                }
            }
        }
    }
}
