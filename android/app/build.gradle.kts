import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val requireReleaseSigning =
    providers.gradleProperty("requireReleaseSigning").orNull == "true"

if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword").forEach { key ->
        if (keystoreProperties.getProperty(key).isNullOrBlank()) {
            throw GradleException("Missing Android release signing property: $key")
        }
    }

    val configuredStoreFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
    if (!configuredStoreFile.isFile) {
        throw GradleException(
            "Configured Android release keystore does not exist: ${configuredStoreFile.path}",
        )
    }
}

if (requireReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is required for Play delivery, but android/key.properties is missing.",
    )
}

android {
    namespace = "com.camperboss.camperboss"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.camperboss.camperboss"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Play delivery sets -PrequireReleaseSigning=true and hard-fails
            // without the upload key. The debug signing fallback is QA-only.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
