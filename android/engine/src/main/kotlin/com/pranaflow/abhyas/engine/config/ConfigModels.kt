package com.pranaflow.abhyas.engine.config

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Strongly typed domain models deserializing configuration from [SeedConfig] or remote JSON (SRS Section 8).
 * All practice ratios, ladders, caps, gates, and weaning rules live in versioned configuration.
 */
@Serializable
data class PracticeConfig(
    @SerialName("config_version") val configVersion: String = "0.1.0",
    @SerialName("matra_default_seconds") val matraDefaultSeconds: Double = 1.0,
    @SerialName("hold_cap_fraction_of_cht") val holdCapFractionOfCht: Double = 0.6,
    @SerialName("comfort_streak_required_for_step") val comfortStreakRequiredForStep: Int = 5,
    @SerialName("vishrama_days_per_week") val vishramaDaysPerWeek: Int = 1,
    val levels: List<SopanaLevel> = emptyList(),
    val weaning: WeaningConfig? = null,
) {
    fun getLevel(levelId: Int): SopanaLevel? = levels.firstOrNull { it.id == levelId }
}

@Serializable
data class SopanaLevel(
    val id: Int,
    val name: String,
    val gate: String = "self", // self | streak | teacher | guru_only
    val practices: List<String> = emptyList(),
    @SerialName("ratio_ladder") val ratioLadder: List<List<Int>> = emptyList(),
    @SerialName("base_count") val baseCount: Int = 4,
    val kapalbhati: KapalbhatiConfig? = null,
    @SerialName("bahya_start_seconds") val bahyaStartSeconds: Int? = null,
    @SerialName("bahya_never_exceeds_antar") val bahyaNeverExceedsAntar: Boolean = true,
    @SerialName("ratio_cap_default") val ratioCapDefault: List<Int>? = null,
    val mudras: List<String> = emptyList(),
    val bandhas: List<String> = emptyList(),
    val pariksha: ParikshaConfig = ParikshaConfig(),
) {
    val requiresTeacherApproval: Boolean
        get() = gate == "teacher" || gate == "guru_only"

    /**
     * Effective maximum antar hold seconds defined by the level's cap or highest ladder step.
     */
    fun levelAntarCapSeconds(matraSeconds: Double = 1.0): Int {
        val explicitCap = ratioCapDefault?.getOrNull(1)
        val ladderMax = ratioLadder.maxOfOrNull { it.getOrNull(1) ?: 0 } ?: 0
        val countUnits = explicitCap ?: ladderMax
        return (countUnits * baseCount * matraSeconds).toInt().coerceAtLeast(0)
    }

    /**
     * Effective maximum bahya hold seconds defined by the level's cap or highest ladder step.
     */
    fun levelBahyaCapSeconds(matraSeconds: Double = 1.0): Int {
        val explicitCap = ratioCapDefault?.getOrNull(3)
        val ladderMax = ratioLadder.maxOfOrNull { it.getOrNull(3) ?: 0 } ?: 0
        val countUnits = explicitCap ?: ladderMax
        return (countUnits * baseCount * matraSeconds).toInt().coerceAtLeast(0)
    }
}

@Serializable
data class KapalbhatiConfig(
    @SerialName("strokes_per_min") val strokesPerMin: Int = 60,
    @SerialName("strokes_per_round_ladder") val strokesPerRoundLadder: List<Int> = listOf(30, 45, 60),
    val rounds: Int = 3,
)

@Serializable
data class ParikshaConfig(
    @SerialName("min_sessions") val minSessions: Int? = null,
    @SerialName("consecutive_days_window") val consecutiveDaysWindow: Int? = null,
    @SerialName("cht_required") val chtRequired: Boolean = false,
    @SerialName("teacher_signoff") val teacherSignoff: Boolean = false,
    @SerialName("teacher_observes_early_sessions") val teacherObservesEarlySessions: Boolean = false,
    @SerialName("live_or_video_review") val liveOrVideoReview: Boolean = false,
    @SerialName("guru_only") val guruOnly: Boolean = false,
) {
    val summaryDescription: String
        get() {
            val requirements = buildList {
                minSessions?.let { add("$it completed sessions") }
                consecutiveDaysWindow?.let { add("within $it days streak") }
                if (chtRequired) add("CHT benchmark assessment")
                if (teacherSignoff) add("Guru Anumati teacher sign-off")
                if (teacherObservesEarlySessions) add("Teacher observes early sessions")
                if (liveOrVideoReview) add("Live / video form review")
                if (guruOnly) add("Direct Guru transmission only")
            }
            return if (requirements.isEmpty()) "Self-evaluated readiness" else requirements.joinToString(" · ")
        }
}

@Serializable
data class WeaningConfig(
    @SerialName("stage_min_weeks") val stageMinWeeks: List<Int> = listOf(3, 3, 3, 3, 0),
    @SerialName("stage_min_consecutive_sessions") val stageMinConsecutiveSessions: List<Int> = listOf(10, 10, 10, 10, 0),
    @SerialName("graduation_consecutive_sessions") val graduationConsecutiveSessions: Int = 3,
)
