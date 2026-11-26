package com.pranaflow.abhyas.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Air
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.SkipNext
import androidx.compose.material.icons.outlined.Vibration
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pranaflow.abhyas.R
import com.pranaflow.abhyas.engine.meditation.JapaStage
import com.pranaflow.abhyas.engine.player.PracticePhase
import com.pranaflow.abhyas.ui.state.AbhyasUiState
import com.pranaflow.abhyas.ui.state.PlayerMode
import com.pranaflow.abhyas.ui.theme.SanctuaryColors

@Composable
fun PracticePlayerScreen(
    state: AbhyasUiState,
    onClose: () -> Unit,
    onTogglePause: () -> Unit,
    onSkipTransition: () -> Unit,
    onSkipStep: () -> Unit,
    onReturnToNaturalBreath: () -> Unit,
    onCycleWeaningStage: () -> Unit,
    onToggleHaptics: () -> Unit,
    onToggleAudioTones: () -> Unit,
    onTapMalaBead: () -> Unit,
) {
    val player = state.player

    Surface(
        color = SanctuaryColors.PlayerDeepCanvas,
        modifier = Modifier.fillMaxSize(),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // 1. Minimalist Player Top Header
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = player.title.ifEmpty { "Active Abhyas Session" },
                            style = MaterialTheme.typography.headlineSmall,
                            color = SanctuaryColors.OnSurface,
                        )
                        Text(
                            text = "${player.subtitle} · Step ${player.currentStepIndex + 1}/${player.totalSteps}",
                            style = MaterialTheme.typography.labelMedium,
                            color = SanctuaryColors.Primary,
                        )
                    }
                    IconButton(onClick = {
                        onReturnToNaturalBreath()
                        onClose()
                    }) {
                        Icon(
                            imageVector = Icons.Outlined.Close,
                            contentDescription = stringResource(R.string.action_close),
                            tint = SanctuaryColors.OnSurfaceVariant,
                        )
                    }
                }

                LinearProgressIndicator(
                    progress = { player.overallProgress },
                    color = SanctuaryColors.PrimaryContainer,
                    trackColor = SanctuaryColors.SurfaceContainer,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp)),
                )

                // Weaning Stage / Guidance Toggle Pill
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.clickable(onClick = onCycleWeaningStage),
                ) {
                    val stageName = when (player.weaningStage) {
                        1 -> "Stage 1 · Guided Voice + Bells"
                        2 -> "Stage 2 · Phase Cues + Bells"
                        3 -> "Stage 3 · Singing Bowls Only"
                        4 -> "Stage 4 · Start & End Bells Only"
                        else -> "Stage 5 · Silent Swatantra"
                    }
                    Text(
                        text = "$stageName (tap to switch)",
                        style = MaterialTheme.typography.labelSmall,
                        color = SanctuaryColors.Secondary,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // 2. Center Sanctuary Focus Ring
            if (player.isTransitioning) {
                TransitionGapContent(
                    completedTitle = player.transitionCompletedTitle,
                    nextTitle = player.transitionNextTitle,
                    mudraGuidance = player.transitionMudraGuidance,
                    secondsLeft = player.transitionSecondsLeft,
                    onSkipTransition = onSkipTransition,
                )
            } else {
                when (player.mode) {
                    PlayerMode.PRANA_DHARANA -> {
                        BreathHaloContent(
                            phaseLabel = "PRANA DHARANA",
                            secondsLabel = formatMmSs(player.elapsedStepSeconds),
                            cueText = player.dharanaPrompt.ifEmpty {
                                "Observe natural breath at ${player.dharanaAnchor.name.lowercase().replace('_', ' ')}"
                            },
                            targetScale = 1.04f,
                            ringColor = SanctuaryColors.BreathNatural,
                            roundLabel = "Target ${player.stepDurationSeconds / 60} min",
                        )
                    }

                    PlayerMode.YOGA_NIDRA -> {
                        BreathHaloContent(
                            phaseLabel = "YOGA NIDRA",
                            secondsLabel = formatMmSs(player.elapsedStepSeconds),
                            cueText = player.yogaNidraStage.ifEmpty { "Settle completely into Savasana" },
                            targetScale = 1.0f,
                            ringColor = SanctuaryColors.Secondary,
                            roundLabel = "Conscious Relaxation",
                        )
                    }

                    PlayerMode.NAAM_JAPA -> {
                        JapaStageContent(
                            stage = player.japaStage,
                            instruction = player.japaInstruction,
                            mantraText = player.selectedMantra?.text ?: "ॐ",
                            elapsedSeconds = player.elapsedStepSeconds,
                            currentBead = state.malaCurrentBead,
                            targetBeads = state.malaTargetBeads,
                            onTapBead = onTapMalaBead,
                        )
                    }

                    PlayerMode.PRANAYAMA_OR_CYCLE -> {
                        val frame = player.phaseFrame
                        if (player.subtitle.lowercase().contains("japa") || player.subtitle.lowercase().contains("naam")) {
                            JapaStageContent(
                                stage = player.japaStage,
                                instruction = player.japaInstruction,
                                mantraText = player.selectedMantra?.text ?: "राधा राधा",
                                elapsedSeconds = player.elapsedStepSeconds,
                                currentBead = state.malaCurrentBead,
                                targetBeads = state.malaTargetBeads,
                                onTapBead = onTapMalaBead,
                            )
                        } else if (frame != null) {
                            val targetScale = when (frame.phase) {
                                PracticePhase.PURAKA -> 1.15f
                                PracticePhase.ANTAR_KUMBHAKA -> 1.15f
                                PracticePhase.RECHAKA -> 0.86f
                                PracticePhase.BAHYA_KUMBHAKA -> 0.84f
                                PracticePhase.NATURAL_BREATH -> 1.0f
                            }
                            val ringColor = when (frame.phase) {
                                PracticePhase.PURAKA -> SanctuaryColors.BreathInhale
                                PracticePhase.ANTAR_KUMBHAKA -> SanctuaryColors.BreathHold
                                PracticePhase.RECHAKA -> SanctuaryColors.BreathExhale
                                PracticePhase.BAHYA_KUMBHAKA -> SanctuaryColors.Tertiary
                                PracticePhase.NATURAL_BREATH -> SanctuaryColors.BreathNatural
                            }
                            val counterDisplay = if (frame.phaseTargetSeconds > 0) {
                                "${frame.secondsInPhase} / ${frame.phaseTargetSeconds}s"
                            } else {
                                formatMmSs(player.elapsedStepSeconds)
                            }
                            BreathHaloContent(
                                phaseLabel = frame.phaseTitle,
                                secondsLabel = counterDisplay,
                                cueText = frame.cueText,
                                targetScale = targetScale,
                                ringColor = ringColor,
                                roundLabel = "Round ${frame.currentRound} of ${frame.totalRounds} · Guide Cap ${frame.maxAllowedHoldSeconds}s",
                            )
                        } else {
                            BreathHaloContent(
                                phaseLabel = player.subtitle.uppercase(),
                                secondsLabel = formatMmSs(player.elapsedStepSeconds),
                                cueText = "Sit upright comfortably and breathe at natural ease",
                                targetScale = 1.02f,
                                ringColor = SanctuaryColors.Primary,
                                roundLabel = "Step ${player.currentStepIndex + 1} of ${player.totalSteps}",
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // 3. Controls & Calm Release Button
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Surface(
                    color = SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(14.dp),
                    border = BorderStroke(1.dp, SanctuaryColors.OutlineVariant.copy(alpha = 0.6f)),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(onClick = onReturnToNaturalBreath),
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Air,
                            contentDescription = null,
                            tint = SanctuaryColors.Primary,
                        )
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = stringResource(R.string.action_return_natural_breath),
                                style = MaterialTheme.typography.titleMedium,
                                color = SanctuaryColors.OnSurface,
                            )
                            Text(
                                text = "Immediate effortless release · Soft grounding chime",
                                style = MaterialTheme.typography.bodySmall,
                                color = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    IconButton(onClick = onToggleAudioTones) {
                        Icon(
                            imageVector = Icons.Outlined.GraphicEq,
                            contentDescription = "Audio Tones",
                            tint = if (state.audioPreferences.audioTonesEnabled) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.35f),
                        )
                    }
                    Surface(
                        color = SanctuaryColors.PrimaryContainer,
                        shape = CircleShape,
                        modifier = Modifier
                            .size(64.dp)
                            .clickable(onClick = onTogglePause),
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = if (player.isPaused) Icons.Rounded.PlayArrow else Icons.Rounded.Pause,
                                contentDescription = if (player.isPaused) "Resume" else "Pause",
                                tint = SanctuaryColors.OnPrimaryContainer,
                                modifier = Modifier.size(32.dp),
                            )
                        }
                    }
                    IconButton(onClick = onToggleHaptics) {
                        Icon(
                            imageVector = Icons.Outlined.Vibration,
                            contentDescription = "Haptics",
                            tint = if (state.audioPreferences.hapticsEnabled) SanctuaryColors.Primary else SanctuaryColors.OnSurfaceVariant.copy(alpha = 0.35f),
                        )
                    }
                    if (player.totalSteps > 1 && player.mode == PlayerMode.PRANAYAMA_OR_CYCLE) {
                        IconButton(onClick = onSkipStep) {
                            Icon(
                                imageVector = Icons.Outlined.SkipNext,
                                contentDescription = "Next Step",
                                tint = SanctuaryColors.OnSurfaceVariant,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BreathHaloContent(
    phaseLabel: String,
    secondsLabel: String,
    cueText: String,
    targetScale: Float,
    ringColor: androidx.compose.ui.graphics.Color,
    roundLabel: String,
) {
    val scale by animateFloatAsState(
        targetValue = targetScale,
        animationSpec = tween(durationMillis = 850),
        label = "breathHaloScale",
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = phaseLabel,
            style = MaterialTheme.typography.labelLarge,
            color = ringColor,
            textAlign = TextAlign.Center,
        )

        Box(
            modifier = Modifier
                .size(220.dp)
                .scale(scale)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(
                        listOf(
                            ringColor.copy(alpha = 0.25f),
                            SanctuaryColors.SurfaceContainer.copy(alpha = 0.7f),
                            SanctuaryColors.PlayerDeepCanvas,
                        ),
                    ),
                ),
            contentAlignment = Alignment.Center,
        ) {
            Surface(
                color = SanctuaryColors.SurfaceLowest.copy(alpha = 0.85f),
                shape = CircleShape,
                border = BorderStroke(2.dp, ringColor.copy(alpha = 0.85f)),
                modifier = Modifier.size(164.dp),
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = secondsLabel,
                            style = MaterialTheme.typography.displayMedium,
                            color = SanctuaryColors.OnSurface,
                        )
                        Text(
                            text = roundLabel,
                            style = MaterialTheme.typography.labelSmall,
                            color = SanctuaryColors.OnSurfaceVariant,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 10.dp),
                        )
                    }
                }
            }
        }

        Text(
            text = cueText,
            style = MaterialTheme.typography.bodyMedium,
            color = SanctuaryColors.OnSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 12.dp),
        )
    }
}

