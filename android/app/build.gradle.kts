import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val defaultAndroidTestAppId = "ca-app-pub-3940256099942544~3347511713"
val androidAdmobAppId = System.getenv("ADMOB_ANDROID_APP_ID") ?: defaultAndroidTestAppId
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val hasReleaseSigning = keystorePropertiesFile.exists() &&
    keystoreProperties.containsKey("storeFile") &&
    keystoreProperties.containsKey("storePassword") &&
    keystoreProperties.containsKey("keyAlias") &&
    keystoreProperties.containsKey("keyPassword")

android {
    namespace = "com.example.smoke_timer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (uses Java 8+ APIs on older Android).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smoke_timer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AdMob app ID is environment-driven for secure release configuration.
        manifestPlaceholders["admobAppId"] = androidAdmobAppId
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use explicit release signing only when key.properties is configured.
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Keep in sync with AGP; this enables Java 8+ language APIs (e.g., java.time) on old devices.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
