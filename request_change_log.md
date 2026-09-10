\# Comprehensive Code Review: `feature/apply-profile-history`



\*\*Repository:\*\* `job-platform-mobile`  

\*\*Branch:\*\* `feature/apply-profile-history`  

\*\*Base Branch:\*\* `origin/main`  

\*\*Commits Reviewed:\*\*

\- `371d73c`: \*feat: implement core modules for job application, profile management, and related repository services\*

\- `855db20`: \*Format code\*

\- `af80f3d`: \*fix ci build error\*



\*\*Scope of Changes:\*\* 36 files changed (+6,539 insertions, -146 deletions)  

\*\*Test Suite Status:\*\* 52/52 tests passing (`flutter test` — re-verified 2026-09-10, `All tests passed!`)  

\*\*Static Analysis Status:\*\* 6 `info`-level deprecation warnings (`flutter analyze`, exact lines verified in §4.8)



> \*\*Re-verification note (2026-09-10):\*\* Re-ran `git diff --stat origin/main...HEAD`, `grep` for `MainNavigationScreen` / `Navigator.push` / direct `:500x` ports, `flutter analyze`, `flutter test`, and cross-checked `job-platform-profile-svc/ProfileEndpoints.cs`, `job-platform-app-svc/ApplicationDtos.cs` + `ApplicationEndpoints.cs`, and `job-platform-gateway/appsettings.json`. Sections 4.3–4.5, 4.8 corrected/expanded; §§4.9–4.10, checklist rows, and §7 steps added. Core verdicts (HIGH: §§4.1–4.3) unchanged.



\---



\## 1. Executive Summary



The `feature/apply-profile-history` branch implements the core Week 3 deliverables according to the project specifications:

1\. \*\*Candidate Job Application Flow (APP-01, MOB-01-04):\*\* Applying with CV attachment, cover letter quick-suggestions, validation, and confirmation dialogs.

2\. \*\*Application Tracking \& History (APP-01-03, APP-01-04, MOB-01-06):\*\* Application history list with status filtering chips, application detail screen with status progress timeline, and recruiter feedback visualization.

3\. \*\*Candidate Profile Management (PROFILE-01, MOB-01-05):\*\* Full candidate profile dashboard, profile completion progress metric, edit personal info dialog, and modular management of Skills, Work Experiences, and Education entries.

4\. \*\*Data \& Networking Layer:\*\* Repository abstractions with dual implementations (`Mock\*Repository` and `Api\*Repository` via Dio) adhering to the Single Entry Point architecture via API Gateway.

5\. \*\*Quality Assurance:\*\* 8 comprehensive test files with 52 unit and widget tests covering models, repositories, and UI flows.



\### Overall Assessment: \*\*Conditionally Approved with Required Fixes\*\*

The feature set is feature-rich, visually polished, and adheres closely to Vietnamese localization standards and clean domain modeling. However, there are \*\*critical architectural gaps\*\* regarding navigation integration (`MainNavigationScreen` is unused), an authentication route guard flaw on `/jobs/:id/apply`, backend API endpoint naming mismatches with `job-platform-profile-svc`, missing routes in the YARP Gateway, and an over-permissive mock fallback error handling pattern that masks server failures.



\---



\## 2. Key Strengths \& Highlights



\- \*\*Exemplary Domain Modeling:\*\* `ApplicationModel`, `ProfileModel`, `SkillModel`, `WorkExperienceModel`, and `EducationModel` are immutable, support robust `fromJson`/`toJson` mappings (including fallback key variants like camelCase and snake\_case), and provide practical utility helpers (e.g. `completionPercentage`, `formattedPeriod`).

\- \*\*Standard-Compliant Status Workflow:\*\* `ApplicationStatus` enum faithfully mirrors SRS Section 3.5.2 (`pending`, `reviewed`, `shortlisted`, `accepted`, `rejected`) with tailored Vietnamese labels, descriptions, icons, and theme colors.

\- \*\*Superior UI Polish \& User Experience:\*\*

&#x20; - Dynamic completion meter for user profiles.

&#x20; - Linear status progression timeline with past, active, and upcoming step indicators.

&#x20; - Cover letter quick-suggestion chips that speed up mobile CV applications.

