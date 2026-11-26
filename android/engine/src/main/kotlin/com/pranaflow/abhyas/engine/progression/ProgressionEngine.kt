package com.pranaflow.abhyas.engine.progression

import com.pranaflow.abhyas.engine.config.PracticeConfig
import com.pranaflow.abhyas.engine.config.SeedConfig
import kotlinx.serialization.Serializable
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Minimal pure-JVM session summary used by [ProgressionEngine] to compute Sopanas, Tapas,
 * Mala milestones, ratio ladder steps, auto-regression, Vishrama grace days, and weaning.
 */
@Serializable
data class SessionSummary(
    val practiceName: String,
    val level: Int,
    val durationSeconds: Int,
    val epochDay: Long,
    val checkinRating: String, // calm | neutral | agitated | strained
    val dizziness: Boolean = false,
    val preCalmnessScore: Int? = null,
    val calmnessScore: Int? = null,
    val isVishrama: Boolean = false,
) {
    val calmnessDelta: Int
        get() = if (calmnessScore != null && preCalmnessScore != null) calmnessScore - preCalmnessScore else 0

    val hasStrainFlag: Boolean
        get() = dizziness || checkinRating.equals("strained", ignoreCase = true)
}

data class SopanaRankInfo(
    val level: Int,
    val title: String,
    val subtitle: String,
    val minTapas: Int,
    val nextLevelTapas: Int,
    val ratioDescription: String,
    val ratio: List<Int>,
    val kapalbhatiStrokes: Int,
    val unlockedSeals: List<String>,
    val featureHighlight: String,
    val journeyPhase: String,
    val phaseName: String,
)

data class MalaProgress(
    val totalCompletedPractices: Int,
    val currentBeadInMala: Int,
    val completedMalas: Int,
)

data class RatioProgressionDecision(
    val currentStepIndex: Int,
    val nextStepIndex: Int,
    val shouldAutoRegress: Boolean,
    val lockRetentionForTeacherReview: Boolean,
    val notifyTeacher: Boolean,
    val reason: String,
)

data class WeaningProgress(
    val stage: Int,
    val stageName: String,
    val consecutiveCalmSessionsInStage: Int,
    val requiredSessionsForNext: Int,
    val canAdvanceStage: Boolean,
    val isSwatantraGraduated: Boolean,
)

data class SelfCheckEvaluation(
    val targetHoldSeconds: Int,
    val recordedHoldsSeconds: List<Int>,
    val averageHoldSeconds: Double,
    val steadinessMessage: String,
)

data class UserProgression(
    val level: Int,
    val title: String,
    val totalTapas: Int,
    val currentLevelTapas: Int,
    val tapasNeededForNextLevel: Int,
    val progressPercent: Double,
    val dailyStreak: Int,
    val vishramaDaysUsedThisWeek: Int,
    val vishramaDaysAllowance: Int,
    val earnedSeals: List<String>,
    val ratioDescription: String,
    val ratio: List<Int>,
    val kapalbhatiStrokes: Int,
    val featureHighlight: String,
    val journeyPhase: String,
    val phaseName: String,
    val malaProgress: MalaProgress,
    val weaningProgress: WeaningProgress,
)

/**
 * Pure Kotlin progression & calm gamification engine (FR-GM-01..09, FR-WN-01..05, SR-08).
 * Strictly non-competitive: tracks personal Sopana mastery, Tapas XP, Mala beads, Seals,
 * Calmness Shift, Vishrama grace days, ratio ladder steps, and auto-regression.
 */
object ProgressionEngine {