@Composable
private fun TransitionGapContent(
    completedTitle: String,
    nextTitle: String,
    mudraGuidance: String,
    secondsLeft: Int,
    onSkipTransition: () -> Unit,
) {
    Surface(
        color = SanctuaryColors.SurfaceContainer,
        shape = RoundedCornerShape(22.dp),
        border = BorderStroke(1.dp, SanctuaryColors.Primary.copy(alpha = 0.45f)),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Completed: $completedTitle", style = MaterialTheme.typography.labelMedium, color = SanctuaryColors.BreathNatural)
            Text("Next Practice", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.OnSurfaceVariant)
            Text(nextTitle, style = MaterialTheme.typography.headlineMedium, color = SanctuaryColors.Primary, textAlign = TextAlign.Center)
            Text(mudraGuidance, style = MaterialTheme.typography.bodyMedium, color = SanctuaryColors.OnSurface, textAlign = TextAlign.Center)
            Text("${secondsLeft}s", style = MaterialTheme.typography.displayLarge, color = SanctuaryColors.PrimaryContainer)
            Button(
                onClick = onSkipTransition,
                colors = ButtonDefaults.buttonColors(containerColor = SanctuaryColors.PrimaryContainer, contentColor = SanctuaryColors.OnPrimaryContainer),
                shape = RoundedCornerShape(10.dp),
            ) {
                Text("${stringResource(R.string.action_skip_transition)} →")
            }
        }
    }
}

