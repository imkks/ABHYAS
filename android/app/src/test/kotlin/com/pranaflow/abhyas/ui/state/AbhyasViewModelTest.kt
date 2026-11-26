package com.pranaflow.abhyas.ui.state

import android.content.Context
import com.pranaflow.abhyas.core.audio.RecordingAudioPlaybackDriver
import com.pranaflow.abhyas.core.di.AbhyasContainer
import com.pranaflow.abhyas.core.haptic.NoOpHapticDriver
import com.pranaflow.abhyas.data.store.InMemoryKeyValueStore
import com.pranaflow.abhyas.engine.clock.FakeMonotonicClock
import com.pranaflow.abhyas.engine.player.PracticePhase
import com.pranaflow.abhyas.engine.player.RoutineIntensity
import com.pranaflow.abhyas.engine.player.RoutinePreset
import com.pranaflow.abhyas.engine.player.SoundPalette
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AbhyasViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var store: InMemoryKeyValueStore
    private lateinit var audioDriver: RecordingAudioPlaybackDriver
    private lateinit var clock: FakeMonotonicClock
    private lateinit var viewModel: AbhyasViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        store = InMemoryKeyValueStore()
        audioDriver = RecordingAudioPlaybackDriver()
        clock = FakeMonotonicClock()
        val mockContext = mockk<Context>(relaxed = true)
        val container = AbhyasContainer(
            appContext = mockContext,
            store = store,
            customAudioDriver = audioDriver,
            customHapticDriver = NoOpHapticDriver(),
        )
        viewModel = AbhyasViewModel(
            container = container,
            clock = clock,
            tickerDispatcher = testDispatcher,
        )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial load opens all pranayama techniques with advisory guide badges`() = runTest {
        advanceUntilIdle()
        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(6, state.techniques.size)
        assertTrue(state.techniques.all { it.accessResult.allowed })

        val bhastrika = state.techniques.first { it.id == "bhastrika" }
        assertEquals(4, bhastrika.accessResult.recommendedLevel)
        assertNotNull(bhastrika.accessResult.advisoryNote)
    }

    @Test
    fun `composer updates preset, steps, saves and reloads custom routine offline`() = runTest {
        advanceUntilIdle()
        viewModel.selectComposerPreset(RoutinePreset.CHANDRA)
        viewModel.selectComposerIntensity(RoutineIntensity.INTENSE)
        viewModel.addComposerCatalogExercise("trataka")
        val stepCount = viewModel.uiState.value.composer.steps.size
        assertTrue(stepCount >= 4)

        viewModel.saveCurrentCustomRoutine("Evening Wind-Down")
        advanceUntilIdle()

        val saved = viewModel.uiState.value.savedRoutines
        assertEquals(1, saved.size)
        assertEquals("Evening Wind-Down", saved.first().name)
    }

    @Test
    fun `digital mala reaches Meru completion bell and custom mantras persist`() = runTest {
        advanceUntilIdle()
        viewModel.addCustomMantra("So-Ham Personal", "सोऽहम्", "So'ham", "Breath awareness mantra")
        advanceUntilIdle()
        assertEquals("So-Ham Personal", viewModel.uiState.value.selectedMantra.name)

        viewModel.setMalaTargetBeads(27)
        repeat(27) { viewModel.tapMalaBead() }
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(0, state.malaCurrentBead)
        assertEquals(1, state.malaRoundsCompleted)
        assertTrue(state.meruBannerVisible)
        assertTrue(audioDriver.playedBells.isNotEmpty())
    }

    @Test
    fun `single technique player starts, releases gently to natural breath, and logs calmness shift`() = runTest {
        advanceUntilIdle()
        val nadi = viewModel.uiState.value.techniques.first { it.id == "nadi_shodhana" }
        viewModel.updatePreCalmness(4)
        viewModel.startSingleTechnique(nadi)

        val activePlayer = viewModel.uiState.value.player
        assertTrue(activePlayer.isActive)
        assertEquals(PracticePhase.PURAKA, activePlayer.phaseFrame?.phase)

        viewModel.returnToNaturalBreathAndStop()
        val releasedState = viewModel.uiState.value
        assertFalse(releasedState.player.isActive)
        assertTrue(releasedState.player.isNaturalBreathReturn)
        assertNotNull(releasedState.pendingCheckin)

        viewModel.submitPostSessionCheckin("calm", 8, "Peaceful session")
        advanceUntilIdle()

        val afterCheckin = viewModel.uiState.value
        assertNull(afterCheckin.pendingCheckin)
        assertTrue(afterCheckin.progression.totalTapas > 0)
        assertEquals(4.0, afterCheckin.averageCalmnessDelta, 0.01)
    }

    @Test
    fun `CHT calibration and audio palette preferences persist cleanly`() = runTest {
        advanceUntilIdle()
        viewModel.saveChtMeasurement(40.0)
        viewModel.updateSoundPalette(SoundPalette.FLUTE_HARMONIC)
        viewModel.logVishramaRestDay(todayEpochDay = 120L)
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(40.0, state.chtBenchmarkSeconds ?: 0.0, 0.01)
        assertEquals(SoundPalette.FLUTE_HARMONIC, state.audioPreferences.soundPalette)
        assertEquals(1, state.progression.vishramaDaysUsedThisWeek)
    }
}
