package com.pranaflow.abhyas.ui.state

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.pranaflow.abhyas.core.audio.BellType
import com.pranaflow.abhyas.core.di.AbhyasContainer
import com.pranaflow.abhyas.core.reminder.ReminderScheduler
import com.pranaflow.abhyas.core.reminder.ScheduledReminder
import com.pranaflow.abhyas.core.service.PracticePlaybackService
import com.pranaflow.abhyas.data.models.AudioPreferences
import com.pranaflow.abhyas.data.models.CheckinEntry
import com.pranaflow.abhyas.data.models.ChtMeasurement
import com.pranaflow.abhyas.data.models.CustomMantra
import com.pranaflow.abhyas.data.models.ReminderSettings
import com.pranaflow.abhyas.data.models.SavedCustomRoutine
import com.pranaflow.abhyas.data.models.SessionRecord
import com.pranaflow.abhyas.data.models.UserProfileSettings
import com.pranaflow.abhyas.engine.clock.MonotonicClock
import com.pranaflow.abhyas.engine.clock.SystemMonotonicClock
import com.pranaflow.abhyas.engine.config.PracticeConfig
import com.pranaflow.abhyas.engine.config.SeedConfig
import com.pranaflow.abhyas.engine.meditation.BreathAnchor
import com.pranaflow.abhyas.engine.meditation.DigitalMalaEngine
import com.pranaflow.abhyas.engine.meditation.JapaStage
import com.pranaflow.abhyas.engine.meditation.PranaDharanaEngine
import com.pranaflow.abhyas.engine.meditation.ProgressiveJapaEngine
import com.pranaflow.abhyas.engine.player.AudioGuidanceEngine
import com.pranaflow.abhyas.engine.player.CycleSequencer
import com.pranaflow.abhyas.engine.player.CycleStepItem
import com.pranaflow.abhyas.engine.player.PlayerEngine
import com.pranaflow.abhyas.engine.player.PracticePhase
import com.pranaflow.abhyas.engine.player.PracticePhaseFrame
import com.pranaflow.abhyas.engine.player.RoutineCatalog
import com.pranaflow.abhyas.engine.player.RoutineIntensity
import com.pranaflow.abhyas.engine.player.RoutinePreset
import com.pranaflow.abhyas.engine.player.SoundPalette
import com.pranaflow.abhyas.engine.player.YogaNidraPlayer
import com.pranaflow.abhyas.engine.progression.ProgressionEngine
import com.pranaflow.abhyas.engine.progression.SelfCheckEvaluation
import com.pranaflow.abhyas.engine.progression.UserProgression
import com.pranaflow.abhyas.engine.safety.PracticeAccessResult
import com.pranaflow.abhyas.engine.safety.SafetyProfile
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import kotlin.math.roundToInt

enum class PranayamaCategory { ALL, BALANCING, SOLAR, LUNAR }

data class PranayamaTechniqueUiModel(
    val id: String,
    val title: String,
    val sanskritTag: String,
    val category: PranayamaCategory,
    val subtitle: String,
    val guideLevel: Int,
    val defaultMinutes: Int,
    val ratio: List<Int>, // [puraka, antar, rechaka, bahya]
    val strokesPerRound: Int = 30,
    val rounds: Int = 3,
    val mudra: String = "Jnana Mudra",
    val styleOption: String = "Classic",
    val accessResult: PracticeAccessResult,
)

data class ComposerUiState(
    val routineName: String = "My Sadhana Cycle",
    val preset: RoutinePreset = RoutinePreset.SURYA,
    val intensity: RoutineIntensity = RoutineIntensity.ADAPTIVE,
    val targetMinutes: Int = 30,
    val steps: List<CycleStepItem> = emptyList(),
) {
    val totalMinutes: Int
        get() = (steps.filter { it.isEnabled }.sumOf { it.durationSeconds } / 60).coerceAtLeast(1)
}

enum class PlayerMode { PRANAYAMA_OR_CYCLE, NAAM_JAPA, PRANA_DHARANA, YOGA_NIDRA }

data class PlayerUiState(
    val isActive: Boolean = false,
    val mode: PlayerMode = PlayerMode.PRANAYAMA_OR_CYCLE,
    val title: String = "",
    val subtitle: String = "",
    val isRunning: Boolean = false,
    val isPaused: Boolean = false,
    val isCompleted: Boolean = false,
    val isNaturalBreathReturn: Boolean = false,
    val isTransitioning: Boolean = false,
    val transitionSecondsLeft: Int = 0,
    val transitionCompletedTitle: String = "",
    val transitionNextTitle: String = "",
    val transitionMudraGuidance: String = "",
    val currentStepIndex: Int = 0,
    val totalSteps: Int = 1,
    val elapsedStepSeconds: Int = 0,
    val stepDurationSeconds: Int = 60,
    val totalElapsedSeconds: Int = 0,
    val totalCycleDurationSeconds: Int = 60,
    val phaseFrame: PracticePhaseFrame? = null,
    val japaStage: JapaStage = JapaStage.VAIKHARI,
    val japaInstruction: String = "",
    val selectedMantra: CustomMantra? = null,
    val dharanaAnchor: BreathAnchor = BreathAnchor.NOSTRILS,
    val dharanaPrompt: String = "",
    val yogaNidraStage: String = "",
    val weaningStage: Int = 1,
    val preCalmness: Int = 5,
    val recordedHoldSeconds: List<Int> = emptyList(),
    val primaryPracticeId: String = "nadi_shodhana",
) {
    val overallProgress: Float
        get() = if (totalCycleDurationSeconds > 0) {
            (totalElapsedSeconds.toFloat() / totalCycleDurationSeconds.toFloat()).coerceIn(0f, 1f)
        } else 0f
}

data class PendingCheckinSession(
    val practiceId: String,
    val practiceName: String,
    val durationSeconds: Int,
    val level: Int,
    val preCalmness: Int,
    val holdDurations: List<Double> = emptyList(),
)

