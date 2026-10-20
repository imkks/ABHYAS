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
