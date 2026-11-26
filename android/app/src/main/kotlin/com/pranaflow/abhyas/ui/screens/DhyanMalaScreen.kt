package com.pranaflow.abhyas.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.NotificationsActive
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.TouchApp
import androidx.compose.material.icons.outlined.Vibration
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.pranaflow.abhyas.engine.meditation.BreathAnchor
import com.pranaflow.abhyas.engine.player.CycleStepItem
import com.pranaflow.abhyas.ui.components.DurationChipRow
import com.pranaflow.abhyas.ui.state.AbhyasUiState
import com.pranaflow.abhyas.ui.theme.SanctuaryColors

@Composable
fun DhyanMalaScreen(
    state: AbhyasUiState,
    onBeginCombinedFlow: () -> Unit,
    onSelectMantra: (String) -> Unit,
    onAddCustomMantra: (name: String, text: String, transliteration: String, meaning: String?) -> Unit,
    onSetMalaTarget: (Int) -> Unit,
    onTapBead: () -> Unit,
    onResetMala: () -> Unit,
    onToggleMalaHaptics: () -> Unit,
    onToggleMalaBell: () -> Unit,
    onStartJapa: (Int) -> Unit,
    onSelectDharanaAnchor: (BreathAnchor) -> Unit,
    onSelectDharanaMinutes: (Int) -> Unit,
    onStartDharana: () -> Unit,
    onSelectYogaNidraMinutes: (Int) -> Unit,
    onStartYogaNidra: () -> Unit,
    onStartCycle: (String, List<CycleStepItem>) -> Unit,
) {
    var showAddMantraDialog by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = "Dhyan & Mala Mastery",
                    style = MaterialTheme.typography.headlineLarge,
                    color = SanctuaryColors.OnSurface,
                )
                Text(
                    text = "Progressive Naam Japa, 108 Digital Mala, Prana Dharana breath anchoring & classical Yoga Nidra.",
                    style = MaterialTheme.typography.bodySmall,
                    color = SanctuaryColors.OnSurfaceVariant,
                )
            }
        }

        // 1. Featured Combined Dhyan Flow
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
                    Text(
                        text = "COMBINED DHYAN KRAMA · 18 MIN",
                        style = MaterialTheme.typography.labelSmall,
                        color = SanctuaryColors.Primary,
                    )
                    Text(
                        text = "3-Stage Naam Japa → Nostril Dhyan",
                        style = MaterialTheme.typography.headlineMedium,
                        color = SanctuaryColors.OnSurface,
                    )
                    Text(
                        text = "Moves smoothly from spoken chanting (Vaikhari) to whisper (Upamshu) to silent mental stillness (Manasika) at the nostril rims.",
                        style = MaterialTheme.typography.bodySmall,
                        color = SanctuaryColors.OnSurfaceVariant,
                    )
                    Button(
                        onClick = onBeginCombinedFlow,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SanctuaryColors.PrimaryContainer,
                            contentColor = SanctuaryColors.OnPrimaryContainer,
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Icon(imageVector = Icons.Rounded.PlayArrow, contentDescription = null)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Begin Combined Flow (${state.selectedMantra.name})")
                    }
                }
            }
        }

        // 2. Interactive 108 Digital Mala Counter
        item {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(18.dp),
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column {
                            Text(
                                text = "Digital Rudraksha Mala",
                                style = MaterialTheme.typography.headlineSmall,
                                color = SanctuaryColors.OnSurface,
                            )
                            Text(
                                text = "Malas Completed: ${state.malaRoundsCompleted}",
                                style = MaterialTheme.typography.labelMedium,
                                color = SanctuaryColors.Primary,
                            )
                        }
                        Row {
                            IconButton(onClick = onToggleMalaHaptics) {
                                Icon(
                                    imageVector = Icons.Outlined.Vibration,
                                    contentDescription = "Mala Haptic",
                                    tint = if (state.malaHapticEnabled) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.4f),
                                )
                            }
                            IconButton(onClick = onToggleMalaBell) {
                                Icon(
                                    imageVector = Icons.Outlined.NotificationsActive,
                                    contentDescription = "Meru Bell",
                                    tint = if (state.malaBellEnabled) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.4f),
                                )
                            }
                            IconButton(onClick = onResetMala) {
                                Icon(
                                    imageVector = Icons.Outlined.Refresh,
                                    contentDescription = "Reset Mala",
                                    tint = SanctuaryColors.OnSurfaceVariant,
                                )
                            }
                        }
                    }

                    // Target Bead Count Chips (27, 54, 108, Free)
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        listOf(27 to "27 (¼)", 54 to "54 (½)", 108 to "108 (Full)", -1 to "Free")
                            .forEach { (count, label) ->
                                val selected = state.malaTargetBeads == count
                                Surface(
                                    color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceLow,
                                    shape = RoundedCornerShape(10.dp),
                                    modifier = Modifier.clickable { onSetMalaTarget(count) },
                                ) {
                                    Text(
                                        text = label,
                                        style = MaterialTheme.typography.labelMedium,
                                        color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp),
                                    )
                                }
                            }
                    }

                    // Active Mantra Preview
                    Text(
                        text = state.selectedMantra.text,
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.Primary,
                        textAlign = TextAlign.Center,
                    )

                    // Tactile Tap Bead Disc
                    Box(
                        modifier = Modifier
                            .size(152.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.radialGradient(
                                    listOf(
                                        SanctuaryColors.PrimaryContainer.copy(alpha = 0.30f),
                                        SanctuaryColors.SurfaceLow,
                                    ),
                                ),
                            )
                            .clickable(onClick = onTapBead),
                        contentAlignment = Alignment.Center,
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Outlined.TouchApp,
                                contentDescription = null,
                                tint = SanctuaryColors.Primary,
                                modifier = Modifier.size(22.dp),
                            )
                            Text(
                                text = "${state.malaCurrentBead}",
                                style = MaterialTheme.typography.displayMedium,
                                color = SanctuaryColors.OnSurface,
                            )
                            val targetLabel = if (state.malaTargetBeads > 0) "of ${state.malaTargetBeads} beads" else "continuous"
                            Text(
                                text = targetLabel,
                                style = MaterialTheme.typography.labelSmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                    }

                    if (state.meruBannerVisible) {
                        Text(
                            text = "Meru Bead reached — round honored in stillness.",
                            style = MaterialTheme.typography.labelMedium,
                            color = SanctuaryColors.Secondary,
                        )
                    }
                }
            }
        }

        // 3. Sacred Japa Mantra Selector + Add Custom Mantra
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "Sacred Japa Mantras",
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.OnSurface,
                    )
                    Surface(
                        color = SanctuaryColors.SurfaceHigh,
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.clickable { showAddMantraDialog = true },
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Add,
                                contentDescription = null,
                                tint = SanctuaryColors.Primary,
                                modifier = Modifier.size(14.dp),
                            )
                            Text("Custom", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.Primary)
                        }
                    }
                }

                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    state.mantras.forEach { mantra ->
                        val isSelected = mantra.id == state.selectedMantra.id
                        Surface(
                            color = if (isSelected) SanctuaryColors.SurfaceHigh else SanctuaryColors.SurfaceContainer,
                            shape = RoundedCornerShape(14.dp),
                            border = BorderStroke(
                                1.dp,
                                if (isSelected) SanctuaryColors.Primary else SanctuaryColors.OutlineVariant.copy(alpha = 0.35f),
                            ),
                            modifier = Modifier
                                .width(196.dp)
                                .clickable { onSelectMantra(mantra.id) },
                        ) {
                            Column(
                                modifier = Modifier.padding(14.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                Text(
                                    text = mantra.name,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = if (isSelected) SanctuaryColors.Primary else SanctuaryColors.OnSurface,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                )
                                Text(
                                    text = mantra.text,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = SanctuaryColors.Secondary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                )
                                mantra.meaning?.let {
                                    Text(
                                        text = it,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = SanctuaryColors.OnSurfaceVariant,
                                        maxLines = 2,
                                        overflow = TextOverflow.Ellipsis,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. Classical Dhyan Disciplines (Progressive Japa, Prana Dharana, Yoga Nidra, Trataka & Antar Mouna)
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Classical Dhyan Disciplines",
                    style = MaterialTheme.typography.headlineSmall,
                    color = SanctuaryColors.OnSurface,
                )

                // Progressive 3-Stage Japa
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Text(
                            text = "3-Stage Progressive Naam Japa",
                            style = MaterialTheme.typography.titleMedium,
                            color = SanctuaryColors.OnSurface,
                        )
                        Text(
                            text = "Vaikhari (Aloud) → Upamshu (Whispered) → Manasika (Silent) → Laya (Stillness)",
                            style = MaterialTheme.typography.bodySmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                        )
                        Button(
                            onClick = { onStartJapa(10) },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = SanctuaryColors.PrimaryContainer,
                                contentColor = SanctuaryColors.OnPrimaryContainer,
                            ),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text("Launch 10m Progressive Japa")
                        }
                    }
                }

                // Prana Dharana (Breath Witnessing)
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Text(
                            text = "Nasagra Breath Witnessing (Prana Dharana)",
                            style = MaterialTheme.typography.titleMedium,
                            color = SanctuaryColors.OnSurface,
                        )
                        Row(
                            modifier = Modifier.horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            listOf(
                                BreathAnchor.NOSTRILS to "Nostril Rim",
                                BreathAnchor.NAVEL to "Navel Center",
                                BreathAnchor.CHEST to "Heart Space",
                                BreathAnchor.SPONTANEOUS_PAUSE to "Kevala Pause",
                            ).forEach { (anchor, label) ->
                                val selected = state.selectedDharanaAnchor == anchor
                                Surface(
                                    color = if (selected) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceLow,
                                    shape = RoundedCornerShape(8.dp),
                                    modifier = Modifier.clickable { onSelectDharanaAnchor(anchor) },
                                ) {
                                    Text(
                                        text = label,
                                        style = MaterialTheme.typography.labelMedium,
                                        color = if (selected) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    )
                                }
                            }
                        }
                        DurationChipRow(
                            optionsMinutes = listOf(5, 10, 15, 20),
                            selectedMinutes = state.selectedDharanaMinutes,
                            onSelect = onSelectDharanaMinutes,
                        )
                        OutlinedButton(
                            onClick = onStartDharana,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(10.dp),
                        ) {
                            Text("Begin ${state.selectedDharanaMinutes}m Breath Awareness", color = SanctuaryColors.Primary)
                        }
                    }
                }

                // Classical Yoga Nidra
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(16.dp),
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Text(
                            text = "Classical Yoga Nidra",
                            style = MaterialTheme.typography.titleMedium,
                            color = SanctuaryColors.OnSurface,
                        )
                        Text(
                            text = "Conscious deep relaxation guiding awareness through the 7 classical stages.",
                            style = MaterialTheme.typography.bodySmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                        )
                        DurationChipRow(
                            optionsMinutes = listOf(20, 30, 45),
                            selectedMinutes = state.selectedYogaNidraMinutes,
                            onSelect = onSelectYogaNidraMinutes,
                        )
                        Button(
                            onClick = onStartYogaNidra,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = SanctuaryColors.SecondaryContainer,
                                contentColor = SanctuaryColors.OnPrimaryContainer,
                            ),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text("Begin ${state.selectedYogaNidraMinutes}m Yoga Nidra")
                        }
                    }
                }

                // Trataka & Antar Mouna Quiet Notes
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Surface(
                        color = SanctuaryColors.SurfaceLow,
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier
                            .weight(1f)
                            .clickable {
                                onStartCycle(
                                    "Trataka Gazing (5m)",
                                    listOf(CycleStepItem("trataka", "Trataka (Steady Gaze)", "Soft unblinking flame gaze followed by closed-eye afterimage stillness", 5 * 60)),
                                )
                            },
                    ) {
                        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("त्राटक · Trataka", style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.Primary)
                            Text("5m Candle Gazing", style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.OnSurfaceVariant)
                        }
                    }

                    Surface(
                        color = SanctuaryColors.SurfaceLow,
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier
                            .weight(1f)
                            .clickable {
                                onStartCycle(
                                    "Antar Mouna (10m)",
                                    listOf(CycleStepItem("antar_mouna", "Antar Mouna (Inner Silence)", "Witnessing sensory impressions and thought ripples neutrally without attachment", 10 * 60)),
                                )
                            },
                    ) {
                        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("अन्तर्मौन · Silence", style = MaterialTheme.typography.titleMedium, color = SanctuaryColors.Primary)
                            Text("10m Inner Witness", style = MaterialTheme.typography.bodySmall, color = SanctuaryColors.OnSurfaceVariant)
                        }
                    }
                }
            }
        }
    }

    if (showAddMantraDialog) {
        var name by remember { mutableStateOf("") }
        var scriptText by remember { mutableStateOf("") }
        var translit by remember { mutableStateOf("") }
        var meaning by remember { mutableStateOf("") }

        Dialog(onDismissRequest = { showAddMantraDialog = false }) {
            Surface(
                color = SanctuaryColors.SurfaceContainer,
                shape = RoundedCornerShape(20.dp),
                border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant),
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text(
                        text = "Add Personal Mantra",
                        style = MaterialTheme.typography.headlineSmall,
                        color = SanctuaryColors.Primary,
                    )
                    OutlinedTextField(value = name, onValueChange = { name = it }, label = { Text("Mantra Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = scriptText, onValueChange = { scriptText = it }, label = { Text("Text (Devanagari / Script)") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = translit, onValueChange = { translit = it }, label = { Text("Transliteration (optional)") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                    OutlinedTextField(value = meaning, onValueChange = { meaning = it }, label = { Text("Meaning / Note (optional)") }, maxLines = 2, modifier = Modifier.fillMaxWidth())
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        OutlinedButton(onClick = { showAddMantraDialog = false }, modifier = Modifier.weight(1f)) {
                            Text("Cancel")
                        }
                        Button(
                            onClick = {
                                onAddCustomMantra(name, scriptText, translit, meaning)
                                showAddMantraDialog = false
                            },
                            enabled = name.isNotBlank() && scriptText.isNotBlank(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = SanctuaryColors.PrimaryContainer,
                                contentColor = SanctuaryColors.OnPrimaryContainer,
                            ),
                            modifier = Modifier.weight(1f),
                        ) {
                            Text("Save Mantra")
                        }
                    }
                }
            }
        }
    }
}
