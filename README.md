# Job Platform Mobile

A cross-platform mobile application for job search and recruitment, built with **Flutter**. The project belongs to the **Vietnam Job Platform** (`pbl6`) ecosystem of the [`dut-pbl6-2026`](https://github.com/dut-pbl6-2026) organization.

---

## 📋 System Requirements

To run this project, you need to install and configure the following tools:

- **Flutter SDK**: Stable version.
- **IDE**: Visual Studio Code or Android Studio with the Flutter & Dart plugins.
- **Android**:
  - Android Studio with a matching SDK & Build Tools.
  - JDK 17+ (Note: do not commit local paths, such as the custom configuration in `gradle.properties`, to Git).
  - Recommended test environment: Android 12+ (API 31+).
- **iOS**:
  - macOS with the latest Xcode version.
  - Requires iOS Deployment Target **16.0+**.

---

## 🚀 Getting Started

### 1. Project Setup

```bash
# Clone repository
git clone https://github.com/dut-pbl6-2026/job-platform-mobile.git

# Di chuyển vào thư mục dự án
cd job-platform-mobile

# Cài đặt các thư viện phụ thuộc
flutter pub get
```

### 2. Environment Configuration

- Make sure the `JAVA_HOME` environment variable is set correctly on your machine, instead of hardcoding a local path in `android/gradle.properties`.
- Check and set the required configuration in the `.env` file (if any).
- **Backend connection**: The app communicates exclusively through the **API Gateway (YARP)**; calling the internal microservice ports directly is prohibited.

### 3. Run the Project

```bash
# Kiểm tra các thiết bị khả dụng
flutter devices

# Chạy ứng dụng trên thiết bị đang kết nối
flutter run
```

---

## 🛠 Notes for Developers

- **Branching Flow (Trunk-Based)**:
  - Branching flow: `feature/*` / `fix/*` $\rightarrow$ `main` — each repo has only one `main` branch, and CI runs on `main` (`.github/workflows/ci.yml`).
  - Please create new branches in the format `feature/[feature-name]` or `fix/[bug-name]` and open PRs against `main`.
- **Task management**: Track tasks on Jira at [skid.atlassian.net](https://skid.atlassian.net).
- **Debug / Release configuration**:
  - Always make sure debug settings (such as `debugLogDiagnostics` and logging) are wrapped in `kDebugMode` to avoid exposing sensitive information.
- **Standards & security compliance**:
  - Follow the security rules (SEC) and the SRS standards (for example: password strength requirements, token encryption, session lifetime, and role-based access for 3 user groups: Admin, Recruiter, User).

## Deploy (Mobile — TM4 Khoa, excluded from prod)
- Build: `flutter pub get` `ApiAuthRepository FLUTTER_API_URL=http://10.0.2.2:5000 --dart-define` `AuthSession.load() minSdk 23` `excluded from prod` `backlog.md#2`