&#x20; - Dedicated shimmer loading skeletons (`JobDetailShimmerLoading`) and responsive empty/error states.

\- \*\*Strong Automated Test Culture:\*\* 52 automated tests passing, verifying model serialization, repository fallbacks, and UI component interaction via `WidgetTester`.

\- \*\*Dio Client Standardization:\*\* `ApiJobRepository` was refactored from low-level `HttpClient` to the centralized `DioProvider`.



\---



\## 3. API Gateway Integration \& Architecture Compliance



\### 3.1. Architectural Compliance: Does Mobile Call Gateway or Direct Services?

\* \*\*Verdict:\*\* ✅ \*\*Mobile correctly targets ONLY the API Gateway.\*\* It strictly avoids calling internal microservice ports (`5001`, `5002`, `5004`, `5005`) directly, satisfying SRS Section 1.1 / Section 4 architectural constraints.

\* \*\*Mechanism:\*\* All remote repositories (`ApiAuthRepository`, `ApiJobRepository`, `ApiApplicationRepository`, `ApiProfileRepository`) inject the centralized `DioProvider.instance.dio`, which resolves to a single Base URL:

&#x20; ```dart

&#x20; // lib/core/network/dio\_provider.dart

&#x20; const \_baseUrl = String.fromEnvironment(

&#x20;   'FLUTTER\_API\_URL',

&#x20;   defaultValue: 'https://jp-gateway.onrender.com', // Single entry point

&#x20; );

&#x20; ```



\### 3.2. End-to-End Request Lifecycle Through Gateway

Once configured, the complete request lifecycle adheres to the microservices reverse-proxy pattern:

```

Mobile Client (Flutter)

&#x20;    │

&#x20;    │ 1. HTTP Request with Bearer JWT

&#x20;    │    e.g. POST https://jp-gateway.onrender.com/api/applications

&#x20;    ▼

API Gateway (YARP Reverse Proxy :5000)

&#x20;    │

&#x20;    │ 2. Validates Bearer JWT signature, issuer, and audience

&#x20;    │ 3. Enforces IP rate limiting (600 req/min per IP)

&#x20;    │ 4. Executes Request Transform:

&#x20;    │    - Strips incoming spoofed X-User-\* headers

&#x20;    │    - Injects verified claims: X-User-Id and X-User-Role

&#x20;    │ 5. YARP routes to internal private microservice cluster:

&#x20;    ▼

Downstream Microservice (jp-app :5004 or jp-profile :5005)

&#x20;    │

&#x20;    │ 6. Processes request using X-User-Id

&#x20;    │ 7. Returns response to Gateway

&#x20;    ▼

API Gateway (YARP :5000)

&#x20;    │

&#x20;    │ 8. Relays response back to Mobile Client

&#x20;    ▼

Mobile Client (Flutter)

```



\### 3.3. Current Integration Gaps: Why Live Gateway Calls Fail

Even though Mobile's architectural pattern is correct, live calls currently return \*\*404 Not Found\*\* at the Gateway due to two configuration gaps:

1\. \*\*Missing YARP Routes in Gateway (`job-platform-gateway`):\*\*

&#x20;  `Gateway.Api/appsettings.json` currently only defines routes for `auth` (:5001), `jobs` (:5002), and `search` (:5003). There are \*\*no routes\*\* for `/api/applications` or `/api/profiles`.

2\. \*\*Endpoint Path Mismatches in Mobile:\*\*

&#x20;  `ApiProfileRepository` calls singular `/api/profile/me` and `PUT /api/profile`, whereas `job-platform-profile-svc` defines plural `/api/profiles/me`.

3\. \*\*Silent Mock Fallback Masking:\*\*

&#x20;  Because `ApiApplicationRepository` and `ApiProfileRepository` catch `DioException` and fallback to in-memory mocks, the UI and tests continue to function without alerting developers that the live Gateway returned 404.



\---



\## 4. Critical Issues \& Technical Gaps



\### 4.1. \[HIGH] `MainNavigationScreen` is Disconnected from Routing

\- \*\*File:\*\* `lib/features/home/main\_navigation\_screen.dart` vs `lib/core/router/app\_router.dart`

