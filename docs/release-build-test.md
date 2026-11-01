# Mobile Release Build & Compatibility Verification Report

**Repository:** `dut-pbl6-2026/job-platform-mobile`  
**Branch:** `feature/mobile-release-build-test`  
**Base Branch:** `origin/main` (commit `bf9c0bd`)  
**SRS Reference:** `MOB-01-08`, `PORT-01`, `PORT-02`, Master Plan Week 8  
**Date:** 2026-10-30  

---

## 1. Environment

| Property | Value | Notes |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.47.1` (Channel stable) | Dart `3.13.1` |
| **Dart SDK** | `3.13.1` | Modern Dart 3+ syntax |
| **Host Operating System** | Windows 11 Pro 64-bit (Build 26300) | Local development workstation |
| **Android SDK API Level** | Android 34 / 37.0 | `minSdk = 31` (Android 12+), `targetSdk = 36` |
| **Android Build Tools** | `36.0.0` | Android SDK Platform-Tools |
| **JDK Version** | OpenJDK 25.0.2 | Bundled with Android Studio (`jbr`) |
| **Android Gradle Plugin (AGP)** | `9.1.0` | Gradle `9.3.1` wrapper |
| **iOS Deployment Target** | iOS 16.0 (`IPHONEOS_DEPLOYMENT_TARGET = 16.0`) | Configured in `ios/Runner.xcodeproj` & `ios/Podfile` |

---

## 2. Build Results

| Verification Step | Command | Status | Result / Details |
| :--- | :--- | :---: | :--- |
| **Dependency Resolution** | `flutter pub get` | **PASS** | All dependencies resolved cleanly. |
| **Code Formatting** | `dart format --set-exit-if-changed .` | **PASS** | 114 files inspected, 0 changed. Formatted cleanly. |
| **Static Code Analysis** | `flutter analyze` | **PASS** | 0 warnings, 0 errors (`No issues found!`). |
| **Automated Test Suite** | `flutter test` | **PASS** | 124 of 124 unit and widget tests passed (`+124: All tests passed!`). |
| **Android Release APK** | `flutter build apk --release` | **PASS** | Output: `build/app/outputs/flutter-apk/app-release.apk`<br>Size: `59,615,873` bytes (~56.9 MB). |
| **Android Release App Bundle** | `flutter build appbundle --release` | **PASS** | Output: `build/app/outputs/bundle/release/app-release.aab`<br>Size: `57,654,694` bytes (~55.0 MB). |
| **iOS Release Build** | `flutter build ios --release --no-codesign` | **BLOCKED** | Host OS is Windows 11. iOS build requires macOS environment with Xcode and CocoaPods. Configuration verified (`IPHONEOS_DEPLOYMENT_TARGET = 16.0`). |

---

## 3. Release Smoke Test (Android 14 / API 34 Emulator)

Tested on local Android emulator `Pixel_API_34` (Android 14 / API 34, `x86_64`):

| Test Item | Status | Evidence / Observation |
| :--- | :---: | :--- |
| **APK Installation** | **PASS** | `adb install -r build/app/outputs/flutter-apk/app-release.apk` returned `Success`. |
| **Cold Startup** | **PASS** | Process started (`pid 3369`), Impeller OpenGLES engine initialized, Firebase native services registered. |
| **Login Screen Display** | **PASS** | Logo rendered cleanly, Vietnamese typography ("Chào mừng trở lại!"), and email/password form displayed without crash. |
| **Runtime Permissions** | **PASS** | Android 13+ `POST_NOTIFICATIONS` runtime permission dialog displayed correctly by Firebase Messaging. |
| **Login (Interactive)** | **BLOCKED** | Software-rendered headless emulator (swiftshader) high latency prevented reliable automated UI taps and interactive gateway auth flow. |
| **Registration** | **BLOCKED** | Blocked due to headless emulator UI interaction limitations. |
| **Session Restoration** | **BLOCKED** | Requires prior authenticated login session on device. |
| **Role-Based Navigation** | **BLOCKED** | Requires authenticated role session on device. |
| **Job Listing & Details** | **BLOCKED** | Requires authenticated session / interactive navigation on device. |
| **Search Flow** | **BLOCKED** | Requires interactive navigation. |
| **Application Flow** | **BLOCKED** | Requires interactive navigation. |
| **Profile Access** | **BLOCKED** | Requires interactive navigation. |
| **Logout** | **BLOCKED** | Requires authenticated session. |

---

## 4. Application Size Analysis

### 4.1 Artifact Sizes
- **Release APK (`app-release.apk`):** `59,615,873` bytes (**~56.85 MB**)
- **Release AAB (`app-release.aab`):** `57,654,694` bytes (**~54.98 MB**)

### 4.2 Asset & Dependency Breakdown
- Image assets (`assets/images/logo.jpg`): `230 KB` (optimized).
- Font assets: Google Fonts Roboto packaged for full Vietnamese Unicode support.
- Native shared libraries (`lib/`): Multi-ABI packaging (`arm64-v8a`, `armeabi-v7a`, `x86_64`) included inside single universal APK.
- Google Play Store Distribution: With Android App Bundle (AAB), Google Play generates device-specific split APKs, resulting in an end-user download size estimated between **~20 MB to ~25 MB**.

### 4.3 Optimization Opportunities
1. **Split-per-ABI APKs:** For non-store distribution, run `flutter build apk --split-per-abi` to produce individual APKs per architecture (~22 MB each).
2. **WebP Asset Compression:** Convert `.jpg` and `.png` assets to `.webp` format to reduce asset bundle size by ~30–40%.
3. **ProGuard / R8 Shrinking:** Configure explicit ProGuard rules for release shrinking in `android/app/proguard-rules.pro`.

---

## 5. Configuration Issues Encountered & Fixes Applied

During the release build audit and execution, several compatibility issues were identified and addressed in the Gradle build configuration:

1. **Java 8+ Core Library Desugaring (`android/app/build.gradle.kts`):**
   - *Issue:* Plugin `flutter_local_notifications` requires desugaring to support modern `java.time` APIs on older Android versions. Without it, `:app:checkReleaseAarMetadata` failed.
   - *Fix:* Added `isCoreLibraryDesugaringEnabled = true` under `compileOptions` and added `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` to `dependencies`.

2. **Kotlin Gradle Plugin with AGP 9.1 (`android/build.gradle.kts`):**
   - *Issue:* `file_picker` (11.0.3) conditionally skips applying `org.jetbrains.kotlin.android` when AGP >= 9, but `android.builtInKotlin=false` was configured, leading to uncompiled Kotlin classes and missing symbol errors in `GeneratedPluginRegistrant.java`.
   - *Fix:* Added a root `subprojects` configuration enforcing `org.jetbrains.kotlin.android` application for Android library subprojects.

3. **Windows Multi-Partition Cross-Drive Cache (`android/gradle.properties`):**
   - *Issue:* Building from drive `D:\` with pub cache on `C:\` triggered path comparison exceptions in Gradle / Kotlin compile daemon.
   - *Fix:* Set `kotlin.incremental=false` in `android/gradle.properties` and ran builds with local pub cache.

4. **JVM Target Validation (`android/gradle.properties`):**
   - *Issue:* JDK 25 environment caused a JVM target compatibility mismatch warning between Java 17 and Kotlin tasks in 3rd-party plugins.
   - *Fix:* Configured `kotlin.jvm.target.validation.mode=warning` in `android/gradle.properties`.

---

## 6. Summary & Recommendations

- **Android 12+ Release Builds:** **PASS** (Both APK and AAB build cleanly with zero errors and install on Android 14 API 34).
- **Static Analysis & Unit Tests:** **PASS** (100% clean analysis, 124/124 tests pass).
- **iOS Release Build:** **BLOCKED** (Windows environment limitation; requires macOS/Xcode for final IPA generation).
- **Interactive Smoke Testing:** **BLOCKED** (Headless swiftshader emulator performance limitations; basic cold startup and UI splash/login rendering confirmed **PASS**).
- **Next Steps:**
  - Execute iOS release build validation on macOS runner in CI/CD pipeline (`.github/workflows/ci.yml`).
  - Perform interactive E2E smoke tests on physical Android and iOS devices.
