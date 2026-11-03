# Google Play Store Publishing Guide for PranaFlow

This guide provides end-to-end instructions for releasing the **PranaFlow** mobile app to the Google Play Store, including setting up automated CI/CD builds, repository secrets, triggering the manual release workflow, and ready-to-use answers for every Google Play Console questionnaire and policy declaration.

---

## Table of Contents

1. [Prerequisites & Repository Secrets Setup](#1-prerequisites--repository-secrets-setup)
2. [Triggering the Release Workflow (Manual Dispatch)](#2-triggering-the-release-workflow-manual-dispatch)
3. [Downloading the Signed Bundle (.aab)](#3-downloading-the-signed-bundle-aab)
4. [Google Play Console Initial Setup](#4-google-play-console-initial-setup)
5. [Complete Answers to Play Console Questionnaires](#5-complete-answers-to-play-console-questionnaires)
   - [Privacy Policy](#51-privacy-policy)
   - [App Access](#52-app-access)
   - [Ads](#53-ads)
   - [Content Rating (IARC)](#54-content-rating-iarc)
   - [Target Audience & Content](#55-target-audience--content)
   - [News Apps](#56-news-apps)
   - [COVID-19 Contact Tracing](#57-covid-19-contact-tracing)
   - [Data Safety Section](#58-data-safety-section)
   - [Health Apps Declaration](#59-health-apps-declaration)
   - [Financial Features Declaration](#510-financial-features-declaration)
   - [Government Apps](#511-government-apps)
   - [Foreground Service & Location Permissions Declarations](#512-foreground-service--location-permissions-declarations)
6. [Store Listing Metadata & Copy](#6-store-listing-metadata--copy)
7. [Uploading the AAB & Publishing Tracks](#7-uploading-the-aab--publishing-tracks)
8. [Troubleshooting & FAQs](#8-troubleshooting--faqs)

---

## 1. Prerequisites & Repository Secrets Setup

### 1.1 Application Package Name
The app package ID in `app/android/app/build.gradle.kts` is set to:
```kotlin
applicationId = "come.evertrail.pranaflow"
```
> [!NOTE]
> If your Google Play Console app was registered as `com.evertrail.pranaflow` (with `com` instead of `come`), you can simply adjust `applicationId = "com.evertrail.pranaflow"` in `app/android/app/build.gradle.kts`.

### 1.2 GitHub Actions Secrets
The GitHub Actions workflow requires 4 secrets to sign the Android App Bundle (`.aab`):

| Secret Name | Description | Example / Source |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded string of your `.jks` file | `cat abhyas-upload.jks \| base64` |
| `ANDROID_KEY_ALIAS` | Alias name chosen when generating key | e.g. `upload` or `abhyas` |
| `ANDROID_KEY_PASSWORD` | Password for the key alias | Keystore key password |
| `ANDROID_STORE_PASSWORD`| Password for the keystore file | Keystore store password |

#### How to encode the keystore on your machine:
- **macOS**:
  ```bash
  base64 -i abhyas-upload.jks | pbcopy
  # The base64 string is now copied to your clipboard!
  ```
- **Linux**:
  ```bash
  base64 -w 0 abhyas-upload.jks | xclip -selection clipboard
  # Or output to terminal:
  base64 -w 0 abhyas-upload.jks
  ```
- **Windows (PowerShell)**:
  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("abhyas-upload.jks")) | Set-Clipboard
  ```

#### Adding secrets in GitHub:
1. Open your repository on GitHub.
2. Click **Settings** (top tab) ➔ **Secrets and variables** (left sidebar) ➔ **Actions**.
3. Click **New repository secret** for each of the 4 secrets listed above.

---

## 2. Triggering the Release Workflow (Manual Dispatch)

The release workflow is defined at [`.github/workflows/release-bundle.yml`](../.github/workflows/release-bundle.yml). It supports manual trigger with custom version names and numbers.

### Steps to Run:
1. On GitHub, navigate to the **Actions** tab of your repository.
2. Under the left sidebar, click on **Release Android App Bundle (.aab)**.
3. Click the **Run workflow** dropdown button on the right side.
4. Fill in the two parameters:
   - **Version Name**: e.g., `1.0.0` (Semantic version visible to users in Google Play).
   - **Version Code / Build Number**: e.g., `1` (Strictly an increasing integer. E.g. `1`, `2`, `3`... Each upload to Google Play must have a higher number than the previous one).
5. Click the green **Run workflow** button.

The workflow will:
- Check out the repository.
- Verify Flutter and Java environments.
- Validate that all 4 signing secrets exist.
- Run unit & safety rule matrix tests.
- Execute `flutter build appbundle --release --build-name="<version_name>" --build-number="<version_code>"`.
- Cryptographically verify the signature with `jarsigner`.
- Stage the artifact with SHA256 checksum generation.
- Upload the signed `.aab` bundle to GitHub Actions Artifacts.

---

## 3. Downloading the Signed Bundle (.aab)

1. When the workflow run completes (typically within 3–4 minutes), click on the completed run.
2. Scroll down to the **Artifacts** section at the bottom of the Summary page.
3. Click on the artifact named:
   `abhyas-v<version_name>+<version_code>-bundle` (e.g. `abhyas-v1.0.0+1-bundle`).
4. A `.zip` archive containing `abhyas-v1.0.0+1.aab` and its `.sha256` checksum will download to your computer.
5. Unzip the archive. The extracted `.aab` file is the final signed binary ready for upload to Google Play Console.

---

## 4. Google Play Console Initial Setup

1. Open [Google Play Console](https://play.google.com/console).
2. Sign in with your Google Play Developer Account.
3. Click **Create app** (top-right).
4. Enter the initial details:
   - **App name**: `PranaFlow` (or `PranaFlow: Pranayama & Dhyan`)
   - **Default language**: `English (United States) – en-US` (or `English (India) – en-IN`)
   - **App or game**: Select `App`
   - **Free or paid**: Select `Free`
5. Check the declarations:
   - Accept **Developer Program Policies**.
   - Accept **US export laws**.
6. Click **Create app**.

---

## 5. Complete Answers to Play Console Questionnaires

Under the left menu, scroll down to **Policy and programs** ➔ **App content**. You must complete each required task. Use the exact answers below:

### 5.1 Privacy Policy
* **Requirement**: Google requires an accessible public HTTPS URL containing the app's privacy policy.
* **Privacy Policy URL**: Host the policy on GitHub Pages or your domain (e.g., `https://<your-username>.github.io/ABHYAS/privacy.html`).
* **Privacy Policy Content Template**:
```markdown
# Privacy Policy for PranaFlow

Effective Date: November 2026

PranaFlow ("we", "our", or "the app") is committed to respecting and protecting your privacy. This privacy policy explains our practices regarding user information.

1. Offline-First Architecture
PranaFlow operates primarily offline. All your pranayama logs, comfortable hold time (CHT) diagnostics, meditation japa counts, and calmness reflection scores are stored locally on your device in secure local application storage. We do not transmit or store your personal health and meditation data on external cloud servers without explicit user initiation.

2. Location Data
The app requests access to coarse and fine location (ACCESS_COARSE_LOCATION, ACCESS_FINE_LOCATION) solely to calculate the exact astronomical sunrise and Brahma Muhurta (auspicious dawn meditation hours) based on your geographic coordinates. This calculation occurs entirely offline on your device. Your location coordinates are never logged, tracked, transmitted to remote servers, or shared with third parties.

3. Background Audio & Foreground Service
The app utilizes a foreground service (FOREGROUND_SERVICE_MEDIA_PLAYBACK) with a wake lock to play acoustic breath chimes, bells, and timing cues while the screen is locked or turned off during meditation sessions. No audio or microphone input is recorded.

4. Third-Party Tracking and Analytics
PranaFlow contains NO commercial advertising SDKs, NO tracking beacons, and NO behavioral analytics engines. We do not sell, rent, or share personal data with data brokers or ad networks.

5. Data Deletion
Since all personal sadhana records reside on your local device, you can delete all stored records at any time by selecting "Clear Data" inside the app settings or by clearing the app's storage via Android Settings.

6. Contact
For any questions regarding this policy, contact us at: support@evertrail.com
```

---

### 5.2 App Access
* **Question**: Is any part of your app restricted by credentials, two-factor authentication, or paywalls?
* **Answer**: Select **"All functionality is available without special access"**.
* *(Explanation: PranaFlow opens directly into the home screen with open-access practice modules and does not lock core features behind a login wall).*

---

### 5.3 Ads
* **Question**: Does your app contain ads?
* **Answer**: Select **"No, my app does not contain ads"**.

---

### 5.4 Content Rating (IARC)
Click **Start questionnaire**:
1. **Email address**: Enter your developer contact email.
2. **Category**: Select **Consumer / Utility / Productivity / Health & Fitness / Other**.
3. **Questionnaire responses**:
   - Violence: **No**
   - Sexuality: **No**
   - Language / Profanity: **No**
   - Controlled Substances (alcohol, tobacco, drugs): **No**
   - Miscellaneous:
     - Does the app natively allow users to interact or exchange content with other users through voice, text, or sharing photos? ➔ **No**
     - Does the app share the user’s current and precise physical location with other users? ➔ **No**
     - Does the app allow users to purchase digital goods? ➔ **No**
     - Does the app contain web browsing capabilities (open browser)? ➔ **No**
     - Is the app primarily a news or educational product? ➔ **No**
4. Click **Save** ➔ **Next** ➔ **Submit**.
5. Expected rating: **PEGI 3 / Everyone / USK 0**.

---

### 5.5 Target Audience & Content
1. **Target age groups**:
   - Check **18 and over** (and optionally **13–17**).
2. **Appeal to children**:
   - Question: *Could your store listing unintentionally appeal to children under 13?*
   - Answer: **No**.
3. Click **Save**.

---

### 5.6 News Apps
* **Question**: Is your app a news app?
* **Answer**: Select **"No"**.

---

### 5.7 COVID-19 Contact Tracing
* **Question**: Is your app a COVID-19 contact tracing or status app?
* **Answer**: Select **"My app is not a publicly available COVID-19 contact tracing or status app"**.

---

### 5.8 Data Safety Section
Google Play requires developers to complete the Data Safety declaration:

1. **Data collection and security**:
   - *Does your app collect or share any of the required user data types?*
     - If you operate strictly offline with no server sync: Select **No** (data processed ephemerally on-device without remote collection).
     - *Alternative (if Google flags permissions):* Select **Yes**, then specify:
       - **Location (Approximate & Precise)**:
         - Collected: **No** (Processed ephemerally on-device only).
         - Shared: **No**.
         - Purpose: **App functionality** (Calculating astronomical sunrise and Brahma Muhurta timings).
       - **Health and fitness**:
         - Collected: **No** (Stored locally on-device).
         - Shared: **No**.
         - Purpose: **App functionality** (Tracking personal sadhana progress and breath capacity).
2. **Security practices**:
   - *Is data encrypted in transit?* ➔ Select **Yes** (or N/A if no network transmission).
   - *Do you provide a way for users to request that their data be deleted?* ➔ Select **Yes** (users can clear app data in settings).

---

### 5.9 Health Apps Declaration
*(Google Play Health Apps Policy requirement)*:
1. **Health app category**:
   - Check **Health and fitness**.
2. **Select applicable health features**:
   - Check **Stress management and relaxation**.
   - Check **Physical activity and breathing tracking**.
3. **Medical device declaration**:
   - *Is your app a regulated medical device or does it offer clinical diagnosis / medical treatment?*
   - Select **No**.
   - Reviewer Note / Disclaimer:
     > *"PranaFlow is a traditional wellness, pranayama breath pacing, and meditation aid. It does not provide medical diagnosis, treatment, or clinical health advice. All practices are non-medical wellness exercises rooted in classical yoga."*

---

### 5.10 Financial Features Declaration
* **Question**: Does your app provide financial features (banking, cryptocurrency, loans, etc.)?
* **Answer**: Select **"My app doesn't provide any financial features"**.

---

### 5.11 Government Apps
* **Question**: Is your app developed by or on behalf of a government entity?
* **Answer**: Select **"No"**.

---

### 5.12 Foreground Service & Location Permissions Declarations

In `AndroidManifest.xml`, PranaFlow declares:
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

#### Foreground Service (mediaPlayback) Justification:
When asked by Google Console to justify the foreground service:
- **Foreground service type**: `mediaPlayback`
- **User-facing reason to copy & paste for Google Reviewers**:
  > *"PranaFlow is a meditation and pranayama breath-pacing companion. Sadhanas run for 10 to 60 minutes, during which users lock their screen or place their device face down on a mat. The foreground service with mediaPlayback type plays continuous acoustic cue bells, chimes, and breath interval audio so practitioners can maintain their breathing cycles with their screen turned off."*
- **Video link**: Google may ask for a link to a short (30-second) unlisted YouTube video showing the app playing breathing chimes while the screen is off or in background.

#### Location Permission Justification:
- **Reason to copy & paste for Google Reviewers**:
  > *"Location permissions (ACCESS_COARSE_LOCATION, ACCESS_FINE_LOCATION) are used exclusively on-device to compute local sunrise times and astronomical Brahma Muhurta (auspicious dawn meditation hours). Location data is processed ephemerally on the client, is never saved remotely, and is never shared with third parties."*

---

## 6. Store Listing Metadata & Copy

Under **Grow** ➔ **Store presence** ➔ **Main store listing**:

### 6.1 App Details
* **App Name** (max 30 chars):
  `PranaFlow` (or `PranaFlow: Pranayama & Dhyan`)
* **Short Description** (max 80 chars):
  `Authentic classical Pranayama, breath retention, and meditation sadhana.`
* **Full Description** (max 4000 chars):
```markdown
PranaFlow (प्राण प्रवाह) is an authentic, sacred companion for classical Pranayama (breathwork) and Dhyan (meditation) sadhana.

Designed with reverence to traditional yogic scriptures (Hatha Yoga Pradipika, Gheranda Samhita, Patanjali Yoga Sutras), PranaFlow provides structured breath pacing, safe retention ladders, and silent meditation tools free from commercial distractions.

KEY PRACTICES & FEATURES:

• Classical Pranayama Engine:
  Step-by-step guided pacing for Kapalbhati (with empty-lung Bahir Kumbhaka), Nadi Shodhana (4-phase alternate nostril retention), Ujjayi (Ocean breath), Bhramari (Humming bee breath), and Sheetali.

• 1-Minute Breath Capacity Diagnostic (CHT):
  Measure your Comfortable Hold Time safely. The diagnostic dynamically calibrates your breath ratio ladders (1:1, 1:2, 1:4:2, 1:4:2:2) to ensure you never strain or force Kumbhaka.

• Guided Routines for Dawn & Dusk:
  - Surya Sadhana: Dynamic morning vitality routine (Invoking mantras, Kapalbhati, Nadi Shodhana, Breath Awareness).
  - Chandra Sadhana: Restorative evening routine (Bhramari, Naam Jaap, guided Yoga Nidra).

• Digital Mala & Sacred Naam Japa:
  Smooth tactile bead counting (27, 54, 108 beads) with subtle haptic feedback for your daily Japa sadhana.

• Brahma Muhurta Dawn Calculation:
  Calculates local astronomical dawn hours offline based on your location so you can practice during the most tranquil time of day.

• Offline-First & Private:
  Zero advertisements. Zero social vanity metrics. Zero third-party tracking. All your sadhana history remains securely on your device.

Begin your daily sadhana with clarity, stillness, and breath.
```

### 6.2 Graphic Assets Requirements
* **App Icon**: 512 x 512 px, 32-bit PNG with alpha channel (max 1 MB). Ready-to-upload icon generated at `app/assets/icon/playstore_icon_512.png`.
* **Feature Graphic**: 1024 x 500 px, JPG or 24-bit PNG (no alpha, max 15 MB).
* **Phone Screenshots**: Minimum 2 screenshots (16:9 or 9:16 aspect ratio, between 320 px and 3840 px).
* **Category**: Health & Fitness.
* **Tags**: Meditation, Yoga, Breathing exercises, Health, Mindfulness.

---

## 7. Uploading the AAB & Publishing Tracks

Google Play offers several release tracks:

| Track | Purpose | Requirements |
|---|---|---|
| **Internal Testing** | Immediate sharing with up to 100 internal testers (team & teachers) | No review wait time; available within minutes. |
| **Closed Testing** | Required for personal developer accounts created after Nov 13, 2023 | Must test with at least 20 opted-in testers for 14 continuous days before applying for Production. |
| **Open Testing / Production** | Publicly accessible on Google Play | Full policy review by Google. |

### Steps to Upload:
1. In Google Play Console, go to **Testing** ➔ **Internal testing** (or **Closed testing** / **Production**).
2. Click **Create new release** (top right).
3. Under **App bundles**, click **Upload** and select the unzipped `pranaflow-v<version_name>+<version_code>.aab` file.
4. Google Play will inspect the bundle, verify the signature, and automatically extract:
   - Package name (`come.evertrail.pranaflow`)
   - Version name (e.g., `1.0.0`)
   - Version code (e.g., `1`)
   - Target SDK & permissions
5. **Release name**: Automatically set to your version (e.g., `1.0.0 (1)`).
6. **Release notes**: Add release notes (e.g.):
```
<en-US>
Initial release of PranaFlow.
- Classical Pranayama breath pacing (Kapalbhati, Nadi Shodhana, Ujjayi, Bhramari).
- 1-minute Comfortable Hold Time (CHT) breath capacity diagnostic.
- Morning Surya and Evening Chandra routines.
- Digital Mala with haptic bead counting.
- Offline Brahma Muhurta dawn calculation.
</en-US>
```
7. Click **Next** ➔ **Save** ➔ **Review release**.
8. Resolve any warnings (informational warnings regarding ProGuard/deobfuscation mapping files can be uploaded from `app/build/app/outputs/mapping/release/mapping.txt` if enabled, or skipped).
9. Click **Start rollout**!

---

## 8. Troubleshooting & FAQs

### Q: Why does Google Play reject an upload with "package name com.example.abhyas"?
**A**: Google Play strictly bans `com.example.*`. We have configured `applicationId = "com.abhyas.app"` in `app/android/app/build.gradle.kts`. Ensure you are building from the latest commit.

### Q: Why does the workflow fail with "Missing required repository secret(s)"?
**A**: Ensure you added all 4 secrets in GitHub Repository Settings ➔ Secrets and variables ➔ Actions:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

### Q: Can I install the downloaded `.aab` file directly on my phone?
**A**: No. Android devices only install `.apk` files directly. `.aab` (Android App Bundle) is the packaging format Google Play uses to generate optimized device-specific APKs. To test an APK directly on your device, use the `build-apk` or `release-apk` workflows, or upload the `.aab` to Google Play's **Internal Testing** track, which generates an installable link for your testers.

### Q: What version number should I use for subsequent updates?
**A**:
- `version_name` can be any semantic version (e.g., `1.0.1`, `1.1.0`, `2.0.0`).
- `version_code` **must always strictly increment** by at least 1 (e.g. `2`, `3`, `4`). Google Play will reject an upload with a `version_code` equal to or lower than any previous release.
