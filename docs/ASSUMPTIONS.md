# Assumptions for Abhyas

As per the task brief, the following assumptions were made regarding the design, implementation, and overall product requirements where the document was silent or ambiguous:

## Tech Stack
* Mobile: Flutter (iOS + Android) using default `flutter create` template since offline-first is requested and local DB will be required later.
* The test environment will assume no database for phase 1 testing unless mocked in memory, for CI/CD apk generation as requested.

## Definitions
* Phase 1 involves only basic UI-independent modules. Therefore no UI/widgets are created. We just created tests for the underlying logics.
* `hold_cap_fraction_of_cht` applies equally to `antar_kumbhaka` and `bahya_kumbhaka` holds unless a separate cap is defined.

## Engine
* Monotonic clock for timers is modeled as standard `Stopwatch` in dart, which operates independently from system clock variations.

## CI/CD & Workflow
* We build `apk` using `ubuntu-latest` inside Github Actions.
* GitHub Actions workflow `build-apk.yml` triggers specifically on `pull_request` targeting `main` and manual `workflow_dispatch` to prevent redundant runs on non-main commit pushes.
* GitHub Actions workflow `deploy-console.yml` deploys the Teacher Console to GitHub Pages on every push to `main` affecting `console/**` (or manual trigger).
* `"homepage": "."` configured in `console/package.json` to allow static assets to resolve relatively on GitHub Pages subdirectory paths.

## Audio & Haptics
* `AudioService` uses an injectable interface abstraction layer with logging stubs pending external audio dependency (`just_audio`).
* `HapticService` dynamically suppresses or scales haptic feedback in accordance with weaning stages 1 through 5 (e.g. stage 5 independent practice suppresses all haptic guidance).

## Modern Flutter Standards & Lints
* Deprecated `Color.withOpacity(alpha)` updated to Flutter 3.27+ `Color.withValues(alpha: alpha)` across all widgets.
* Deprecated `ColorScheme.background` and `onBackground` replaced with `surface` and `onSurface`.
* Super parameters (`super.key`) and public State type signatures (`State<WidgetName>`) enforced throughout the codebase to ensure clean `flutter analyze` runs with zero warnings or info notices.

## Backend
* Local testing of APK doesn't require backend interaction right now since Phase 1 includes no backend features. We will mock everything needed to run.

## Self-Mastery & Open Access Mode (Bypassing Teacher Plan)
* The teacher sign-off gate in `GuruAnumatiWorkflow` has been put into idle/bypass mode via `_openAccessMode = true` (default). All 7 Sopana levels and practices are open to the practitioner for self-guided exploration and daily practice.
* Non-blocking safety advisories remain active in `SafetyRulesEngine` and post-session check-ins to alert users if contraindications are present.

## Dynamic Routine Planner & Signature Presets
* `CycleComposerScreen` is upgraded to support time-adaptive scheduling (10m, 15m, 20m, 25m, 30m, 45m, 60m).
* Two signature presets are provided:
  - **Surya Abhyas (Morning Vitality - 30m default)**: Invocation, Kapalbhati, Nadi Shodhana, Ujjayi, and Breath Awareness Dhyan.
  - **Chandra Abhyas (Night Bedtime - 25m default)**: Naam Jaap (108 beads), Bhramari Pranayama, and guided Yoga Nidra.
* Step durations can be customized directly with `+1m` / `-1m` steppers, steps can be reordered, and new exercises can be added from an expandable catalog.

## Custom Mantra & Digital Mala Engine
* `DhyanScreen` features a customizable Digital Mala supporting 27, 54, 108, or continuous bead counting with haptic pulses and Meru bead completion alerts.
* Practitioners can select from classical mantras (*Om, Om Namah Shivaya, Hare Krishna, Gayatri, Soham, Ram*) or save their own custom mantras and Ishta Devata Naam to local storage.

## "See the Difference" Reflection & Metrics
* `PostSessionCheckinScreen` incorporates a Calmness Score (1–10 slider) and computes the Calmness Delta (post - pre) to visually demonstrate transformation.
* `SessionRepository` persists calmness scores and physical sensations, calculating average calmness improvement and total practice time for display on `ProgressScreen`.

## UI Simplification & Zen Aesthetic
* Home screen (`TodayScreen`) decluttered from a multi-card wall to 5 purposeful components:
  1. Header with Tapas XP progress & daily streak.
  2. Scaled Morning Surya Routine card.
  3. Evening Bedtime Chandra Routine card.
  4. Quick time-adaptive session chips (10m, 15m, 20m, 30m, 45m).
  5. Quiet daily Sankalp reflection.
* Removed the persistent floating action button and redundant developer/admin mock cards to preserve serene focus.
* Restructured navigation into 5 dedicated tabs: `Sadhana`, `Abhyas`, `Dhyan`, `Vidyapeeth`, and `Mera`.

