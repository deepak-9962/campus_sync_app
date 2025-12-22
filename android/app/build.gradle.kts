plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.campus_sync_app"
    compileSdk = 36

    // Add the NDK version here
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.campus_sync_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Updated to 21 to support PDFView
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Add configurations to handle missing plugins
    configurations.all {
        resolutionStrategy {
            force("com.aboutyou.dart_packages:sign_in_with_apple:0.0.0")
            // Force kotlin stdlib and metadata to match our kotlin version
            force("org.jetbrains.kotlin:kotlin-stdlib:2.0.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.0.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.0.0")
            force("org.jetbrains.kotlin:kotlin-reflect:2.0.0")
            // Force a specific version of the Kotlin metadata that matches 2.0.0
            force("org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0")
            
            // Exclude problematic modules
            exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jre7")
            exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jre8")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Use an older version of Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:31.5.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