\- \*\*Issue:\*\* `MainNavigationScreen` was created with a 4-tab `NavigationBar` (Trang chủ, Việc làm, Ứng tuyển, Hồ sơ) as requested by SRS `MOB-01-07`. However, in `AppRouter`, `AppRoutes.home` (`/home`) routes directly to `HomeScreen`, and `MainNavigationScreen` is never referenced anywhere in the routing configuration.

\- \*\*Impact:\*\* Users who log in are taken to `HomeScreen` without persistent bottom navigation tabs, requiring them to use manual dashboard buttons to navigate. The entire bottom navigation shell remains dead code.



\### 4.2. \[HIGH] Security / Route Guard Bypass on `/jobs/:id/apply`

\- \*\*File:\*\* `lib/core/router/app\_router.dart` (Lines 58–65)

\- \*\*Issue:\*\* In `AppRouter.redirect`:

&#x20; ```dart

&#x20; final isPublicRoute =

&#x20;     AppRoutes.publicRoutes.contains(currentPath) ||

&#x20;     currentPath.startsWith('/jobs');

&#x20; ```

&#x20; Because `currentPath.startsWith('/jobs')` evaluates to `true` for `/jobs/:id/apply`, unauthenticated visitors navigating directly (or via deep links) to `/jobs/123/apply` bypass the login redirect guard.

\- \*\*Impact:\*\* Unauthenticated users can access the application submission screen directly without being prompted to log in.



\### 4.3. \[HIGH] Backend API Path Mismatch with `job-platform-profile-svc`

\- \*\*Files:\*\* `lib/features/profile/data/repositories/api\_profile\_repository.dart` vs `job-platform-profile-svc` (`ProfileEndpoints.cs`)

\- \*\*Issue (verified against `ProfileEndpoints.cs` on `main`):\*\*

&#x20; 1. In `job-platform-profile-svc`, endpoints are mapped under plural `/api/profiles` (`GET /api/profiles/me` and `PUT /api/profiles/me` only — verified, no sub-resource routes exist in code).

&#x20; 2. Mobile's `ApiProfileRepository` calls singular `/api/profile/me` for GET, and `/api/profile` for PUT (missing `/me`, singular vs plural).

&#x20; 3. Mobile calls individual sub-resource endpoints (verified exact paths in code):

&#x20;    - `POST /api/profile/skills` and `DELETE /api/profile/skills/$skillId`

&#x20;    - `POST /api/profile/experience` (singular) and `DELETE /api/profile/experience/$experienceId`

&#x20;    - `POST /api/profile/education` (singular) and `DELETE /api/profile/education/$educationId`

&#x20;    However, `job-platform-profile-svc` only exposes `PUT /api/profiles/me` (+ `GET /me`, `GET /{userId}`), where skills, experiences, and educations are returned as part of the aggregate `ProfileDetailDto`.

&#x20; 4. \*\*Two-sided gap (added on re-verification):\*\* `job-platform-profile-svc/AGENTS.md` \*specs\* `POST/DELETE /api/profiles/skills`, `/experiences`, `/educations` (plural), but `ProfileEndpoints.cs` does not implement them yet. So mobile is ahead of the backend implementation on one side, and uses wrong singular paths on the other — both sides need alignment toward the plural spec (`/api/profiles/skills`, `/api/profiles/experiences`, `/api/profiles/educations`).

\- \*\*Impact:\*\* When connected to the live backend or YARP Gateway, all profile API calls will return 404 Not Found.



\### 4.4. \[MEDIUM] Over-Permissive Mock Fallback Silently Swallowing Server Errors

\- \*\*Files:\*\*

&#x20; - `lib/features/applications/data/repositories/api\_application\_repository.dart`

&#x20; - `lib/features/profile/data/repositories/api\_profile\_repository.dart`

\- \*\*Issue:\*\* While `ApiAuthRepository` correctly checks:

&#x20; ```dart

&#x20; if (e.response != null \&\& e.response!.statusCode != null) {

&#x20;   throw mapDioToFailure(e);

&#x20; }

&#x20; ```

