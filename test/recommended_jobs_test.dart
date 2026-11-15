import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/home/home_screen.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/api_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/recommended_job_model.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/recommended_job_card.dart';

import 'package:job_platform_mobile/features/jobs/presentation/widgets/recommended_jobs_section.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  final Map<String, dynamic> Function(RequestOptions options) handler;

  _FakeHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final res = handler(options);
    return ResponseBody.fromString(
      jsonEncode(res),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RecommendedJob backend shape (job-svc RecommendedJobDto)', () {
    Map<String, dynamic> recommendedItem() => {
      'id': '8c1f2a3b-0000-0000-0000-000000000001',
      'title': 'Lập trình viên .NET',
      'companyId': 'a12b3c4d-0000-0000-0000-000000000001',
      'company': {
        'id': 'a12b3c4d-0000-0000-0000-000000000001',
        'name': 'Công ty ABC',
      },
      'categoryId': 'c34d5e6f-0000-0000-0000-000000000002',
      'category': {'id': 'c34d5e6f-0000-0000-0000-000000000002', 'name': 'IT'},
      'location': 'Đà Nẵng',
      'salaryMin': 15000000,
      'salaryMax': 25000000,
      'salaryCurrency': 'VND',
      'employmentType': 'Contract',
      'experienceLevel': 'Mid',
      'createdAt': '2026-11-02T03:00:00Z',
      'strategy': 'Collaborative',
      'reason': 'Người ứng tuyển "Lập trình viên Java" cũng ứng tuyển việc này',
    };

    test('reads companyName from the nested company object', () {
      final item = RecommendedJob.fromJson(recommendedItem());

      expect(item.job.companyName, 'Công ty ABC');
      expect(item.job.category, 'IT');
      expect(item.job.jobType, JobType.contract);
      expect(item.job.experienceLevel, ExperienceLevel.middle);
      expect(item.reason, startsWith('Người ứng tuyển'));
    });

    test('leaves companyName empty when the company object is null', () {
      final json = recommendedItem()..['company'] = null;
      final item = RecommendedJob.fromJson(json);

      expect(item.job.companyName, '');
    });

    test('prefers a flat companyName over the nested company object', () {
      final json = recommendedItem()..['companyName'] = 'Flat Name';
      final item = RecommendedJob.fromJson(json);

      expect(item.job.companyName, 'Flat Name');
    });
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleJob = JobModel(
    id: 'rec-job-1',
    title: 'Senior Flutter Developer',
    companyName: 'Tech Innovations Corp',
    location: 'Đà Nẵng',
    salaryMin: 30000000,
    salaryMax: 45000000,
    category: 'Công nghệ thông tin',
    jobType: JobType.hybrid,
    experienceLevel: ExperienceLevel.senior,
    skills: const ['Flutter', 'Dart', 'Bloc'],
    description: 'Tuyển dụng Senior Flutter Dev.',
    requirements: '3 năm kinh nghiệm.',
    postedAt: DateTime.now().subtract(const Duration(hours: 1)),
  );

  group('RecommendedJob & RecommendationExplanation Models', () {
    test('RecommendedJob deserializes from full JSON envelope correctly', () {
      final json = {
        'job': sampleJob.toJson(),
        'reason': 'Khớp 95% với kỹ năng Flutter & Dart trong hồ sơ của bạn',
        'matchType': 'skills',
      };

      final model = RecommendedJob.fromJson(json);

      expect(model.job.id, 'rec-job-1');
      expect(model.job.title, 'Senior Flutter Developer');
      expect(
        model.reason,
        'Khớp 95% với kỹ năng Flutter & Dart trong hồ sơ của bạn',
      );
      expect(model.matchType, 'skills');
    });

    test('RecommendedJob deserializes flat job JSON with fallback reason', () {
      final json = sampleJob.toJson();

      final model = RecommendedJob.fromJson(
        json,
        defaultReason: 'Gợi ý xu hướng',
      );

      expect(model.job.id, 'rec-job-1');
      expect(model.reason, 'Gợi ý xu hướng');
      expect(model.matchType, isNull);
    });

    test('RecommendedJob toJson and copyWith work as expected', () {
      final original = RecommendedJob(
        job: sampleJob,
        reason: 'Lý do ban đầu',
        matchType: 'trending',
      );

      final copy = original.copyWith(reason: 'Lý do cập nhật');

      expect(copy.reason, 'Lý do cập nhật');
      expect(copy.matchType, 'trending');

      final serialized = copy.toJson();
      expect(serialized['reason'], 'Lý do cập nhật');
      expect(serialized['matchType'], 'trending');
      expect(serialized.containsKey('matchScore'), isFalse);
    });

    test('RecommendationExplanation fromJson and toJson work correctly', () {
      final json = {
        'job_id': 'job-1',
        'reason': 'Kỹ năng phù hợp với hồ sơ ứng viên',
        'score': 92,
      };

      final expl = RecommendationExplanation.fromJson(json);
      expect(expl.jobId, 'job-1');
      expect(expl.reason, 'Kỹ năng phù hợp với hồ sơ ứng viên');
      expect(expl.score, 92);

      final out = expl.toJson();
      expect(out['jobId'], 'job-1');
      expect(out['score'], 92);
    });
  });

  group('Job Repositories Recommendation Integration (RECOMMEND-01)', () {
    test(
      'MockJobRepository returns personalized recommendations with limits',
      () async {
        final mockRepo = MockJobRepository();

        final recommendations = await mockRepo.getRecommendedJobs(limit: 3);

        expect(recommendations.length, 3);
        expect(recommendations.first.reason, contains('Flutter'));
        expect(recommendations.first.matchType, 'skills');

        final explanation = await mockRepo.explainRecommendation('job-1');
        expect(explanation, isNotNull);
        expect(explanation!.jobId, 'job-1');
        expect(explanation.reason, contains('Flutter'));
      },
    );

    test(
      'ApiJobRepository parses recommendations from remote Gateway',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
        dio.httpClientAdapter = _FakeHttpAdapter((options) {
          if (options.path == '/api/jobs/recommended') {
            return {
              'items': [sampleJob.toJson()],
              'reasons': {'rec-job-1': 'Phù hợp 95% theo kỹ năng của bạn'},
            };
          }
          if (options.path == '/api/jobs/recommended/explain') {
            return {
              'jobId': 'rec-job-1',
              'reason': 'Giải thích chi tiết về độ phù hợp',
              'score': 95,
            };
          }
          return {};
        });

        final apiRepo = ApiJobRepository(dio: dio);

        final recs = await apiRepo.getRecommendedJobs(limit: 5);
        expect(recs.isNotEmpty, isTrue);
        expect(recs.first.job.id, 'rec-job-1');
        expect(recs.first.reason, 'Phù hợp 95% theo kỹ năng của bạn');

        final expl = await apiRepo.explainRecommendation('rec-job-1');
        expect(expl, isNotNull);
        expect(expl!.reason, 'Giải thích chi tiết về độ phù hợp');
      },
    );
  });

  group('RecommendedJobCard Widget Tests', () {
    testWidgets('renders all card components, badges, and triggers callbacks', (
      tester,
    ) async {
      bool tapped = false;

      final item = RecommendedJob(
        job: sampleJob,
        reason: 'Khớp 95% với kỹ năng trong hồ sơ của bạn',
        matchType: 'skills',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: RecommendedJobCard(
                recommendation: item,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title, company name, location, score badge, and rationale
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('Tech Innovations Corp'), findsOneWidget);
      expect(find.text('Đà Nẵng'), findsOneWidget);
      expect(find.text('95% Phù hợp'), findsNothing);
      expect(find.text('Kỹ năng tương thích'), findsOneWidget);
      expect(
        find.text('Khớp 95% với kỹ năng trong hồ sơ của bạn'),
        findsOneWidget,
      );

      // Tap card
      await tester.tap(find.text('Senior Flutter Developer'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'renders without overflow at small viewport with 1.5x font scale',
      (tester) async {
        final item = RecommendedJob(
          job: sampleJob,
          reason:
              'Lý do gợi ý rất dài nhằm kiểm tra độ co giãn và khả năng chống tràn bố cục trên màn hình nhỏ',
          matchType: 'trending',
        );

        tester.view.physicalSize = const Size(345, 680);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(345, 680),
                textScaler: TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: RecommendedJobCard(recommendation: item, onTap: () {}),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Xu hướng tuần'), findsOneWidget);
      },
    );
  });

  group('RecommendedJobsSection Widget Tests', () {
    testWidgets('renders shimmer loader when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecommendedJobsSection(
              recommendations: const [],
              isLoading: true,
              onRefresh: () async {},
              onJobTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RecommendedJobsShimmer), findsOneWidget);
      expect(find.text('Việc làm gợi ý cho bạn'), findsOneWidget);
    });

    testWidgets(
      'renders error banner and retry button when errorMessage is provided',
      (tester) async {
        bool refreshed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: RecommendedJobsSection(
                recommendations: const [],
                isLoading: false,
                errorMessage: 'Lỗi tải gợi ý việc làm',
                onRefresh: () async => refreshed = true,
                onJobTap: (_) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Lỗi tải gợi ý việc làm'), findsOneWidget);
        expect(find.text('Thử lại'), findsOneWidget);

        await tester.tap(find.text('Thử lại'));
        expect(refreshed, isTrue);
      },
    );

    testWidgets(
      'renders populated list and refresh button triggers onRefresh',
      (tester) async {
        bool refreshed = false;
        RecommendedJob? tappedItem;

        final items = [
          RecommendedJob(
            job: sampleJob,
            reason: 'Phù hợp 96% theo kỹ năng',
            matchType: 'skills',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: RecommendedJobsSection(
                recommendations: items,
                isLoading: false,
                onRefresh: () async => refreshed = true,
                onJobTap: (item) => tappedItem = item,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('recommended_jobs_list')), findsOneWidget);
        expect(find.text('Senior Flutter Developer'), findsOneWidget);

        // Tap card
        await tester.tap(find.text('Senior Flutter Developer'));
        expect(tappedItem?.job.id, 'rec-job-1');

        // Tap refresh button
        await tester.tap(
          find.byKey(const Key('refresh_recommendations_button')),
        );
        expect(refreshed, isTrue);
      },
    );
  });

  group('HomeScreen Integration with RecommendedJobsSection', () {
    testWidgets(
      'displays recommended jobs section for authenticated candidate',
      (tester) async {
        AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'cand-1',
              name: 'Nguyễn Văn A',
              email: 'candidate@example.com',
              role: UserRole.user,
              createdAt: DateTime.now(),
            ),
            token: 'token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        final mockAuth = MockAuthRepository();
        final mockJob = MockJobRepository();

        final router = GoRouter(
          initialLocation: AppRoutes.home,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) =>
                  HomeScreen(authRepository: mockAuth, jobRepository: mockJob),
            ),
            GoRoute(
              path: '${AppRoutes.jobs}/:id',
              builder: (context, state) => Scaffold(
                body: Text(
                  'Job Detail Destination: ${state.pathParameters['id']}',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
        );

        await tester.pumpAndSettle();

        // Check section header is rendered on home screen
        expect(find.text('Việc làm gợi ý cho bạn'), findsOneWidget);
        expect(
          find.text('Cá nhân hóa theo hồ sơ và kỹ năng của bạn'),
          findsOneWidget,
        );

        // Tap on the first recommended card to navigate to job detail
        await tester.tap(find.byKey(const Key('recommended_job_job-1')));
        await tester.pumpAndSettle();

        expect(find.text('Job Detail Destination: job-1'), findsOneWidget);
      },
    );

    testWidgets(
      'HomeScreen mounts shimmer and error state properly during recommendations lifecycle',
      (tester) async {
        AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'u-1',
              email: 'cand@test.com',
              name: 'Candidate Test',
              role: UserRole.user,
              createdAt: DateTime.now(),
            ),
            token: 'token',
            refreshToken: 'ref-token',
            expiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
        );

        final mockAuth = MockAuthRepository();
        final mockJob = MockJobRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: HomeScreen(authRepository: mockAuth, jobRepository: mockJob),
          ),
        );

        // Before pumpAndSettle, while loading:
        await tester.pump();
        expect(find.byType(RecommendedJobsShimmer), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(RecommendedJobsSection), findsOneWidget);
      },
    );

    test('RecommendedJob maps backend strategy and ignores any score', () {
      final collaborative = RecommendedJob.fromJson({
        'job': sampleJob.toJson(),
        'strategy': 'Collaborative',
      });
      expect(collaborative.matchType, 'collaborative');

      final content = RecommendedJob.fromJson({
        'job': sampleJob.toJson(),
        'strategy': 'Content',
      });
      expect(content.matchType, 'content');

      final popular = RecommendedJob.fromJson({
        'job': sampleJob.toJson(),
        'strategy': 'Popular',
      });
      expect(popular.matchType, 'popular');

      // No strategy means no label: nothing is invented.
      final none = RecommendedJob.fromJson({'job': sampleJob.toJson()});
      expect(none.matchType, isNull);

      // A legacy numeric score is no longer read.
      final withScore = RecommendedJob.fromJson({
        'job': sampleJob.toJson(),
        'score': 0.88,
        'strategy': 'Popular',
      });
      expect(withScore.matchType, 'popular');
      expect(withScore.toJson().containsKey('score'), isFalse);
    });

    testWidgets('RecommendedJobCard handles whitespace company name safely', (
      tester,
    ) async {
      final blankCompanyJob = sampleJob.copyWith(companyName: '   ');
      final rec = RecommendedJob(job: blankCompanyJob, reason: 'Test reason');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecommendedJobCard(recommendation: rec, onTap: () {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('RecommendedJobCard shows the strategy label and no score', (
      tester,
    ) async {
      final item = RecommendedJob.fromJson({
        'job': sampleJob.toJson(),
        'reason': 'Người dùng có hồ sơ tương tự đã ứng tuyển',
        'strategy': 'Collaborative',
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RecommendedJobCard(recommendation: item, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Người dùng tương tự'), findsOneWidget);
      expect(find.textContaining('% Phù hợp'), findsNothing);
    });
  });
}
