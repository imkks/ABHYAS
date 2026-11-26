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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.pranaflow.abhyas.R
import com.pranaflow.abhyas.ui.components.AdvisoryGuidePill
import com.pranaflow.abhyas.ui.state.AbhyasUiState
import com.pranaflow.abhyas.ui.state.PranayamaCategory
import com.pranaflow.abhyas.ui.state.PranayamaTechniqueUiModel
import com.pranaflow.abhyas.ui.theme.SanctuaryColors
import kotlin.math.roundToInt

@Composable
fun PranayamaMasteryScreen(
    state: AbhyasUiState,
    onSelectCategory: (PranayamaCategory) -> Unit,
    onStartMasterSequence: () -> Unit,
    onStartTechnique: (PranayamaTechniqueUiModel) -> Unit,
    onUpdateTechnique: (PranayamaTechniqueUiModel) -> Unit,
    onOpenChtTest: () -> Unit,
) {
    var editingTechnique by remember { mutableStateOf<PranayamaTechniqueUiModel?>(null) }

    val filtered = remember(state.techniques, state.selectedCategory) {
        if (state.selectedCategory == PranayamaCategory.ALL) {
            state.techniques
        } else {
            state.techniques.filter { it.category == state.selectedCategory }
        }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "Pranayama Mastery",
                    style = MaterialTheme.typography.headlineLarge,
                    color = SanctuaryColors.OnSurface,
                )
                Text(
                    text = "Practice any technique individually or step through the full Krama sequence. Sopana levels serve gently as a guide.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SanctuaryColors.OnSurfaceVariant,
                )
            }
        }

        // Krama Master Sequence Card + Quick CHT
        item {
            Surface(
                color = SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(18.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.5f)),
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "KRAMA SADHANA",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.Primary,
                            )
                            Text(
                                text = "Complete Master Sequence",
                                style = MaterialTheme.typography.headlineMedium,
                                color = SanctuaryColors.OnSurface,
                            )
                        }
                        Surface(
                            color = SanctuaryColors.SurfaceLow,
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.clickable(onClick = onOpenChtTest),
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.Timer,
                                    contentDescription = null,
                                    tint = SanctuaryColors.Primary,
                                    modifier = Modifier.height(14.dp),
                                )
                                Text(
                                    text = state.chtBenchmarkSeconds?.let { "CHT ${it.roundToInt()}s" } ?: "Test CHT",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = SanctuaryColors.Primary,
                                )
                            }
                        }
                    }

                    Text(
                        text = "Sankalp → Kapalbhati → Nadi Shodhana → Ujjayi → Bhramari → Silent Nostril Dhyan",
                        style = MaterialTheme.typography.bodySmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )

                    Button(
                        onClick = onStartMasterSequence,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SanctuaryColors.PrimaryContainer,
                            contentColor = SanctuaryColors.OnPrimaryContainer,
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Icon(imageVector = Icons.Rounded.PlayArrow, contentDescription = null)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Begin 18m Master Flow", style = MaterialTheme.typography.labelLarge)
                    }
                }
            }
        }

        // Category Filter Row
        item {
            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                val tabs = listOf(
                    PranayamaCategory.ALL to "All Disciplines",
                    PranayamaCategory.BALANCING to "Balancing (Sama)",
                    PranayamaCategory.SOLAR to "Solar / Heating",
                    PranayamaCategory.LUNAR to "Lunar / Cooling",
                )
                tabs.forEach { (cat, label) ->
                    val selected = cat == state.selectedCategory
                    Surface(
                        color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceContainer,
                        shape = RoundedCornerShape(20.dp),
                        modifier = Modifier.clickable { onSelectCategory(cat) },
                    ) {
                        Text(
                            text = label,
                            style = MaterialTheme.typography.labelMedium,
                            color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                        )
                    }
                }
            }
        }

        // Classical Individual Technique Cards
        items(filtered, key = { it.id }) { tech ->
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(16.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.35f)),
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
                        AdvisoryGuidePill(
                            text = "Guide: Sopana ${tech.guideLevel} · Open to Explore",
                        )
                        Text(
                            text = "${tech.defaultMinutes} min",
                            style = MaterialTheme.typography.labelMedium,
                            color = SanctuaryColors.Primary,
                        )
                    }

                    Text(
                        text = tech.title,
                        style = MaterialTheme.typography.headlineMedium,
                        color = SanctuaryColors.OnSurface,
                    )
                    Text(
                        text = tech.sanskritTag,
                        style = MaterialTheme.typography.labelMedium,
                        color = SanctuaryColors.Secondary,
                    )
                    Text(
                        text = tech.subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )

                    tech.accessResult.advisoryNote?.let { note ->
                        Surface(
                            color = SanctuaryColors.SurfaceLow,
                            shape = RoundedCornerShape(10.dp),
                        ) {
                            Text(
                                text = note,
                                style = MaterialTheme.typography.bodySmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                                modifier = Modifier.padding(10.dp),
                            )
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Button(
                            onClick = { onStartTechnique(tech) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = SanctuaryColors.PrimaryContainer,
                                contentColor = SanctuaryColors.OnPrimaryContainer,
                            ),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.weight(1f),
                        ) {
                            Icon(imageVector = Icons.Rounded.PlayArrow, contentDescription = null)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(stringResource(R.string.action_begin_practice))
                        }

                        OutlinedButton(
                            onClick = { editingTechnique = tech },
                            shape = RoundedCornerShape(10.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Tune,
                                contentDescription = null,
                                tint = SanctuaryColors.Primary,
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(stringResource(R.string.action_configure), color = SanctuaryColors.Primary)
                        }
                    }
                }
            }
        }
    }

    editingTechnique?.let { current ->
        TechniqueCustomizerDialog(
            technique = current,
            onDismiss = { editingTechnique = null },
            onSave = { updated ->
                onUpdateTechnique(updated)
                editingTechnique = null
            },
        )
    }
}

