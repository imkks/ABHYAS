# Architecture Overview — Abhyas / PranaFlow (Android Native)

The application is built with **native Android (Kotlin)** using a **100% local, offline-first two-module Gradle architecture** (`/android`), keeping domain rules and timers cleanly separated from platform drivers and presentation.

## 1. Pure Kotlin Domain Engine (`android/engine` — Gradle module `:engine`)

Zero Android, Flutter, or network dependencies (`kotlin("jvm")`), unit-tested directly on the JVM:

* **Monotonic Clock Abstraction (`clock/MonotonicClock.kt`)**: `MonotonicClock`, `SystemMonotonicClock`, and `FakeMonotonicClock` eliminate wall-clock drift during breath holds and timed sequences.
* **Versioned Config & Seed Defaults (`config/`)**:
  * `ConfigModels.kt`: `PracticeConfig`, `SopanaLevel`, `KapalbhatiConfig`, `ParikshaConfig`, `WeaningConfig` loaded dynamically with zero hard-coded practice parameters in engine logic.
  * `SeedConfig.kt` & `ConfigValidator.kt`: Schema-validates configs and structural invariants (`hold_cap_fraction_of_cht`, `bahya <= antar`, `weaning` stages). Levels 3–7 use `"advisory"` gates in `SeedConfig` so Sopanas act as a progressive guide without blocking users.
* **Open Advisory Access & Cap Calibrator (`safety/SafetyRulesEngine.kt`)**:
  * Evaluates `SafetyRulesEngine.evaluatePracticeAccess(...)` with `openAccessMode = true` and `teacherGatingEnabled = false` by default: **all trainable pranayama and Dhyan practices remain open** while returning helpful `recommendedLevel` and `advisoryNote` hints for advanced Sopanas (`Khechari` remains non-trainable information-only).
  * `SafetyRulesEngine.clampRatioToSafeCaps(...)` continues to honor configured CHT scaling (`min(levelCap, floor(CHT * holdCapFractionOfCht))`) and the `bahya <= antar` structural invariant.
* **Pranayama & Audio Engines (`player/`)**:
  * `PlayerEngine.kt`: Breath phase state machine (`PracticePhase`, `PracticePhaseFrame`) driven by `MonotonicClock`.
  * `CycleSequencer.kt`: Multi-step daily and custom sequence orchestrator (`RoutinePreset`, `RoutineIntensity`, `CycleStepItem`, `RoutineCatalog`) with a 10-second posture/breathing transition gap between exercises.
  * `AudioGuidanceEngine.kt`: 5-stage progressive autonomy/weaning model (`AudioGuidanceLevel`, `AudioCueEvent`, `HandsFreeAction`) across 4 traditional sound palettes (`SoundPalette`).
  * `YogaNidraPlayer.kt`: Deep-relaxation audio session state machine.
* **Dhyan & Japa Engines (`meditation/`)**:
  * `MeditationEngine.kt`: `ProgressiveJapaEngine` (`JapaStage`), `PranaDharanaEngine` (`BreathAnchor`), and `DigitalMalaEngine` (`MalaAdvanceResult`) for 108-bead japa, breath awareness, and focused contemplation.
* **Progression & Calm Gamification (`progression/`)**:
  * `ProgressionEngine.kt`: Computes `UserProgression` across 7 Sopana ranks (`SopanaRankInfo`), private Tapas points, 108 Mala milestone (`MalaProgress`), non-punitive Vishrama rest days, `WeaningProgress`, comfort ratio ladder stepping (`RatioProgressionDecision`), and post-session `SelfCheckEvaluation`—all progressing freely in open mode without teacher gates.
  * `GuruAnumatiWorkflow.kt`: Optional workflow defaulted to `teacherGatingEnabled = false` so all 7 Sopana ranks are open by default.

## 2. Android Data & Platform Services Layer (`android/app` — Gradle module `:app`)

Package namespace `com.pranaflow.abhyas` (preserving `applicationId = "come.evertrail.pranaflow"` in `android/app/build.gradle.kts`, `minSdk = 26`, `targetSdk = 35`):

* **Dependency Injection Container (`core/di/AbhyasContainer.kt`)**: Wires `:engine` workflows (open advisory mode, no remote backend gating), Jetpack DataStore repositories, audio/haptic drivers, and `ContentRepository` asset loading without third-party analytics, ads, or remote cloud SDKs.
* **Local Persistence (`data/store/`, `data/models/`, `data/repositories/`)**:
  * `KeyValueStore.kt`: `DataStoreKeyValueStore` (Jetpack `datastore-preferences-android`) and `InMemoryKeyValueStore` for fast unit testing.
  * `DataModels.kt`: Serializable models (`SessionRecord`, `CheckinEntry`, `ChtMeasurement`, `CustomMantra`, `SavedCustomRoutine`, `ReminderSettings`, `AudioPreferences`, `UserProfileSettings`).
  * Repositories: `UserRepository`, `SessionRepository`, `MantraAndRoutineRepository`, `ConfigRepository`, and `ContentRepository` running 100% locally on device.
