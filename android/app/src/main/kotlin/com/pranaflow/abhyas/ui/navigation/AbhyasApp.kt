package com.pranaflow.abhyas.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.pranaflow.abhyas.ui.components.BreathCapacityTestDialog
import com.pranaflow.abhyas.ui.components.PostSessionCheckinDialog
import com.pranaflow.abhyas.ui.components.SanctuaryBottomBar
import com.pranaflow.abhyas.ui.components.SanctuaryTab
import com.pranaflow.abhyas.ui.components.SanctuaryTopBar
import com.pranaflow.abhyas.ui.screens.CustomComposerScreen
import com.pranaflow.abhyas.ui.screens.DailySanctuaryScreen
import com.pranaflow.abhyas.ui.screens.DhyanMalaScreen
import com.pranaflow.abhyas.ui.screens.PersonalGrowthScreen
import com.pranaflow.abhyas.ui.screens.PracticePlayerScreen
import com.pranaflow.abhyas.ui.screens.PranayamaMasteryScreen
import com.pranaflow.abhyas.ui.state.AbhyasViewModel
import com.pranaflow.abhyas.ui.theme.SanctuaryColors
import com.pranaflow.abhyas.ui.theme.VedicSerenityTheme

private const val ROUTE_COMPOSER = "composer"
private const val ROUTE_PLAYER = "player"