&#x20; `ApiProfileRepository` (all 8 methods) and `ApiApplicationRepository.getMyApplications` / `getApplicationById` catch all exceptions in a broad `catch (e)` and silently return data from `MockProfileRepository` / `MockApplicationRepository`. Note nuance: `ApiApplicationRepository.applyJob` \*does\* handle `409 Conflict` explicitly (duplicate application) before falling back, so only non-409 HTTP errors (400/401/500) are swallowed there — but `getMyApplications` / `getApplicationById` have no such guard.

\- \*\*Impact:\*\* In production or staging, if the backend returns 401 Unauthorized, 400 Bad Request, or 500 Server Error, the mobile app treats the request as successful by saving to local mock memory. The user believes their CV or profile was saved on the server, but the data disappears upon app restart.



\### 4.5. \[MEDIUM] Imperative `Navigator.push` Bypassing Declarative `GoRouter`

\- \*\*Files (verified — exactly 2 occurrences, not 3):\*\*

&#x20; - `lib/features/jobs/presentation/job\_detail\_screen.dart` (Line 171, `\_showApplyBottomSheet`)

&#x20; - `lib/features/applications/presentation/application\_history\_screen.dart` (Line 257, `ApplicationCard.onTap`)

\- \*\*Correction vs previous revision:\*\* `lib/features/applications/presentation/apply\_job\_screen.dart` (Line 168) was previously listed here but is \*\*not\*\* a violation — it correctly uses `context.push(AppRoutes.applications)` after the success dialog (with `Navigator.of(dialogContext).pop()` only to dismiss the dialog, which is idiomatic). Only the 2 files above use `Navigator.of(context).push(MaterialPageRoute(...))` instead of `context.push(...)`.

\- \*\*Issue:\*\* Navigation to `ApplyJobScreen` and `ApplicationDetailScreen` uses `Navigator.of(context).push(MaterialPageRoute(...))` instead of `context.push('/jobs/:id/apply', extra: ...)` or `context.push('/applications/:id')`.

\- \*\*Impact:\*\* Breaks GoRouter route hierarchy, disables deep linking for application details, breaks browser back navigation on web, and prevents route analytics listeners from logging screen transitions.



\### 4.6. \[MEDIUM] Missing Device File Picker Dependency (`file\_picker`)

\- \*\*Files:\*\* `lib/core/services/file\_picker\_service.dart`, `pubspec.yaml`

\- \*\*Issue:\*\* `SelectedCvFile` and `MockCvPickerService` are implemented, but `file\_picker` is not included in `pubspec.yaml`. No production implementation of `ICvPickerService` exists.

\- \*\*Impact:\*\* Users on real devices cannot pick their actual resume document from local storage or cloud drives; only mock files can be selected.



\### 4.7. \[MEDIUM] Data Model Enrichment Gap in `getMyApplications`

\- \*\*Files:\*\* `job-platform-app-svc` (`ApplicationSummaryDto`) vs `lib/features/applications/domain/models/application\_model.dart`

\- \*\*Issue:\*\* `app-svc`'s `GET /api/applications/me` returns `ApplicationSummaryDto` which contains only `id, jobId, applicantId, status, cvUrl, coverLetter, createdAt, updatedAt`. It does \*\*not\*\* include `jobTitle` or `companyName`.

\- \*\*Impact:\*\* When connecting to the real API, mobile applications in `ApplicationHistoryScreen` will fall back to the default placeholders: `"Vị trí tuyển dụng"` and `"Doanh nghiệp"`.



\### 4.8. \[LOW] Flutter SDK Deprecation Warnings from CI Workaround

\- \*\*Files:\*\*

&#x20; - `lib/features/profile/presentation/widgets/add\_education\_dialog.dart` (Lines 128, 183, 218)

&#x20; - `lib/features/profile/presentation/widgets/add\_experience\_dialog.dart` (Lines 144, 171, 214)

\- \*\*Issue:\*\* `dart analyze` reports 6 warnings (re-verified with `flutter analyze`: 6 `info` level issues, exact lines match):

&#x20; - `value` is deprecated for `DropdownButtonFormField`. Use `initialValue`.

&#x20; - `activeColor` is deprecated for `SwitchListTile` (actually `CheckboxListTile`/`SwitchListTile` family — here `SwitchListTile` line 144). Use `activeThumbColor`.

