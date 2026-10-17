# Abhyas

Abhyas is a traditional Pranayama and Dhyan practice app designed for a closed pilot reviewed by experienced yoga teachers.

## Setup and Testing Locally
The project uses Flutter for the mobile app, found in the `app` folder.

1. **Prerequisites**: Make sure you have the [Flutter SDK installed](https://docs.flutter.dev/get-started/install).
2. **Database/Backend**: For Phase 1 (current), no external database or backend connection is required to test the APK locally.
3. **Build the APK**:
    ```bash
    cd app
    flutter build apk
    ```
4. **Install on device**:
    - Locate the generated APK at `app/build/app/outputs/flutter-apk/app-release.apk`.
    - Install it on your device either via adb `adb install build/app/outputs/flutter-apk/app-release.apk` or by sending the file to your Android phone.
    - Since this is Phase 1 without database dependencies, it will work natively E2E to test any available offline-first interfaces or flows.

## Repository Structure
- `app/`: Flutter mobile app.
- `console/`: Teacher/Admin console (placeholder).
- `backend/`: Supabase or Firebase configurations (placeholder).
- `content/`: Static content like mantras and scripts.
- `docs/`: Technical documents (Architecture, Assumptions, etc.).
- `tests/`: End-to-end and integration tests outside the standard flutter testing scopes.

## Running Unit Tests
Unit tests for the rules engine, configuration schema, and player engine can be run directly:
```bash
cd app
flutter test
```