    val ranks: List<SopanaRankInfo> = listOf(
        SopanaRankInfo(
            level = 1,
            title = "Prarambha (Seeker)",
            subtitle = "Foundational Breath & Centering",
            minTapas = 0,
            nextLevelTapas = 300,
            ratioDescription = "1:0:1:0 (Natural Rhythm)",
            ratio = listOf(4, 0, 4, 0),
            kapalbhatiStrokes = 30,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra"),
            featureHighlight = "Gentle 4s In : 4s Out breath pacer",
            journeyPhase = "Phase 1: Foundation (Weeks 1–4)",
            phaseName = "Foundation",
        ),
        SopanaRankInfo(
            level = 2,
            title = "Abhyasi (Dedicated)",
            subtitle = "Extended Exhalation & Calming",
            minTapas = 300,
            nextLevelTapas = 750,
            ratioDescription = "1:0:2:0 (Extended Exhale)",
            ratio = listOf(4, 0, 8, 0),
            kapalbhatiStrokes = 45,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra", "Dhyana Mudra"),
            featureHighlight = "1:0:2:0 Parasympathetic deep relaxation",
            journeyPhase = "Phase 1: Foundation (Weeks 1–4)",
            phaseName = "Foundation",
        ),
        SopanaRankInfo(
            level = 3,
            title = "Antaranga (Inward Journeyer)",
            subtitle = "Internal Retention & Throat Lock",
            minTapas = 750,
            nextLevelTapas = 1500,
            ratioDescription = "1:1:2:0 (Antar Kumbhaka)",
            ratio = listOf(4, 4, 8, 0),
            kapalbhatiStrokes = 60,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra", "Dhyana Mudra", "Nasika Mudra", "Jalandhara Bandha"),
            featureHighlight = "Internal breath hold + Jalandhara Bandha cue",
            journeyPhase = "Phase 2: Deepening (Weeks 5–12)",
            phaseName = "Deepening",
        ),
        SopanaRankInfo(
            level = 4,
            title = "Shaktiman (Vital Force)",
            subtitle = "Bellows Breath & Root Energy",
            minTapas = 1500,
            nextLevelTapas = 2500,
            ratioDescription = "1:2:2:0 (Vital Energy)",
            ratio = listOf(4, 8, 8, 0),
            kapalbhatiStrokes = 80,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra", "Dhyana Mudra", "Nasika Mudra", "Jalandhara Bandha", "Shanmukhi Mudra", "Mula Bandha"),
            featureHighlight = "Bhastrika (Bellows breath) & Mula Bandha",
            journeyPhase = "Phase 2: Deepening (Weeks 5–12)",
            phaseName = "Deepening",
        ),
        SopanaRankInfo(
            level = 5,
            title = "Kumbhaka Siddha (Breath Master)",
            subtitle = "Classical 1:4:2:0 Ratio Mastery",
            minTapas = 2500,
            nextLevelTapas = 4000,
            ratioDescription = "1:4:2:0 (Classical Kumbhaka)",
            ratio = listOf(4, 16, 8, 0),
            kapalbhatiStrokes = 100,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra", "Dhyana Mudra", "Nasika Mudra", "Jalandhara Bandha", "Shanmukhi Mudra", "Mula Bandha", "Prana Mudra"),
            featureHighlight = "Deep classical 1:4:2:0 retention ladder",
            journeyPhase = "Phase 3: Advanced (Month 4+)",
            phaseName = "Advanced",
        ),
        SopanaRankInfo(
            level = 6,
            title = "Bandha Yogi (Energy Master)",
            subtitle = "External Retention & The Great Lock",
            minTapas = 4000,
            nextLevelTapas = 6000,
            ratioDescription = "1:4:2:2 (Bahya Retention)",
            ratio = listOf(4, 16, 8, 8),
            kapalbhatiStrokes = 120,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra", "Dhyana Mudra", "Nasika Mudra", "Jalandhara Bandha", "Shanmukhi Mudra", "Mula Bandha", "Uddiyana Bandha", "Maha Bandha"),
            featureHighlight = "Bahya Kumbhaka + Maha Bandha (Tri-lock)",
            journeyPhase = "Phase 3: Advanced (Month 4+)",
            phaseName = "Advanced",
        ),
        SopanaRankInfo(
            level = 7,
            title = "Dhyani (Absorbed Master)",
            subtitle = "Transcendent Stillness & Ajapa Japa",
            minTapas = 6000,
            nextLevelTapas = 10000,
            ratioDescription = "Samadhi Dhyana Pacing",
            ratio = listOf(6, 24, 12, 0),
            kapalbhatiStrokes = 120,
            unlockedSeals = listOf("Gyan Mudra", "Chin Mudra", "Dhyana Mudra", "Nasika Mudra", "Jalandhara Bandha", "Shanmukhi Mudra", "Mula Bandha", "Uddiyana Bandha", "Maha Bandha", "Shambhavi Mudra"),
            featureHighlight = "Shambhavi Mudra & Silent Ajapa Japa",
            journeyPhase = "Phase 3: Advanced (Month 4+)",
            phaseName = "Advanced",
        ),
    )

