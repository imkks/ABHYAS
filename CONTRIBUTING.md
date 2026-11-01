# Contributing to Abhyas

Abhyas is a closed pilot being reviewed by yoga teachers. Contributions should support the pilot scope, preserve safety requirements, and avoid adding unreviewed religious or health content.

## Before you start

1. Read the relevant requirements in [docs/SRS.md](docs/SRS.md) and screen behavior in [docs/UI_SPEC.md](docs/UI_SPEC.md).
2. Read [AGENTS.md](AGENTS.md) for repository rules, safety invariants, and test expectations.
3. For architecture changes, review [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Record implementation decisions in [docs/ASSUMPTIONS.md](docs/ASSUMPTIONS.md).
4. Open an issue first for substantial changes so scope and teacher review can be agreed before implementation.

## Safety and content rules

- Never weaken or bypass a safety rule for speed or convenience.
- Keep safety enforcement in the practice engine and, when backend enforcement is available, on the server as well.
- Load practice parameters from validated configuration; code should hold invariants, not practice prescriptions.
- Do not add Sanskrit, mantras, translations, doctrine, ritual instructions, or health claims yourself. Use `[CONTENT PENDING – TEACHER REVIEW]` and update the content manifest for missing material.
- Only teacher-approved content may appear in a pilot build.
- Do not add leaderboards, user comparisons, hold-length rewards, ad SDKs, or third-party tracking SDKs.

## Development workflow

Keep changes focused and use a branch for each contribution. From the repository root, run the checks relevant to your change:

```sh
cd app
flutter pub get
flutter analyze
flutter test
flutter test test/safety_rules_engine_test.dart
```

The Android pull request workflow runs the mobile test suite and uploads a debug APK. A merge to `main` that changes `app/` runs the signed APK workflow; it requires the Android upload signing secrets and only uploads an artifact for manual Play Console submission.

Do not commit generated build output, local credentials, keystores, user health data, or unapproved practice content.

## Pull request checklist

- Explain the user need and the behavior changed.
- Cite the applicable FR/SR requirement IDs from `docs/SRS.md`.
- Describe how the change was checked and include relevant test results.
- Update `docs/ASSUMPTIONS.md` for decisions made where requirements are silent.
- List open questions or content that needs teacher review.
- Include screenshots for visible UI changes when practical.

There is no project license yet. Please discuss code reuse or redistribution with the project owner before relying on this repository as a licensed dependency.