data class AbhyasUiState(
    val isLoading: Boolean = true,
    val config: PracticeConfig = SeedConfig.defaultConfig,
    val progression: UserProgression = ProgressionEngine.computeProgression(emptyList(), LocalDate.now().toEpochDay()),
    val profileSettings: UserProfileSettings = UserProfileSettings(),
    val audioPreferences: AudioPreferences = AudioPreferences(),
    val reminderSettings: ReminderSettings = ReminderSettings(),
    val scheduledReminders: List<ScheduledReminder> = emptyList(),
    val chtBenchmarkSeconds: Double? = null,
    val chtHistory: List<ChtMeasurement> = emptyList(),
    val averageCalmnessDelta: Double = 0.0,
    val totalPracticeMinutes: Int = 0,
    val recentSessions: List<SessionRecord> = emptyList(),
    val recentCheckins: List<CheckinEntry> = emptyList(),
    val sankalp: String = "Today my intention is to practice steadiness of breath and mind.",
    val mantras: List<CustomMantra> = emptyList(),
    val selectedMantra: CustomMantra = CustomMantra("radha", "Radha Radha", "राधा राधा", "Rādhā Rādhā"),
    val malaTargetBeads: Int = 108,
    val malaCurrentBead: Int = 0,
    val malaRoundsCompleted: Int = 0,
    val malaHapticEnabled: Boolean = true,
    val malaBellEnabled: Boolean = true,
    val meruBannerVisible: Boolean = false,
    val selectedDharanaAnchor: BreathAnchor = BreathAnchor.NOSTRILS,
    val selectedDharanaMinutes: Int = 10,
    val selectedYogaNidraMinutes: Int = 20,
    val selectedSuryaMinutes: Int = 30,
    val selectedChandraMinutes: Int = 25,
    val selectedCategory: PranayamaCategory = PranayamaCategory.ALL,
    val techniques: List<PranayamaTechniqueUiModel> = emptyList(),
    val savedRoutines: List<SavedCustomRoutine> = emptyList(),
    val composer: ComposerUiState = ComposerUiState(),
    val player: PlayerUiState = PlayerUiState(),
    val pendingCheckin: PendingCheckinSession? = null,
    val showChtDialog: Boolean = false,
    val lastSelfCheck: SelfCheckEvaluation? = null,
    val exportedSnapshotJson: String? = null,
    val statusBanner: String? = null,
)

