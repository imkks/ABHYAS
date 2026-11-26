import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("org.jetbrains.kotlin.plugin.compose")
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

val rawVersionCode = (project.findProperty("versionCode") as? String)
    ?: System.getenv("ANDROID_VERSION_CODE")
val resolvedVersionCode = rawVersionCode?.let {
    it.toIntOrNull()?.takeIf { code -> code > 0 }
        ?: throw GradleException("Invalid versionCode '$it': expected positive integer.")
} ?: 1

val resolvedVersionName = ((project.findProperty("versionName") as? String)
    ?: System.getenv("ANDROID_VERSION_NAME"))
    ?.takeIf { it.isNotBlank() }
    ?: "1.0.0"

android {
    namespace = "com.pranaflow.abhyas"
    compileSdk = 36

    defaultConfig {
        // Preserved Play Store applicationId for PranaFlow
        applicationId = "come.evertrail.pranaflow"
        minSdk = 26
        targetSdk = 36
        versionCode = resolvedVersionCode
        versionName = resolvedVersionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
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
            isMinifyEnabled = false
            signingConfig = if (hasCompleteUploadSigning) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(project(":engine"))

    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.activity:activity-compose:1.10.0")
    implementation("androidx.navigation:navigation-compose:2.8.5")

    implementation(platform("androidx.compose:compose-bom:2025.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")

    implementation("androidx.datastore:datastore-preferences-android:1.1.7")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.8.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.1")
    testImplementation("org.robolectric:robolectric:4.12.1")
    testImplementation("io.mockk:mockk:1.13.11")
}
