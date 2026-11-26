package com.pranaflow.abhyas.engine.safety

import kotlinx.serialization.Serializable

/**
 * Health screening & contraindication profile (FR-ON-02, SR-01..SR-04).
 * Stored securely on device and used by [SafetyRulesEngine] — never bypassed by UI.
 */
@Serializable
data class SafetyProfile(
    val pregnancy: Boolean = false,
    val hypertension: Boolean = false,
    val heartCondition: Boolean = false,
    val epilepsy: Boolean = false,
    val glaucoma: Boolean = false,
    val hernia: Boolean = false,
    val recentSurgery: Boolean = false,
    val asthmaOrRespiratory: Boolean = false,
    val panicOrAnxiety: Boolean = false,
    val menstruation: Boolean = false,
    val emptyStomachConfirmed: Boolean = false,
) {
    val hasGeneralHighRiskCondition: Boolean
        get() = pregnancy ||
            hypertension ||
            heartCondition ||
            epilepsy ||
            glaucoma ||
            hernia ||
            recentSurgery
}

enum class LockType {
    NONE,
    SAFETY_BLOCKED,
    MENSTRUATION_SUGGESTED_OFF,
    EMPTY_STOMACH_REQUIRED,
    LEVEL_LOCKED,
    TEACHER_APPROVAL_REQUIRED,
    GURU_ONLY,
    STRAIN_REVIEW_LOCK,
}

data class PracticeAccessResult(
    val allowed: Boolean,
    val lockType: LockType = LockType.NONE,
    val reason: String? = null,
    val recommendedLevel: Int? = null,
    val advisoryNote: String? = null,
)

/**
 * Practice access & cap evaluator.
 * Runs in open advisory mode by default (`openAccessMode = true`) so Sopana levels act as a
 * gentle progression guide and nothing stops anyone from practicing trainable pranayama/dhyan exercises,
 * while keeping Khechari non-trainable per scope rules and preserving hold/ratio invariants.
 */
object SafetyRulesEngine {

    val highRiskPractices: Set<String> = setOf(
        "kapalbhati",
        "kapalbhati_advanced",
        "bhastrika",
        "antar_kumbhaka",
        "antar_kumbhaka_short",
        "bahya_kumbhaka",
        "nadi_shodhana_full",
        "surya_bhedana",
        "uddiyana_kriya",
        "maha_bandha",
        "jalandhara",
        "mula",
        "bandhas",
    )

    val retentionPractices: Set<String> = setOf(
        "antar_kumbhaka",
        "antar_kumbhaka_short",
        "bahya_kumbhaka",
        "nadi_shodhana_full",
    )

    val menstruationRestrictedPractices: Set<String> = setOf(
        "kapalbhati",
        "kapalbhati_advanced",
        "uddiyana_kriya",
        "maha_bandha",
    )

    val emptyStomachPractices: Set<String> = setOf(
        "uddiyana_kriya",
        "maha_bandha",
    )

    /**
     * Checks practice accessibility. Defaults to [openAccessMode] = true so all trainable
     * meditation & pranayama exercises are open without blocking disclaimers or locks.
     */
    fun isPracticeAllowed(
        practice: String,
        profile: SafetyProfile,
        teacherCleared: Boolean = false,
        openAccessMode: Boolean = true,
    ): Boolean {
        val normalized = practice.trim().lowercase()

        if (normalized == "khechari") {
            // Khechari is information-only; never a trainable exercise
            return false
        }

        if (openAccessMode) {
            return true
        }

        if (normalized in highRiskPractices) {
            if (profile.pregnancy) {
                if (!teacherCleared) return false
            }
            if (profile.hypertension ||
                profile.heartCondition ||
                profile.epilepsy ||
                profile.glaucoma ||
                profile.hernia ||
                profile.recentSurgery
            ) {
                if (!teacherCleared) return false
            }
        }

        if (profile.menstruation && normalized in menstruationRestrictedPractices) {
            return false
        }

        if (normalized in emptyStomachPractices && !profile.emptyStomachConfirmed) {
            return false
        }

        return true
    }