    fun getLevelInfo(level: Int): SopanaRankInfo =
        ranks.firstOrNull { it.level == level } ?: ranks.first()

    fun calculateLevelFromCht(chtSeconds: Double): Int = when {
        chtSeconds < 15.0 -> 1
        chtSeconds < 25.0 -> 2
        chtSeconds < 40.0 -> 3
        chtSeconds < 60.0 -> 4
        else -> 5
    }

    /**
     * Computes consistency streak allowing up to [vishramaAllowancePerWeek] rest days per 7-day rolling block
     * without breaking progress (FR-GM-05). Never emits streak-loss warnings.
     */
    fun computeDailyStreakWithVishrama(
        practicedEpochDays: Set<Long>,
        vishramaEpochDays: Set<Long>,
        todayEpochDay: Long,
        vishramaAllowancePerWeek: Int = 1,
    ): Int {
        val activeDays = practicedEpochDays + vishramaEpochDays
        if (activeDays.isEmpty()) return 0

        val startDay = when {
            todayEpochDay in activeDays -> todayEpochDay
            (todayEpochDay - 1) in activeDays -> todayEpochDay - 1
            else -> return 0
        }

        val earliestActiveDay = activeDays.min()
        var streak = 0
        var graceLeftInWindow = vishramaAllowancePerWeek.coerceAtLeast(0)
        var cursor = startDay
        var daysCheckedInWeek = 0

        while (cursor >= earliestActiveDay) {
            if (cursor in practicedEpochDays) {
                streak++
            } else if (cursor in vishramaEpochDays || graceLeftInWindow > 0) {
                if (graceLeftInWindow > 0 && cursor !in practicedEpochDays) {
                    graceLeftInWindow--
                }
                streak++
            } else {
                break
            }
            cursor--
            daysCheckedInWeek++
            if (daysCheckedInWeek == 7) {
                daysCheckedInWeek = 0
                graceLeftInWindow = vishramaAllowancePerWeek.coerceAtLeast(0)
            }
        }
        return streak
    }

    /**
     * Evaluates whether a student's ratio ladder advances, holds, or gently steps back on strain (FR-GM-08, FR-GM-09).
     */
    fun evaluateRatioLadder(
        currentStepIndex: Int,
        maxStepIndex: Int,
        recentSessionsChronological: List<SessionSummary>,
        todayEpochDay: Long,
        comfortStreakRequiredForStep: Int = 5,
        teacherGatingEnabled: Boolean = false,
    ): RatioProgressionDecision {
        val latest = recentSessionsChronological.lastOrNull()
        val strainCount7Days = recentSessionsChronological.count {
            it.hasStrainFlag && (todayEpochDay - it.epochDay) in 0..6
        }

        if (latest != null && latest.hasStrainFlag) {
            val regressed = (currentStepIndex - 1).coerceAtLeast(0)
            return RatioProgressionDecision(
                currentStepIndex = currentStepIndex,
                nextStepIndex = regressed,
                shouldAutoRegress = true,
                lockRetentionForTeacherReview = teacherGatingEnabled && strainCount7Days >= 2,
                notifyTeacher = teacherGatingEnabled,
                reason = if (teacherGatingEnabled && strainCount7Days >= 2) {
                    "Multiple strain/dizziness flags within 7 days. Retention paused until teacher review."
                } else {
                    "We'll go gently next time — ratio stepped back by one comfort step."
                },
            )
        }

        var consecutiveCalm = 0
        for (s in recentSessionsChronological.asReversed()) {
            if (s.checkinRating.equals("calm", ignoreCase = true) && !s.dizziness) {
                consecutiveCalm++
            } else {
                break
            }
        }

        val canAdvance = consecutiveCalm >= comfortStreakRequiredForStep && currentStepIndex < maxStepIndex
        return RatioProgressionDecision(
            currentStepIndex = currentStepIndex,
            nextStepIndex = if (canAdvance) currentStepIndex + 1 else currentStepIndex,
            shouldAutoRegress = false,
            lockRetentionForTeacherReview = strainCount7Days >= 2,
            notifyTeacher = false,
            reason = if (canAdvance) {
                "Steady comfort across $consecutiveCalm sessions — ready for the next ratio step."
            } else {
                "Maintaining current ratio ($consecutiveCalm / $comfortStreakRequiredForStep comfortable sessions)."
            },
        )
    }

