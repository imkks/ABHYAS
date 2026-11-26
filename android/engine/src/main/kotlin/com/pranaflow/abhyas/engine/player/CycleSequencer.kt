package com.pranaflow.abhyas.engine.player

import com.pranaflow.abhyas.engine.clock.MonotonicClock
import com.pranaflow.abhyas.engine.clock.SystemMonotonicClock
import kotlinx.serialization.Serializable

enum class RoutinePreset {
    SURYA,   // Morning Vitality
    CHANDRA, // Bedtime Restorative
    CUSTOM,  // Flexible Custom Sadhana
}

enum class RoutineIntensity {
    GENTLE,   // Level 1 gentle pacing
    ADAPTIVE, // Matched to active Sopana level
    INTENSE,  // Advanced (+1 level, capped at 7)
}

@Serializable
data class CycleStepItem(
    val id: String,
    val title: String,
    val subtitle: String,
    val durationSeconds: Int,
    val ratio: List<Int>? = null, // [puraka, antar, rechaka, bahya]
    val strokes: Int? = null,
    val rounds: Int? = null,
    val mudra: String? = null,
    val mantraId: String? = null,
    val breathAnchor: String? = null,
    val isRequired: Boolean = false,
    val isPranayamaWithPacer: Boolean = false,
    val isEnabled: Boolean = true,
)

@Serializable
data class CatalogExerciseTemplate(
    val id: String,
    val title: String,
    val category: String,
    val subtitle: String,
    val defaultMinutes: Int,
    val isPranayamaWithPacer: Boolean,
)

/**
 * Pure Kotlin routine composer catalog preserving all proven presets (Surya, Chandra, Custom, Master Sequence)
 * and individual customizer parameter sets.
 */
object RoutineCatalog {
    val availableDurationsMinutes: List<Int> = listOf(10, 15, 20, 25, 30, 45, 60)

    val catalog: List<CatalogExerciseTemplate> = listOf(
        // Pranayamas
        CatalogExerciseTemplate("nadi_shodhana", "Nadi Shodhana", "Pranayama", "Alternate nostril balance", 6, true),
        CatalogExerciseTemplate("kapalbhati", "Kapalbhati", "Pranayama", "Cleansing frontal brain", 4, true),
        CatalogExerciseTemplate("bhramari", "Bhramari", "Pranayama", "Humming bee calming breath", 4, true),
        CatalogExerciseTemplate("ujjayi", "Ujjayi", "Pranayama", "Ocean sound deep breathing", 4, true),
        CatalogExerciseTemplate("sheetali", "Sheetali", "Pranayama", "Cooling tongue breath", 3, true),
        CatalogExerciseTemplate("bhastrika", "Bhastrika", "Pranayama", "Bellows breath for prana energy", 4, true),
        CatalogExerciseTemplate("surya_bhedana", "Surya Bhedana", "Pranayama", "Right nostril heating breath", 4, true),
        // Dhyan
        CatalogExerciseTemplate("breath_awareness", "Breath Awareness Dhyan", "Dhyan", "Witnessing natural incoming/outgoing prana", 8, false),
        CatalogExerciseTemplate("antar_mouna", "Antar Mouna", "Dhyan", "Inner silence & observing thought ripples", 10, false),
        CatalogExerciseTemplate("trataka", "Trataka (Gazing)", "Dhyan", "Single-point concentration meditation", 5, false),
        // Mantra & Japa
        CatalogExerciseTemplate("naam_jaap", "3-Stage Naam Jaap", "Mantra & Japa", "Vaikhari -> Upamshu -> Manasika (Digital Mala)", 5, false),
        CatalogExerciseTemplate("om_chant", "Om Chanting", "Mantra & Japa", "Primordial sound vibration (A-U-M)", 3, false),
        CatalogExerciseTemplate("gayatri_mantra", "Gayatri Mantra", "Mantra & Japa", "Illumination of the intellect", 5, false),
        // Restorative
        CatalogExerciseTemplate("yoga_nidra", "Yoga Nidra", "Restorative", "Conscious deep psychic sleep & rejuvenation", 15, false),
        CatalogExerciseTemplate("savasana", "Savasana Integration", "Restorative", "Complete physical and mental surrender", 5, false),
        // Preparation
        CatalogExerciseTemplate("sankalp", "Sankalp & Invocation", "Preparation", "Awakening intention & guru prayer", 2, false),
        CatalogExerciseTemplate("warmup", "Sukshma Vyayama", "Preparation", "Joint loosening & spinal preparation", 3, false),
        CatalogExerciseTemplate("shanti_path", "Shanti Path", "Preparation", "Closing peace chant & stillness", 2, false),
    )

