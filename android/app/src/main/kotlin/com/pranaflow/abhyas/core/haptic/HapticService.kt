package com.pranaflow.abhyas.core.haptic

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

enum class HapticPattern {
    MATRA_TICK,
    PHASE_TRANSITION,
    ROUND_COMPLETE,
    MALA_BEAD,
    MERU_REACHED,
    SAFETY_STOP,
    COMPLETION,
}

interface HapticDriver {
    fun vibrate(pattern: HapticPattern)
}

class NoOpHapticDriver : HapticDriver {
    val recordedPatterns = mutableListOf<HapticPattern>()
    override fun vibrate(pattern: HapticPattern) {
        recordedPatterns.add(pattern)
    }
}

class AndroidHapticDriver(
    context: Context,
) : HapticDriver {
    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val mgr = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
        mgr?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    override fun vibrate(pattern: HapticPattern) {
        val vib = vibrator ?: return
        if (!vib.hasVibrator()) return

        val effect = when (pattern) {
            HapticPattern.MATRA_TICK -> VibrationEffect.createOneShot(18L, 70)
            HapticPattern.MALA_BEAD -> VibrationEffect.createOneShot(24L, 110)
            HapticPattern.PHASE_TRANSITION -> VibrationEffect.createOneShot(45L, 150)
            HapticPattern.ROUND_COMPLETE -> VibrationEffect.createWaveform(longArrayOf(0, 55, 60, 55), -1)
            HapticPattern.MERU_REACHED -> VibrationEffect.createOneShot(240L, 140)
            HapticPattern.SAFETY_STOP -> VibrationEffect.createOneShot(120L, 220)
            HapticPattern.COMPLETION -> VibrationEffect.createWaveform(longArrayOf(0, 70, 90, 90), -1)
        }
        vib.vibrate(effect)
    }
}

/**
 * Centralized haptic controller calibrated to weaning stages 1-5 and UI_SPEC Section 6 patterns.
 * Disabled by default for gentle breathwork until opted in.
 */
class HapticService(
    private val driver: HapticDriver,
) {
    var isEnabled: Boolean = false

    fun pulseForMatra(weaningStage: Int) {
        if (!isEnabled) return
        if (weaningStage <= 2) {
            driver.vibrate(HapticPattern.MATRA_TICK)
        }
    }

    fun phaseTransitionPulse(weaningStage: Int) {
        if (!isEnabled) return
        if (weaningStage <= 3) {
            driver.vibrate(HapticPattern.PHASE_TRANSITION)
        } else if (weaningStage == 4) {
            driver.vibrate(HapticPattern.MATRA_TICK)
        }
    }

    fun roundCompletePulse(weaningStage: Int) {
        if (!isEnabled) return
        if (weaningStage <= 4) {
            driver.vibrate(HapticPattern.ROUND_COMPLETE)
        }
    }

    fun malaBeadPulse() {
        if (!isEnabled) return
        driver.vibrate(HapticPattern.MALA_BEAD)
    }

    fun meruReachedPulse() {
        if (!isEnabled) return
        driver.vibrate(HapticPattern.MERU_REACHED)
    }

    fun safetyStopPulse() {
        // Safety feedback vibrates even during low-guidance stages if haptics are enabled
        if (!isEnabled) return
        driver.vibrate(HapticPattern.SAFETY_STOP)
    }

    fun completionPulse() {
        if (!isEnabled) return
        driver.vibrate(HapticPattern.COMPLETION)
    }
}
