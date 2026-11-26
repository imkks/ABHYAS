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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ArrowDownward
import androidx.compose.material.icons.outlined.ArrowUpward
import androidx.compose.material.icons.outlined.BookmarkAdd
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.pranaflow.abhyas.R
import com.pranaflow.abhyas.data.models.SavedCustomRoutine
import com.pranaflow.abhyas.engine.player.CycleStepItem
import com.pranaflow.abhyas.engine.player.RoutineCatalog
import com.pranaflow.abhyas.engine.player.RoutineIntensity
import com.pranaflow.abhyas.engine.player.RoutinePreset
import com.pranaflow.abhyas.ui.components.DurationChipRow
import com.pranaflow.abhyas.ui.state.AbhyasUiState
import com.pranaflow.abhyas.ui.theme.SanctuaryColors
import kotlin.math.roundToInt

@Composable
fun CustomComposerScreen(
    state: AbhyasUiState,
    onBack: () -> Unit,
    onSelectPreset: (RoutinePreset) -> Unit,
    onSelectIntensity: (RoutineIntensity) -> Unit,
    onSelectDuration: (Int) -> Unit,
    onAdjustStepDuration: (index: Int, deltaMin: Int) -> Unit,
    onMoveStep: (index: Int, delta: Int) -> Unit,
    onRemoveStep: (index: Int) -> Unit,
    onAddExercise: (String) -> Unit,
    onUpdateStep: (index: Int, CycleStepItem) -> Unit,
    onSaveRoutine: (String) -> Unit,
    onLoadSavedRoutine: (SavedCustomRoutine) -> Unit,
    onDeleteSavedRoutine: (String) -> Unit,
    onBeginSequence: () -> Unit,
) {
    var showAddCatalogDialog by remember { mutableStateOf(false) }
    var showSaveDialog by remember { mutableStateOf(false) }
    var editingStepIndex by remember { mutableStateOf<Int?>(null) }

    val composer = state.composer

    Scaffold(
        containerColor = SanctuaryColors.Surface,
        topBar = {
            Surface(color = SanctuaryColors.Surface.copy(alpha = 0.96f)) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconButton(onClick = onBack) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                                contentDescription = "Back",
                                tint = SanctuaryColors.OnSurface,
                            )
                        }
                        Column {
                            Text(
                                text = "Sadhana Composer",
                                style = MaterialTheme.typography.headlineSmall,
                                color = SanctuaryColors.OnSurface,
                            )
                            Text(
                                text = "${composer.steps.size} steps · ${composer.totalMinutes} min (10s transition gaps)",
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.Primary,
                            )
                        }
                    }

                    Row {
                        IconButton(onClick = { showSaveDialog = true }) {
                            Icon(
                                imageVector = Icons.Outlined.BookmarkAdd,
                                contentDescription = "Save Routine",
                                tint = SanctuaryColors.Primary,
                            )
                        }
                    }
                }
            }
        },
        bottomBar = {
            Surface(color = SanctuaryColors.SurfaceLowest, tonalElevation = 4.dp) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    OutlinedButton(
                        onClick = { showAddCatalogDialog = true },
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Icon(imageVector = Icons.Outlined.Add, contentDescription = null, tint = SanctuaryColors.Primary)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Add", color = SanctuaryColors.Primary)
                    }
                    Button(
                        onClick = onBeginSequence,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SanctuaryColors.PrimaryContainer,
                            contentColor = SanctuaryColors.OnPrimaryContainer,
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.weight(1f),
                    ) {
                        Icon(imageVector = Icons.Rounded.PlayArrow, contentDescription = null)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Begin Sequence (${composer.totalMinutes}m)")
                    }
                }
            }
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            // Blueprint Preset Selector
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "ROUTINE BLUEPRINT",
                        style = MaterialTheme.typography.labelSmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        listOf(
                            RoutinePreset.SURYA to "Morning Vitality (Surya)",
                            RoutinePreset.CHANDRA to "Night Stillness (Chandra)",
                            RoutinePreset.CUSTOM to "Custom Sadhana",
                        ).forEach { (preset, label) ->
                            val selected = composer.preset == preset
                            Surface(
                                color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceContainer,
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier.clickable { onSelectPreset(preset) },
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
                }
            }

            // Intensity & Duration Scaling
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "PACING & TARGET DURATION",
                        style = MaterialTheme.typography.labelSmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        listOf(
                            RoutineIntensity.GENTLE to "Gentle",
                            RoutineIntensity.ADAPTIVE to "Adaptive",
                            RoutineIntensity.INTENSE to "Deep",
                        ).forEach { (intensity, label) ->
                            val selected = composer.intensity == intensity
                            Surface(
                                color = if (selected) SanctuaryColors.SecondaryContainer else SanctuaryColors.SurfaceContainer,
                                shape = RoundedCornerShape(10.dp),
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { onSelectIntensity(intensity) },
                            ) {
                                Text(
                                    text = label,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                                )
                            }
                        }
                    }
                    DurationChipRow(
                        optionsMinutes = RoutineCatalog.availableDurationsMinutes,
                        selectedMinutes = composer.targetMinutes,
                        onSelect = onSelectDuration,
                    )
                    state.chtBenchmarkSeconds?.let { cht ->
                        Text(
                            text = "Comfort CHT Guide: ${cht.roundToInt()}s (recommended hold cap ~${(cht * state.config.holdCapFractionOfCht).roundToInt()}s)",
                            style = MaterialTheme.typography.labelSmall,
                            color = SanctuaryColors.Secondary,
                        )
                    }
                }
            }

            // Saved Routines Strip (when present)
            if (state.savedRoutines.isNotEmpty()) {
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            text = "SAVED ROUTINES",
                            style = MaterialTheme.typography.labelSmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                        )
                        Row(
                            modifier = Modifier.horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            state.savedRoutines.forEach { saved ->
                                Surface(
                                    color = SanctuaryColors.SurfaceLow,
                                    shape = RoundedCornerShape(12.dp),
                                    border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.4f)),
                                    modifier = Modifier.clickable { onLoadSavedRoutine(saved) },
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    ) {
                                        Column {
                                            Text(saved.name, style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.Primary)
                                            Text("${saved.targetMinutes}m · ${saved.steps.size} steps", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.OnSurfaceVariant)
                                        }
                                        Icon(
                                            imageVector = Icons.Outlined.DeleteOutline,
                                            contentDescription = "Delete routine",
                                            tint = SanctuaryColors.OnSurfaceVariant,
                                            modifier = Modifier
                                                .size(16.dp)
                                                .clickable { onDeleteSavedRoutine(saved.id) },
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Step Cards
            itemsIndexed(composer.steps) { index, step ->
                val mins = (step.durationSeconds / 60).coerceAtLeast(1)
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                    border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.35f)),
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
                                    text = "${index + 1}. ${step.title}",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = SanctuaryColors.OnSurface,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                )
                                Text(
                                    text = step.subtitle,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = SanctuaryColors.OnSurfaceVariant,
                                )
                            }
                            Row {
                                IconButton(onClick = { onMoveStep(index, -1) }, enabled = index > 0) {
                                    Icon(Icons.Outlined.ArrowUpward, contentDescription = "Move Up", tint = if (index > 0) SanctuaryColors.OnSurfaceVariant else SanctuaryColors.OutlineVariant)
                                }
                                IconButton(onClick = { onMoveStep(index, 1) }, enabled = index < composer.steps.lastIndex) {
                                    Icon(Icons.Outlined.ArrowDownward, contentDescription = "Move Down", tint = if (index < composer.steps.lastIndex) SanctuaryColors.OnSurfaceVariant else SanctuaryColors.OutlineVariant)
                                }
                                IconButton(onClick = { onRemoveStep(index) }, enabled = composer.steps.size > 1) {
                                    Icon(Icons.Outlined.DeleteOutline, contentDescription = "Remove Step", tint = SanctuaryColors.OnSurfaceVariant)
                                }
                            }
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Surface(
                                    color = SanctuaryColors.SurfaceHigh,
                                    shape = RoundedCornerShape(8.dp),
                                    modifier = Modifier.clickable { onAdjustStepDuration(index, -1) },
                                ) {
                                    Text("-1m", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.Primary, modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp))
                                }
                                Text("${mins} min", style = MaterialTheme.typography.labelLarge, color = SanctuaryColors.Primary)
                                Surface(
                                    color = SanctuaryColors.SurfaceHigh,
                                    shape = RoundedCornerShape(8.dp),
                                    modifier = Modifier.clickable { onAdjustStepDuration(index, 1) },
                                ) {
                                    Text("+1m", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.Primary, modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp))
                                }
                            }

                            if (step.isPranayamaWithPacer) {
                                OutlinedButton(
                                    onClick = { editingStepIndex = index },
                                    shape = RoundedCornerShape(8.dp),
                                ) {
                                    Icon(Icons.Outlined.Tune, contentDescription = null, tint = SanctuaryColors.Primary, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Adjust", color = SanctuaryColors.Primary, style = MaterialTheme.typography.labelMedium)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showAddCatalogDialog) {
        Dialog(onDismissRequest = { showAddCatalogDialog = false }) {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(20.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
            ) {
                Column(
                    modifier = Modifier
                        .verticalScroll(rememberScrollState())
                        .padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text("Add Practice Step", style = MaterialTheme.typography.headlineSmall, color = SanctuaryColors.Primary)
                    RoutineCatalog.catalog.forEach { item ->
                        Surface(
                            color = SanctuaryColors.SurfaceLow,
                            shape = RoundedCornerShape(12.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    onAddExercise(item.id)
                                    showAddCatalogDialog = false
                                },
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(item.title, style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.OnSurface)
                                    Text("${item.category} · ${item.subtitle}", style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.OnSurfaceVariant)
                                }
                                Text("+ ${item.defaultMinutes}m", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.Primary)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showSaveDialog) {
        var name by remember(composer.routineName) { mutableStateOf(composer.routineName) }
        Dialog(onDismissRequest = { showSaveDialog = false }) {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(18.dp),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text("Save Custom Sadhana", style = MaterialTheme.typography.headlineSmall, color = SanctuaryColors.Primary)
                    OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Routine Title") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        OutlinedButton(onClick = { showSaveDialog = false }, modifier = Modifier.weight(1f)) {
                            Text(stringResource(R.string.action_cancel))
                        }
                        Button(
                            onClick = {
                                onSaveRoutine(name)
                                showSaveDialog = false
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = SanctuaryColors.PrimaryContainer, contentColor = SanctuaryColors.OnPrimaryContainer),
                            modifier = Modifier.weight(1f),
                        ) {
                            Text(stringResource(R.string.action_save))
                        }
                    }
                }
            }
        }
    }

    editingStepIndex?.let { idx ->
        val step = composer.steps.getOrNull(idx)
        if (step != null) {
            StepQuickAdjustDialog(
                step = step,
                onDismiss = { editingStepIndex = null },
                onSave = { updated ->
                    onUpdateStep(idx, updated)
                    editingStepIndex = null
                },
            )
        }
    }
}

@Composable
private fun StepQuickAdjustDialog(
    step: CycleStepItem,
    onDismiss: () -> Unit,
    onSave: (CycleStepItem) -> Unit,
) {
    val curRatio = step.ratio ?: listOf(4, 0, 4, 0)
    val ratio = remember(step) { mutableStateListOf(curRatio.getOrElse(0) { 4 }, curRatio.getOrElse(1) { 0 }, curRatio.getOrElse(2) { 4 }, curRatio.getOrElse(3) { 0 }) }
    var strokes by remember(step) { mutableIntStateOf(step.strokes ?: 30) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            color = SanctuaryColors.SurfaceContainer,
            shape = RoundedCornerShape(18.dp),
            border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text("Adjust ${step.title}", style = MaterialTheme.typography.headlineSmall, color = SanctuaryColors.Primary)
                if (step.id.contains("kapal")) {
                    Text("Strokes / round: $strokes · Bahir hold: ${ratio[3]}s", style = MaterialTheme.typography.bodyMedium, color = SanctuaryColors.OnSurface)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        listOf(30, 45, 60, 80).forEach { s ->
                            Surface(
                                color = if (strokes == s) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceHigh,
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.clickable { strokes = s },
                            ) {
                                Text("$s", color = if (strokes == s) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurface, modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp))
                            }
                        }
                    }
                } else {
                    Text("Ratio ${ratio[0]}:${ratio[1]}:${ratio[2]}:${ratio[3]}", style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.Primary)
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        listOf(
                            "4:0:4:0" to listOf(4, 0, 4, 0),
                            "4:0:8:0" to listOf(4, 0, 8, 0),
                            "4:4:8:0" to listOf(4, 4, 8, 0),
                            "4:8:8:0" to listOf(4, 8, 8, 0),
                        ).forEach { (lbl, p) ->
                            Surface(
                                color = SanctuaryColors.SurfaceHigh,
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.clickable {
                                    for (i in 0..3) ratio[i] = p[i]
                                },
                            ) {
                                Text(lbl, style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.Primary, modifier = Modifier.padding(10.dp, 6.dp))
                            }
                        }
                    }
                }
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) {
                        Text(stringResource(R.string.action_cancel))
                    }
                    Button(
                        onClick = {
                            onSave(
                                step.copy(
                                    ratio = ratio.toList(),
                                    strokes = strokes,
                                    subtitle = if (step.id.contains("kapal")) "$strokes strokes/round + ${ratio[3]}s Bahir Kumbhaka" else "Ratio ${ratio.joinToString(":")}",
                                ),
                            )
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = SanctuaryColors.PrimaryContainer, contentColor = SanctuaryColors.OnPrimaryContainer),
                        modifier = Modifier.weight(1f),
                    ) {
                        Text(stringResource(R.string.action_save))
                    }
                }
            }
        }
    }
}