&#x20; Commit `af80f3d` intentionally reverted to deprecated properties to fix a build error on an older CI Flutter SDK runner.

\- \*\*Recommendation:\*\* Align the CI Flutter SDK version with the repository's target Flutter version (3.27+) using an explicit `.fvmrc` or GitHub Action configuration.



\### 4.9. \[MEDIUM] Mock-Only Shortcuts Bypassing Live API (missed in previous revision, added on re-verification)

\- \*\*Files:\*\*

&#x20; - `lib/features/applications/data/repositories/api\_application\_repository.dart` (Lines 133–135): `hasApplied()` returns `\_fallbackMockRepository.hasApplied(jobId)` directly without any Dio call — duplicate-application guard never consults the server (which would return 409 on `POST /api/applications`).

&#x20; - `lib/features/jobs/presentation/job\_detail\_screen.dart` (Line 38): defaults to `MockJobRepository()` instead of `ApiJobRepository()`, so job detail never hits `/api/jobs/:id` live even though the API implementation exists.

&#x20; - `lib/features/jobs/data/repositories/api\_job\_repository.dart` (Line 142–144): `toggleSaveJob` is mock-only (no backend endpoint yet — acceptable short-term, but should be marked `TODO`).

\- \*\*Impact:\*\* Users can re-apply to the same job without client-side warning; job detail content diverges from search/list (which do use `ApiJobRepository`). Tests pass because they inject mocks, masking the dead live path.



\### 4.10. \[LOW] Hardcoded Contact Fallbacks in `ApplyJobScreen`

\- \*\*File:\*\* `lib/features/applications/presentation/apply\_job\_screen.dart` (Lines 309, 315, 321)

\- \*\*Issue:\*\* Contact card falls back to `'Nguyễn Văn An'`, `'candidate@example.com'`, and hardcoded `'0905 123 456'` when `AuthSession.currentUser` fields are null, instead of pulling from `ProfileModel` or prompting profile completion. Cover letter `maxLength: 1000` is also stricter than backend `Application.CoverLetterMaxLength = 4000` (app-svc), so client rejects input the server would accept.

\- \*\*Impact:\*\* Cosmetic / data-quality only; no crash. But demo builds show a fake phone number, and legitimate long cover letters are blocked client-side.



\---



\## 5. Suggested Code Improvements \& Refactoring Solutions



\### 5.1. Wire `MainNavigationScreen` with `StatefulShellRoute` in `AppRouter`

Replace the standalone `HomeScreen` route with GoRouter's `StatefulShellRoute.indexedStack` to activate persistent bottom navigation across tabs:



```dart

// lib/core/router/app\_router.dart

StatefulShellRoute.indexedStack(

&#x20; builder: (context, state, navigationShell) {

&#x20;   return Scaffold(

&#x20;     body: navigationShell,

&#x20;     bottomNavigationBar: NavigationBar(

&#x20;       selectedIndex: navigationShell.currentIndex,

&#x20;       onDestinationSelected: (index) => navigationShell.goBranch(

&#x20;         index,

&#x20;         initialLocation: index == navigationShell.currentIndex,

&#x20;       ),

&#x20;       destinations: const \[

&#x20;         NavigationDestination(icon: Icon(Icons.home\_outlined), selectedIcon: Icon(Icons.home\_rounded), label: 'Trang chủ'),

&#x20;         NavigationDestination(icon: Icon(Icons.work\_outline), selectedIcon: Icon(Icons.work\_rounded), label: 'Việc làm'),

&#x20;         NavigationDestination(icon: Icon(Icons.history\_edu\_outlined), selectedIcon: Icon(Icons.history\_edu\_rounded), label: 'Ứng tuyển'),

&#x20;         NavigationDestination(icon: Icon(Icons.person\_outline), selectedIcon: Icon(Icons.person\_rounded), label: 'Hồ sơ'),

&#x20;       ],

&#x20;     ),

&#x20;   );

&#x20; },

&#x20; branches: \[

&#x20;   StatefulShellBranch(routes: \[GoRoute(path: AppRoutes.home, builder: (\_, \_\_) => const HomeScreen())]),

&#x20;   StatefulShellBranch(routes: \[GoRoute(path: AppRoutes.jobs, builder: (\_, \_\_) => const JobListScreen())]),

&#x20;   StatefulShellBranch(routes: \[GoRoute(path: AppRoutes.applications, builder: (\_, \_\_) => const ApplicationHistoryScreen())]),

&#x20;   StatefulShellBranch(routes: \[GoRoute(path: AppRoutes.profile, builder: (\_, \_\_) => const ProfileScreen())]),

&#x20; ],

)

```



