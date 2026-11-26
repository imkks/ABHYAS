package com.pranaflow.abhyas.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material.icons.outlined.Bedtime
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.SelfImprovement
import androidx.compose.material.icons.outlined.Spa
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.pranaflow.abhyas.R
import com.pranaflow.abhyas.ui.components.DurationChipRow
import com.pranaflow.abhyas.ui.state.AbhyasUiState
import com.pranaflow.abhyas.ui.state.PranayamaTechniqueUiModel
import com.pranaflow.abhyas.ui.theme.SanctuaryColors
import kotlin.math.roundToInt

@Composable
fun DailySanctuaryScreen(
    state: AbhyasUiState,
    onSelectSuryaDuration: (Int) -> Unit,
    onSelectChandraDuration: (Int) -> Unit,
    onBeginSurya: () -> Unit,
    onBeginChandra: () -> Unit,
    onOpenComposer: () -> Unit,
    onStartTechnique: (PranayamaTechniqueUiModel) -> Unit,
    onOpenPranayamaTab: () -> Unit,
    onOpenDhyanTab: () -> Unit,
    onOpenChtTest: () -> Unit,
    onLogVishrama: () -> Unit,
    onSaveSankalp: (String) -> Unit,
) {
    if (state.isLoading) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator(color = SanctuaryColors.Primary)
        }
        return
    }

    var showSankalpEditor by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        // 1. Greeting & Daily Sankalp
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "Pranam, ${state.profileSettings.displayName}",
                        style = MaterialTheme.typography.headlineLarge,
                        color = SanctuaryColors.OnSurface,
                    )
                    IconButton(onClick = { showSankalpEditor = true }) {
                        Icon(
                            imageVector = Icons.Outlined.Edit,
                            contentDescription = "Edit Sankalp",
                            tint = SanctuaryColors.Primary,
                        )
                    }
                }

                Text(
                    text = "“${state.sankalp}”",
                    style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                    color = SanctuaryColors.OnSurfaceVariant,
                )

                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 11.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Spa,
                            contentDescription = null,
                            tint = SanctuaryColors.Primary,
                            modifier = Modifier.size(18.dp),
                        )
                        Text(
                            text = stringResource(R.string.label_open_daily_abhyas),
                            style = MaterialTheme.typography.labelMedium,
                            color = SanctuaryColors.Primary,
                            modifier = Modifier.weight(1f),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        Icon(
                            imageVector = Icons.Outlined.AutoAwesome,
                            contentDescription = null,
                            tint = SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.7f),
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
            }
        }

        // 2. Featured Daily Surya Abhyas Card
        item {
            Surface(
                color = SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(18.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.45f)),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.WbSunny,
                                    contentDescription = null,
                                    tint = SanctuaryColors.PrimaryContainer,
                                    modifier = Modifier.size(18.dp),
                                )
                                Text(
                                    text = "MORNING VITALITY · DAILY CYCLE",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = SanctuaryColors.Primary,
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Surya Abhyas",
                                style = MaterialTheme.typography.headlineMedium,
                                color = SanctuaryColors.OnSurface,
                            )
                            Text(
                                text = "${state.progression.title} · Ratio ${state.progression.ratio.joinToString(":")}",
                                style = MaterialTheme.typography.bodySmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                        IconButton(onClick = onOpenComposer) {
                            Icon(
                                imageVector = Icons.Outlined.Tune,
                                contentDescription = "Customize Sequence",
                                tint = SanctuaryColors.Primary,
                            )
                        }
                    }

                    DurationChipRow(
                        optionsMinutes = listOf(15, 20, 30, 45),
                        selectedMinutes = state.selectedSuryaMinutes,
                        onSelect = onSelectSuryaDuration,
                    )

                    Button(
                        onClick = onBeginSurya,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SanctuaryColors.PrimaryContainer,
                            contentColor = SanctuaryColors.OnPrimaryContainer,
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.PlayArrow,
                            contentDescription = null,
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Begin Surya Abhyas (${state.selectedSuryaMinutes}m)",
                            style = MaterialTheme.typography.labelLarge,
                        )
                    }
                }
            }
        }

        // 3. Evening Chandra Abhyas Card
        item {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(16.dp),
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Bedtime,
                            contentDescription = null,
                            tint = SanctuaryColors.Secondary,
                            modifier = Modifier.size(18.dp),
                        )
                        Text(
                            text = "Chandra Abhyas · Night Stillness",
                            style = MaterialTheme.typography.headlineSmall,
                            color = SanctuaryColors.OnSurface,
                        )
                    }
                    Text(
                        text = "3-Stage Naam Japa, calming Bhramari resonance & guided Yoga Nidra",
                        style = MaterialTheme.typography.bodySmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )
                    DurationChipRow(
                        optionsMinutes = listOf(20, 25, 40),
                        selectedMinutes = state.selectedChandraMinutes,
                        onSelect = onSelectChandraDuration,
                    )
                    OutlinedButton(
                        onClick = onBeginChandra,
                        border = BorderStroke(1.dp, SanctuaryColors.Primary.copy(alpha = 0.5f)),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(
                            text = "Begin Chandra Abhyas (${state.selectedChandraMinutes}m)",
                            color = SanctuaryColors.Primary,
                            style = MaterialTheme.typography.labelLarge,
                        )
                    }
                }
            }
        }

        // 4. Individual Techniques & Custom Composer Shortcuts
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "Individual Techniques",
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.OnSurface,
                    )
                    Text(
                        text = "View all →",
                        style = MaterialTheme.typography.labelMedium,
                        color = SanctuaryColors.Primary,
                        modifier = Modifier.clickable(onClick = onOpenPranayamaTab),
                    )
                }

                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    state.techniques.take(4).forEach { tech ->
                        Surface(
                            color = SanctuaryColors.SurfaceLow,
                            shape = RoundedCornerShape(14.dp),
                            border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.4f)),
                            modifier = Modifier
                                .width(156.dp)
                                .clickable { onStartTechnique(tech) },
                        ) {
                            Column(
                                modifier = Modifier.padding(14.dp),
                                verticalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                Text(
                                    text = "SOPANA ${tech.guideLevel} GUIDE",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = SanctuaryColors.Primary,
                                )
                                Text(
                                    text = tech.title,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = SanctuaryColors.OnSurface,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                )
                                Text(
                                    text = "${tech.defaultMinutes}m standalone",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = SanctuaryColors.OnSurfaceVariant,
                                )
                            }
                        }
                    }

                    Surface(
                        color = SanctuaryColors.SurfaceContainer,
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier
                            .width(156.dp)
                            .clickable(onClick = onOpenDhyanTab),
                    ) {
                        Column(
                            modifier = Modifier.padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.SelfImprovement,
                                contentDescription = null,
                                tint = SanctuaryColors.Secondary,
                            )
                            Text(
                                text = "108 Mala & Dhyan",
                                style = MaterialTheme.typography.titleMedium,
                                color = SanctuaryColors.OnSurface,
                            )
                            Text(
                                text = "${state.malaCurrentBead}/${state.malaTargetBeads} beads",
                                style = MaterialTheme.typography.bodySmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                    }
                }

                OutlinedButton(
                    onClick = onOpenComposer,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Tune,
                        contentDescription = null,
                        tint = SanctuaryColors.Primary,
                        modifier = Modifier.size(18.dp),
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = stringResource(R.string.label_custom_composer),
                        color = SanctuaryColors.Primary,
                    )
                }
            }
        }

        // 5. Personal Progress: Sopana Rank, CHT, Calmness Shift & Weaning Ladder
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Sadhana Progress",
                    style = MaterialTheme.typography.headlineSmall,
                    color = SanctuaryColors.OnSurface,
                )

                // Sopana XP + Steadiness + Vishrama
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
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Sopana ${state.progression.level}: ${state.progression.title}",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = SanctuaryColors.Primary,
                                )
                                Text(
                                    text = "${state.progression.totalTapas} Tapas XP · ${state.progression.dailyStreak}d steadiness",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = SanctuaryColors.OnSurfaceVariant,
                                )
                            }
                            Text(
                                text = "${(state.progression.progressPercent * 100).roundToInt()}%",
                                style = MaterialTheme.typography.labelLarge,
                                color = SanctuaryColors.Primary,
                            )
                        }

                        LinearProgressIndicator(
                            progress = { state.progression.progressPercent.toFloat() },
                            color = SanctuaryColors.PrimaryContainer,
                            trackColor = SanctuaryColors.SurfaceLowest,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(6.dp)
                                .clip(RoundedCornerShape(4.dp)),
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = "Vishrama allowance: ${state.progression.vishramaDaysUsedThisWeek}/${state.progression.vishramaDaysAllowance} this week",
                                style = MaterialTheme.typography.bodySmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                            Text(
                                text = "Rest Day",
                                style = MaterialTheme.typography.labelMedium,
                                color = SanctuaryColors.Secondary,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.clickable(onClick = onLogVishrama),
                            )
                        }
                    }
                }

                // Comfort Hold Test & Calmness Shift
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Surface(
                        color = SanctuaryColors.SurfaceLow,
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.weight(1f),
                    ) {
                        Column(
                            modifier = Modifier.padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Text(
                                text = "COMFORT HOLD TEST",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                            val chtDisplay = state.chtBenchmarkSeconds?.roundToInt()?.let { "${it}s" } ?: "Not tested"
                            Text(
                                text = chtDisplay,
                                style = MaterialTheme.typography.headlineMedium,
                                color = SanctuaryColors.Primary,
                            )
                            Text(
                                text = "Tap to calibrate →",
                                style = MaterialTheme.typography.labelMedium,
                                color = SanctuaryColors.Secondary,
                                modifier = Modifier.clickable(onClick = onOpenChtTest),
                            )
                        }
                    }

                    Surface(
                        color = SanctuaryColors.SurfaceLow,
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.weight(1f),
                    ) {
                        Column(
                            modifier = Modifier.padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Text(
                                text = stringResource(R.string.label_calmness_shift).uppercase(),
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                            val avgSign = if (state.averageCalmnessDelta >= 0) "+" else ""
                            Text(
                                text = "$avgSign${"%.1f".format(state.averageCalmnessDelta)}",
                                style = MaterialTheme.typography.headlineMedium,
                                color = SanctuaryColors.Primary,
                            )
                            Text(
                                text = "${state.totalPracticeMinutes}m total abhyas",
                                style = MaterialTheme.typography.bodySmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                    }
                }

                // Autonomy / Weaning Ladder strip
                Surface(
                    color = SanctuaryColors.SurfaceLow,
                    shape = RoundedCornerShape(14.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(
                                text = "AUTONOMY LADDER",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                            Text(
                                text = "Stage ${state.progression.weaningProgress.stage}: ${state.progression.weaningProgress.stageName}",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.Primary,
                            )
                        }
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                        ) {
                            for (i in 1..5) {
                                Surface(
                                    color = if (i <= state.progression.weaningProgress.stage) {
                                        SanctuaryColors.Primary
                                    } else {
                                        SanctuaryColors.SurfaceHighest
                                    },
                                    shape = RoundedCornerShape(4.dp),
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(6.dp),
                                ) {}
                            }
                        }
                        Text(
                            text = "Gradually reduces audio cues as you build inner breath independence.",
                            style = MaterialTheme.typography.bodySmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                        )
                    }
                }
            }
        }
    }

    if (showSankalpEditor) {
        var draft by remember(state.sankalp) { mutableStateOf(state.sankalp) }
        Dialog(onDismissRequest = { showSankalpEditor = false }) {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(18.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(
                        text = "Edit Daily Sankalp",
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.Primary,
                    )
                    OutlinedTextField(
                        value = draft,
                        onValueChange = { draft = it },
                        label = { Text("Intention") },
                        maxLines = 3,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        OutlinedButton(
                            onClick = { showSankalpEditor = false },
                            modifier = Modifier.weight(1f),
                        ) {
                            Text(stringResource(R.string.action_cancel))
                        }
                        Button(
                            onClick = {
                                onSaveSankalp(draft)
                                showSankalpEditor = false
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = SanctuaryColors.PrimaryContainer,
                                contentColor = SanctuaryColors.OnPrimaryContainer,
                            ),
                            modifier = Modifier.weight(1f),
                        ) {
                            Text(stringResource(R.string.action_save))
                        }
                    }
                }
            }
        }
    }
}