@Composable
private fun JapaStageContent(
    stage: JapaStage,
    instruction: String,
    mantraText: String,
    elapsedSeconds: Int,
    currentBead: Int,
    targetBeads: Int,
    onTapBead: () -> Unit,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            listOf(
                JapaStage.VAIKHARI to "Vaikhari",
                JapaStage.UPAMSHU to "Upamshu",
                JapaStage.MANASIKA to "Manasika",
                JapaStage.LAYA to "Laya",
            ).forEach { (s, lbl) ->
                val active = s == stage
                Surface(
                    color = if (active) SanctuaryColors.PrimaryContainer else SanctuaryColors.SurfaceContainer,
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Text(
                        text = lbl,
                        style = MaterialTheme.typography.labelSmall,
                        color = if (active) SanctuaryColors.OnPrimaryContainer else SanctuaryColors.OnSurfaceVariant,
                        fontWeight = if (active) FontWeight.Bold else FontWeight.Medium,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                    )
                }
            }
        }

        Text(
            text = mantraText,
            style = MaterialTheme.typography.headlineMedium,
            color = SanctuaryColors.Primary,
            textAlign = TextAlign.Center,
        )

        Surface(
            color = SanctuaryColors.SurfaceContainer,
            shape = CircleShape,
            border = BorderStroke(2.dp, SanctuaryColors.Primary.copy(alpha = 0.65f)),
            modifier = Modifier
                .size(168.dp)
                .clickable(onClick = onTapBead),
        ) {
            Box(contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(formatMmSs(elapsedSeconds), style = MaterialTheme.typography.headlineLarge, color = SanctuaryColors.OnSurface)
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = if (targetBeads > 0) "Bead $currentBead / $targetBeads" else "Bead $currentBead",
                        style = MaterialTheme.typography.labelMedium,
                        color = SanctuaryColors.Primary,
                    )
                    Text("Tap bead", style = MaterialTheme.typography.labelSmall, color = SanctuaryColors.OnSurfaceVariant)
                }
            }
        }

        Text(
            text = instruction,
            style = MaterialTheme.typography.bodySmall,
            color = SanctuaryColors.OnSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

private fun formatMmSs(totalSeconds: Int): String {
    val safe = totalSeconds.coerceAtLeast(0)
    val mins = safe / 60
    val secs = safe % 60
    return "%02d:%02d".format(mins, secs)
}
