# Abhyas

**A teacher-reviewed Pranayama and Dhyan practice companion for a closed pilot.**

Abhyas is being built to help practitioners follow a steady daily practice with paced guidance, session audio, and a clear return-to-natural-breath control. Its longer-term aim is to help practitioners become less dependent on app guidance over time. This project is a pilot prototype, not a medical product or a public release.

## Why this project may help

Guided breath and meditation sessions can be difficult to follow consistently without a teacher beside you. Abhyas brings practice cues and a configurable routine into one mobile app, while keeping teacher review and safety rules central to the design. Practice content and parameters are subject to teacher review; the app does not diagnose or treat health conditions.

## Project status

- Closed pilot prototype; not ready for public release.
- Flutter mobile app for Android and iOS.
- Practice logic, safety rules, configuration validation, routine sequencing, and Panchang calculations live in `app/lib/engine/`.
- The teacher web console is paused and currently shows a temporary-unavailable page. Its CI and GitHub Pages deployment workflows are disabled.
- No production backend is configured in this repository yet; current development focuses on local app flows.
- Religious and instructional content must be teacher supplied and approved before appearing in a pilot build.

## Try the mobile app locally

### Requirements

- Flutter SDK with a Dart version compatible with [`app/pubspec.yaml`](app/pubspec.yaml).
- Android Studio and an Android emulator, or a USB-connected Android device with developer mode enabled.
- For iOS, macOS with Xcode and an iOS Simulator or connected iPhone.

### Run on Android

```sh
cd app
flutter pub get
flutter devices
flutter run -d <device-id>
```

`flutter run` launches a debug build. Replace `<device-id>` with an ID printed by `flutter devices`. To build a debug APK instead:

```sh
cd app
flutter build apk --debug
```

The APK is written to `app/build/app/outputs/flutter-apk/app-debug.apk`.

### Run on iOS

On macOS with Xcode installed:

```sh
cd app
flutter pub get
open -a Simulator
flutter devices
flutter run -d <device-id>
```

## Checks for contributors

Run these from the repository root when changing the mobile app:

```sh
cd app
flutter analyze
flutter test
flutter test test/safety_rules_engine_test.dart
```

The safety test command is especially important for changes to practice eligibility, hold limits, progression, or configuration validation. See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Signed Android release artifacts & Play Store Publishing

- **Signed Android App Bundle (.aab)**: For publishing to the Google Play Store, trigger [`.github/workflows/release-bundle.yml`](.github/workflows/release-bundle.yml) manually via GitHub Actions with your desired `version_name` and `version_code`. The workflow tests, builds, signs, and outputs an `.aab` file ready for download and upload to Google Play Console.
- **Signed APK**: Merges to `main` also build a signed release `.apk` via [`.github/workflows/release-apk.yml`](.github/workflows/release-apk.yml) for direct sideloading or internal manual distribution.
- **Publishing & Questionnaire Guide**: Complete step-by-step instructions and ready-to-use answers for all Google Play Console questionnaires (Data Safety, Content Rating, Health Declarations, Foreground Services, etc.) can be found in [`docs/PLAYSTORE_PUBLISHING_GUIDE.md`](docs/PLAYSTORE_PUBLISHING_GUIDE.md).

Both release workflows require repository secrets named `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, and `ANDROID_STORE_PASSWORD`. Never commit a keystore or signing password.

## Repository map

| Path | What it contains |
| --- | --- |
| [`app/`](app/) | Flutter mobile app, tests, Android and iOS projects, bundled audio |
| [`app/lib/engine/`](app/lib/engine/) | UI-independent practice, safety, configuration, and calculation logic |
| [`console/`](console/) | Paused teacher/admin web console |
| [`content/`](content/) | Content manifest and teacher-review placeholders |
| [`docs/SRS.md`](docs/SRS.md) | Product and functional requirements, including safety requirements |
| [`docs/UI_SPEC.md`](docs/UI_SPEC.md) | Screen layouts, interaction behavior, and design tokens |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Current app architecture and module responsibilities |
| [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) | Decisions and known implementation assumptions |
| [`CONTENT_REQUIREMENTS.md`](CONTENT_REQUIREMENTS.md) | Audio and content asset requirements |
| [`AGENTS.md`](AGENTS.md) | Repository-specific instructions for coding agents |

## Safety and content principles

- Safety rules take priority over convenience and must be enforced in the engine (and server when one is added), not only in widgets.
- Practice ratios, caps, ladders, and sequences belong in validated configuration rather than hard-coded logic.
- Do not invent mantras, translations, religious instruction, or health claims. Use the content manifest and teacher-review process.
- This app does not replace medical advice or qualified instruction. Pilot users should follow their teacher's guidance and consult a physician about health concerns.

## License

No license has been added yet. Until the project owner chooses one, the repository does not grant permission to reuse or redistribute the code. See [CONTRIBUTING.md](CONTRIBUTING.md) for the current contribution process.
