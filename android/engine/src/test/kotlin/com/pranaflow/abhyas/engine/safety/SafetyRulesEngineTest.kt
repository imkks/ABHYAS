package com.pranaflow.abhyas.engine.safety

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SafetyRulesEngineTest {

    private val gatedPractices = listOf(
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

    private val gentleSafePractices = listOf(
        "breath_awareness",
        "nadi_shodhana_basic",
        "om_chant",
        "bhramari",
        "ujjayi",
        "sheetali",
        "sheetkari",
    )

    @Test
    fun `default open advisory mode allows all trainable pranayama and dhyan exercises without blocking`() {
        val sampleProfiles = listOf(
            SafetyProfile(),
            SafetyProfile(pregnancy = true, hypertension = true, emptyStomachConfirmed = false),
            SafetyProfile(menstruation = true),
        )

        for (profile in sampleProfiles) {
            for (practice in gatedPractices + gentleSafePractices) {
                assertTrue(
                    "Default open mode should allow $practice",
                    SafetyRulesEngine.isPracticeAllowed(practice, profile),
                )
                val eval = SafetyRulesEngine.evaluatePracticeAccess(
                    practice = practice,
                    profile = profile,
                    userLevel = 1,
                    requiredLevel = 6,
                    recentStrainCount7Days = 3,
                )
                assertTrue("evaluatePracticeAccess should allow $practice", eval.allowed)
                assertEquals(LockType.NONE, eval.lockType)
                assertEquals(6, eval.recommendedLevel)
                assertTrue(eval.advisoryNote?.contains("Sopana 6") == true)
            }
            // Khechari remains out-of-scope (information-only)
            assertFalse(SafetyRulesEngine.isPracticeAllowed("khechari", profile))
            assertEquals(LockType.GURU_ONLY, SafetyRulesEngine.evaluatePracticeAccess("khechari", profile).lockType)
        }
    }

    @Test
    fun `optional strict mode matrix still supports teacher-gated pilot profiles when opted in`() {
        val flaggedProfiles = listOf(
            "pregnancy" to SafetyProfile(pregnancy = true, emptyStomachConfirmed = true),
            "hypertension" to SafetyProfile(hypertension = true, emptyStomachConfirmed = true),
            "heartCondition" to SafetyProfile(heartCondition = true, emptyStomachConfirmed = true),
            "epilepsy" to SafetyProfile(epilepsy = true, emptyStomachConfirmed = true),
            "glaucoma" to SafetyProfile(glaucoma = true, emptyStomachConfirmed = true),
            "hernia" to SafetyProfile(hernia = true, emptyStomachConfirmed = true),
            "recentSurgery" to SafetyProfile(recentSurgery = true, emptyStomachConfirmed = true),
        )

        for ((label, profile) in flaggedProfiles) {
            for (practice in gatedPractices) {
                assertFalse(
                    "$label in strict mode without clearance must block $practice",
                    SafetyRulesEngine.isPracticeAllowed(practice, profile, teacherCleared = false, openAccessMode = false),
                )
                assertTrue(
                    "$label WITH clearance in strict mode should allow $practice",
                    SafetyRulesEngine.isPracticeAllowed(practice, profile, teacherCleared = true, openAccessMode = false),
                )
            }
            for (safe in gentleSafePractices) {
                assertTrue(
                    "$label should still allow gentle practice $safe",
                    SafetyRulesEngine.isPracticeAllowed(safe, profile, teacherCleared = false, openAccessMode = false),
                )
            }
            // Khechari is NEVER trainable regardless of profile or clearance
            assertFalse(SafetyRulesEngine.isPracticeAllowed("khechari", profile, teacherCleared = true, openAccessMode = false))
        }
    }

    @Test
    fun `optional strict mode menstruation restricts kapalbhati, uddiyana, and maha bandha`() {
        val profile = SafetyProfile(menstruation = true, emptyStomachConfirmed = true)
        assertFalse(SafetyRulesEngine.isPracticeAllowed("kapalbhati", profile, false, openAccessMode = false))
        assertFalse(SafetyRulesEngine.isPracticeAllowed("kapalbhati_advanced", profile, false, openAccessMode = false))
        assertFalse(SafetyRulesEngine.isPracticeAllowed("uddiyana_kriya", profile, false, openAccessMode = false))
        assertFalse(SafetyRulesEngine.isPracticeAllowed("maha_bandha", profile, false, openAccessMode = false))
        assertTrue(SafetyRulesEngine.isPracticeAllowed("nadi_shodhana_basic", profile, false, openAccessMode = false))
        assertTrue(SafetyRulesEngine.isPracticeAllowed("bhramari", profile, false, openAccessMode = false))
    }

    @Test
    fun `optional strict mode uddiyana and maha bandha require empty stomach and level 6`() {
        val notEmpty = SafetyProfile(emptyStomachConfirmed = false)
        assertFalse(SafetyRulesEngine.isPracticeAllowed("uddiyana_kriya", notEmpty, false, openAccessMode = false))
        assertFalse(SafetyRulesEngine.isPracticeAllowed("maha_bandha", notEmpty, false, openAccessMode = false))

        val empty = SafetyProfile(emptyStomachConfirmed = true)
        assertTrue(SafetyRulesEngine.isPracticeAllowed("uddiyana_kriya", empty, false, openAccessMode = false))
        assertTrue(SafetyRulesEngine.isPracticeAllowed("maha_bandha", empty, false, openAccessMode = false))

        val level5Eval = SafetyRulesEngine.evaluatePracticeAccess(
            practice = "uddiyana_kriya",
            profile = empty,
            userLevel = 5,
            requiredLevel = 6,
            approvedLevels = setOf(1, 2, 3, 4, 5, 6),
            openAccessMode = false,
            teacherGatingEnabled = true,
        )
        assertFalse(level5Eval.allowed)

        val level6Eval = SafetyRulesEngine.evaluatePracticeAccess(
            practice = "uddiyana_kriya",
            profile = empty,
            userLevel = 6,
            requiredLevel = 6,
            approvedLevels = setOf(1, 2, 3, 4, 5, 6),
            openAccessMode = false,
            teacherGatingEnabled = true,
        )
        assertTrue(level6Eval.allowed)
    }

    @Test
    fun `optional strict mode enforces teacher approval and 7-day strain lock`() {
        val clean = SafetyProfile(emptyStomachConfirmed = true)

        val lockedLvl3 = SafetyRulesEngine.evaluatePracticeAccess(
            practice = "antar_kumbhaka_short",
            profile = clean,
            userLevel = 2,
            requiredLevel = 3,
            approvedLevels = setOf(1, 2),
            teacherGatingEnabled = true,
            openAccessMode = false,
        )
        assertFalse(lockedLvl3.allowed)
        assertEquals(LockType.TEACHER_APPROVAL_REQUIRED, lockedLvl3.lockType)

        val strainLocked = SafetyRulesEngine.evaluatePracticeAccess(
            practice = "antar_kumbhaka",
            profile = clean,
            userLevel = 5,
            requiredLevel = 5,
            approvedLevels = setOf(1, 2, 3, 4, 5),
            recentStrainCount7Days = 2,
            openAccessMode = false,
        )
        assertFalse(strainLocked.allowed)
        assertEquals(LockType.STRAIN_REVIEW_LOCK, strainLocked.lockType)
    }

    @Test
    fun `property check - clampRatioToSafeCaps always honors SR-05 and SR-07`() {
        val chtValues = listOf(0, 5, 12, 20, 35, 60, 100)
        val fractions = listOf(0.3, 0.5, 0.6, 0.75)
        val levelCaps = listOf(0, 4, 8, 16, 24, 40)
        val requests = listOf(
            listOf(4, 0, 4, 0),
            listOf(4, 16, 8, 8),
            listOf(4, 10, 8, 20), // bahya > antar in request!
            listOf(6, 40, 12, 40),
        )

        for (cht in chtValues) {
            for (frac in fractions) {
                for (cap in levelCaps) {
                    for (req in requests) {
                        val safe = SafetyRulesEngine.clampRatioToSafeCaps(
                            ratioSeconds = req,
                            userChtSeconds = cht,
                            holdCapFractionOfCht = frac,
                            levelAntarCapSeconds = cap,
                            levelBahyaCapSeconds = cap,
                        )
                        val expectedMax = minOf(cap, (cht * frac).toInt())
                        assertTrue("Antar ${safe[1]} exceeded $expectedMax", safe[1] <= expectedMax)
                        assertTrue("Bahya ${safe[3]} exceeded Antar ${safe[1]}", safe[3] <= safe[1])
                        assertTrue("Bahya ${safe[3]} exceeded $expectedMax", safe[3] <= expectedMax)
                    }
                }
            }
        }
    }
}
