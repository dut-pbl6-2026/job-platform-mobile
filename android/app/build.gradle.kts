import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing comes from environment variables (CI) or android/key.properties
// (local, gitignored). Each value is read from the environment first.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun releaseSigningValue(envName: String, propertyName: String): String? =
    System.getenv(envName)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(propertyName)?.takeIf { it.isNotBlank() }

val releaseStoreFilePath = releaseSigningValue("ANDROID_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = releaseSigningValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = releaseSigningValue("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = releaseSigningValue("ANDROID_KEY_PASSWORD", "keyPassword")

// Names only, never values, so the failure message is safe to print.
val missingReleaseSigningInputs = buildList {
    if (releaseStoreFilePath == null) add("ANDROID_KEYSTORE_PATH (storeFile)")
    if (releaseStorePassword == null) add("ANDROID_KEYSTORE_PASSWORD (storePassword)")
    if (releaseKeyAlias == null) add("ANDROID_KEY_ALIAS (keyAlias)")
    if (releaseKeyPassword == null) add("ANDROID_KEY_PASSWORD (keyPassword)")
}
val releaseSigningReady = missingReleaseSigningInputs.isEmpty() &&
    rootProject.file(releaseStoreFilePath!!).exists()

android {
    namespace = "com.dutpbl6.job_platform_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // The Kotlin Gradle plugin bundled with the pinned Flutter SDK (2.1.0) sets
    // jvmTarget through `kotlinOptions`; the top-level `kotlin {}` block used by
    // KGP 2.4 is not available there.
    @Suppress("DEPRECATION")
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dutpbl6.job_platform_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 31 // Android 12+ (SRS 7.2.2)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    // Missing values leave the config incomplete, so release packaging fails
    // instead of falling back to the debug key.
    signingConfigs {
        create("release") {
            if (releaseSigningReady) {
                storeFile = rootProject.file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

private val releasePackagingPrefixes = listOf("assemble", "bundle", "install", "package")

// Fail release packaging up front when release signing is not configured,
// instead of producing an unsigned artifact.
gradle.taskGraph.whenReady {
    val releasePackagingRequested = allTasks.any { task ->
        task.project == project &&
            task.name.endsWith("Release") &&
            releasePackagingPrefixes.any { task.name.startsWith(it) }
    }
    if (releasePackagingRequested && !releaseSigningReady) {
        val missing = missingReleaseSigningInputs.ifEmpty {
            listOf("keystore file not found at the configured storeFile")
        }
        throw GradleException(
            "Release signing is not configured. Provide a release keystore through " +
                "environment variables or android/key.properties. Missing: " +
                missing.joinToString(", ") + ". Debug builds do not need these values."
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