* **Triple-Channel Audio, Haptics & Background Service (`core/`)**:
  * `AudioService.kt` & `PracticeAudioService.kt`: Concurrent triple-channel playback (voice prompts, phase bell cues, continuous Tanpura/ambient bed) via `AudioPlaybackDriver` (`AndroidAudioPlaybackDriver` with audio focus handling, plus `RecordingAudioPlaybackDriver` for deterministic tests).
  * `HapticService.kt`: Eyes-closed tactile phase cue driver (`AndroidHapticDriver`, `HapticPattern`, plus `NoOpHapticDriver`).
  * `PracticePlaybackService.kt`: Android foreground service (`foregroundServiceType="mediaPlayback"`, `WAKE_LOCK`) so timed sessions continue reliably when the screen locks.
  * `ReminderScheduler.kt`: Local offline practice reminder calculator (`ScheduledReminder`) for Morning, Evening, and Bedtime windows (`POST_NOTIFICATIONS`).
* **Bundled Assets (`android/app/src/main/assets/`)**: Traditional audio cues/tracks under `assets/audio/` and content manifest/items under `assets/content/` (`manifest.json`, `instructions/`, `lessons/`, `mantras/`).

## 3. Modules Intentionally Removed in Native Migration

* **Panchang & Astrological Scheduling Removed**: Legacy Flutter modules for solar/lunar calculations (`PanchangEngine`, `SolarCalculator`, Tithi, Nakshatra, Choghadiya, Svara orientation) and location permissions were removed to eliminate clutter and keep daily practice focused on core Pranayama, Dhyan, and personal growth.
* **Remote Backend Control & Health Disclaimer Removed**: Supabase DB migrations/server gating and mandatory medical disclaimer banners are omitted so practice stays 100% local, offline, and open, with Sopana levels acting as an encouraging guide rather than hard blockers.

## 4. Presentation Layer (Jetpack Compose — `android/app/.../ui/`)

Implements the 6 **Google Stitch** (`Vedic Serenity`) explorations directly atop `AbhyasContainer` and `:engine`:
* **Theme & Components (`ui/theme/`, `ui/components/`)**: `SanctuaryColors`, `SanctuaryTypography`, `VedicSerenityTheme`, `SanctuaryTopBar`, `SanctuaryBottomBar`, `AdvisoryGuidePill`, `BreathCapacityTestDialog`, and `PostSessionCheckinDialog`.
* **State & Navigation (`ui/state/`, `ui/navigation/`)**: `AbhyasViewModel` orchestrates multi-mode practice timing (`CycleSequencer`, `PlayerEngine`, `AudioGuidanceEngine`, `ProgressiveJapaEngine`, `PranaDharanaEngine`, `YogaNidraPlayer`, `DigitalMalaEngine`), open advisory evaluations, and local preferences; `AbhyasApp` hosts the 4-tab bottom navigation plus full-screen Composer and Player routes.
* **Screens (`ui/screens/`)**:
  1. `DailySanctuaryScreen`: Daily Sankalp intention, Surya & Chandra routines, individual drill shortcuts, CHT comfort guide, Calmness Shift summary, 5-stage autonomy ladder.
  2. `PranayamaMasteryScreen`: Krama Master Sequence, discipline filters, all 6 open Pranayama techniques with `Guide: Sopana X` badges and per-technique customizer dialogs.
  3. `DhyanMalaScreen`: Combined 3-Stage Japa → Nostril Dhyan flow, interactive 108 Digital Mala, sacred + custom mantras, Prana Dharana breath anchoring, 20/30/45m Yoga Nidra, Trataka & Antar Mouna.
  4. `CustomComposerScreen`: Preset/intensity/duration selectors, reorderable sequence cards, per-step adjusters, catalog step insertion, and offline routine persistence.
  5. `PracticePlayerScreen`: `#090D16` deep canvas breathing halo, 10s posture/mudra transition view, live Japa/Yoga Nidra stages, guidance-stage switcher, tactile controls, and immediate `Return to Natural Breath` release.
  6. `PersonalGrowthScreen`: CHT baseline calibration, 7 Sopana open mastery path, 108 Mala/Mudra/Bandha milestones, Calmness Shift history, sound palette, matra speed, reminders, and local JSON snapshot export.