@Composable
private fun TechniqueCustomizerDialog(
    technique: PranayamaTechniqueUiModel,
    onDismiss: () -> Unit,
    onSave: (PranayamaTechniqueUiModel) -> Unit,
) {
    val ratio = remember(technique) { mutableStateListOf(technique.ratio[0], technique.ratio[1], technique.ratio[2], technique.ratio[3]) }
    var strokes by remember(technique) { mutableIntStateOf(technique.strokesPerRound) }
    var rounds by remember(technique) { mutableIntStateOf(technique.rounds) }
    var minutes by remember(technique) { mutableIntStateOf(technique.defaultMinutes) }
    var mudra by remember(technique) { mutableStateOf(technique.mudra) }
    var style by remember(technique) { mutableStateOf(technique.styleOption) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = SanctuaryColors.SurfaceContainer,
            shape = RoundedCornerShape(20.dp),
            border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
        ) {
            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(22.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    text = "Configure ${technique.title}",
                    style = MaterialTheme.typography.headlineSmall,
                    color = SanctuaryColors.Primary,
                )

                // Duration control
                StepperRow(
                    label = "Session Duration",
                    valueText = "$minutes min",
                    onMinus = { if (minutes > 2) minutes-- },
                    onPlus = { if (minutes < 30) minutes++ },
                )

                when (technique.id) {
                    "nadi_shodhana" -> {
                        Text(
                            text = "Classical Ratio Presets",
                            style = MaterialTheme.typography.labelMedium,
                            color = SanctuaryColors.OnSurfaceVariant,
                        )
                        Row(
                            modifier = Modifier.horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            listOf(
                                "1:0:1:0" to listOf(4, 0, 4, 0),
                                "1:0:2:0" to listOf(4, 0, 8, 0),
                                "1:1:2:0" to listOf(4, 4, 8, 0),
                                "1:2:2:0" to listOf(4, 8, 8, 0),
                                "1:4:2:1" to listOf(4, 16, 8, 4),
                            ).forEach { (label, preset) ->
                                Surface(
                                    color = SanctuaryColors.SurfaceHigh,
                                    shape = RoundedCornerShape(8.dp),
                                    modifier = Modifier.clickable {
                                        for (i in 0..3) ratio[i] = preset[i]
                                    },
                                ) {
                                    Text(
                                        text = label,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = SanctuaryColors.Primary,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    )
                                }
                            }
                        }
                        StepperRow("Puraka (Inhale)", "${ratio[0]}s", { if (ratio[0] > 2) ratio[0]-- }, { if (ratio[0] < 16) ratio[0]++ })
                        StepperRow("Antar Kumbhaka", "${ratio[1]}s", { if (ratio[1] > 0) ratio[1]-- }, { if (ratio[1] < 32) ratio[1]++ })
                        StepperRow("Rechaka (Exhale)", "${ratio[2]}s", { if (ratio[2] > 2) ratio[2]-- }, { if (ratio[2] < 32) ratio[2]++ })
                        StepperRow("Bahya Kumbhaka", "${ratio[3]}s", { if (ratio[3] > 0) ratio[3]-- }, { if (ratio[3] < ratio[1]) ratio[3]++ })
                    }

                    "kapalbhati" -> {
                        Text("Strokes per Round", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.OnSurfaceVariant)
                        OptionChips(listOf(30, 45, 60, 80), strokes) { strokes = it }
                        StepperRow("Bahir Kumbhaka (Empty Hold)", "${ratio[3]}s", { if (ratio[3] > 0) ratio[3] -= 5 }, { if (ratio[3] < 20) ratio[3] += 5 })
                        StepperRow("Rounds", "$rounds", { if (rounds > 1) rounds-- }, { if (rounds < 6) rounds++ })
                    }

                    "ujjayi" -> {
                        Text("Ocean Breath Pacing", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.OnSurfaceVariant)
                        LabeledOptionChips(listOf("4:4" to listOf(4, 0, 4, 0), "4:8" to listOf(4, 0, 8, 0), "5:5" to listOf(5, 0, 5, 0)), "${ratio[0]}:${ratio[2]}") {
                            ratio[0] = it[0]
                            ratio[2] = it[2]
                        }
                        StepperRow("Antar Hold", "${ratio[1]}s", { if (ratio[1] > 0) ratio[1] -= 2 }, { if (ratio[1] < 12) ratio[1] += 2 })
                        StepperRow("Breaths", "$rounds", { if (rounds > 5) rounds -= 2 }, { if (rounds < 20) rounds += 2 })
                    }

                    "bhramari" -> {
                        Text("Mudra Selection", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.OnSurfaceVariant)
                        OptionChips(listOf("Shanmukhi Mudra", "Ear Tragus", "Jnana Mudra"), mudra) { mudra = it }
                        StepperRow("Optional Antar Hold", "${ratio[1]}s", { if (ratio[1] > 0) ratio[1]-- }, { if (ratio[1] < 10) ratio[1]++ })
                        StepperRow("Humming Cycles", "$rounds", { if (rounds > 3) rounds-- }, { if (rounds < 15) rounds++ })
                    }

                    "bhastrika" -> {
                        Text("Bellows Strokes / Round", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.OnSurfaceVariant)
                        OptionChips(listOf(15, 20, 25, 30), strokes) { strokes = it }
                        StepperRow("Antar Hold after Round", "${ratio[1]}s", { if (ratio[1] > 0) ratio[1] -= 4 }, { if (ratio[1] < 20) ratio[1] += 4 })
                        StepperRow("Rounds", "$rounds", { if (rounds > 2) rounds-- }, { if (rounds < 6) rounds++ })
                    }

                    else -> {
                        Text("Cooling Technique", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.OnSurfaceVariant)
                        OptionChips(listOf("Sheetali Tongue Curl", "Sheetkari Teeth Inhale"), style) { style = it }
                        StepperRow("Cooling Cycles", "$rounds", { if (rounds > 6) rounds -= 3 }, { if (rounds < 24) rounds += 3 })
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                        Text(stringResource(R.string.action_cancel))
                    }
                    Button(
                        onClick = {
                            val newSubtitle = when (technique.id) {
                                "nadi_shodhana" -> "Alternate Nostril • Ratio ${ratio.joinToString(":")}"
                                "kapalbhati" -> "$strokes strokes × $rounds rounds + ${ratio[3]}s Bahir Kumbhaka"
                                "bhramari" -> "$mudra · ${ratio[1]}s hold · $rounds cycles"
                                "bhastrika" -> "$strokes bellows × $rounds rounds · ${ratio[1]}s hold"
                                "sheetali" -> "$style · $rounds cycles"
                                else -> "Ujjayi pacing ${ratio[0]}:${ratio[1]}:${ratio[2]} · $rounds breaths"
                            }
                            onSave(
                                technique.copy(
                                    defaultMinutes = minutes,
                                    ratio = ratio.toList(),
                                    strokesPerRound = strokes,
                                    rounds = rounds,
                                    mudra = mudra,
                                    styleOption = style,
                                    subtitle = newSubtitle,
                                ),
                            )
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

@Composable
private fun StepperRow(
    label: String,
    valueText: String,
    onMinus: () -> Unit,
    onPlus: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = label, style = MaterialTheme.typography.bodyMedium, color = SanctuaryColors.OnSurface)
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Surface(
                color = SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.clickable(onClick = onMinus),
            ) {
                Text("-", style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.Primary, modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp))
            }
            Text(text = valueText, style = MaterialTheme.typography.labelLarge, color = SanctuaryColors.Primary)
            Surface(
                color = SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.clickable(onClick = onPlus),
            ) {
                Text("+", style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.Primary, modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp))
            }
        }
    }
}

@Composable
private fun <T> OptionChips(
    options: List<T>,
    selected: T,
    onSelect: (T) -> Unit,
) {
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        options.forEach { item ->
            val isSel = item == selected
            Surface(
                color = if (isSel) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.clickable { onSelect(item) },
            ) {
                Text(
                    text = item.toString(),
                    style = MaterialTheme.typography.labelMedium,
                    color = if (isSel) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp),
                )
            }
        }
    }
}

@Composable
private fun <T> LabeledOptionChips(
    options: List<Pair<String, T>>,
    selectedLabel: String,
    onSelect: (T) -> Unit,
) {
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        options.forEach { (label, value) ->
            val isSel = label == selectedLabel
            Surface(
                color = if (isSel) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceHigh,
                shape = RoundedCornerShape(8.dp),
                modifier = Modifier.clickable { onSelect(value) },
            ) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium,
                    color = if (isSel) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp),
                )
            }
        }
    }
}