    /**
     * Evaluates practice access & level guidance.
     * In default [openAccessMode] = true (with [teacherGatingEnabled] = false), levels serve purely as an
     * informational guide ([recommendedLevel] + [advisoryNote]) and never block access to trainable practices.
     */
    fun evaluatePracticeAccess(
        practice: String,
        profile: SafetyProfile = SafetyProfile(),
        userLevel: Int = 1,
        requiredLevel: Int = 1,
        teacherClearedPractices: Set<String> = emptySet(),
        approvedLevels: Set<Int> = (1..7).toSet(),
        teacherGatingEnabled: Boolean = false,
        recentStrainCount7Days: Int = 0,
        openAccessMode: Boolean = true,
    ): PracticeAccessResult {
        val normalized = practice.trim().lowercase()
        val teacherCleared = normalized in teacherClearedPractices

        if (normalized == "khechari") {
            return PracticeAccessResult(
                allowed = false,
                lockType = LockType.GURU_ONLY,
                reason = "Khechari Mudra is information-only and not a trainable app exercise.",
            )
        }

        if (openAccessMode) {
            val recommended = if (requiredLevel > userLevel) requiredLevel else null
            val note = when {
                recommended != null ->
                    "Guided for Sopana $recommended — feel free to explore gently at your own pace."
                normalized in emptyStomachPractices && !profile.emptyStomachConfirmed ->
                    "Traditionally practiced on a light or empty stomach."
                profile.menstruation && normalized in menstruationRestrictedPractices ->
                    "Keep intensity gentle or pause whenever comfort calls for rest."
                else -> null
            }
            return PracticeAccessResult(
                allowed = true,
                lockType = LockType.NONE,
                recommendedLevel = recommended,
                advisoryNote = note,
            )
        }

        // SR-02: Pregnancy restriction
        if (profile.pregnancy && normalized in highRiskPractices && !teacherCleared) {
            return PracticeAccessResult(
                allowed = false,
                lockType = LockType.SAFETY_BLOCKED,
                reason = "Paused during pregnancy unless explicitly cleared by your teacher and physician.",
            )
        }

        // SR-01: Medical contraindications
        if (profile.hasGeneralHighRiskCondition && normalized in highRiskPractices && !teacherCleared) {
            return PracticeAccessResult(
                allowed = false,
                lockType = LockType.SAFETY_BLOCKED,
                reason = "Locked for your health profile. Talk to your teacher or doctor before enabling.",
            )
        }

        // SR-03: Menstruation
        if (profile.menstruation && normalized in menstruationRestrictedPractices) {
            return PracticeAccessResult(
                allowed = false,
                lockType = LockType.MENSTRUATION_SUGGESTED_OFF,
                reason = "Suggested off during menstruation. Choose gentle practices like Nadi Shodhana without holds or Bhramari.",
            )
        }

        // SR-08: 2 strain/dizziness flags in 7 days lock retention until teacher review
        if (recentStrainCount7Days >= 2 && normalized in retentionPractices && !teacherCleared) {
            return PracticeAccessResult(
                allowed = false,
                lockType = LockType.STRAIN_REVIEW_LOCK,
                reason = "Retention paused after recent strain/dizziness check-ins until your teacher reviews.",
            )
        }

        // SR-04: Level 6+ and empty stomach required for Uddiyana & Maha Bandha
        if (normalized in emptyStomachPractices) {
            if (userLevel < 6) {
                return PracticeAccessResult(
                    allowed = false,
                    lockType = if (teacherGatingEnabled) LockType.TEACHER_APPROVAL_REQUIRED else LockType.LEVEL_LOCKED,
                    reason = "Available from Sopana 6 (Bahya) onward.",
                )
            }
            if (!profile.emptyStomachConfirmed) {
                return PracticeAccessResult(
                    allowed = false,
                    lockType = LockType.EMPTY_STOMACH_REQUIRED,
                    reason = "Confirm an empty stomach (3–4 hours after meals) before practicing Uddiyana or Maha Bandha.",
                )
            }
        }

        // SR-06: Level 3+ requires teacher approval when teacher gating is active
        if (teacherGatingEnabled && requiredLevel >= 3 && requiredLevel !in approvedLevels) {
            val lockType = if (requiredLevel >= 7) LockType.GURU_ONLY else LockType.TEACHER_APPROVAL_REQUIRED
            val reason = if (requiredLevel >= 7) {
                "Sopana 7 is direct Guru transmission only."
            } else {
                "Requires Guru Anumati (teacher approval) to unlock Sopana $requiredLevel."
            }
            return PracticeAccessResult(
                allowed = false,
                lockType = lockType,
                reason = reason,
            )
        }

        if (!teacherGatingEnabled && userLevel < requiredLevel && requiredLevel >= 7) {
            return PracticeAccessResult(
                allowed = false,
                lockType = LockType.GURU_ONLY,
                reason = "Sopana 7 requires direct Guru guidance.",
            )
        }

        return PracticeAccessResult(allowed = true)
    }

    /**
     * Enforces SR-05 (bahya <= antar) and SR-07 (hold <= min(levelCap, CHT * fraction))
     * on any ratio [puraka, antar, rechaka, bahya] in seconds.
     */
    fun clampRatioToSafeCaps(
        ratioSeconds: List<Int>,
        userChtSeconds: Int,
        holdCapFractionOfCht: Double,
        levelAntarCapSeconds: Int,
        levelBahyaCapSeconds: Int = levelAntarCapSeconds,
    ): List<Int> {
        val puraka = (ratioSeconds.getOrNull(0) ?: 4).coerceAtLeast(1)
        val requestedAntar = (ratioSeconds.getOrNull(1) ?: 0).coerceAtLeast(0)
        val rechaka = (ratioSeconds.getOrNull(2) ?: puraka).coerceAtLeast(1)
        val requestedBahya = (ratioSeconds.getOrNull(3) ?: 0).coerceAtLeast(0)

        val chtCap = (userChtSeconds.coerceAtLeast(0) * holdCapFractionOfCht.coerceIn(0.0, 1.0)).toInt()
        val safeAntarMax = minOf(levelAntarCapSeconds.coerceAtLeast(0), chtCap)
        val safeAntar = requestedAntar.coerceAtMost(safeAntarMax)

        // SR-05: Bahya never exceeds Antar in the same session, and honors hard cap + CHT cap
        val safeBahyaMax = minOf(safeAntar, levelBahyaCapSeconds.coerceAtLeast(0), chtCap)
        val safeBahya = requestedBahya.coerceAtMost(safeBahyaMax)

        return listOf(puraka, safeAntar, rechaka, safeBahya)
    }
}
