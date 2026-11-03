plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadStoreFile = System.getenv("ANDROID_KEYSTORE_PATH")
val uploadStorePassword = System.getenv("ANDROID_STORE_PASSWORD")
val uploadKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
val uploadKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")
val uploadSigningValues = listOf(
    uploadStoreFile,
    uploadStorePassword,
    uploadKeyAlias,
    uploadKeyPassword,
)
val hasAnyUploadSigningValue = uploadSigningValues.any { !it.isNullOrBlank() }
val hasCompleteUploadSigning = uploadSigningValues.all { !it.isNullOrBlank() }

if (hasAnyUploadSigningValue && !hasCompleteUploadSigning) {
    throw GradleException("Android upload signing requires all keystore environment variables.")
}

android {
    namespace = "com.example.abhyas"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion is commented out to prevent AGP from attempting to download
    // unneeded NDK packages via sdkmanager in CI environments.
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID / package name for PranaFlow on Google Play
        applicationId = "come.evertrail.pranaflow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCompleteUploadSigning) {
            create("upload") {
                storeFile = file(uploadStoreFile!!)
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // The main-branch workflow supplies upload credentials; local releases
            // remain usable with the debug key.
            signingConfig = if (hasCompleteUploadSigning) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
