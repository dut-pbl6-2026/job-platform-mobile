import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/services/file_picker_service.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/presentation/job_detail_screen.dart';

class _MockTestAiRepo implements IAiRepository {
  ResumeFeedback? predefinedFeedback;
  AiFailure? failure;
  int scoreResumeCalls = 0;
  AiCvInput? lastCvInput;
  String? lastJobId;

  @override
  Future<AiChatReply> sendMessage(String message, {String? sessionId}) async {
    return const AiChatReply(response: 'Mock', sessionId: 's-1');
  }

  @override
  Future<ResumeFeedback> scoreResume(
    AiCvInput cv, {
    required String jobId,
  }) async {
    scoreResumeCalls++;
    lastCvInput = cv;
    lastJobId = jobId;
    if (failure != null) throw failure!;
    return predefinedFeedback ??
        const ResumeFeedback(
          score: 85,
          matchingSkills: ['Flutter', 'Dart'],
          missingSkills: ['Docker'],
          extraSkills: ['Firebase'],
          experienceScore: 90,
          experienceYears: 3,
          requiredExperienceYears: 2,
          experienceRelevance: 'Phù hợp cao',
          educationScore: 95,
          educationDegree: 'Đại học Bách Khoa',
          requiredEducationDegree: 'Đại học chuyên ngành CNTT',
          suggestions: ['Bổ sung kiến thức Docker Containerization vào CV'],
        );
  }

  @override
  void cancelCurrentRequest() {}
}

void main() {
  late MockJobRepository mockRepo;
  late _MockTestAiRepo aiRepo;
  late MockCvPickerService pickerService;

  setUp(() {
    mockRepo = MockJobRepository();
    aiRepo = _MockTestAiRepo();
    pickerService = MockCvPickerService(
      predefinedFile: SelectedCvFile(
        name: 'Nguyen_Van_A_CV.pdf',
        size: 500 * 1024,
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    AuthSession.instance.clearSession();
  });

  testWidgets(
    'JobDetailScreen renders job info, metrics, and content correctly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobDetailScreen(jobId: 'job-1', jobRepository: mockRepo),
        ),
      );

      // Initial pump: Shimmer loading
      expect(find.text('Chi tiết việc làm'), findsOneWidget);

      // Settle async fetch
      await tester.pumpAndSettle();

      // Verify Job info is displayed
      expect(
        find.text('Senior Flutter Developer (Cross-Platform)'),
        findsOneWidget,
      );
      expect(find.text('FPT Software'), findsWidgets);
      expect(find.text('Mô tả công việc'), findsOneWidget);
      expect(find.text('Yêu cầu ứng viên'), findsOneWidget);
      expect(find.text('Kỹ năng chuyên môn'), findsOneWidget);
      expect(find.text('Quyền lợi & Phúc lợi'), findsOneWidget);
      expect(find.text('Flutter'), findsWidgets);
      expect(find.text('Dart'), findsWidgets);

      // Verify Guest CTA button
      expect(find.text('Ứng tuyển ngay'), findsOneWidget);
    },
  );

  testWidgets(
    'JobDetailScreen shows recruiter CTA when logged in as recruiter',
    (tester) async {
      // Log in as recruiter
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'recruiter-1',
            name: 'HR Manager',
            email: 'recruiter@fpt.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: 'mock-recruiter-token',
          refreshToken: 'mock-refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobDetailScreen(jobId: 'job-1', jobRepository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Recruiter button is rendered
      expect(find.textContaining('Xem ứng viên'), findsOneWidget);
    },
  );

  testWidgets('JobDetailScreen shows error view when job is not found', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: JobDetailScreen(
          jobId: 'non-existent-job-id',
          jobRepository: mockRepo,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Không tìm thấy thông tin tin tuyển dụng này.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại danh sách'), findsOneWidget);
  });

  testWidgets(
    'JobDetailScreen runs AI scoring in-place and renders score & breakdown without leaving screen (SCORE-01)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobDetailScreen(
            jobId: 'job-1',
            jobRepository: mockRepo,
            aiRepository: aiRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AI scoring banner is rendered initially
      expect(find.text('Chấm điểm CV với vị trí này'), findsOneWidget);
      expect(
        find.text('Phân tích kỹ năng, kinh nghiệm & gợi ý tối ưu CV'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('job_detail_score_resume_button')),
        findsOneWidget,
      );

      // Tap the upload and score button
      await tester.tap(find.byKey(const Key('job_detail_score_resume_button')));
      await tester.pumpAndSettle();

      // Verify AI scoring ran inline
      expect(aiRepo.scoreResumeCalls, equals(1));
      expect(aiRepo.lastJobId, equals('job-1'));
      expect(aiRepo.lastCvInput?.name, equals('Nguyen_Van_A_CV.pdf'));

      // Verify Results are displayed directly in JobDetailScreen without leaving
      expect(find.text('Kết quả chấm điểm AI'), findsOneWidget);
      expect(find.text('85 / 100'), findsOneWidget);
      expect(find.text('Rất phù hợp'), findsOneWidget);
      expect(find.text('Kỹ năng phù hợp'), findsOneWidget);
      expect(find.text('Kỹ năng cần bổ sung'), findsOneWidget);
      expect(find.text('Docker'), findsOneWidget);
      expect(find.text('Kỹ năng bổ sung trong CV'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);
      expect(find.text('Kinh nghiệm làm việc'), findsOneWidget);
      expect(find.text('Học vấn & Bằng cấp'), findsOneWidget);
      expect(find.text('Gợi ý tối ưu từ AI'), findsOneWidget);
      expect(find.textContaining('Bổ sung kiến thức Docker'), findsOneWidget);

      // Verify action buttons
      expect(
        find.byKey(const Key('job_detail_rescore_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('job_detail_apply_after_scoring_button')),
        findsOneWidget,
      );

      // Test Collapse and Expand
      expect(find.text('Thu gọn'), findsOneWidget);
      await tester.tap(find.text('Thu gọn'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết'), findsOneWidget);
      expect(find.text('Kỹ năng phù hợp'), findsNothing);

      await tester.tap(find.text('Chi tiết'));
      await tester.pumpAndSettle();
      expect(find.text('Kỹ năng phù hợp'), findsOneWidget);

      // Test "Chấm lại CV khác"
      await tester.ensureVisible(
        find.byKey(const Key('job_detail_rescore_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('job_detail_rescore_button')));
      await tester.pumpAndSettle();
      expect(aiRepo.scoreResumeCalls, equals(2));
    },
  );

  testWidgets(
    'JobDetailScreen shows error card with retry when AI scoring fails',
    (tester) async {
      aiRepo.failure = const AiFailure('Gateway AI service timeout');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobDetailScreen(
            jobId: 'job-1',
            jobRepository: mockRepo,
            aiRepository: aiRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('job_detail_score_resume_button')));
      await tester.pumpAndSettle();

      expect(find.text('Không thể hoàn tất chấm điểm'), findsOneWidget);
      expect(find.text('Gateway AI service timeout'), findsOneWidget);
      expect(
        find.byKey(const Key('job_detail_retry_scoring_button')),
        findsOneWidget,
      );

      // Now recover failure and tap retry
      aiRepo.failure = null;
      await tester.tap(
        find.byKey(const Key('job_detail_retry_scoring_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết quả chấm điểm AI'), findsOneWidget);
      expect(find.text('85 / 100'), findsOneWidget);
    },
  );
}
