import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/services/file_picker_service.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/resume_scoring_screen.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';

class _MockScoringAiRepo implements IAiRepository {
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
          suggestions: ['Bổ sung Docker vào CV'],
        );
  }

  @override
  void cancelCurrentRequest() {}
}

void main() {
  late _MockScoringAiRepo aiRepo;
  late MockJobRepository jobRepo;
  late MockCvPickerService pickerService;

  setUp(() {
    aiRepo = _MockScoringAiRepo();
    jobRepo = MockJobRepository();
    pickerService = MockCvPickerService(
      predefinedFile: SelectedCvFile(
        name: 'NguyenVanAn_CV.pdf',
        size: 2 * 1024 * 1024,
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
  });

  testWidgets(
    'ResumeScoringScreen initial view renders header, job/CV selectors, and submit button (SCORE-01)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResumeScoringScreen(
            repository: aiRepo,
            jobRepository: jobRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      expect(find.text('Mức độ phù hợp CV'), findsOneWidget);
      expect(
        find.text('SCORE-01 · AI Smart Resume Scoring Engine'),
        findsOneWidget,
      );
      expect(find.text('Đối chiếu CV với việc làm'), findsOneWidget);
      expect(find.byKey(const Key('scoring_choose_job')), findsOneWidget);
      expect(find.byKey(const Key('scoring_choose_cv')), findsOneWidget);
      expect(find.byKey(const Key('scoring_submit')), findsOneWidget);
    },
  );

  testWidgets(
    'ResumeScoringScreen pre-populates target job when passed via constructor',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResumeScoringScreen(
            jobId: 'job-1',
            targetJobTitle: 'Senior Flutter Developer',
            repository: aiRepo,
            jobRepository: jobRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Senior Flutter Developer'), findsOneWidget);
    },
  );

  testWidgets(
    'ResumeScoringScreen validates missing selection and shows error on submit',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResumeScoringScreen(
            repository: aiRepo,
            jobRepository: jobRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('scoring_submit')));
      await tester.pumpAndSettle();

      expect(aiRepo.scoreResumeCalls, 0);
      expect(
        find.text('Vui lòng chọn việc làm và tải CV trước khi chấm.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ResumeScoringScreen renders full SRS 5.3.4 breakdown (Skills, Experience, Education, Suggestions)',
    (tester) async {
      aiRepo.predefinedFeedback = const ResumeFeedback(
        score: 78,
        skillsScore: 85,
        matchingSkills: ['React', 'JavaScript', 'TypeScript'],
        missingSkills: ['Node.js', 'Docker'],
        extraSkills: ['Vue.js'],
        experienceScore: 75,
        experienceYears: 3,
        requiredExperienceYears: 5,
        experienceRelevance: 'High',
        educationScore: 70,
        educationDegree: "Bachelor's",
        requiredEducationDegree: "Bachelor's",
        educationRelevance: 'Match',
        suggestions: [
          'Add Node.js to your skills section',
          'Highlight Docker experience',
          'Expand on React project details',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResumeScoringScreen(
            jobId: 'job-1',
            targetJobTitle: 'Frontend Engineer',
            repository: aiRepo,
            jobRepository: jobRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      // Pick CV
      await tester.tap(find.byKey(const Key('scoring_choose_cv')));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('scoring_submit')));
      await tester.pumpAndSettle();

      expect(aiRepo.scoreResumeCalls, 1);

      // Verify Overall Score & Badge
      expect(find.text('78 / 100'), findsOneWidget);
      expect(find.text('Khá phù hợp'), findsOneWidget);

      // Verify Skills Breakdown
      expect(find.text('Kỹ năng phù hợp'), findsOneWidget);
      expect(find.text('React'), findsOneWidget);
      expect(find.text('TypeScript'), findsOneWidget);
      expect(find.text('Cần bổ sung'), findsOneWidget);
      expect(find.text('Node.js'), findsOneWidget);
      expect(find.text('Docker'), findsOneWidget);
      expect(find.text('Kỹ năng bổ sung trong CV'), findsOneWidget);
      expect(find.text('Vue.js'), findsOneWidget);

      // Verify Experience Breakdown
      expect(find.text('Đánh giá Kinh nghiệm làm việc'), findsOneWidget);
      expect(find.textContaining('3 năm'), findsOneWidget);
      expect(find.textContaining('Yêu cầu: 5 năm'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);

      // Verify Education Breakdown
      expect(find.text('Trình độ Học vấn & Bằng cấp'), findsOneWidget);
      expect(find.text("Bachelor's"), findsWidgets);
      expect(find.text('Match'), findsOneWidget);

      // Verify Suggestions
      expect(find.text('Gợi ý cải thiện'), findsOneWidget);
      expect(find.text('Add Node.js to your skills section'), findsOneWidget);

      // Verify Disclaimer & CTA buttons
      expect(find.text('Lưu ý'), findsOneWidget);
      expect(find.text('Ứng tuyển ngay'), findsOneWidget);
      expect(find.text('Chấm điểm lại / Chọn file khác'), findsOneWidget);
    },
  );

  testWidgets(
    'ResumeScoringScreen resets feedback when tapping re-score button',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResumeScoringScreen(
            jobId: 'job-1',
            targetJobTitle: 'Senior Flutter Developer',
            repository: aiRepo,
            jobRepository: jobRepo,
            cvPickerService: pickerService,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('scoring_choose_cv')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring_submit')));
      await tester.pumpAndSettle();

      expect(find.text('85 / 100'), findsOneWidget);

      // Tap re-score
      await tester.ensureVisible(find.text('Chấm điểm lại / Chọn file khác'));
      await tester.tap(find.text('Chấm điểm lại / Chọn file khác'));
      await tester.pumpAndSettle();

      // Feedback is cleared
      expect(find.text('85 / 100'), findsNothing);
      expect(find.text('Phân tích CV'), findsOneWidget);
    },
  );
}