@Composable
fun AbhyasApp() {
    val context = LocalContext.current
    val viewModel: AbhyasViewModel = viewModel(factory = AbhyasViewModel.Factory(context))
    val state by viewModel.uiState.collectAsState()
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route ?: SanctuaryTab.SANCTUARY.route

    LaunchedEffect(state.statusBanner) {
        val msg = state.statusBanner
        if (msg != null) {
            snackbarHostState.showSnackbar(msg)
            viewModel.clearStatusBanner()
        }
    }

    LaunchedEffect(state.player.isActive) {
        if (state.player.isActive && currentRoute != ROUTE_PLAYER) {
            navController.navigate(ROUTE_PLAYER) { launchSingleTop = true }
        }
    }

    val isFullScreenModal = currentRoute == ROUTE_COMPOSER || currentRoute == ROUTE_PLAYER
    val selectedTab = SanctuaryTab.entries.firstOrNull { it.route == currentRoute } ?: SanctuaryTab.SANCTUARY

    VedicSerenityTheme {
        Scaffold(
            containerColor = SanctuaryColors.Surface,
            snackbarHost = { SnackbarHost(snackbarHostState) },
            topBar = {
                if (!isFullScreenModal) {
                    SanctuaryTopBar(
                        displayName = state.profileSettings.displayName,
                        sopanaLevel = state.progression.level,
                        onRemindersClick = {
                            navController.navigate(SanctuaryTab.GROWTH.route) { launchSingleTop = true }
                        },
                        onProfileClick = {
                            navController.navigate(SanctuaryTab.GROWTH.route) { launchSingleTop = true }
                        },
                    )
                }
            },
            bottomBar = {
                if (!isFullScreenModal) {
                    SanctuaryBottomBar(
                        currentTab = selectedTab,
                        onTabSelected = { tab ->
                            navController.navigate(tab.route) {
                                popUpTo(SanctuaryTab.SANCTUARY.route) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                    )
                }
            },
        ) { innerPadding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
            ) {
                NavHost(
                    navController = navController,
                    startDestination = SanctuaryTab.SANCTUARY.route,
                ) {
                    composable(SanctuaryTab.SANCTUARY.route) {
                        DailySanctuaryScreen(
                            state = state,
                            onSelectSuryaDuration = viewModel::selectSuryaDuration,
                            onSelectChandraDuration = viewModel::selectChandraDuration,
                            onBeginSurya = { viewModel.startSuryaRoutine() },
                            onBeginChandra = { viewModel.startChandraRoutine() },
                            onOpenComposer = { navController.navigate(ROUTE_COMPOSER) },
                            onStartTechnique = viewModel::startSingleTechnique,
                            onOpenPranayamaTab = {
                                navController.navigate(SanctuaryTab.PRANAYAMA.route) { launchSingleTop = true }
                            },
                            onOpenDhyanTab = {
                                navController.navigate(SanctuaryTab.DHYAN.route) { launchSingleTop = true }
                            },
                            onOpenChtTest = { viewModel.setShowChtDialog(true) },
                            onLogVishrama = { viewModel.logVishramaRestDay() },
                            onSaveSankalp = viewModel::saveSankalp,
                        )
                    }

                    composable(SanctuaryTab.PRANAYAMA.route) {
                        PranayamaMasteryScreen(
                            state = state,
                            onSelectCategory = viewModel::selectPranayamaCategory,
                            onStartMasterSequence = viewModel::startMasterSequence,
                            onStartTechnique = viewModel::startSingleTechnique,
                            onUpdateTechnique = viewModel::updateTechniqueConfig,
                            onOpenChtTest = { viewModel.setShowChtDialog(true) },
                        )
                    }

                    composable(SanctuaryTab.DHYAN.route) {
                        DhyanMalaScreen(
                            state = state,
                            onBeginCombinedFlow = viewModel::startCombinedDhyanFlow,
                            onSelectMantra = viewModel::selectMantra,
                            onAddCustomMantra = viewModel::addCustomMantra,
                            onSetMalaTarget = viewModel::setMalaTargetBeads,
                            onTapBead = viewModel::tapMalaBead,
                            onResetMala = viewModel::resetMalaRound,
                            onToggleMalaHaptics = viewModel::toggleMalaHaptics,
                            onToggleMalaBell = viewModel::toggleMalaBell,
                            onStartJapa = viewModel::startStandaloneJapa,
                            onSelectDharanaAnchor = viewModel::selectDharanaAnchor,
                            onSelectDharanaMinutes = viewModel::selectDharanaMinutes,
                            onStartDharana = { viewModel.startStandaloneDharana() },
                            onSelectYogaNidraMinutes = viewModel::selectYogaNidraMinutes,
                            onStartYogaNidra = { viewModel.startYogaNidra() },
                            onStartCycle = { title, steps -> viewModel.startCycleSession(title, steps) },
                        )
                    }

                    composable(SanctuaryTab.GROWTH.route) {
                        PersonalGrowthScreen(
                            state = state,
                            onOpenChtTest = { viewModel.setShowChtDialog(true) },
                            onLogVishrama = { viewModel.logVishramaRestDay() },
                            onSelectPalette = viewModel::updateSoundPalette,
                            onToggleVoice = viewModel::toggleVoiceGuidance,
                            onToggleTones = viewModel::toggleAudioTones,
                            onToggleHaptics = viewModel::toggleHaptics,
                            onToggleTanpura = viewModel::toggleTanpuraDrone,
                            onSaveProfileSettings = viewModel::updateProfileSettings,
                            onSaveReminderSettings = viewModel::saveReminderSettings,
                            onRunSelfCheck = viewModel::evaluateSelfCheckHolds,
                            onExportSnapshot = viewModel::exportUserSnapshot,
                        )
                    }

                    composable(ROUTE_COMPOSER) {
                        CustomComposerScreen(
                            state = state,
                            onBack = { navController.popBackStack() },
                            onSelectPreset = viewModel::selectComposerPreset,
                            onSelectIntensity = viewModel::selectComposerIntensity,
                            onSelectDuration = viewModel::selectComposerDuration,
                            onAdjustStepDuration = viewModel::adjustComposerStepDuration,
                            onMoveStep = viewModel::moveComposerStep,
                            onRemoveStep = viewModel::removeComposerStep,
                            onAddExercise = viewModel::addComposerCatalogExercise,
                            onUpdateStep = viewModel::updateComposerStep,
                            onSaveRoutine = viewModel::saveCurrentCustomRoutine,
                            onLoadSavedRoutine = viewModel::loadSavedRoutine,
                            onDeleteSavedRoutine = viewModel::deleteSavedRoutine,
                            onBeginSequence = {
                                viewModel.startComposerSession()
                                navController.navigate(ROUTE_PLAYER) {
                                    popUpTo(ROUTE_COMPOSER) { inclusive = true }
                                }
                            },
                        )
                    }

                    composable(ROUTE_PLAYER) {
                        PracticePlayerScreen(
                            state = state,
                            onClose = { navController.popBackStack() },
                            onTogglePause = viewModel::togglePlayerPause,
                            onSkipTransition = viewModel::skipPlayerTransition,
                            onSkipStep = viewModel::skipCurrentStep,
                            onReturnToNaturalBreath = viewModel::returnToNaturalBreathAndStop,
                            onCycleWeaningStage = viewModel::cycleWeaningStageInPlayer,
                            onToggleHaptics = viewModel::toggleHaptics,
                            onToggleAudioTones = viewModel::toggleAudioTones,
                            onTapMalaBead = viewModel::tapMalaBead,
                        )
                    }
                }
            }
        }

        if (state.showChtDialog) {
            BreathCapacityTestDialog(
                currentChtSeconds = state.chtBenchmarkSeconds,
                onDismiss = { viewModel.setShowChtDialog(false) },
                onSaveCht = viewModel::saveChtMeasurement,
            )
        }

        state.pendingCheckin?.let { pending ->
            PostSessionCheckinDialog(
                practiceName = pending.practiceName,
                durationSeconds = pending.durationSeconds,
                preCalmness = pending.preCalmness,
                onDismiss = {
                    viewModel.dismissCheckin()
                    if (currentRoute == ROUTE_PLAYER) {
                        navController.popBackStack()
                    }
                },
                onSubmit = { feeling, postCalmness, note ->
                    viewModel.submitPostSessionCheckin(feeling, postCalmness, note)
                    if (currentRoute == ROUTE_PLAYER) {
                        navController.popBackStack()
                    }
                },
            )
        }
    }
}
