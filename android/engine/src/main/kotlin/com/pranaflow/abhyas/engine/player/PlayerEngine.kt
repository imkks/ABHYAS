package com.pranaflow.abhyas.engine.player

import com.pranaflow.abhyas.engine.clock.MonotonicClock
import com.pranaflow.abhyas.engine.clock.SystemMonotonicClock
import com.pranaflow.abhyas.engine.safety.SafetyRulesEngine
import kotlin.math.min

enum class PracticePhase {
    PURAKA,
    ANTAR_KUMBHAKA,
    RECHAKA,
    BAHYA_KUMBHAKA,
    NATURAL_BREATH,
}

data class PracticePhaseFrame(
    val phase: PracticePhase,
    val phaseTitle: String,
    val secondsInPhase: Int,
    val phaseTargetSeconds: Int,
    val currentRound: Int,
    val totalRounds: Int,
    val cueText: String,
    val maxAllowedHoldSeconds: Int,
    val holdCapReached: Boolean = false,
)

/**
 * Pure Kotlin breathwork player state machine with monotonic clock timing and strict safety hold caps (SR-05, SR-07, AC-2, AC-9).
 */
class PlayerEngine(
    val holdCapFractionOfCht: Double,
    val levelCapSeconds: Int,
    val userChtSeconds: Int,
    val bahyaCapSeconds: Int = levelCapSeconds,
    val targetCycles: Int? = null,
    private val clock: MonotonicClock = SystemMonotonicClock,
) {
    private var accumulatedMillis: Long = 0L
    private var activeStartMillis: Long? = null
    private var isPausedState: Boolean = false

    var currentCycle: Int = 1
        private set

    var currentPhase: PracticePhase = PracticePhase.PURAKA
        private set

    val isRunning: Boolean
        get() = activeStartMillis != null && !isPausedState

    val isPaused: Boolean
        get() = isPausedState

    val isTargetCyclesReached: Boolean
        get() = targetCycles != null && currentCycle > targetCycles

    fun startTimer() {
        accumulatedMillis = 0L
        activeStartMillis = clock.elapsedMillis()
        isPausedState = false
    }

    fun pauseTimer() {
        val start = activeStartMillis ?: return
        accumulatedMillis += (clock.elapsedMillis() - start).coerceAtLeast(0L)
        activeStartMillis = null
        isPausedState = true
    }

    fun resumeTimer() {
        if (activeStartMillis == null) {
            activeStartMillis = clock.elapsedMillis()
            isPausedState = false
        }
    }

    fun stopTimer() {
        accumulatedMillis = 0L
        activeStartMillis = null
        isPausedState = false
    }

    fun elapsedMillis(): Long {
        val runningDelta = activeStartMillis?.let { (clock.elapsedMillis() - it).coerceAtLeast(0L) } ?: 0L
        return accumulatedMillis + runningDelta
    }

    fun elapsedSeconds(): Int = (elapsedMillis() / 1_000L).toInt()

    fun incrementCycle() {
        currentCycle++
    }

    fun resetCycles() {
        currentCycle = 1
        currentPhase = PracticePhase.PURAKA
    }

    /**
     * AC-2 / SR-07: Hold capped strictly by min(levelCap, floor(userCht * holdCapFractionOfCht)).
     */
    fun calculateMaxHoldSeconds(): Int {
        val fraction = holdCapFractionOfCht.coerceIn(0.0, 1.0)
        val userCap = userChtSeconds.coerceAtLeast(0) * fraction
        return min(levelCapSeconds.coerceAtLeast(0).toDouble(), userCap).toInt().coerceAtLeast(0)
    }

    /**
     * Schedules an internal retention hold firmly capped by [calculateMaxHoldSeconds].
     */
    fun scheduleHold(ratioRequiredSeconds: Int): Int {
        val requested = ratioRequiredSeconds.coerceAtLeast(0)
        return min(requested, calculateMaxHoldSeconds())
    }

    /**
     * SR-05 & SR-07: Schedules external retention (Bahya Kumbhaka) so it NEVER exceeds
     * scheduled Antar Kumbhaka, level bahya cap, or CHT cap.
     */
    fun scheduleBahyaHold(ratioRequiredBahyaSeconds: Int, scheduledAntarSeconds: Int): Int {
        val requested = ratioRequiredBahyaSeconds.coerceAtLeast(0)
        val maxAllowed = minOf(
            scheduledAntarSeconds.coerceAtLeast(0),
            bahyaCapSeconds.coerceAtLeast(0),
            calculateMaxHoldSeconds(),
        )
        return min(requested, maxAllowed)
    }

    /**
     * Clamps any requested 4-part ratio [puraka, antar, rechaka, bahya] to safe engine caps.
     */
    fun resolveSafeRatio(requestedRatio: List<Int>): List<Int> {
        return SafetyRulesEngine.clampRatioToSafeCaps(
            ratioSeconds = requestedRatio,
            userChtSeconds = userChtSeconds,
            holdCapFractionOfCht = holdCapFractionOfCht,
            levelAntarCapSeconds = levelCapSeconds,
            levelBahyaCapSeconds = bahyaCapSeconds,
        )
    }

    /**
     * Classical state transitions; skips 0-second kumbhaka phases when ratio specifies 0.
     */
    fun getNextPhase(current: PracticePhase, activeRatio: List<Int>? = null): PracticePhase {
        val antar = activeRatio?.getOrNull(1) ?: 1
        val bahya = activeRatio?.getOrNull(3) ?: 1

        val next = when (current) {
            PracticePhase.PURAKA -> if (antar > 0) PracticePhase.ANTAR_KUMBHAKA else PracticePhase.RECHAKA
            PracticePhase.ANTAR_KUMBHAKA -> PracticePhase.RECHAKA
            PracticePhase.RECHAKA -> if (bahya > 0) {
                PracticePhase.BAHYA_KUMBHAKA
            } else {
                currentCycle++
                PracticePhase.PURAKA
            }
            PracticePhase.BAHYA_KUMBHAKA -> {
                currentCycle++
                PracticePhase.PURAKA
            }
            PracticePhase.NATURAL_BREATH -> PracticePhase.PURAKA
        }
        currentPhase = next
        return next
    }

    /**
     * AC-9: Immediately ends retention and transitions to natural breath.
     */
    fun returnToNaturalBreath(): PracticePhase {
        stopTimer()
        currentPhase = PracticePhase.NATURAL_BREATH
        return currentPhase
    }

    /**
     * Deterministic frame evaluation for a given step elapsed second across any Pranayama technique.
     * Guarantees zero UI-layer calculation of holds, caps, or phase boundaries.
     */
    fun evaluateFrame(
        practiceId: String,
        stepElapsedSeconds: Int,
        requestedRatio: List<Int>,
        strokesPerRound: Int = 30,
        totalRounds: Int = 3,
    ): PracticePhaseFrame {
        val normalizedId = practiceId.lowercase()
        val maxHold = calculateMaxHoldSeconds()
        val safeRatio = resolveSafeRatio(requestedRatio)
        val elapsed = stepElapsedSeconds.coerceAtLeast(0)

        if (normalizedId.contains("kapal")) {
            val strokes = strokesPerRound.coerceIn(10, 120)
            val bahirHold = scheduleHold(requestedRatio.getOrNull(3) ?: 10)
            val purakaRelease = 4
            val rest = 6
            val roundDuration = strokes + bahirHold + purakaRelease + rest
            val round = (elapsed / roundDuration) + 1
            val secInRound = elapsed % roundDuration

            return when {
                round > totalRounds -> PracticePhaseFrame(
                    phase = PracticePhase.NATURAL_BREATH,
                    phaseTitle = "KAPALBHATI COMPLETE",
                    secondsInPhase = 0,
                    phaseTargetSeconds = 0,
                    currentRound = totalRounds,
                    totalRounds = totalRounds,
                    cueText = "Rest in natural breath · Observe stillness",
                    maxAllowedHoldSeconds = maxHold,
                )
                secInRound < strokes -> PracticePhaseFrame(
                    phase = PracticePhase.RECHAKA,
                    phaseTitle = "ACTIVE EXHALATIONS",
                    secondsInPhase = secInRound + 1,
                    phaseTargetSeconds = strokes,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Sharp abdominal pumping · Chin Mudra · Passive inhale",
                    maxAllowedHoldSeconds = maxHold,
                )
                bahirHold > 0 && secInRound < strokes + bahirHold -> {
                    val holdSec = (secInRound - strokes) + 1
                    PracticePhaseFrame(
                        phase = PracticePhase.BAHYA_KUMBHAKA,
                        phaseTitle = "BAHIR KUMBHAKA (HOLD EMPTY)",
                        secondsInPhase = holdSec,
                        phaseTargetSeconds = bahirHold,
                        currentRound = round,
                        totalRounds = totalRounds,
                        cueText = "Exhale completely · Hold outside · Maha Bandha",
                        maxAllowedHoldSeconds = maxHold,
                        holdCapReached = holdSec >= bahirHold,
                    )
                }
                secInRound < strokes + bahirHold + purakaRelease -> PracticePhaseFrame(
                    phase = PracticePhase.PURAKA,
                    phaseTitle = "PURAKA RELEASE",
                    secondsInPhase = (secInRound - strokes - bahirHold) + 1,
                    phaseTargetSeconds = purakaRelease,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Release locks gently · Slow diaphragmatic inhalation",
                    maxAllowedHoldSeconds = maxHold,
                )
                else -> PracticePhaseFrame(
                    phase = PracticePhase.NATURAL_BREATH,
                    phaseTitle = "NATURAL REST",
                    secondsInPhase = (secInRound - strokes - bahirHold - purakaRelease) + 1,
                    phaseTargetSeconds = rest,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Breathe naturally before next round",
                    maxAllowedHoldSeconds = maxHold,
                )
            }
        }

        if (normalizedId.contains("bhramari")) {
            val puraka = safeRatio[0]
            val antarHold = safeRatio[1]
            val humming = safeRatio[2].coerceAtLeast(6)
            val cycleTotal = puraka + antarHold + humming
            val round = (elapsed / cycleTotal) + 1
            val secInCycle = elapsed % cycleTotal

            return when {
                secInCycle < puraka -> PracticePhaseFrame(
                    phase = PracticePhase.PURAKA,
                    phaseTitle = "PURAKA (SMOOTH INHALE)",
                    secondsInPhase = secInCycle + 1,
                    phaseTargetSeconds = puraka,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Shanmukhi Mudra · Deep smooth inhalation",
                    maxAllowedHoldSeconds = maxHold,
                )
                antarHold > 0 && secInCycle < puraka + antarHold -> {
                    val holdSec = (secInCycle - puraka) + 1
                    PracticePhaseFrame(
                        phase = PracticePhase.ANTAR_KUMBHAKA,
                        phaseTitle = "ANTAR KUMBHAKA (INTERNAL HOLD)",
                        secondsInPhase = holdSec,
                        phaseTargetSeconds = antarHold,
                        currentRound = round,
                        totalRounds = totalRounds,
                        cueText = "Soft internal retention · Stillness at brow center",
                        maxAllowedHoldSeconds = maxHold,
                        holdCapReached = holdSec >= maxHold,
                    )
                }
                else -> PracticePhaseFrame(
                    phase = PracticePhase.RECHAKA,
                    phaseTitle = "BHRAMARI RECHAKA (HUMMING)",
                    secondsInPhase = (secInCycle - puraka - antarHold) + 1,
                    phaseTargetSeconds = humming,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Close ears gently · Steady humming resonance",
                    maxAllowedHoldSeconds = maxHold,
                )
            }
        }

        if (normalizedId.contains("ujjayi")) {
            val puraka = safeRatio[0]
            val antarHold = safeRatio[1]
            val rechaka = safeRatio[2]
            val cycleTotal = puraka + antarHold + rechaka
            val round = (elapsed / cycleTotal) + 1
            val secInCycle = elapsed % cycleTotal

            return when {
                secInCycle < puraka -> PracticePhaseFrame(
                    phase = PracticePhase.PURAKA,
                    phaseTitle = "UJJAYI PURAKA (OCEAN INHALE)",
                    secondsInPhase = secInCycle + 1,
                    phaseTargetSeconds = puraka,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Gently constrict glottis · Soft ocean sound",
                    maxAllowedHoldSeconds = maxHold,
                )
                antarHold > 0 && secInCycle < puraka + antarHold -> {
                    val holdSec = (secInCycle - puraka) + 1
                    PracticePhaseFrame(
                        phase = PracticePhase.ANTAR_KUMBHAKA,
                        phaseTitle = "ANTAR KUMBHAKA (INTERNAL HOLD)",
                        secondsInPhase = holdSec,
                        phaseTargetSeconds = antarHold,
                        currentRound = round,
                        totalRounds = totalRounds,
                        cueText = "Gentle chin lock (Jalandhara Bandha)",
                        maxAllowedHoldSeconds = maxHold,
                        holdCapReached = holdSec >= maxHold,
                    )
                }
                else -> PracticePhaseFrame(
                    phase = PracticePhase.RECHAKA,
                    phaseTitle = "UJJAYI RECHAKA (OCEAN EXHALE)",
                    secondsInPhase = (secInCycle - puraka - antarHold) + 1,
                    phaseTargetSeconds = rechaka,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Smooth continuous exhalation like ocean surf",
                    maxAllowedHoldSeconds = maxHold,
                )
            }
        }

        // Standard 4-phase Pranayama (Nadi Shodhana, Surya Bhedana, Bhastrika hold cycles, Sheetali)
        val puraka = safeRatio[0]
        val antar = safeRatio[1]
        val rechaka = safeRatio[2]
        val bahya = safeRatio[3]
        val cycleTotal = (puraka + antar + rechaka + bahya).coerceAtLeast(1)
        val round = (elapsed / cycleTotal) + 1
        val secInCycle = elapsed % cycleTotal
        val isOddRound = round % 2 == 1
        val isNadi = normalizedId.contains("nadi")

        return when {
            secInCycle < puraka -> PracticePhaseFrame(
                phase = PracticePhase.PURAKA,
                phaseTitle = "PURAKA (INHALE)",
                secondsInPhase = secInCycle + 1,
                phaseTargetSeconds = puraka,
                currentRound = round,
                totalRounds = totalRounds,
                cueText = if (isNadi) {
                    if (isOddRound) "Inhale Left (Ida) · Thumb closes right nostril"
                    else "Inhale Right (Pingala) · Ring finger closes left"
                } else {
                    "Smooth steady inhalation"
                },
                maxAllowedHoldSeconds = maxHold,
            )
            secInCycle < puraka + antar -> {
                val holdSec = (secInCycle - puraka) + 1
                PracticePhaseFrame(
                    phase = PracticePhase.ANTAR_KUMBHAKA,
                    phaseTitle = "ANTAR KUMBHAKA (HOLD IN)",
                    secondsInPhase = holdSec,
                    phaseTargetSeconds = antar,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = if (isNadi) "Both nostrils closed · Jalandhara Bandha" else "Gentle internal retention",
                    maxAllowedHoldSeconds = maxHold,
                    holdCapReached = holdSec >= maxHold,
                )
            }
            secInCycle < puraka + antar + rechaka -> PracticePhaseFrame(
                phase = PracticePhase.RECHAKA,
                phaseTitle = "RECHAKA (EXHALE)",
                secondsInPhase = (secInCycle - puraka - antar) + 1,
                phaseTargetSeconds = rechaka,
                currentRound = round,
                totalRounds = totalRounds,
                cueText = if (isNadi) {
                    if (isOddRound) "Exhale Right (Pingala) · Release right thumb"
                    else "Exhale Left (Ida) · Release left ring finger"
                } else {
                    "Smooth unforced exhalation"
                },
                maxAllowedHoldSeconds = maxHold,
            )
            else -> {
                val holdSec = (secInCycle - puraka - antar - rechaka) + 1
                PracticePhaseFrame(
                    phase = PracticePhase.BAHYA_KUMBHAKA,
                    phaseTitle = "BAHYA KUMBHAKA (HOLD OUT)",
                    secondsInPhase = holdSec,
                    phaseTargetSeconds = bahya,
                    currentRound = round,
                    totalRounds = totalRounds,
                    cueText = "Hold empty gently · Maha Bandha",
                    maxAllowedHoldSeconds = maxHold,
                    holdCapReached = holdSec >= maxHold,
                )
            }
        }
    }
}