class AbhyasViewModel(
    private val container: AbhyasContainer,
    private val clock: MonotonicClock = SystemMonotonicClock,
    private val onStartForeground: () -> Unit = {},
    private val onStopForeground: () -> Unit = {},
    private val tickerDispatcher: CoroutineDispatcher = Dispatchers.Default,
) : ViewModel() {

    private val _uiState = MutableStateFlow(AbhyasUiState())
    val uiState: StateFlow<AbhyasUiState> = _uiState.asStateFlow()

    private var tickerJob: Job? = null
    private var cycleSequencer: CycleSequencer? = null
    private var playerEngine: PlayerEngine? = null
    private var guidanceEngine: AudioGuidanceEngine? = null
    private var japaEngine: ProgressiveJapaEngine? = null
    private var dharanaEngine: PranaDharanaEngine? = null
    private var yogaNidraPlayer: YogaNidraPlayer? = null
    private var malaEngine: DigitalMalaEngine = DigitalMalaEngine()
    private var lastPhaseKey: String? = null

    init {
        refreshAll()
    }

    fun refreshAll(todayEpochDay: Long = LocalDate.now().toEpochDay()) {
        viewModelScope.launch {
            val config = container.configRepository.getActiveConfig()
            val settings = container.userRepository.loadProfileSettings()
            val audioPrefs = container.userRepository.loadAudioPreferences()
            val reminders = container.userRepository.loadReminderSettings()
            val cht = container.userRepository.loadChtBenchmark()
            val chtHistory = container.userRepository.getChtHistory()
            val sessions = container.sessionRepository.getSessions()
            val checkins = container.sessionRepository.getCheckins()
            val progression = container.computeUserProgression(todayEpochDay)
            val sankalp = container.mantraAndRoutineRepository.getSankalp()
            val mantras = container.mantraAndRoutineRepository.getAllMantras()
            val selectedMantra = container.mantraAndRoutineRepository.getSelectedMantra()
            val malaBeads = container.mantraAndRoutineRepository.getMalaBeadCount()
            val malaRounds = container.mantraAndRoutineRepository.getMalaRoundsCompleted()
            val savedRoutines = container.mantraAndRoutineRepository.getSavedCustomRoutines()

            malaEngine = DigitalMalaEngine(
                initialBeadCount = malaBeads,
                initialRoundsCompleted = malaRounds,
                targetBeads = _uiState.value.malaTargetBeads,
            )

            syncAudioPreferencesToDrivers(audioPrefs)

            val builtTechniques = buildDefaultTechniques(
                config = config,
                userLevel = progression.level,
                ratio = progression.ratio,
                kapalbhatiStrokes = progression.kapalbhatiStrokes,
            )
            val currentComposer = if (_uiState.value.composer.steps.isEmpty()) {
                val lvl = RoutineCatalog.effectiveLevel(progression.level, RoutineIntensity.ADAPTIVE)
                ComposerUiState(
                    routineName = "Morning Vitality (Surya)",
                    preset = RoutinePreset.SURYA,
                    intensity = RoutineIntensity.ADAPTIVE,
                    targetMinutes = 30,
                    steps = RoutineCatalog.buildPresetSteps(
                        preset = RoutinePreset.SURYA,
                        targetMinutes = 30,
                        effectiveLevel = lvl,
                        levelRatio = progression.ratio,
                        kapalbhatiStrokes = progression.kapalbhatiStrokes,
                    ),
                )
            } else {
                _uiState.value.composer
            }

            _uiState.update { prev ->
                prev.copy(
                    isLoading = false,
                    config = config,
                    progression = progression,
                    profileSettings = settings,
                    audioPreferences = audioPrefs,
                    reminderSettings = reminders,
                    scheduledReminders = ReminderScheduler.computeEnabledReminders(reminders),
                    chtBenchmarkSeconds = cht,
                    chtHistory = chtHistory,
                    averageCalmnessDelta = container.sessionRepository.getAverageCalmnessDelta(),
                    totalPracticeMinutes = container.sessionRepository.getTotalPracticeMinutes(),
                    recentSessions = sessions.takeLast(12).reversed(),
                    recentCheckins = checkins.takeLast(12).reversed(),
                    sankalp = sankalp,
                    mantras = mantras,
                    selectedMantra = selectedMantra,
                    malaCurrentBead = malaEngine.currentBead,
                    malaRoundsCompleted = malaEngine.roundsCompleted,
                    techniques = if (prev.techniques.isEmpty()) builtTechniques else prev.techniques,
                    savedRoutines = savedRoutines,
                    composer = currentComposer,
                )
            }
        }
    }

    private fun buildDefaultTechniques(
        config: PracticeConfig,
        userLevel: Int,
        ratio: List<Int>,
        kapalbhatiStrokes: Int,
    ): List<PranayamaTechniqueUiModel> {
        fun access(id: String, guideLevel: Int) = container.evaluatePracticeAccess(
            practiceId = id,
            userLevel = userLevel,
            requiredLevel = guideLevel,
        )
        return listOf(
            PranayamaTechniqueUiModel(
                id = "nadi_shodhana",
                title = "Nadi Shodhana",
                sanskritTag = "नाडी शोधन · Balancing",
                category = PranayamaCategory.BALANCING,
                subtitle = "Alternate Nostril • Ratio ${ratio.joinToString(":")}",
                guideLevel = 1,
                defaultMinutes = 6,
                ratio = ratio,
                mudra = "Vishnu Mudra",
                accessResult = access("nadi_shodhana", 1),
            ),
            PranayamaTechniqueUiModel(
                id = "kapalbhati",
                title = "Kapalbhati",
                sanskritTag = "कपालभाति · Cleansing",
                category = PranayamaCategory.SOLAR,
                subtitle = "$kapalbhatiStrokes strokes/round + 10s Bahir Kumbhaka",
                guideLevel = 2,
                defaultMinutes = 4,
                ratio = listOf(0, 0, 0, 10),
                strokesPerRound = kapalbhatiStrokes,
                rounds = config.getLevel(2)?.kapalbhati?.rounds ?: 3,
                mudra = "Chin Mudra",
                accessResult = access("kapalbhati", 2),
            ),
            PranayamaTechniqueUiModel(
                id = "ujjayi",
                title = "Ujjayi Pranayama",
                sanskritTag = "उज्जायी · Tridoshic Ocean",
                category = PranayamaCategory.BALANCING,
                subtitle = "Soft glottal ocean sound · 4:0:8:0",
                guideLevel = 2,
                defaultMinutes = 4,
                ratio = listOf(4, 0, 8, 0),
                rounds = 10,
                mudra = "Jnana Mudra",
                accessResult = access("ujjayi", 2),
            ),
            PranayamaTechniqueUiModel(
                id = "bhramari",
                title = "Bhramari",
                sanskritTag = "भ्रामरी · Parasympathetic",
                category = PranayamaCategory.LUNAR,
                subtitle = "Shanmukhi Mudra · Steady humming exhale",
                guideLevel = 1,
                defaultMinutes = 4,
                ratio = listOf(4, 0, 8, 0),
                rounds = 7,
                mudra = "Shanmukhi Mudra",
                accessResult = access("bhramari", 1),
            ),
            PranayamaTechniqueUiModel(
                id = "bhastrika",
                title = "Bhastrika Pranayama",
                sanskritTag = "भस्त्रिका · Guide: Sopana 4",
                category = PranayamaCategory.SOLAR,
                subtitle = "Energizing bellows breath · Gentle rhythm",
                guideLevel = 4,
                defaultMinutes = 4,
                ratio = listOf(2, 4, 2, 0),
                strokesPerRound = 20,
                rounds = 3,
                mudra = "Chin Mudra",
                accessResult = access("bhastrika", 4),
            ),
            PranayamaTechniqueUiModel(
                id = "sheetali",
                title = "Sheetali & Sheetkari",
                sanskritTag = "शीतली · Lunar Cooling",
                category = PranayamaCategory.LUNAR,
                subtitle = "Cooling tongue curl or clenched teeth inhale",
                guideLevel = 3,
                defaultMinutes = 3,
                ratio = listOf(4, 0, 8, 0),
                rounds = 12,
                mudra = "Jnana Mudra",
                styleOption = "Sheetali Tongue Curl",
                accessResult = access("sheetali", 3),
            ),
        )
    }

    fun selectSuryaDuration(minutes: Int) {
        _uiState.update { it.copy(selectedSuryaMinutes = minutes) }
    }

    fun selectChandraDuration(minutes: Int) {
        _uiState.update { it.copy(selectedChandraMinutes = minutes) }
    }

    fun selectPranayamaCategory(category: PranayamaCategory) {
        _uiState.update { it.copy(selectedCategory = category) }
    }

    fun updateTechniqueConfig(updated: PranayamaTechniqueUiModel) {
        _uiState.update { state ->
            state.copy(
                techniques = state.techniques.map { if (it.id == updated.id) updated else it },
                statusBanner = "Updated ${updated.title} parameters",
            )
        }
    }

    fun setShowChtDialog(show: Boolean) {
        _uiState.update { it.copy(showChtDialog = show) }
    }

    fun saveChtMeasurement(seconds: Double) {
        viewModelScope.launch {
            val fraction = _uiState.value.config.holdCapFractionOfCht
            container.userRepository.saveChtBenchmark(seconds, holdCapFraction = fraction)
            val level = ProgressionEngine.calculateLevelFromCht(seconds)
            container.userRepository.saveCalibratedLevel(level)
            _uiState.update { it.copy(showChtDialog = false, statusBanner = "Calibrated CHT ${seconds.roundToInt()}s · Suggested Sopana $level") }
            refreshAll()
        }
    }

    fun logVishramaRestDay(todayEpochDay: Long = LocalDate.now().toEpochDay()) {
        viewModelScope.launch {
            container.sessionRepository.logVishramaDay(todayEpochDay)
            _uiState.update { it.copy(statusBanner = "Vishrama rest day recorded — steadiness honored") }
            refreshAll(todayEpochDay)
        }
    }

    fun saveSankalp(text: String) {
        viewModelScope.launch {
            val trimmed = text.trim()
            if (trimmed.isNotEmpty()) {
                container.mantraAndRoutineRepository.saveSankalp(trimmed)
                _uiState.update { it.copy(sankalp = trimmed, statusBanner = "Daily Sankalp updated") }
            }
        }
    }

    fun evaluateSelfCheckHolds(targetHold: Int, recorded: List<Int>) {
        val eval = ProgressionEngine.evaluateSelfCheck(targetHold, recorded)
        _uiState.update { it.copy(lastSelfCheck = eval) }
    }

    // --- Dhyan & Digital Mala ---

    fun selectMantra(id: String) {
        viewModelScope.launch {
            container.mantraAndRoutineRepository.setSelectedMantraId(id)
            val mantra = container.mantraAndRoutineRepository.getSelectedMantra()
            _uiState.update { it.copy(selectedMantra = mantra) }
        }
    }

    fun addCustomMantra(name: String, text: String, transliteration: String = "", meaning: String? = null) {
        if (name.isBlank() || text.isBlank()) return
        viewModelScope.launch {
            val id = "custom_${System.currentTimeMillis()}"
            val newMantra = CustomMantra(
                id = id,
                name = name.trim(),
                text = text.trim(),
                transliteration = transliteration.trim(),
                meaning = meaning?.trim()?.takeIf { it.isNotEmpty() },
                isCustom = true,
            )
            container.mantraAndRoutineRepository.saveCustomMantra(newMantra)
            container.mantraAndRoutineRepository.setSelectedMantraId(id)
            val all = container.mantraAndRoutineRepository.getAllMantras()
            _uiState.update {
                it.copy(
                    mantras = all,
                    selectedMantra = newMantra,
                    statusBanner = "Added mantra: ${newMantra.name}",
                )
            }
        }
    }

    fun setMalaTargetBeads(target: Int) {
        malaEngine = DigitalMalaEngine(
            initialBeadCount = malaEngine.currentBead,
            initialRoundsCompleted = malaEngine.roundsCompleted,
            targetBeads = target,
        )
        _uiState.update { it.copy(malaTargetBeads = target, meruBannerVisible = false) }
    }

    fun toggleMalaHaptics() {
        _uiState.update { it.copy(malaHapticEnabled = !it.malaHapticEnabled) }
    }

    fun toggleMalaBell() {
        _uiState.update { it.copy(malaBellEnabled = !it.malaBellEnabled) }
    }

    fun tapMalaBead() {
        val result = malaEngine.advanceBead()
        if (_uiState.value.malaHapticEnabled) {
            if (result.meruReached) {
                container.hapticService.completionPulse()
            } else {
                container.hapticService.pulseForMatra(1)
            }
        }
        if (result.meruReached && _uiState.value.malaBellEnabled) {
            container.audioService.playBell(BellType.END)
        }
        _uiState.update {
            it.copy(
                malaCurrentBead = result.currentBead,
                malaRoundsCompleted = result.roundsCompleted,
                meruBannerVisible = result.meruReached,
            )
        }
        viewModelScope.launch {
            container.mantraAndRoutineRepository.saveMalaBeadCount(result.currentBead)
            container.mantraAndRoutineRepository.saveMalaRoundsCompleted(result.roundsCompleted)
        }
    }

    fun resetMalaRound() {
        malaEngine.resetCurrentRound()
        _uiState.update { it.copy(malaCurrentBead = 0, meruBannerVisible = false) }
        viewModelScope.launch {
            container.mantraAndRoutineRepository.saveMalaBeadCount(0)
        }
    }

    fun selectDharanaAnchor(anchor: BreathAnchor) {
        _uiState.update { it.copy(selectedDharanaAnchor = anchor) }
    }

    fun selectDharanaMinutes(minutes: Int) {
        _uiState.update { it.copy(selectedDharanaMinutes = minutes) }
    }

    fun selectYogaNidraMinutes(minutes: Int) {
        _uiState.update { it.copy(selectedYogaNidraMinutes = minutes) }
    }

    // --- Custom Session Composer ---

    fun selectComposerPreset(preset: RoutinePreset) {
        val st = _uiState.value
        val effectiveLvl = RoutineCatalog.effectiveLevel(st.progression.level, st.composer.intensity)
        val steps = RoutineCatalog.buildPresetSteps(
            preset = preset,
            targetMinutes = st.composer.targetMinutes,
            effectiveLevel = effectiveLvl,
            levelRatio = st.progression.ratio,
            kapalbhatiStrokes = st.progression.kapalbhatiStrokes,
        )
        val title = when (preset) {
            RoutinePreset.SURYA -> "Morning Vitality (Surya)"
            RoutinePreset.CHANDRA -> "Night Stillness (Chandra)"
            RoutinePreset.CUSTOM -> "Custom Sadhana"
        }
        _uiState.update {
            it.copy(
                composer = it.composer.copy(
                    preset = preset,
                    routineName = title,
                    steps = steps,
                ),
            )
        }
    }

    fun selectComposerIntensity(intensity: RoutineIntensity) {
        val st = _uiState.value
        val effectiveLvl = RoutineCatalog.effectiveLevel(st.progression.level, intensity)
        val lvlInfo = ProgressionEngine.getLevelInfo(effectiveLvl)
        val steps = RoutineCatalog.buildPresetSteps(
            preset = st.composer.preset,
            targetMinutes = st.composer.targetMinutes,
            effectiveLevel = effectiveLvl,
            levelRatio = lvlInfo.ratio,
            kapalbhatiStrokes = lvlInfo.kapalbhatiStrokes,
        )
        _uiState.update {
            it.copy(
                composer = it.composer.copy(
                    intensity = intensity,
                    steps = steps,
                ),
            )
        }
    }

    fun selectComposerDuration(minutes: Int) {
        val st = _uiState.value
        val effectiveLvl = RoutineCatalog.effectiveLevel(st.progression.level, st.composer.intensity)
        val steps = RoutineCatalog.buildPresetSteps(
            preset = st.composer.preset,
            targetMinutes = minutes,
            effectiveLevel = effectiveLvl,
            levelRatio = st.progression.ratio,
            kapalbhatiStrokes = st.progression.kapalbhatiStrokes,
        )
        _uiState.update {
            it.copy(
                composer = it.composer.copy(
                    targetMinutes = minutes,
                    steps = steps,
                ),
            )
        }
    }

    fun adjustComposerStepDuration(index: Int, deltaMinutes: Int) {
        _uiState.update { state ->
            val list = state.composer.steps.toMutableList()
            val item = list.getOrNull(index) ?: return@update state
            val newSec = (item.durationSeconds + deltaMinutes * 60).coerceIn(60, 45 * 60)
            list[index] = item.copy(durationSeconds = newSec)
            state.copy(composer = state.composer.copy(steps = list))
        }
    }

    fun moveComposerStep(index: Int, delta: Int) {
        _uiState.update { state ->
            val list = state.composer.steps.toMutableList()
            val targetIdx = index + delta
            if (index !in list.indices || targetIdx !in list.indices) return@update state
            val moved = list.removeAt(index)
            list.add(targetIdx, moved)
            state.copy(composer = state.composer.copy(steps = list))
        }
    }

    fun removeComposerStep(index: Int) {
        _uiState.update { state ->
            val list = state.composer.steps.toMutableList()
            if (list.size <= 1 || index !in list.indices) return@update state
            list.removeAt(index)
            state.copy(composer = state.composer.copy(steps = list))
        }
    }

    fun addComposerCatalogExercise(templateId: String) {
        val template = RoutineCatalog.catalog.firstOrNull { it.id == templateId } ?: return
        val newItem = CycleStepItem(
            id = template.id,
            title = template.title,
            subtitle = template.subtitle,
            durationSeconds = template.defaultMinutes * 60,
            ratio = if (template.isPranayamaWithPacer) _uiState.value.progression.ratio else null,
            strokes = if (template.id == "kapalbhati") _uiState.value.progression.kapalbhatiStrokes else null,
            rounds = if (template.id == "kapalbhati") 3 else null,
            isPranayamaWithPacer = template.isPranayamaWithPacer,
        )
        _uiState.update { state ->
            state.copy(composer = state.composer.copy(steps = state.composer.steps + newItem))
        }
    }

    fun updateComposerStep(index: Int, updated: CycleStepItem) {
        _uiState.update { state ->
            val list = state.composer.steps.toMutableList()
            if (index !in list.indices) return@update state
            list[index] = updated
            state.copy(composer = state.composer.copy(steps = list))
        }
    }

    fun saveCurrentCustomRoutine(name: String) {
        val st = _uiState.value
        val cleanName = name.trim().ifEmpty { "Saved Sadhana" }
        val routine = SavedCustomRoutine(
            id = "routine_${System.currentTimeMillis()}",
            name = cleanName,
            preset = st.composer.preset,
            targetMinutes = st.composer.totalMinutes,
            intensity = st.composer.intensity,
            steps = st.composer.steps,
        )
        viewModelScope.launch {
            container.mantraAndRoutineRepository.saveCustomRoutine(routine)
            val saved = container.mantraAndRoutineRepository.getSavedCustomRoutines()
            _uiState.update {
                it.copy(
                    savedRoutines = saved,
                    composer = it.composer.copy(routineName = cleanName),
                    statusBanner = "Saved routine: $cleanName",
                )
            }
        }
    }

    fun loadSavedRoutine(routine: SavedCustomRoutine) {
        _uiState.update {
            it.copy(
                composer = ComposerUiState(
                    routineName = routine.name,
                    preset = routine.preset,
                    intensity = routine.intensity,
                    targetMinutes = routine.targetMinutes,
                    steps = routine.steps,
                ),
            )
        }
    }

    fun deleteSavedRoutine(routineId: String) {
        viewModelScope.launch {
            container.mantraAndRoutineRepository.deleteCustomRoutine(routineId)
            val saved = container.mantraAndRoutineRepository.getSavedCustomRoutines()
            _uiState.update { it.copy(savedRoutines = saved) }
        }
    }

    // --- Active Player Lifecycle ---

    fun startSuryaRoutine(minutes: Int = _uiState.value.selectedSuryaMinutes) {
        val st = _uiState.value
        val steps = RoutineCatalog.buildPresetSteps(
            preset = RoutinePreset.SURYA,
            targetMinutes = minutes,
            effectiveLevel = st.progression.level,
            levelRatio = st.progression.ratio,
            kapalbhatiStrokes = st.progression.kapalbhatiStrokes,
        )
        startCycleSession("Surya Abhyas (${minutes}m)", steps)
    }

    fun startChandraRoutine(minutes: Int = _uiState.value.selectedChandraMinutes) {
        val st = _uiState.value
        val steps = RoutineCatalog.buildPresetSteps(
            preset = RoutinePreset.CHANDRA,
            targetMinutes = minutes,
            effectiveLevel = st.progression.level,
            levelRatio = st.progression.ratio,
            kapalbhatiStrokes = st.progression.kapalbhatiStrokes,
        )
        startCycleSession("Chandra Abhyas (${minutes}m)", steps)
    }

    fun startMasterSequence() {
        val st = _uiState.value
        val steps = RoutineCatalog.masterSequence(
            nadiShodhanaRatio = st.progression.ratio,
            kapalbhatiStrokes = st.progression.kapalbhatiStrokes,
        )
        startCycleSession("Krama Master Sequence", steps)
    }

    fun startCombinedDhyanFlow() {
        val mantra = _uiState.value.selectedMantra.name
        val steps = RoutineCatalog.combinedMeditationFlow(mantra)
        startCycleSession("3-Stage Naam Japa → Nostril Dhyan", steps)
    }

    fun startComposerSession() {
        val c = _uiState.value.composer
        if (c.steps.isNotEmpty()) {
            startCycleSession(c.routineName, c.steps)
        }
    }

    fun startSingleTechnique(technique: PranayamaTechniqueUiModel) {
        val step = CycleStepItem(
            id = technique.id,
            title = technique.title,
            subtitle = technique.subtitle,
            durationSeconds = technique.defaultMinutes * 60,
            ratio = technique.ratio,
            strokes = technique.strokesPerRound,
            rounds = technique.rounds,
            mudra = technique.mudra,
            isPranayamaWithPacer = true,
        )
        startCycleSession(technique.title, listOf(step))
    }

    fun startCycleSession(title: String, steps: List<CycleStepItem>, preCalmness: Int = _uiState.value.player.preCalmness) {
        val enabled = steps.filter { it.isEnabled }
        if (enabled.isEmpty()) return

        stopPlayerInternals()
        onStartForeground()

        val st = _uiState.value
        val seq = CycleSequencer(steps = enabled, transitionDurationSeconds = 10, clock = clock)
        val chtSec = (st.chtBenchmarkSeconds ?: 30.0).roundToInt().coerceAtLeast(10)
        val pEngine = PlayerEngine(
            holdCapFractionOfCht = st.config.holdCapFractionOfCht,
            levelCapSeconds = 30,
            userChtSeconds = chtSec,
            bahyaCapSeconds = 24,
            clock = clock,
        )
        val gEngine = AudioGuidanceEngine(
            palette = st.audioPreferences.soundPalette,
            weaningStage = st.progression.weaningProgress.stage,
        )

        cycleSequencer = seq
        playerEngine = pEngine
        guidanceEngine = gEngine
        japaEngine = null
        dharanaEngine = null
        yogaNidraPlayer = null
        lastPhaseKey = null

        val firstStep = seq.currentStep
        val initialFrame = computeStepFrame(pEngine, firstStep, 0)

        seq.start(
            onTransitionStart = { completed, next ->
                val cue = gEngine.getCueForPhaseTransition(PracticePhase.NATURAL_BREATH, pEngine.currentCycle)
                container.practiceAudioService.dispatchCue(cue, _uiState.value.player.weaningStage)
                _uiState.update { cur ->
                    cur.copy(
                        player = cur.player.copy(
                            isTransitioning = true,
                            transitionSecondsLeft = seq.transitionRemainingSeconds,
                            transitionCompletedTitle = completed.title,
                            transitionNextTitle = next.title,
                            transitionMudraGuidance = CycleSequencer.getMudraAndPrepGuidance(next),
                        ),
                    )
                }
            },
            onCycleComplete = {
                val endCue = gEngine.startIntegrationBuffer()
                container.practiceAudioService.dispatchCue(endCue, _uiState.value.player.weaningStage)
                finishPlayerIntoCheckin(
                    id = firstStep.id,
                    name = title,
                    durationSeconds = seq.totalSecondsElapsed.coerceAtLeast(1),
                )
            },
        )
        pEngine.startTimer()

        if (firstStep.id.contains("naam") || firstStep.id.contains("japa")) {
            japaEngine = ProgressiveJapaEngine(totalDurationSeconds = firstStep.durationSeconds)
            val startJapaCue = japaEngine!!.start()
            container.practiceAudioService.dispatchCue(startJapaCue, gEngine.weaningStage)
        } else if (st.audioPreferences.tanpuraDroneEnabled) {
            container.audioService.playTrack("audio/tanpura_drone.wav", looping = true)
        }

        _uiState.update {
            it.copy(
                player = PlayerUiState(
                    isActive = true,
                    mode = PlayerMode.PRANAYAMA_OR_CYCLE,
                    title = title,
                    subtitle = firstStep.title,
                    isRunning = true,
                    isPaused = false,
                    currentStepIndex = 0,
                    totalSteps = seq.steps.size,
                    elapsedStepSeconds = 0,
                    stepDurationSeconds = firstStep.durationSeconds,
                    totalElapsedSeconds = 0,
                    totalCycleDurationSeconds = seq.totalCycleDurationSeconds,
                    phaseFrame = initialFrame,
                    weaningStage = st.progression.weaningProgress.stage,
                    preCalmness = preCalmness,
                    primaryPracticeId = firstStep.id,
                    selectedMantra = st.selectedMantra,
                ),
            )
        }

        launchCycleTicker(title, preCalmness)
    }

    fun startStandaloneJapa(durationMinutes: Int = 10, preCalmness: Int = _uiState.value.player.preCalmness) {
        stopPlayerInternals()
        onStartForeground()

        val st = _uiState.value
        val engine = ProgressiveJapaEngine(totalDurationSeconds = durationMinutes * 60)
        val gEngine = AudioGuidanceEngine(st.audioPreferences.soundPalette, st.progression.weaningProgress.stage)
        japaEngine = engine
        guidanceEngine = gEngine
        val startCue = engine.start()
        container.practiceAudioService.dispatchCue(startCue, st.progression.weaningProgress.stage)

        _uiState.update {
            it.copy(
                player = PlayerUiState(
                    isActive = true,
                    mode = PlayerMode.NAAM_JAPA,
                    title = "3-Stage Progressive Naam Japa",
                    subtitle = st.selectedMantra.name,
                    isRunning = true,
                    stepDurationSeconds = durationMinutes * 60,
                    totalCycleDurationSeconds = durationMinutes * 60,
                    japaStage = engine.currentStage,
                    japaInstruction = engine.stageInstruction,
                    selectedMantra = st.selectedMantra,
                    weaningStage = st.progression.weaningProgress.stage,
                    preCalmness = preCalmness,
                    primaryPracticeId = "naam_jaap",
                ),
            )
        }
        launchStandaloneMeditationTicker()
    }

    fun startStandaloneDharana(
        anchor: BreathAnchor = _uiState.value.selectedDharanaAnchor,
        minutes: Int = _uiState.value.selectedDharanaMinutes,
        preCalmness: Int = _uiState.value.player.preCalmness,
    ) {
        stopPlayerInternals()
        onStartForeground()

        val st = _uiState.value
        val engine = PranaDharanaEngine(durationMinutes = minutes, anchor = anchor)
        val gEngine = AudioGuidanceEngine(st.audioPreferences.soundPalette, st.progression.weaningProgress.stage)
        dharanaEngine = engine
        guidanceEngine = gEngine
        val startCue = engine.start()
        container.practiceAudioService.dispatchCue(startCue, st.progression.weaningProgress.stage)

        _uiState.update {
            it.copy(
                player = PlayerUiState(
                    isActive = true,
                    mode = PlayerMode.PRANA_DHARANA,
                    title = "Prana Dharana · Breath Witnessing",
                    subtitle = "Anchor: ${anchor.name.lowercase().replace('_', ' ')}",
                    isRunning = true,
                    stepDurationSeconds = minutes * 60,
                    totalCycleDurationSeconds = minutes * 60,
                    dharanaAnchor = anchor,
                    dharanaPrompt = startCue.spokenText ?: "",
                    weaningStage = st.progression.weaningProgress.stage,
                    preCalmness = preCalmness,
                    primaryPracticeId = "breath_awareness",
                ),
            )
        }
        launchStandaloneMeditationTicker()
    }

    fun startYogaNidra(minutes: Int = _uiState.value.selectedYogaNidraMinutes, preCalmness: Int = _uiState.value.player.preCalmness) {
        stopPlayerInternals()
        onStartForeground()

        val st = _uiState.value
        val player = YogaNidraPlayer(durationMinutes = minutes, clock = clock)
        yogaNidraPlayer = player
        player.start()
        container.audioService.playTrack(player.audioAssetPath(), looping = false) {
            finishPlayerIntoCheckin(
                id = "yoga_nidra_${minutes}m",
                name = "Yoga Nidra (${minutes}m)",
                durationSeconds = player.totalSeconds,
            )
        }

        _uiState.update {
            it.copy(
                player = PlayerUiState(
                    isActive = true,
                    mode = PlayerMode.YOGA_NIDRA,
                    title = "Classical Yoga Nidra",
                    subtitle = "${minutes}-Minute Deep Conscious Sleep",
                    isRunning = true,
                    stepDurationSeconds = player.totalSeconds,
                    totalCycleDurationSeconds = player.totalSeconds,
                    yogaNidraStage = player.currentStageName(),
                    weaningStage = st.progression.weaningProgress.stage,
                    preCalmness = preCalmness,
                    primaryPracticeId = "yoga_nidra",
                ),
            )
        }
        launchYogaNidraTicker()
    }

    private fun launchCycleTicker(sessionTitle: String, preCalmness: Int) {
        tickerJob?.cancel()
        tickerJob = viewModelScope.launch(tickerDispatcher) {
            val seq = cycleSequencer ?: return@launch
            val pEngine = playerEngine ?: return@launch
            val gEngine = guidanceEngine ?: return@launch

            while (!seq.isCompleted) {
                delay(1_000L)
                if (seq.isPaused || !seq.isRunning) continue

                val prevStepIdx = seq.currentStepIndex
                seq.tickSecond()
                if (seq.isCompleted) break

                val curStep = seq.currentStep
                if (curStep.id != seq.steps[prevStepIdx].id && (curStep.id.contains("naam") || curStep.id.contains("japa"))) {
                    japaEngine = ProgressiveJapaEngine(totalDurationSeconds = curStep.durationSeconds)
                    val cue = japaEngine!!.start()
                    container.practiceAudioService.dispatchCue(cue, _uiState.value.player.weaningStage)
                }

                if (seq.isTransitioning) {
                    val left = seq.transitionRemainingSeconds
                    if (left in 1..3) {
                        container.audioService.playTick()
                    }
                    _uiState.update { cur ->
                        cur.copy(
                            player = cur.player.copy(
                                isTransitioning = true,
                                transitionSecondsLeft = left,
                            ),
                        )
                    }
                } else {
                    val activeJapa = japaEngine
                    var stage = _uiState.value.player.japaStage
                    var japaNote = _uiState.value.player.japaInstruction
                    if (activeJapa != null && (curStep.id.contains("naam") || curStep.id.contains("japa"))) {
                        val cue = activeJapa.tickSecond(seq.secondsInCurrentStep)
                        if (cue != null) {
                            container.practiceAudioService.dispatchCue(cue, _uiState.value.player.weaningStage)
                        }
                        stage = activeJapa.currentStage
                        japaNote = activeJapa.stageInstruction
                    }

                    val frame = computeStepFrame(pEngine, curStep, seq.secondsInCurrentStep)
                    val phaseKey = "${seq.currentStepIndex}_${frame?.phase}_${frame?.currentRound}"
                    if (frame != null && phaseKey != lastPhaseKey) {
                        lastPhaseKey = phaseKey
                        val cue = gEngine.getCueForPhaseTransition(frame.phase, frame.currentRound)
                        container.practiceAudioService.dispatchCue(cue, _uiState.value.player.weaningStage)
                    } else if (curStep.isPranayamaWithPacer && _uiState.value.player.weaningStage < 4) {
                        container.audioService.playTick()
                    }

                    _uiState.update { cur ->
                        cur.copy(
                            player = cur.player.copy(
                                isTransitioning = false,
                                subtitle = curStep.title,
                                currentStepIndex = seq.currentStepIndex,
                                elapsedStepSeconds = seq.secondsInCurrentStep,
                                stepDurationSeconds = curStep.durationSeconds,
                                totalElapsedSeconds = seq.totalSecondsElapsed,
                                phaseFrame = frame,
                                japaStage = stage,
                                japaInstruction = japaNote,
                            ),
                        )
                    }
                }
            }
        }
    }

    private fun launchStandaloneMeditationTicker() {
        tickerJob?.cancel()
        tickerJob = viewModelScope.launch(tickerDispatcher) {
            var elapsed = 0
            while (true) {
                delay(1_000L)
                val p = _uiState.value.player
                if (!p.isActive || !p.isRunning || p.isPaused || p.isCompleted) continue
                elapsed++
                val japa = japaEngine
                val dharana = dharanaEngine
                if (japa != null) {
                    val cue = japa.tickSecond(elapsed)
                    if (cue != null) {
                        container.practiceAudioService.dispatchCue(cue, p.weaningStage)
                    }
                    _uiState.update {
                        it.copy(
                            player = it.player.copy(
                                elapsedStepSeconds = elapsed,
                                totalElapsedSeconds = elapsed,
                                japaStage = japa.currentStage,
                                japaInstruction = japa.stageInstruction,
                            ),
                        )
                    }
                    if (japa.currentStage == JapaStage.COMPLETE) {
                        finishPlayerIntoCheckin(p.primaryPracticeId, p.title, elapsed)
                        break
                    }
                } else if (dharana != null) {
                    val cue = dharana.tickSecond(elapsed)
                    if (cue != null) {
                        container.practiceAudioService.dispatchCue(cue, p.weaningStage)
                    }
                    _uiState.update {
                        it.copy(
                            player = it.player.copy(
                                elapsedStepSeconds = elapsed,
                                totalElapsedSeconds = elapsed,
                                dharanaPrompt = cue?.spokenText ?: it.player.dharanaPrompt,
                            ),
                        )
                    }
                    if (dharana.isComplete) {
                        finishPlayerIntoCheckin(p.primaryPracticeId, p.title, elapsed)
                        break
                    }
                }
            }
        }
    }

    private fun launchYogaNidraTicker() {
        tickerJob?.cancel()
        tickerJob = viewModelScope.launch(tickerDispatcher) {
            while (true) {
                delay(1_000L)
                val nidra = yogaNidraPlayer ?: break
                val p = _uiState.value.player
                if (!p.isActive || p.isCompleted) break
                val secs = nidra.elapsedSeconds()
                _uiState.update {
                    it.copy(
                        player = it.player.copy(
                            elapsedStepSeconds = secs,
                            totalElapsedSeconds = secs,
                            yogaNidraStage = nidra.currentStageName(),
                        ),
                    )
                }
                if (nidra.isCompleted) {
                    finishPlayerIntoCheckin(p.primaryPracticeId, p.title, secs)
                    break
                }
            }
        }
    }

    private fun computeStepFrame(
        pEngine: PlayerEngine,
        step: CycleStepItem,
        stepElapsedSeconds: Int,
    ): PracticePhaseFrame? {
        if (!step.isPranayamaWithPacer) return null
        val requested = step.ratio ?: _uiState.value.progression.ratio
        return pEngine.evaluateFrame(
            practiceId = step.id,
            stepElapsedSeconds = stepElapsedSeconds,
            requestedRatio = requested,
            strokesPerRound = step.strokes ?: _uiState.value.progression.kapalbhatiStrokes,
            totalRounds = step.rounds ?: 3,
        )
    }

    fun togglePlayerPause() {
        val cur = _uiState.value.player
        if (!cur.isActive) return
        val nowPaused = !cur.isPaused
        if (nowPaused) {
            cycleSequencer?.pause()
            playerEngine?.pauseTimer()
            yogaNidraPlayer?.pause()
            container.audioService.pauseTrack()
        } else {
            cycleSequencer?.resume()
            playerEngine?.resumeTimer()
            yogaNidraPlayer?.resume()
            container.audioService.resumeTrack()
        }
        _uiState.update {
            it.copy(
                player = it.player.copy(
                    isPaused = nowPaused,
                    isRunning = !nowPaused,
                ),
            )
        }
    }

    fun skipPlayerTransition() {
        val seq = cycleSequencer ?: return
        seq.skipTransition()
        val cue = guidanceEngine?.getCueForPhaseTransition(PracticePhase.PURAKA, 1)
        if (cue != null) container.practiceAudioService.dispatchCue(cue, _uiState.value.player.weaningStage)
        _uiState.update {
            it.copy(
                player = it.player.copy(
                    isTransitioning = false,
                    transitionSecondsLeft = 0,
                    subtitle = seq.currentStep.title,
                    currentStepIndex = seq.currentStepIndex,
                    elapsedStepSeconds = 0,
                    stepDurationSeconds = seq.currentStep.durationSeconds,
                ),
            )
        }
    }

    fun skipCurrentStep() {
        cycleSequencer?.skipStep()
    }

    fun cycleWeaningStageInPlayer() {
        val current = _uiState.value.player.weaningStage
        val next = if (current >= 5) 1 else current + 1
        val palette = _uiState.value.audioPreferences.soundPalette
        guidanceEngine = AudioGuidanceEngine(palette = palette, weaningStage = next)
        _uiState.update { it.copy(player = it.player.copy(weaningStage = next)) }
    }

    fun updatePreCalmness(score: Int) {
        _uiState.update { it.copy(player = it.player.copy(preCalmness = score.coerceIn(1, 10))) }
    }

    /**
     * Immediate comfortable stop returning to natural breath without waiting.
     */
    fun returnToNaturalBreathAndStop() {
        val naturalPhase = playerEngine?.returnToNaturalBreath() ?: PracticePhase.NATURAL_BREATH
        val groundingCue = guidanceEngine?.getEmergencyGroundingCue()
        if (groundingCue != null) {
            container.practiceAudioService.dispatchCue(groundingCue, 1)
        }
        val p = _uiState.value.player
        stopPlayerInternals()
        onStopForeground()
        _uiState.update {
            it.copy(
                player = p.copy(
                    isActive = false,
                    isRunning = false,
                    isCompleted = true,
                    isNaturalBreathReturn = true,
                    phaseFrame = p.phaseFrame?.copy(
                        phase = naturalPhase,
                        phaseTitle = "NATURAL BREATH",
                        cueText = "Relax shoulders · Breathe naturally at your own pace",
                    ),
                ),
                pendingCheckin = PendingCheckinSession(
                    practiceId = p.primaryPracticeId,
                    practiceName = p.title,
                    durationSeconds = p.totalElapsedSeconds.coerceAtLeast(60),
                    level = it.progression.level,
                    preCalmness = p.preCalmness,
                ),
            )
        }
    }

    fun finishSessionEarly() {
        val p = _uiState.value.player
        finishPlayerIntoCheckin(
            id = p.primaryPracticeId,
            name = p.title,
            durationSeconds = p.totalElapsedSeconds.coerceAtLeast(60),
        )
    }

    private fun finishPlayerIntoCheckin(id: String, name: String, durationSeconds: Int) {
        val p = _uiState.value.player
        stopPlayerInternals()
        onStopForeground()
        _uiState.update {
            it.copy(
                player = p.copy(
                    isActive = false,
                    isRunning = false,
                    isCompleted = true,
                ),
                pendingCheckin = PendingCheckinSession(
                    practiceId = id,
                    practiceName = name,
                    durationSeconds = durationSeconds,
                    level = it.progression.level,
                    preCalmness = p.preCalmness,
                ),
            )
        }
    }

    fun submitPostSessionCheckin(feeling: String, postCalmness: Int, note: String) {
        val pending = _uiState.value.pendingCheckin ?: return
        viewModelScope.launch {
            val today = LocalDate.now().toEpochDay()
            container.sessionRepository.logSession(
                session = SessionRecord(
                    practiceId = pending.practiceId,
                    practiceName = pending.practiceName,
                    level = pending.level,
                    durationSeconds = pending.durationSeconds,
                    timestampIso = Instant.now().toString(),
                    epochDay = today,
                    checkinRating = feeling,
                    holdDurations = pending.holdDurations,
                    preCalmnessScore = pending.preCalmness,
                    calmnessScore = postCalmness,
                    dizziness = feeling == "strained",
                    note = note.trim(),
                ),
                todayEpochDay = today,
            )
            _uiState.update {
                it.copy(
                    player = it.player.copy(preCalmness = 5),
                    pendingCheckin = null,
                    statusBanner = "Session saved · Calmness shift logged",
                )
            }
            refreshAll(today)
        }
    }

    fun dismissCheckin() {
        _uiState.update {
            it.copy(
                player = it.player.copy(preCalmness = 5),
                pendingCheckin = null,
            )
        }
    }

    // --- Settings & Preferences ---

    fun updateSoundPalette(palette: SoundPalette) {
        val updated = _uiState.value.audioPreferences.copy(soundPalette = palette)
        saveAudioPrefs(updated)
    }

    fun toggleVoiceGuidance() {
        val cur = _uiState.value.audioPreferences
        saveAudioPrefs(cur.copy(voiceEnabled = !cur.voiceEnabled))
    }

    fun toggleAudioTones() {
        val cur = _uiState.value.audioPreferences
        saveAudioPrefs(cur.copy(audioTonesEnabled = !cur.audioTonesEnabled))
    }

    fun toggleHaptics() {
        val cur = _uiState.value.audioPreferences
        saveAudioPrefs(cur.copy(hapticsEnabled = !cur.hapticsEnabled))
    }

    fun toggleTanpuraDrone() {
        val cur = _uiState.value.audioPreferences
        saveAudioPrefs(cur.copy(tanpuraDroneEnabled = !cur.tanpuraDroneEnabled))
    }

    private fun saveAudioPrefs(prefs: AudioPreferences) {
        syncAudioPreferencesToDrivers(prefs)
        viewModelScope.launch {
            container.userRepository.saveAudioPreferences(prefs)
            _uiState.update { it.copy(audioPreferences = prefs) }
        }
    }

    private fun syncAudioPreferencesToDrivers(prefs: AudioPreferences) {
        container.practiceAudioService.isVoiceEnabled = prefs.voiceEnabled
        container.practiceAudioService.isAudioTonesEnabled = prefs.audioTonesEnabled
        container.practiceAudioService.isHapticsEnabled = prefs.hapticsEnabled
        container.practiceAudioService.volume = prefs.masterVolume
        container.audioService.setVolume(prefs.masterVolume)
    }

    fun updateProfileSettings(displayName: String, tradition: String, matraSeconds: Double) {
        viewModelScope.launch {
            val updated = _uiState.value.profileSettings.copy(
                displayName = displayName.trim().ifEmpty { "Practitioner" },
                tradition = tradition.trim().ifEmpty { "Smarta" },
                matraSeconds = matraSeconds.coerceIn(0.8, 1.5),
            )
            container.userRepository.saveProfileSettings(updated)
            _uiState.update { it.copy(profileSettings = updated, statusBanner = "Sanctuary preferences saved") }
        }
    }

    fun saveReminderSettings(settings: ReminderSettings) {
        viewModelScope.launch {
            container.userRepository.saveReminderSettings(settings)
            _uiState.update {
                it.copy(
                    reminderSettings = settings,
                    scheduledReminders = ReminderScheduler.computeEnabledReminders(settings),
                    statusBanner = "Practice reminders updated",
                )
            }
        }
    }

    fun exportUserSnapshot() {
        viewModelScope.launch {
            val snapshot = container.userRepository.exportProfileSnapshotJson()
            _uiState.update { it.copy(exportedSnapshotJson = snapshot) }
        }
    }

    fun clearStatusBanner() {
        _uiState.update { it.copy(statusBanner = null, exportedSnapshotJson = null) }
    }

    private fun stopPlayerInternals() {
        tickerJob?.cancel()
        tickerJob = null
        cycleSequencer?.stop()
        cycleSequencer = null
        playerEngine?.stopTimer()
        playerEngine = null
        yogaNidraPlayer?.stop()
        yogaNidraPlayer = null
        japaEngine = null
        dharanaEngine = null
        container.practiceAudioService.stopAll()
        container.audioService.stopAll()
    }

    override fun onCleared() {
        stopPlayerInternals()
        onStopForeground()
        super.onCleared()
    }

    class Factory(
        private val context: Context,
        private val container: AbhyasContainer = AbhyasContainer(context.applicationContext),
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            val appCtx = context.applicationContext
            return AbhyasViewModel(
                container = container,
                onStartForeground = { runCatching { PracticePlaybackService.start(appCtx) } },
                onStopForeground = { runCatching { PracticePlaybackService.stop(appCtx) } },
            ) as T
        }
    }
}