    /**
     * Computes weaning progress (FR-WN-01..05) from consecutive calm sessions and config thresholds.
     */
    fun evaluateWeaningProgress(
        sessionsChronological: List<SessionSummary>,
        config: PracticeConfig = SeedConfig.defaultConfig,
        manualStageOverride: Int? = null,
    ): WeaningProgress {
        var comfortStreak = 0
        for (s in sessionsChronological.asReversed()) {
            if (s.checkinRating.equals("calm", ignoreCase = true) && !s.dizziness) {
                comfortStreak++
            } else {
                break
            }
        }

        val minSessionsList = config.weaning?.stageMinConsecutiveSessions ?: listOf(10, 10, 10, 10, 0)
        val stagePerStep = (minSessionsList.firstOrNull() ?: 10).coerceAtLeast(1)
        val calculatedStage = (1 + (comfortStreak / stagePerStep)).coerceIn(1, 5)
        val effectiveStage = manualStageOverride?.coerceIn(1, calculatedStage) ?: calculatedStage
        val inStageCount = if (effectiveStage < 5) comfortStreak % stagePerStep else stagePerStep
        val gradReq = config.weaning?.graduationConsecutiveSessions ?: 3

        val stageNames = listOf("Guided", "Cued", "Silent Timer", "Self-led", "Independent")

        return WeaningProgress(
            stage = effectiveStage,
            stageName = stageNames[(effectiveStage - 1).coerceIn(0, 4)],
            consecutiveCalmSessionsInStage = inStageCount,
            requiredSessionsForNext = if (effectiveStage < 5) stagePerStep else gradReq,
            canAdvanceStage = effectiveStage < 5 && inStageCount >= stagePerStep,
            isSwatantraGraduated = effectiveStage >= 4 && comfortStreak >= ((effectiveStage - 1) * stagePerStep + gradReq),
        )
    }

    fun evaluateSelfCheck(
        targetHoldSeconds: Int,
        recordedHoldsSeconds: List<Int>,
    ): SelfCheckEvaluation {
        val avg = if (recordedHoldsSeconds.isEmpty()) 0.0 else recordedHoldsSeconds.average()
        val diff = abs(avg - targetHoldSeconds)
        val feedback = when {
            recordedHoldsSeconds.isEmpty() -> "No holds recorded yet."
            diff < 2.0 -> "Steady internal rhythm!"
            avg < targetHoldSeconds -> "You released gently before target. Stay comfortable without strain."
            else -> "Your hold ran longer than target — calibrate rhythm to stay within cap."
        }
        return SelfCheckEvaluation(
            targetHoldSeconds = targetHoldSeconds,
            recordedHoldsSeconds = recordedHoldsSeconds,
            averageHoldSeconds = avg,
            steadinessMessage = feedback,
        )
    }

