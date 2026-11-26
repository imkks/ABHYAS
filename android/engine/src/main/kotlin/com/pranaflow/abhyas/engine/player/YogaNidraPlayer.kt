package com.pranaflow.abhyas.engine.player

import com.pranaflow.abhyas.engine.clock.MonotonicClock
import com.pranaflow.abhyas.engine.clock.SystemMonotonicClock

/**
 * Pure Kotlin Yoga Nidra player state machine supporting 20/30/45 min tracks,
 * monotonic clock tracking, pause/resume/seek, and classical 7-stage consciousness rotation labels.
 */
class YogaNidraPlayer(
    val durationMinutes: Int,
    private val clock: MonotonicClock = SystemMonotonicClock,
) {
    val totalSeconds: Int
        get() = durationMinutes * 60

    private var accumulatedMillis: Long = 0L
    private var activeStartMillis: Long? = null
    var isPaused: Boolean = false
        private set
    var isCompleted: Boolean = false
        private set

    val isPlaying: Boolean
        get() = activeStartMillis != null && !isPaused && !isCompleted

    fun start() {
        accumulatedMillis = 0L
        activeStartMillis = clock.elapsedMillis()
        isPaused = false
        isCompleted = false
    }

    fun pause() {
        val start = activeStartMillis ?: return
        accumulatedMillis += (clock.elapsedMillis() - start).coerceAtLeast(0L)
        activeStartMillis = null
        isPaused = true
    }

    fun resume() {
        if (isCompleted) return
        if (activeStartMillis == null) {
            activeStartMillis = clock.elapsedMillis()
            isPaused = false
        }
    }

    fun seekToSeconds(seconds: Int) {
        val clamped = seconds.coerceIn(0, totalSeconds)
        accumulatedMillis = clamped * 1_000L
        if (activeStartMillis != null) {
            activeStartMillis = clock.elapsedMillis()
        }
        isCompleted = clamped >= totalSeconds
    }

    fun stop() {
        accumulatedMillis = 0L
        activeStartMillis = null
        isPaused = false
    }

    fun elapsedSeconds(): Int {
        val runningDelta = activeStartMillis?.let { (clock.elapsedMillis() - it).coerceAtLeast(0L) } ?: 0L
        val seconds = ((accumulatedMillis + runningDelta) / 1_000L).toInt()
        if (seconds >= totalSeconds) {
            isCompleted = true
            activeStartMillis = null
            accumulatedMillis = totalSeconds * 1_000L
            return totalSeconds
        }
        return seconds
    }

    fun progress(): Double =
        if (totalSeconds > 0) (elapsedSeconds().toDouble() / totalSeconds).coerceIn(0.0, 1.0) else 0.0

    fun currentStageName(): String {
        val p = progress()
        return when {
            p < 0.10 -> "1. Preparation & Stillness (Savasana)"
            p < 0.20 -> "2. Sankalpa (Sacred Resolve)"
            p < 0.50 -> "3. Rotation of Consciousness (Nyasa)"
            p < 0.70 -> "4. Breath Awareness (Prana Dharana)"
            p < 0.85 -> "5. Feeling Opposites (Heavy/Light, Warm/Cool)"
            p < 0.95 -> "6. Chidakasha (Visualization)"
            else -> "7. Externalization & Return"
        }
    }

    fun audioAssetPath(): String = "audio/yoga_nidra_${durationMinutes}min.mp3"
}
