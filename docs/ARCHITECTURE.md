# Architecture

The system is designed with offline-first capabilities for mobile using Flutter, with decoupled internal layers to easily handle business logic, practice timers, and backend syncing later.

## High-Level Diagram

```mermaid
graph TD
    UI[Flutter UI Layer] --> Player[Player Engine]
    UI --> Safety[Safety Rules Engine]
    UI --> Config[Config Schema Validator]
    UI --> Panchang[Panchang & Muhurta Engine]

    Player --> StateMachine[Pacer State Machine]
    Player --> Timer[Timer / Stopwatch]

    Safety --> HealthFlags[Health Profiles & Flags]
    Safety --> Rules[Condition Matrices]

    Panchang --> SolarCalc[NOAA Solar Engine]
    Panchang --> LunarTithi[Lunar Ephemeris & 5 Limbs]
    Panchang --> Muhurtas[Brahma Muhurta & Kaalas]
    Panchang --> Svara[Shiva Svarodaya Breath Matrix]

    Config --> JSON[Local JSON Config Cache]
    JSON --> Backend[(Supabase Backend - Phase 2+)]
```

## Flutter Application Structure

```text
/app/lib
  /core        theme (tokens), l10n, routing, haptics, audio, clock
  /engine      player_engine (pure Dart), safety_rules, config_models, panchang
  /features
    /onboarding
    /today
    /panchang   (panchang_screen, muhurta cards, tithi banners)
    /practice   (list, preflight, player, checkin, cycle_composer)
    /dhyan      (mala, nidra)
    /path       (path_map, level_detail, unlock_request)
    /library
    /me         (progress, health, weaning, settings)
  /widgets     shared components
  /data        repositories, local db (offline), sync
```

## Layers

1. **Engine Layer** (`app/lib/engine`)
    - **Config Schema Validator**: Validates incoming remote configurations against our predefined schema.
    - **Safety Rules Engine**: Evaluates the user's current health screening flags (e.g., pregnancy, hypertension) and decides if a practice can be unlocked. Includes rule-matrix unit tests.
    - **Player Engine**: Manages practice session states and computes maximum allowed durations for breath holds using the logic: `min(level_cap, user_CHT * hold_cap_fraction)`.
    - **Panchang & Muhurta Engine**: Pure Dart offline astronomical and Vedic calculation engine. Computes exact Solar Sunrise/Sunset/Noon (NOAA algorithm), the 5 Limbs (Tithi, Vara, Nakshatra, Yoga, Karana), sacred windows (Brahma Muhurta, Abhijit, Trisandhya), caution periods (Rahu Kalam, Yama Gandam, Gulika Kalam), Day/Night Choghadiyas, and Svara Yoga (Shiva Svarodaya) breath recommendations.

2. **Features Layer** (`app/lib/features`)
    - Contains all the UI screens decoupled by domain (e.g., dhyan, practice, onboarding). The UI layer **only renders state from the engine**; it never computes holds, caps, or locks itself.

3. **Widgets Layer** (`app/lib/widgets`)
    - Reusable, stateless UI components implementing the Design Tokens. Examples: `StopButton`, `PhasePill`, `LockBadge`.

4. **Offline Storage & Backend** (`app/lib/data`)
    - Caches configurations, synced states, and session logs locally (e.g. `shared_preferences`, SQLite), uploading when the network resumes.