\### 5.2. Fix Authentication Route Guard in `AppRouter`

Prevent `/jobs/:id/apply` from inheriting public access:



```dart

// lib/core/router/app\_router.dart

redirect: (context, state) {

&#x20; final isAuthenticated = AuthSession.instance.isAuthenticated;

&#x20; final currentPath = state.matchedLocation;



&#x20; // /jobs and /jobs/:id are public, but /jobs/:id/apply requires authentication!

&#x20; final isApplyRoute = currentPath.endsWith('/apply');

&#x20; final isPublicRoute = AppRoutes.publicRoutes.contains(currentPath) ||

&#x20;     (currentPath.startsWith('/jobs') \&\& !isApplyRoute);



&#x20; if (!isAuthenticated \&\& !isPublicRoute) {

&#x20;   return AppRoutes.login;

&#x20; }

&#x20; // ...

}

```



\### 5.3. Standardize Declarative Navigation

Replace imperative `Navigator.push` calls with `GoRouter`:



```dart

// In JobDetailScreen:

void \_navigateToApply() {

&#x20; context.push(

&#x20;   '/jobs/${\_job!.id}/apply',

&#x20;   extra: {

&#x20;     'title': \_job!.title,

&#x20;     'company': \_job!.companyName,

&#x20;     'logo': \_job!.companyLogo,

&#x20;   },

&#x20; );

}



// In ApplicationHistoryScreen:

onTap: () {

&#x20; context.push('/applications/${app.id}');

}

```



\### 5.4. Tighten Error Handling \& Guard Mock Fallback

Only fallback to mock when network/gateway is physically unreachable (`e.response == null`), rather than swallowing HTTP 4xx/5xx errors:



```dart

// lib/features/applications/data/repositories/api\_application\_repository.dart

} on DioException catch (e) {

&#x20; if (e.response != null) {

&#x20;   if (e.response?.statusCode == 409) {

&#x20;     throw Exception('Bạn đã nộp hồ sơ cho vị trí này rồi. Vui lòng kiểm tra lịch sử ứng tuyển.');

&#x20;   }

&#x20;   // Re-throw server-side validation / permission errors

&#x20;   throw Exception(e.response?.data?\['message'] ?? 'Lỗi máy chủ (${e.response?.statusCode})');

&#x20; }

&#x20; debugPrint('\[ApiApplicationRepository] Gateway offline, falling back to mock: ${e.message}');

&#x20; return \_fallbackMockRepository.applyJob(params);

}

```



\### 5.5. Align `ApiProfileRepository` Endpoints with Backend

Update paths to match `job-platform-profile-svc`:



```dart

// lib/features/profile/data/repositories/api\_profile\_repository.dart

@override

Future<ProfileModel> getMyProfile() async {

&#x20; try {

&#x20;   final response = await \_dio.get('/api/profiles/me'); // Fixed plural 'profiles'

&#x20;   // ...

```



\### 5.6. Configure Gateway Routes in `job-platform-gateway`

Add routes \& clusters for `app-svc` and `profile-svc` in `Gateway.Api/appsettings.json`:



```json

"ReverseProxy": {

&#x20; "Routes": {

&#x20;   "applications": {

&#x20;     "ClusterId": "app",

&#x20;     "Match": { "Path": "/api/applications/{\*\*catch-all}" },

&#x20;     "Transforms": \[{ "PathPattern": "/api/applications/{\*\*catch-all}" }]

&#x20;   },

&#x20;   "profiles": {

&#x20;     "ClusterId": "profile",

&#x20;     "Match": { "Path": "/api/profiles/{\*\*catch-all}" },

&#x20;     "Transforms": \[{ "PathPattern": "/api/profiles/{\*\*catch-all}" }]

&#x20;   }

&#x20; },

&#x20; "Clusters": {

&#x20;   "app": {

&#x20;     "Destinations": {

&#x20;       "app1": { "Address": "http://localhost:5004" }

&#x20;     }

&#x20;   },

&#x20;   "profile": {

&#x20;     "Destinations": {

&#x20;       "profile1": { "Address": "http://localhost:5005" }

&#x20;     }

&#x20;   }

&#x20; }

}

```



