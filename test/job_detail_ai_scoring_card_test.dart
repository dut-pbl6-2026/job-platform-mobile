import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/services/file_picker_service.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_detail_ai_scoring_card.dart';

class _MockAiRepo implements IAiRepository {
  ResumeFeedback? predefinedFeedback;
  AiFailure? failure;
  int scoreResumeCalls = 0;

  @override
  Future<AiChatReply> sendMessage(String message, {String? sessionId}) async {
    return const AiChatReply(response: 'Mock', sessionId: 's-1');
  }

  @override
  Stream<AiChatChunk> streamChat(String message, {String? sessionId}) async* {
    yield const AiChatChunk(delta: 'Mock', sessionId: 's-1', done: true);
  }

  @override
  Future<void> clearSession(String sessionId) async {}

  @override
  Future<ResumeFeedback> scoreResume(
    AiCvInput cv, {
    required String jobId,
  }) async {
    scoreResumeCalls++;
    if (failure != null) throw failure!;
    return predefinedFeedback ??
        const ResumeFeedback(
          score: 88.5,
          matchingSkills: ['Flutter', 'Dart', 'Bloc', 'REST API'],
          missingSkills: ['Kubernetes', 'Docker'],
          extraSkills: ['GraphQL', 'Firebase'],
          experienceScore: 92,
          experienceYears: 4,
          requiredExperienceYears: 3,
          experienceRelevance: 'Rất phù hợp',
          educationScore: 90,
          educationDegree: 'Kỹ sư CNTT',
          requiredEducationDegree: 'Đại học chuyên ngành CNTT',
          suggestions: [
            'Nêu bật các dự án Flutter thực tế trên production',
            'Bổ sung chứng chỉ Kubernetes nếu có',
          ],
        );
  }

  @override
  void cancelCurrentRequest() {}
}

class _NullCvPickerService implements ICvPickerService {
  @override
  Future<SelectedCvFile?> pickCvFile() async => null;
}

void main() {
  late _MockAiRepo aiRepo;
  late MockCvPickerService pickerService;
  late JobModel sampleJob;

  setUp(() async {
    aiRepo = _MockAiRepo();
    pickerService = MockCvPickerService(
      predefinedFile: SelectedCvFile(
        name: 'Nguyen_Van_A_CV.pdf',
        size: 350 * 1024,
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    final repo = MockJobRepository();
    sampleJob = (await repo.getJobById('job-1'))!;
  });

  testWidgets(
    'JobDetailAiScoringCard renders idle state with AI badge and button',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JobDetailAiScoringCard(
                job: sampleJob,
                aiRepository: aiRepo,
                cvPickerService: pickerService,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chấm điểm CV với vị trí này'), findsOneWidget);
      expect(
        find.text('Phân tích kỹ năng, kinh nghiệm & gợi ý tối ưu CV'),
        findsOneWidget,
      );
      expect(find.text('AI'), findsOneWidget);
      expect(
        find.byKey(const Key('job_detail_score_resume_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'JobDetailAiScoringCard transitions from idle -> scoring -> result inline',
    (tester) async {
      bool applyPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JobDetailAiScoringCard(
                job: sampleJob,
                aiRepository: aiRepo,
                cvPickerService: pickerService,
                onApplyPressed: () => applyPressed = true,
              ),
            ),
          ),
        ),
      );

      // Tap to trigger scoring
      await tester.tap(find.byKey(const Key('job_detail_score_resume_button')));
      await tester.pumpAndSettle();

      // Check result view
      expect(find.text('Kết quả chấm điểm AI'), findsOneWidget);
      expect(find.text('88.5 / 100'), findsOneWidget);
      expect(find.text('Rất phù hợp'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Kubernetes'), findsOneWidget);
      expect(find.text('Kỹ năng bổ sung trong CV'), findsOneWidget);
      expect(find.text('GraphQL'), findsOneWidget);
      expect(find.text('Kinh nghiệm làm việc'), findsOneWidget);
      expect(find.text('Học vấn & Bằng cấp'), findsOneWidget);
      expect(find.text('Gợi ý tối ưu từ AI'), findsOneWidget);

      // Verify Apply button triggers callback
      expect(
        find.byKey(const Key('job_detail_apply_after_scoring_button')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const Key('job_detail_apply_after_scoring_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('job_detail_apply_after_scoring_button')),
      );
      expect(applyPressed, isTrue);
    },
  );

  testWidgets('JobDetailAiScoringCard handles file cancel gracefully', (
    tester,
  ) async {
    final cancellingPicker = _NullCvPickerService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: JobDetailAiScoringCard(
              job: sampleJob,
              aiRepository: aiRepo,
              cvPickerService: cancellingPicker,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('job_detail_score_resume_button')));
    await tester.pumpAndSettle();

    // Should return to idle banner smoothly
    expect(find.text('Chấm điểm CV với vị trí này'), findsOneWidget);
    expect(aiRepo.scoreResumeCalls, equals(0));
  });

  testWidgets(
    'JobDetailAiScoringCard rejects .doc files immediately without calling AI service',
    (tester) async {
      final docPicker = MockCvPickerService(
        predefinedFile: const SelectedCvFile(
          name: 'my_resume.doc',
          path: '/tmp/my_resume.doc',
          size: 1024,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: JobDetailAiScoringCard(
                job: sampleJob,
                aiRepository: aiRepo,
                cvPickerService: docPicker,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('job_detail_score_resume_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Vui lòng chọn CV định dạng PDF hoặc DOCX (dung lượng tối đa 5 MB).',
        ),
        findsOneWidget,
      );
      expect(aiRepo.scoreResumeCalls, equals(0));
    },
  );

  testWidgets(
    'JobDetailAiScoringCard responsive layout at 345px width with 1.5x font scale',
    (tester) async {
      tester.view.physicalSize = const Size(345 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(345, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: JobDetailAiScoringCard(
                  job: sampleJob,
                  aiRepository: aiRepo,
                  cvPickerService: pickerService,
                  onApplyPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('job_detail_score_resume_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kết quả chấm điểm AI'), findsOneWidget);
      expect(find.text('88.5 / 100'), findsOneWidget);
    },
  );
}