## Yogic Self-Mastery Level Progression (Gamified Without Anxiety)
* Integrated `ProgressionService` providing 7 Sopana ranks from *Prarambha* (Seeker) to *Dhyani* (Absorbed Master).
* Practice time and calm session check-ins award *Tapas* XP (10 Tapas per minute + calm completion bonuses), advancing the user through the 7 levels.
* Morning Surya Routine dynamically adapts to user rank: higher Kapalbhati stroke targets (30 -> 120), deeper breath retention ladders (from 1:0:1:0 up to classical 1:4:2:2 Kumbhaka), and unlocks authentic Mudras/Bandhas (Gyan Mudra up to Maha Bandha).
* Strictly upholds non-competitive design: no leaderboards, no social comparison, no streak-loss shaming, focusing purely on personal self-mastery.

## Dynamic Ratio Customization & 1-Minute Breath Capacity Diagnostic
* Practitioners can fully customize their Pranayama breath ratios (Puraka, Antar Kumbhaka, Rechaka, Bahya Kumbhaka) in `CycleComposerScreen` via an interactive bottom sheet or choose from classical presets (`1:0:1:0` to `1:4:2:2`).
* Integrated `BreathCapacityTestScreen` (Sopana Pariksha): a 1-minute guided breath exercise (3 centering breaths -> 1 deep inhale -> comfortable hold until first urge) to measure Comfortable Hold Time (CHT).
* The diagnostic maps CHT to the practitioner's apt Sopana level (<15s -> Level 1, 15-25s -> Level 2, 25-40s -> Level 3, 40-60s -> Level 4, 60s+ -> Level 5), calibrates their active rank in `ProgressionService`, and sets the safe hold cap (`CHT * 0.60`).

## Classical Pranayama & Dhyan Segregation and Authentic Pacing Mechanics
* **Strict Pranayama vs. Dhyan Segregation**: Pranayama techniques (breath control: Kapalbhati, Nadi Shodhana, Ujjayi, Bhramari, Bhastrika, Sheetali) are strictly isolated in the "Abhyas" tab. Meditation, Dharana, and Mantra practices (Naam Japa, Breath Awareness / Nostril Dhyan, Yoga Nidra) reside strictly in the "Dhyan" tab.
* **Kapalbhati Bahir Kumbhaka (External Hold)**: Following classical Hatha Yoga mechanics (*Gheranda Samhita*), each round of 30–50 rapid active strokes concludes with a complete exhalation into a **10s Bahir Kumbhaka (hold outside on empty lungs)** with *Maha Bandha* (Jalandhara & Uddiyana lock), followed by a slow *Puraka* release and natural breath recovery.
* **Ujjayi & Bhramari Antar Kumbhaka**: In advanced practice, both Ujjayi and Bhramari support an optional internal retention (*Antar Kumbhaka* of 4–8s) with *Jalandhara Bandha* / *Shanmukhi Mudra* brow focus before exhalation, accessible via an in-card toggle/stepper.
* **Dhyan Studio Redesign & 1-Tap Combined Flow**:
  - The oversized 190px manual mala touch disc was moved into an accessible modal sheet (`_openDigitalMalaSheet`), freeing up the screen for guided sadhanas.
  - Added the top 1-tap **"Complete Meditation Flow: 3-Stage Naam Japa ➔ Nostril Dhyan" (18 min)** combining audible/whisper Naam Japa (e.g. *Radha Radha*) to calm sensory ripples, smoothly transitioning into silent natural breath awareness at the nostril rims (*Nasagra Prana Dharana*).
  - Trataka and Antar Mouna are kept as quiet, unobtrusive classical dharana notes without distracting from primary meditation flows.
* **3-Phase Yogic Journey Progression**:
  - The 7 Sopana levels in `ProgressionService` are officially mapped to the classical 3-Phase developmental journey:
    - *Phase 1: Foundation (Weeks 1–4, Levels 1–2)*: Equal breath 4:4, extended exhalation 1:0:2:0, gentle Kapalbhati (30–45 strokes, no hold), silent So-Hum / Naam Japa, Nostril Breath Awareness (5–10m), Yoga Nidra (10–15m).
    - *Phase 2: Deepening (Weeks 5–12, Levels 3–4)*: Antar Kumbhaka 1:1:2:0 to 1:2:2:0, Kapalbhati with Bahir Kumbhaka, Ujjayi & Bhramari with internal hold, 108-bead Japa.
    - *Phase 3: Advanced (Month 4+, Levels 5–7)*: Classical 1:4:2:0 to 1:4:2:2 Kumbhaka ladders with Maha Bandha, Bhastrika, Surya/Chandra Bhedana, effortless Manasika repetition, extended 30–45m Yoga Nidra.





