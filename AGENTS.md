# AGENTS.md: Abhyas

Abhyas is a traditional Pranayama and Dhyan practice app for a closed pilot with yoga teachers. Full requirements are in `/docs/SRS.md`; screens and layout are in `/docs/UI_SPEC.md`. Read both before starting any task, and re-read the relevant sections for the task at hand.

## Non-negotiable rules

1. **Safety overrides everything.** Never weaken, bypass or "simplify" a safety rule (SRS section 7) for convenience, UX or speed. If a task seems to require it, stop and document the conflict in `docs/ASSUMPTIONS.md`.
2. **Safety is enforced in the engine and on the server, not only in the UI.** The UI only renders state from the engine and never computes holds, caps or locks itself.
3. **No hard-coded practice parameters.** Ratios, ladders, caps, gates, weaning rules and sequences come from versioned, schema-validated config (SRS section 8). Code may only contain *invariants* (e.g. bahya hold ≤ antar hold, caps must exist).
4. **Do not invent religious or spiritual content.** Never write Sanskrit text, mantra translations, doctrine, ritual instructions or health claims yourself. Use `[CONTENT PENDING – TEACHER REVIEW]` placeholders and the content manifest. Only `teacher_approved` content may appear in pilot builds.
5. **No competition mechanics.** No leaderboards, no comparison between users, no reward for hold length, no streak-loss messaging, no confetti or urgency copy.
6. **No third-party ad or tracking SDKs.** Health data is sensitive: encrypt, minimize, respect row-level security and consent.
7. **Do not ask clarifying questions.** Choose the simplest reasonable option, record it in `docs/ASSUMPTIONS.md` with the reason, and continue.

## Repo layout

```
/app        Flutter mobile app (iOS + Android), offline-first
  /lib/core      theme tokens, l10n, routing, haptics, audio, clock
  /lib/engine    player_engine (pure Dart), safety_rules, config_models
  /lib/features  onboarding, today, practice, dhyan, path, library, me
  /lib/widgets   shared components
  /lib/data      repositories, local DB, sync
/console    Teacher/Admin web app
/backend    Supabase migrations, RLS policies, seed data, edge functions
/content    manifest + placeholder content items
/docs       SRS.md, UI_SPEC.md, ARCHITECTURE.md, ASSUMPTIONS.md
/tests      cross-cutting and rule-matrix tests
```

## Setup

Dependencies are installed by the environment setup script (`/scripts/jules_setup.sh`). Do not re-run SDK installs inside tasks. If a tool is missing, note it in `docs/ASSUMPTIONS.md` rather than installing system-wide.

## Commands

```
cd app && flutter pub get
cd app && flutter analyze
cd app && flutter test
cd app && flutter test test/safety          # rule-matrix and property tests
cd console && npm ci && npm run lint && npm test && npm run build
cd backend && supabase db lint              # when the Supabase CLI is available
```

A task is not complete until `flutter analyze` and `flutter test` pass with no new warnings.

## Coding conventions

- Dart: null-safe, strict analysis (`analysis_options.yaml` with `strict-casts`, `strict-inference`, `strict-raw-types`). Prefer immutable models and pure functions.
- State management: Riverpod (record any change in ARCHITECTURE.md).
- The `engine` module must have **zero Flutter or platform dependencies** so it can be unit-tested and property-tested in isolation.
- Time: use a monotonic clock abstraction (injectable `Clock`) for all timers; tests must use a fake clock.
- All user-facing strings go through l10n files. Never inline strings.
- Colors, spacing and text styles come from design tokens only (UI_SPEC section 2).
- Every screen implements loading, empty, error, offline and (where relevant) locked states.
- Small, focused commits with clear messages. Keep PRs scoped to the task.

## Testing requirements

- **Safety rule matrix:** every health condition × every practice → expected allowed/blocked. Must be exhaustive and generated from the rule table.
- **Property tests:** for any config that passes validation, the player engine never schedules a hold above `min(level_cap, CHT × cap_fraction)`, and bahya hold never exceeds antar hold.
- **Config validator:** negative tests for each safety invariant.
- **Widget tests:** one per screen state listed in UI_SPEC.
- **Timing:** engine tests use a fake clock; assert phase boundaries and drift tolerance (< 50 ms per minute).

## Definition of done (every task)

1. Requirements referenced in the task are implemented (cite FR/SR IDs in the PR description).
2. All states and tokens rules above are respected.
3. Tests added and passing; analyze clean.
4. `docs/ASSUMPTIONS.md` updated for any decision made.
5. PR description lists: what was built, how it was tested, open questions for teacher review.

## Out of scope (do not build)

Public store release, payments, social features, leaderboards, secular mode, AI-generated spiritual content, Khechari or other guru-only techniques as trainable exercises, ratios above the teacher-set cap.