\---



\## 6. Review Checklist \& Verification Summary



| Item | Requirement | Status | Notes |

|---|---|---|---|

| \*\*GATEWAY ARCH\*\* | Single Entry Point via Gateway | Passed (Arch) | Mobile only uses `FLUTTER\_API\_URL` (Gateway); no direct service calls. |

| \*\*MOB-01-04\*\* | Job Application Screen | Passed | Validation, file picker abstraction, and submission logic verified. |

| \*\*MOB-01-05\*\* | Candidate Profile Screen | Passed | Sections for Bio, Skills, Experience, Education with edit dialogs. |

| \*\*MOB-01-06\*\* | Application History \& Tracking | Passed | Filter chips by status, status badge color-coding, timeline tracker. |

| \*\*MOB-01-07\*\* | Unified Bottom Navigation | Incomplete | `MainNavigationScreen` implemented but unlinked in `AppRouter`. |

| \*\*SEC-08 / AUTH\*\* | Route Guard Protection | Needs Fix | `/jobs/:id/apply` currently bypassed by `currentPath.startsWith('/jobs')`. |

| \*\*DATA INTEGRITY\*\* | Backend API Contract | Needs Fix | `/api/profiles` endpoint mismatch and silent mock fallback. |

| \*\*MOCK BYPASS\*\* | Live API usage (`hasApplied`, `JobDetail`) | Needs Fix | `hasApplied` mock-only; `JobDetailScreen` defaults to `MockJobRepository` (§4.9). |

| \*\*DATA QUALITY\*\* | Contact fallbacks | Needs Fix (Low) | Hardcoded phone + stricter cover-letter limit (§4.10). |

| \*\*TESTING\*\* | Automated Test Coverage | Passed | 52/52 tests passing. All unit \& widget tests green. |

| \*\*CODE STYLE\*\* | Formatting \& Lint | Passed | Clean formatting; 6 deprecation notices from Flutter version divergence. |



\---



\## 7. Recommended Next Steps



1\. \*\*Route Guard \& Navigation (High Priority):\*\*

&#x20;  - Wire `MainNavigationScreen` into `AppRouter` via `StatefulShellRoute`.

&#x20;  - Restrict `/jobs/:id/apply` so unauthenticated users are redirected to login.

&#x20;  - Refactor the 2 `Navigator.push(MaterialPageRoute(...))` calls (`job\_detail\_screen.dart:171`, `application\_history\_screen.dart:257`) to `context.push(...)`. (`apply\_job\_screen.dart:168` is already correct — no change needed.)

2\. \*\*Backend Contract Alignment (High Priority):\*\*

&#x20;  - Correct `/api/profiles/me` routes in `ApiProfileRepository`.

&#x20;  - Add `/api/applications` and `/api/profiles` routes in `job-platform-gateway/src/Gateway.Api/appsettings.json`.

&#x20;  - Update error handlers to distinguish between network unreachable vs 4xx/5xx HTTP errors.

&#x20;  - Implement missing `POST/DELETE /api/profiles/skills|experiences|educations` in `job-platform-profile-svc` per its own AGENTS.md spec, then point mobile at the plural paths; wire `hasApplied()` to a live check and switch `JobDetailScreen` default to `ApiJobRepository` (§4.9).

3\. \*\*Hardware / OS Integration (Medium Priority):\*\*

&#x20;  - Add `file\_picker: ^8.0.0` or `file\_selector` to `pubspec.yaml` to implement real device file selection for `ICvPickerService`.

4\. \*\*CI Flutter SDK Version Pinning (Low Priority):\*\*

&#x20;  - Add `.fvmrc` or pin Flutter version in GitHub Actions workflow to eliminate deprecation discrepancies.



