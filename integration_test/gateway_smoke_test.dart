// Integration smoke test for the mobile -> YARP gateway wiring (PBL6-33).
//
// Exercises the real repositories (and therefore the app's Dio client,
// interceptors and gateway base URL) against a running stack:
//   health -> register/login -> job search -> apply -> logout
//
// Start the stack first:
//   cd job-platform-infra && ./scripts/dev-up.sh --with-job --with-search --with-app
// Then run (localhost; use http://10.0.2.2:5000 on an Android emulator):
//   flutter test integration_test \
//     --dart-define=FLUTTER_API_URL=http://localhost:5000
//
// When the gateway is unreachable the test skips (so it is harmless when run
// locally without a stack). In a smoke/quality-gate context pass
//   --dart-define=REQUIRE_LIVE_STACK=true
// to make an unreachable gateway a hard failure instead of a skip.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_platform_mobile/core/network/dio_provider.dart';
import 'package:job_platform_mobile/features/applications/data/repositories/api_application_repository.dart';
import 'package:job_platform_mobile/features/applications/domain/models/application_model.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/api_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';

/// When true, an unreachable gateway fails the test instead of skipping it.
/// Set with `--dart-define=REQUIRE_LIVE_STACK=true` in smoke/CI runs.
const bool _requireLiveStack = bool.fromEnvironment('REQUIRE_LIVE_STACK');

/// Backend job ids are UUIDs; mock fallback ids are `job-1`, `job-2`, ...
final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final dio = DioProvider.instance.dio;
  final baseUrl = dio.options.baseUrl;

  Future<bool> gatewayUp() async {
    try {
      final res = await dio.get(
        '/health',
        options: Options(
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  testWidgets('gateway E2E: health -> auth -> search -> apply', (tester) async {
    if (!await gatewayUp()) {
      final message =
          'Gateway $baseUrl unreachable. Start the stack first '
          '(./scripts/dev-up.sh --with-job --with-search --with-app) and run '
          'with --dart-define=FLUTTER_API_URL=http://localhost:5000';
      if (_requireLiveStack) {
        fail('$message (REQUIRE_LIVE_STACK=true)');
      }
      markTestSkipped(message);
      return;
    }

    final auth = ApiAuthRepository();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'e2e-mobile-$stamp@example.com';

    final registered = await auth.register(
      name: 'Mobile E2E',
      email: email,
      password: 'Mobile123',
      role: UserRole.user,
    );
    expect(
      registered.token,
      isNotEmpty,
      reason: 'register should return a JWT',
    );

    final me = await auth.getCurrentUser();
    expect(me?.email, email);

    final jobRepository = ApiJobRepository();
    final jobs = await jobRepository.getJobs(const JobFilterParams());
    expect(
      jobs.items,
      isNotEmpty,
      reason:
          'No jobs returned. Either the search service is unreachable and '
          'ApiJobRepository silently fell back to mock data, or the database '
          'has not been seeded. Seed a job before running this smoke test.',
    );

    final job = jobs.items.first;
    expect(
      _uuid.hasMatch(job.id),
      isTrue,
      reason:
          'Got id "${job.id}", which is not a backend UUID. The search service '
          'is likely down and ApiJobRepository returned mock data instead of a '
          'live result (search fallback).',
    );

    final applications = ApiApplicationRepository(jobRepository: jobRepository);
    final application = await applications.applyJob(
      ApplyJobParams(
        jobId: job.id,
        jobTitle: job.title,
        companyName: job.companyName,
        coverLetter: 'Mobile E2E automated application',
        cvFileName: 'e2e-cv.pdf',
        cvBytes: _minimalPdfBytes,
      ),
    );
    expect(application.jobId, job.id);

    await auth.logout();
    final userAfterLogout = await auth.getCurrentUser();
    expect(
      userAfterLogout,
      isNull,
      reason:
          'Session must be invalidated and cleared after logout (AUTH-01-05).',
    );
  });
}

/// Smallest byte sequence accepted by app-svc CV signature validation (%PDF).
final List<int> _minimalPdfBytes = List<int>.from(
  '%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n'
      .codeUnits,
);
