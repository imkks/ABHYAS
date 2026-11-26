package com.pranaflow.abhyas.engine.clock

/**
 * Monotonic clock abstraction for all practice timers and phase transitions (NFR-02).
 * Production code uses [SystemMonotonicClock]; tests inject [FakeMonotonicClock].
 */
interface MonotonicClock {
    fun elapsedMillis(): Long
}

object SystemMonotonicClock : MonotonicClock {
    override fun elapsedMillis(): Long = System.nanoTime() / 1_000_000L
}

class FakeMonotonicClock(initialMillis: Long = 0L) : MonotonicClock {
    private var currentMillis: Long = initialMillis

    override fun elapsedMillis(): Long = currentMillis

    fun advanceByMillis(deltaMillis: Long) {
        require(deltaMillis >= 0L) { "Monotonic clock cannot move backwards: $deltaMillis" }
        currentMillis += deltaMillis
    }

    fun advanceBySeconds(seconds: Long) {
        advanceByMillis(seconds * 1_000L)
    }

    fun setMillis(millis: Long) {
        require(millis >= currentMillis) { "Monotonic clock cannot move backwards: $millis < $currentMillis" }
        currentMillis = millis
    }
}
