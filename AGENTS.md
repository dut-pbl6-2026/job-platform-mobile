# AGENTS.md - Mobile Development & Architectural Guidelines

This document serves as the primary standard, architectural blueprint, and development guideline for AI agents and developers working on `job-platform-mobile`. All code contributions must align with the Software Requirements Specification (SRS) in `job-platform-docs` and adhere to these conventions.

---

## 1. Project Overview & Scope

- **Repository:** `dut-pbl6-2026/job-platform-mobile`
- **Assigned Role:** **TM4 - Mobile Development (Flutter) & Quality Assurance (QA)**
- **Target Platform:** Cross-platform Mobile (iOS 16+ & Android 12+) using Flutter (Dart 3+)
- **Primary Design System:** Material 3 with customized brand palette (`AppTheme`, `AppColors`, Roboto Typography for full Vietnamese Unicode support)

### 1.1 Microservices & API Gateway Constraint
```
[Flutter Mobile App] ──(HTTPS/REST/WSS)──> [API Gateway (YARP)] ──> [Microservices: 5001-5006, 6000]
```
> [!IMPORTANT]
> **Strict Gateway Rule:** The mobile application **MUST NEVER** call internal microservice ports directly (e.g., `5001` Auth, `5002` Job, `5003` Search, `5004` App, `5005` Profile, `5006` Notif, `6000` AI).
> **All** network communication must be directed exclusively through the **API Gateway (YARP)** via reverse-proxied endpoints (e.g., `/api/auth/*`, `/api/jobs/*`, `/api/applications/*`, `/api/profiles/*`, `/api/ai/*`).

---

## 2. System Architecture & Project Structure

The project follows a **Feature-First Clean Architecture** organization, maintaining separation of concerns across Domain, Data, and Presentation layers.

### 2.1 Directory Structure
```text
lib/
├── app.dart                       # Root MaterialApp with theme & router setup
├── main.dart                      # App entry point, environment config & DI initialization
├── core/                          # Cross-cutting shared modules & primitives
│   ├── constants/                 # App constants, asset paths, storage keys
│   ├── network/                   # Dio/Http client, interceptors, Gateway baseURL config
│   ├── router/                    # GoRouter configuration, route paths, auth guards
│   ├── session/                   # AuthSession, token storage, user state
│   ├── theme/                     # AppTheme, AppColors, typography, dimensions
│   ├── utils/                     # Formatters (currency, dates), validators, helpers
│   └── widgets/                   # Generic reusable UI widgets (buttons, textfields, badges)
└── features/                      # Encapsulated feature modules
    ├── auth/                      # Authentication (Login, Register, Forgot Password)
    │   ├── data/                  # Repositories (Mock & Remote API), DataSources, DTOs
    │   ├── domain/                # Entities/Models (UserModel, AuthResult), Abstract Repositories
    │   └── presentation/          # Screens (login_screen, register_screen), state & widgets
    ├── jobs/                      # Job List, Job Detail, Search, Filtering
    ├── applications/              # Application Form, CV Upload, History Tracking
    ├── profile/                   # User Profile, Skills, Experience, Education
    ├── notifications/             # FCM push notification handlers, notification screen
    └── ai_copilot/                # AI Chatbot stream, Resume Scoring, Job Recommendations
```

### 2.2 Layering Rules
1. **Domain Layer (`features/<feature>/domain/`)**:
   - Contains pure Dart business entities, value objects, and abstract repository contracts (e.g., `IAuthRepository`, `IJobRepository`).
   - Must have **zero dependencies** on Flutter UI packages or external transport protocols.
2. **Data Layer (`features/<feature>/data/`)**:
   - Implements domain repository interfaces (`MockAuthRepository`, `ApiAuthRepository`).
   - Manages data sources (Remote REST APIs via Gateway, Local Hive/SharedPreferences cache).
   - Handles data serialization (`fromJson`, `toJson`) and DTO mapping.
3. **Presentation Layer (`features/<feature>/presentation/` or screen files)**:
   - Contains UI widgets, screens, and view-level state handling.
   - Depends only on Domain contracts/entities and Core abstractions.

---

## 3. Role-Based Access Control (RBAC) & Navigation

The platform supports 3 primary user groups according to the SRS:

| User Role | Code Identifier | Permissions & Capabilities |
| :--- | :--- | :--- |
| **Candidate / Job Seeker** | `UserRole.user` | Search jobs, view details, apply with CV, view application history, edit profile, use AI features |
| **Recruiter** | `UserRole.recruiter` | Manage posted jobs, view received applications & candidates, manage company profile |
| **Admin** | `UserRole.admin` | Restricted administration view, manage platform accounts and audit jobs |

### 3.1 Route Guards & Session Management
- **GoRouter Configuration (`AppRouter`):**
  - Uses `refreshListenable: AuthSession.instance` for reactive navigation on login/logout.
  - Automatically redirects unauthenticated users to `/login` when accessing private routes.
  - Automatically redirects authenticated users away from `/login` and `/register` to `/home`.