    fun computeProgression(
        sessions: List<SessionSummary>,
        todayEpochDay: Long,
        bonusTapas: Int = 0,
        calibratedLevel: Int? = null,
        approvedLevels: Set<Int> = (1..7).toSet(),
        teacherGatingEnabled: Boolean = false,
        config: PracticeConfig = SeedConfig.defaultConfig,
        manualWeaningStage: Int? = null,
    ): UserProgression {
        val practicedDays = sessions.filter { !it.isVishrama }.map { it.epochDay }.toSet()
        val vishramaDays = sessions.filter { it.isVishrama }.map { it.epochDay }.toSet()
        val streak = computeDailyStreakWithVishrama(
            practicedEpochDays = practicedDays,
            vishramaEpochDays = vishramaDays,
            todayEpochDay = todayEpochDay,
            vishramaAllowancePerWeek = config.vishramaDaysPerWeek,
        )

        var sessionTapas = 0
        for (s in sessions.filter { !it.isVishrama }) {
            val mins = (s.durationSeconds / 60.0).roundToInt()
            sessionTapas += (mins * 10).coerceIn(10, 600)
            if (s.checkinRating.equals("calm", ignoreCase = true) && !s.dizziness) {
                sessionTapas += 15
            }
        }
        val totalTapas = sessionTapas + (streak * 50) + bonusTapas

        var currentLevelInfo = ranks.first()
        for (rank in ranks.asReversed()) {
            if (totalTapas >= rank.minTapas) {
                currentLevelInfo = rank
                break
            }
        }

        if (calibratedLevel != null && calibratedLevel > currentLevelInfo.level) {
            currentLevelInfo = getLevelInfo(calibratedLevel)
        }

        // SR-06: Enforce teacher approval gate for Level 3+ if teacherGatingEnabled is active
        if (teacherGatingEnabled && currentLevelInfo.level >= 3) {
            var highestApproved = 2
            for (lvl in 3..currentLevelInfo.level) {
                if (lvl in approvedLevels) {
                    highestApproved = lvl
                } else {
                    break
                }
            }
            if (highestApproved < currentLevelInfo.level) {
                currentLevelInfo = getLevelInfo(highestApproved)
            }
        }

        val rangeStart = currentLevelInfo.minTapas
        val rangeEnd = currentLevelInfo.nextLevelTapas
        val inLevelXp = (totalTapas - rangeStart).coerceAtLeast(0)
        val neededForNext = (rangeEnd - rangeStart).coerceAtLeast(1)
        val percent = (inLevelXp.toDouble() / neededForNext).coerceIn(0.0, 1.0)

        val completedPracticeCount = sessions.count { !it.isVishrama }
        val vishramaUsedWeek = vishramaDays.count { (todayEpochDay - it) in 0..6 }

        return UserProgression(
            level = currentLevelInfo.level,
            title = currentLevelInfo.title,
            totalTapas = totalTapas,
            currentLevelTapas = inLevelXp,
            tapasNeededForNextLevel = neededForNext,
            progressPercent = percent,
            dailyStreak = streak,
            vishramaDaysUsedThisWeek = vishramaUsedWeek,
            vishramaDaysAllowance = config.vishramaDaysPerWeek,
            earnedSeals = currentLevelInfo.unlockedSeals,
            ratioDescription = currentLevelInfo.ratioDescription,
            ratio = currentLevelInfo.ratio,
            kapalbhatiStrokes = currentLevelInfo.kapalbhatiStrokes,
            featureHighlight = currentLevelInfo.featureHighlight,
            journeyPhase = currentLevelInfo.journeyPhase,
            phaseName = currentLevelInfo.phaseName,
            malaProgress = MalaProgress(
                totalCompletedPractices = completedPracticeCount,
                currentBeadInMala = completedPracticeCount % 108,
                completedMalas = completedPracticeCount / 108,
            ),
            weaningProgress = evaluateWeaningProgress(
                sessionsChronological = sessions,
                config = config,
                manualStageOverride = manualWeaningStage,
            ),
        )
    }
}
