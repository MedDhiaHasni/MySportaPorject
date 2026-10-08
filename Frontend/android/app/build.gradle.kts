// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.sporta"
    compileSdk = 36  // ✅ Changed from 34 to 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.sporta"
        minSdk = flutter.minSdkVersion  // ✅ Increased from 21 to 23 for better compatibility
        targetSdk = 36  // ✅ Updated to 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Add this for core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    implementation ("com.google.android.material:material:1.9.0")
    implementation ("androidx.appcompat:appcompat:1.6.1")
}