- **Role-Based UI Rendering:**
  - Navigation bars and action buttons must dynamically adjust based on `AuthSession.instance.currentUser?.role`.

---

## 4. Coding Standards & Conventions

### 4.1 Dart & Flutter Best Practices
- **Dart SDK:** `^3.13.1` (or compatible). Use modern Dart features: patterns, switch expressions, exhaustiveness checking on enums.
- **Immutability:** Domain models must be `@immutable` with `final` fields, `const` constructors, and `copyWith()` implementations.
- **Const Correctness:** Use `const` widgets wherever possible to optimize Flutter rebuild cycles.
- **Async & Lifecycle:** Always verify `if (!mounted) return;` before calling `setState()` or interacting with `BuildContext` across asynchronous gaps.
- **Localization & Formatting:**
  - Vietnamese Dong (VND) formatting: `₫` or `VNĐ` with thousand separators (e.g., `15.000.000 ₫`).
  - Vietnamese Date formats: `dd/MM/yyyy` or `dd/MM/yyyy HH:mm`.

### 4.2 Error Handling & Logging
- Wrap network and repository operations with structured try-catch blocks.
- Map backend API error codes to user-friendly Vietnamese messages (e.g., 401: *"Email hoặc mật khẩu không chính xác"*, 403: *"Bạn không có quyền truy cập"*).
- Avoid raw `print()`. Use `debugPrint()`, Flutter's `Foundation` logger, or dedicated logging interceptors.

### 4.3 Linting Compliance
- Adhere to rules defined in `analysis_options.yaml` (including `flutter_lints`).
- Always run `flutter analyze` prior to committing code. Zero warnings and zero errors are required.

---

## 5. Roadmap & SRS Feature Alignment

| Phase / Timeline | Target Milestone | SRS Requirements | Focus Areas |
| :--- | :--- | :--- | :--- |
| **Phase 1 (Weeks 1–4)** | **Core MVP (Must-Have)** | `MOB-01-01` to `MOB-01-08`<br>`AUTH-01`, `JOB-01`, `APP-01` | • Login / Register screens & GoRouter auth guards<br>• Job List & Detail screens<br>• Job Application flow with CV Upload<br>• Profile & Application History screens<br>• Gateway (YARP) API integration |
| **Phase 2 (Weeks 5–8)** | **Enhanced Platform** | `PUSH-01`, `SEARCH-01`<br>`ADMIN-01`, `OFFLINE-01` | • Push Notifications via Firebase Cloud Messaging (FCM)<br>• Advanced Search UI (filters by salary, skills, location)<br>• Local Caching (Hive / SharedPreferences)<br>• Basic Admin read-only dashboard |
| **Phase 3 (Weeks 9–13)** | **WOW Factor (AI Features)** | `AI-01`, `AI-02`, `AI-03` | • AI Job Copilot Chat screen with SSE / Stream handling<br>• Smart Resume Scoring & feedback UI<br>• Personalized Job Recommendations widget |
| **Phase 4 (Weeks 14–16)** | **QA & Production Release** | Section 8.6, NFRs | • Full E2E testing on iOS 16+ & Android 12+<br>• Performance profiling & smooth frame rate (60fps)<br>• Release build packaging (APK/AAB/IPA) & store prep |

---

## 6. Testing & Quality Assurance (QA)

As part of **TM4 (QA & Mobile)**, comprehensive test coverage is mandatory:

### 6.1 Testing Levels
1. **Unit Tests (`test/unit/` or `test/`):**
   - Test repositories, domain models, serializers (`fromJson`/`toJson`), and utility helpers.
   - Verify state transitions in `AuthSession` and data models.
2. **Widget / Component Tests (`test/widget/`):**
   - Test UI forms (input validation, error state rendering, submit button states).
   - Test custom components (`JobCard`, `StatusBadge`, `FilterBottomSheet`).
3. **Integration & Route Tests:**
   - Test GoRouter navigation flows and redirect logic under authenticated vs. unauthenticated states.

### 6.2 Testing Commands
```bash
# Run all unit and widget tests
flutter test

# Run static analysis and lint checks
flutter analyze

# Run tests with code coverage
flutter test --coverage
```

---

## 7. Git & Commit Guidelines for AI Agents

1. **Commit Message Format (Conventional Commits):**
   - `feat(auth): implement token refresh with biometric login (AUTH-01-04)`
   - `feat(jobs): add filter bottom sheet for salary and location (MOB-01-02)`
   - `fix(router): prevent redirect loop on expired token (MOB-01-01)`
   - `test(auth): add unit tests for MockAuthRepository`
   - `docs(agents): update architectural guidelines and SRS mapping`
2. **Traceability:** Always reference the associated SRS Tag (`MOB-01-XX`, `AUTH-01-XX`, `JOB-01-XX`, etc.) in commit messages and PR descriptions.
3. **Clean Code:** Remove temporary debug logs, unneeded comments, and ensure code compiles cleanly without warnings before finalizing tasks.