    fun effectiveLevel(userLevel: Int, intensity: RoutineIntensity): Int = when (intensity) {
        RoutineIntensity.GENTLE -> 1
        RoutineIntensity.ADAPTIVE -> userLevel.coerceIn(1, 7)
        RoutineIntensity.INTENSE -> (userLevel + 1).coerceIn(1, 7)
    }

    fun buildPresetSteps(
        preset: RoutinePreset,
        targetMinutes: Int,
        effectiveLevel: Int,
        levelRatio: List<Int>,
        kapalbhatiStrokes: Int,
    ): List<CycleStepItem> {
        val level = effectiveLevel.coerceIn(1, 7)
        if (preset == RoutinePreset.SURYA) {
            val (nadiSub, kapalSub) = when {
                level <= 1 -> "1:0:1:0 Natural Balance" to "30 strokes/round gentle cleanse"
                level == 2 -> "1:0:2:0 Extended Exhale (Calming)" to "45 strokes/round rhythmic"
                level == 3 -> "1:1:2:0 Antar Kumbhaka + Jalandhara" to "60 strokes/round channel cleanse"
                else -> "1:2:2:0 Deep Hold + Mula Bandha" to "80 strokes/round + Solar heat"
            }

            return when {
                targetMinutes <= 15 -> listOf(
                    CycleStepItem("sankalp", "Sankalp & Invocation", "Setting sacred intention", 2 * 60),
                    CycleStepItem("kapalbhati", "Phase 1: Kapalbhati", "3 Rounds + 10s Kumbhaka ($kapalSub)", 3 * 60, ratio = listOf(0, 0, 0, 10), strokes = kapalbhatiStrokes, rounds = 3, isPranayamaWithPacer = true),
                    CycleStepItem("nadi_shodhana", "Phase 2: Nadi Shodhana", "Vishnu Mudra · $nadiSub", 5 * 60, ratio = levelRatio, isPranayamaWithPacer = true),
                    CycleStepItem("breath_awareness", "Phase 4: Silent Nostril Dhyan", "Jnana Mudra · Ajna stillness", 5 * 60, breathAnchor = "nostrils"),
                )
                targetMinutes <= 25 -> listOf(
                    CycleStepItem("sankalp", "Sankalp & Invocation", "Setting intention", 2 * 60),
                    CycleStepItem("kapalbhati", "Phase 1: Kapalbhati", "3 Rounds + 10s Kumbhaka ($kapalSub)", 4 * 60, ratio = listOf(0, 0, 0, 10), strokes = kapalbhatiStrokes, rounds = 3, isPranayamaWithPacer = true),
                    CycleStepItem("nadi_shodhana", "Phase 2: Nadi Shodhana", "Vishnu Mudra · $nadiSub", 7 * 60, ratio = levelRatio, isPranayamaWithPacer = true),
                    CycleStepItem("ujjayi", "Phase 3: Ujjayi Breath", "Throat whisper ocean sound", 3 * 60, ratio = listOf(4, 0, 4, 0), isPranayamaWithPacer = true),
                    CycleStepItem("bhramari", "Phase 3: Bhramari", "Shanmukhi Mudra · Humming bee resonance", 3 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
                    CycleStepItem("breath_awareness", "Phase 4: Silent Nostril Dhyan", "Witnessing breath stillness", 6 * 60, breathAnchor = "nostrils"),
                )
                targetMinutes <= 35 -> listOf(
                    CycleStepItem("sankalp", "Sankalp & Invocation", "Setting intention & Om", 2 * 60),
                    CycleStepItem("warmup", "Sukshma Vyayama", "Gentle joint loosening", 2 * 60),
                    CycleStepItem("kapalbhati", "Phase 1: Kapalbhati", "3 Rounds + 10s Kumbhaka ($kapalSub)", 4 * 60, ratio = listOf(0, 0, 0, 10), strokes = kapalbhatiStrokes, rounds = 3, isPranayamaWithPacer = true),
                    CycleStepItem("nadi_shodhana", "Phase 2: Nadi Shodhana", "Vishnu Mudra · $nadiSub", 8 * 60, ratio = levelRatio, isPranayamaWithPacer = true),
                    CycleStepItem("ujjayi", "Phase 3: Ujjayi Ocean Breath", "Throat constriction wave", 3 * 60, ratio = listOf(4, 0, 4, 0), isPranayamaWithPacer = true),
                    CycleStepItem("bhramari", "Phase 3: Bhramari Pranayama", "Shanmukhi Mudra · Humming bee", 3 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
                    CycleStepItem("breath_awareness", "Phase 4: Silent Nostril Dhyan", "Ajna Chakra stillness", 6 * 60, breathAnchor = "nostrils"),
                    CycleStepItem("shanti_path", "Shanti Path", "Universal peace chant", 2 * 60),
                )
                else -> listOf(
                    CycleStepItem("sankalp", "Sankalp & Invocation", "Setting sacred intention", 3 * 60),
                    CycleStepItem("warmup", "Sukshma Vyayama", "Prana loosening", 4 * 60),
                    CycleStepItem("kapalbhati", "Phase 1: Kapalbhati", "3 Rounds + 10s Kumbhaka ($kapalSub)", 5 * 60, ratio = listOf(0, 0, 0, 10), strokes = kapalbhatiStrokes, rounds = 3, isPranayamaWithPacer = true),
                    CycleStepItem("nadi_shodhana", "Phase 2: Nadi Shodhana", "Vishnu Mudra · $nadiSub", 10 * 60, ratio = levelRatio, isPranayamaWithPacer = true),
                    CycleStepItem("bhastrika", "Bhastrika / Surya Bhedana", "Vital solar activation", 4 * 60, ratio = listOf(2, 0, 2, 0), isPranayamaWithPacer = true),
                    CycleStepItem("ujjayi", "Phase 3: Ujjayi Ocean Breath", "Throat resonance", 4 * 60, ratio = listOf(4, 0, 4, 0), isPranayamaWithPacer = true),
                    CycleStepItem("bhramari", "Phase 3: Bhramari", "Shanmukhi Mudra cranial vibration", 4 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
                    CycleStepItem("breath_awareness", "Phase 4: Silent Nostril Dhyan", "Deep meditative stillness", 9 * 60, breathAnchor = "nostrils"),
                    CycleStepItem("shanti_path", "Shanti Path", "Closing integration", 2 * 60),
                )
            }
        }

        if (preset == RoutinePreset.CHANDRA) {
            return when {
                targetMinutes <= 20 -> listOf(
                    CycleStepItem("naam_jaap", "3-Stage Naam Jaap", "Vaikhari -> Upamshu -> Manasika", 5 * 60, mantraId = "radha"),
                    CycleStepItem("bhramari", "Bhramari Pranayama", "Humming bee breath for calming", 5 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
                    CycleStepItem("yoga_nidra", "Yoga Nidra", "Conscious deep relaxation for sleep", 10 * 60),
                )
                targetMinutes <= 30 -> listOf(
                    CycleStepItem("naam_jaap", "3-Stage Naam Jaap", "Vaikhari -> Upamshu -> Manasika (108 beads)", 6 * 60, mantraId = "radha"),
                    CycleStepItem("sheetali", "Sheetali / Chandra Bhedana", "Cooling breath to calm body heat", 3 * 60, ratio = listOf(4, 0, 6, 0), isPranayamaWithPacer = true),
                    CycleStepItem("bhramari", "Bhramari Pranayama", "Humming bee breath to soothe nerves", 5 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
                    CycleStepItem("yoga_nidra", "Yoga Nidra", "Guided deep conscious sleep", 15 * 60),
                )
                else -> listOf(
                    CycleStepItem("naam_jaap", "3-Stage Naam Jaap", "Extended Japa recitation (Vaikhari -> Manasika)", 10 * 60, mantraId = "radha"),
                    CycleStepItem("sheetali", "Sheetali / Chandra Bhedana", "Cooling lunar breath", 5 * 60, ratio = listOf(4, 0, 6, 0), isPranayamaWithPacer = true),
                    CycleStepItem("bhramari", "Bhramari Pranayama", "Deep humming vibration", 5 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
                    CycleStepItem("yoga_nidra", "Yoga Nidra", "Full 20-min psychic sleep induction", 20 * 60),
                )
            }
        }

        // CUSTOM modular sequence blueprint
        return listOf(
            CycleStepItem("sankalp", "Sankalp & Invocation", "Intention setting", 2 * 60),
            CycleStepItem("kapalbhati", "Kapalbhati (Cleansing)", "3 Rounds + 10s Kumbhaka", 4 * 60, ratio = listOf(0, 0, 0, 10), strokes = kapalbhatiStrokes, rounds = 3, isPranayamaWithPacer = true),
            CycleStepItem("nadi_shodhana", "Nadi Shodhana", "Vishnu Mudra · Alternate nostril", 6 * 60, ratio = levelRatio, isPranayamaWithPacer = true),
            CycleStepItem("bhramari", "Bhramari", "Shanmukhi Mudra · Calming vibration", 3 * 60, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
            CycleStepItem("breath_awareness", "Silent Nostril Dhyan", "Silent meditation at nostril rims", 6 * 60, breathAnchor = "nostrils"),
        )
    }

    fun masterSequence(
        nadiShodhanaRatio: List<Int>,
        kapalbhatiStrokes: Int = 30,
    ): List<CycleStepItem> = listOf(
        CycleStepItem("sankalp", "Sankalp & Centering", "Upright posture, Chin Mudra, spine erect", 90),
        CycleStepItem("kapalbhati", "Phase 1: Kapalbhati", "3 Rounds of $kapalbhatiStrokes strokes + 10s Bahir Kumbhaka", 240, ratio = listOf(0, 0, 0, 10), strokes = kapalbhatiStrokes, rounds = 3, isPranayamaWithPacer = true),
        CycleStepItem("nadi_shodhana", "Phase 2: Nadi Shodhana", "Vishnu Mudra · Ratio ${nadiShodhanaRatio.joinToString(":")}", 420, ratio = nadiShodhanaRatio, isPranayamaWithPacer = true),
        CycleStepItem("ujjayi", "Phase 3: Ujjayi Ocean Breath", "5–10 deep throat constriction breaths", 150, ratio = listOf(4, 0, 4, 0), isPranayamaWithPacer = true),
        CycleStepItem("bhramari", "Phase 3: Bhramari Pranayama", "Shanmukhi Mudra · 5–7 humming bee breaths", 180, ratio = listOf(4, 0, 8, 0), mudra = "Shanmukhi Mudra", isPranayamaWithPacer = true),
        CycleStepItem("breath_awareness", "Phase 4: Silent Nostril Dhyan", "Jnana Mudra · Witnessing breath stillness at nostril rim", 240, breathAnchor = "nostrils"),
    )

    fun combinedMeditationFlow(mantraName: String = "Radha Radha"): List<CycleStepItem> = listOf(
        CycleStepItem("sankalp", "Centering & Asana", "Steady posture, hands in Chin Mudra", 60),
        CycleStepItem("naam_jaap", "Stage 1: 3-Stage Naam Japa ($mantraName)", "Vaikhari (loud) -> Upamshu (murmur) -> Manasika (silent mind)", 480),
        CycleStepItem("breath_awareness", "Stage 2: Silent Nostril Dhyan (Nasagra)", "Witnessing natural touch of air at nostril rims · Brow center stillness", 540, breathAnchor = "nostrils"),
    )
}

/**
 * Pure Kotlin state machine orchestrating sequential execution of a multi-step Sadhana cycle,
 * including 10-second posture/mudra transition gaps between steps and monotonic clock tracking.
 */
class CycleSequencer(
    steps: List<CycleStepItem>,
    val transitionDurationSeconds: Int = 10,
    private val clock: MonotonicClock = SystemMonotonicClock,
) {
    val steps: List<CycleStepItem> = steps.filter { it.isEnabled }

    init {
        require(this.steps.isNotEmpty()) { "CycleSequencer requires at least one enabled step." }
    }

    var currentStepIndex: Int = 0
        private set
    var secondsInCurrentStep: Int = 0
        private set
    var totalSecondsElapsed: Int = 0
        private set
    var isRunning: Boolean = false
        private set
    var isPaused: Boolean = false
        private set
    var isCompleted: Boolean = false
        private set
    var isTransitioning: Boolean = false
        private set
    var transitionRemainingSeconds: Int = 0
        private set
    var completedStepIndex: Int = -1
        private set

    private var stepStartElapsedMillis: Long = 0L
    private var accumulatedActiveMillis: Long = 0L
    private var activeSegmentStartMillis: Long? = null

    val currentStep: CycleStepItem
        get() = steps[currentStepIndex]

    val totalCycleDurationSeconds: Int
        get() = steps.sumOf { it.durationSeconds }

    val overallProgress: Double
        get() = if (totalCycleDurationSeconds > 0) {
            (totalSecondsElapsed.toDouble() / totalCycleDurationSeconds).coerceIn(0.0, 1.0)
        } else {
            0.0
        }

    val currentStepProgress: Double
        get() = if (currentStep.durationSeconds > 0) {
            (secondsInCurrentStep.toDouble() / currentStep.durationSeconds).coerceIn(0.0, 1.0)
        } else {
            0.0
        }

    private var onTick: ((stepIndex: Int, stepSeconds: Int, totalSeconds: Int) -> Unit)? = null
    private var onStepComplete: ((completedStepIndex: Int) -> Unit)? = null
    private var onTransitionStart: ((completedStep: CycleStepItem, nextStep: CycleStepItem) -> Unit)? = null
    private var onCycleComplete: (() -> Unit)? = null

    fun start(
        onTick: ((stepIndex: Int, stepSeconds: Int, totalSeconds: Int) -> Unit)? = null,
        onStepComplete: ((completedStepIndex: Int) -> Unit)? = null,
        onTransitionStart: ((completedStep: CycleStepItem, nextStep: CycleStepItem) -> Unit)? = null,
        onCycleComplete: (() -> Unit)? = null,
    ) {
        this.onTick = onTick
        this.onStepComplete = onStepComplete
        this.onTransitionStart = onTransitionStart
        this.onCycleComplete = onCycleComplete

        currentStepIndex = 0
        secondsInCurrentStep = 0
        totalSecondsElapsed = 0
        isPaused = false
        isCompleted = false
        isTransitioning = false
        transitionRemainingSeconds = 0
        completedStepIndex = -1
        accumulatedActiveMillis = 0L
        stepStartElapsedMillis = 0L
        activeSegmentStartMillis = clock.elapsedMillis()
        isRunning = true
    }

    /**
     * Advances the sequencer by 1 discrete second (called by platform coroutine loop or unit test).
     */
    fun tickSecond() {
        if (!isRunning || isPaused || isCompleted) return

        if (isTransitioning) {
            if (transitionRemainingSeconds > 1) {
                transitionRemainingSeconds--
            } else {
                skipTransition()
            }
            return
        }

        secondsInCurrentStep++
        totalSecondsElapsed++
        onTick?.invoke(currentStepIndex, secondsInCurrentStep, totalSecondsElapsed)

        if (secondsInCurrentStep >= currentStep.durationSeconds) {
            advanceAfterStepCompletion(useTransitionGap = transitionDurationSeconds > 0)
        }
    }

    private fun advanceAfterStepCompletion(useTransitionGap: Boolean) {
        val finishedIdx = currentStepIndex
        onStepComplete?.invoke(finishedIdx)

        if (finishedIdx + 1 < steps.size) {
            if (useTransitionGap) {
                completedStepIndex = finishedIdx
                isTransitioning = true
                transitionRemainingSeconds = transitionDurationSeconds
                onTransitionStart?.invoke(steps[finishedIdx], steps[finishedIdx + 1])
            } else {
                currentStepIndex++
                secondsInCurrentStep = 0
                onTick?.invoke(currentStepIndex, secondsInCurrentStep, totalSecondsElapsed)
            }
        } else {
            completeCycle()
        }
    }

    fun skipTransition() {
        if (!isTransitioning || isCompleted) return
        isTransitioning = false
        transitionRemainingSeconds = 0
        currentStepIndex = (completedStepIndex + 1).coerceAtMost(steps.lastIndex)
        secondsInCurrentStep = 0
        onTick?.invoke(currentStepIndex, secondsInCurrentStep, totalSecondsElapsed)
    }

    fun skipStep() {
        if (isCompleted) return
        if (isTransitioning) {
            skipTransition()
            return
        }
        advanceAfterStepCompletion(useTransitionGap = false)
    }

    fun pause() {
        if (!isRunning || isPaused) return
        activeSegmentStartMillis?.let {
            accumulatedActiveMillis += (clock.elapsedMillis() - it).coerceAtLeast(0L)
        }
        activeSegmentStartMillis = null
        isRunning = false
        isPaused = true
    }

    fun resume() {
        if (isCompleted || !isPaused) return
        activeSegmentStartMillis = clock.elapsedMillis()
        isRunning = true
        isPaused = false
    }

    fun stop() {
        activeSegmentStartMillis?.let {
            accumulatedActiveMillis += (clock.elapsedMillis() - it).coerceAtLeast(0L)
        }
        activeSegmentStartMillis = null
        isRunning = false
        isTransitioning = false
    }

    private fun completeCycle() {
        stop()
        isCompleted = true
        onCycleComplete?.invoke()
    }

    fun activeElapsedMillis(): Long {
        val running = activeSegmentStartMillis?.let { (clock.elapsedMillis() - it).coerceAtLeast(0L) } ?: 0L
        return accumulatedActiveMillis + running
    }

    companion object {
        fun getMudraAndPrepGuidance(step: CycleStepItem): String {
            val id = step.id.lowercase()
            val title = step.title.lowercase()
            return when {
                id.contains("nadi") || title.contains("nadi") || title.contains("alternate") ->
                    "Return to natural breath · Rest left hand in Chin Mudra · Raise right hand into Vishnu Mudra (Nasagra)"
                id.contains("kapal") || title.contains("kapal") ->
                    "Sit upright with spine erect · Rest hands in Chin Mudra on knees · Relax abdominal wall"
                id.contains("bhramari") || title.contains("bhramari") ->
                    "Relax facial muscles · Prepare Shanmukhi Mudra or gently place thumbs on the ear tragi"
                id.contains("ujjayi") || title.contains("ujjayi") ->
                    "Sit comfortably upright · Relax throat and jaw · Rest hands in Jnana Mudra"
                id.contains("bhastrika") || title.contains("bhastrika") ->
                    "Straighten spine · Hands on knees in Chin Mudra · Prepare for active bellows respiration"
                id.contains("sheetali") || title.contains("sheetali") || id.contains("sheetkari") || title.contains("sheetkari") ->
                    "Roll tongue into a tube or gently clench teeth · Rest hands in Jnana Mudra on knees"
                id.contains("naam") || id.contains("japa") || id.contains("jaap") || title.contains("naam") || title.contains("japa") || title.contains("jaap") ->
                    "Close eyes softly · Hands in Dhyana Mudra · Prepare for 3-Stage sacred sound immersion"
                id.contains("breath_awareness") || id.contains("dhyan") || id.contains("nostril") || title.contains("dhyan") || title.contains("awareness") ->
                    "Keep eyes gently closed · Settle awareness at nostril rims · Witness natural incoming & outgoing breath"
                id.contains("nidra") || id.contains("savasana") || title.contains("nidra") || title.contains("savasana") ->
                    "Lie flat on back in Savasana · Arms by sides, palms facing up · Surrender bodily weight to the earth"
                step.subtitle.isNotBlank() ->
                    "Return to natural breath · ${step.subtitle}"
                else ->
                    "Take 2 natural calming breaths · Adjust your posture and mudra for the upcoming practice"
            }
        }
    }
}
