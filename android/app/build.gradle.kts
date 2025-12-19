import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
   // namespace = "com.cotodel.cotopay.flutterproject"
    namespace = "com.cotodel.cotopay.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cotodel.cotopay.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        defaultConfig {
            ndk {
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
            }
        }

//        ndk {
//            abiFilters.clear()
//            abiFilters += listOf("arm64-v8a")
//        }
    }


//
//    // ✅ Exclude all other ABIs
//    packaging {
//        jniLibs {
//            excludes += listOf(
//                "**/armeabi-v7a/**",
//                "**/x86/**",
//                "**/x86_64/**"
//            )
//        }
//    }

    // ✅ Ensure bundle does not split ABIs
    bundle {
        abi {
            enableSplit = false
        }
    }




    signingConfigs {
        create("release") {

            val keystoreProperties = Properties()
            val keystorePropertiesFile = rootProject.file("key.properties")

            if (!keystorePropertiesFile.exists()) {
                throw GradleException("❌ key.properties not found")
            }

            keystoreProperties.load(FileInputStream(keystorePropertiesFile))

            storeFile = rootProject.file(
                keystoreProperties["storeFile"] as String
            )
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
