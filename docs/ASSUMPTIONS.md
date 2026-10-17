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

## CI/CD
* We build `apk` using `ubuntu-latest` inside Github Actions.

## Backend
* Local testing of APK doesn't require backend interaction right now since Phase 1 includes no backend features. We will mock everything needed to run.
