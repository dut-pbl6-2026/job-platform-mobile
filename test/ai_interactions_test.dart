import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/services/file_picker_service.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/ai_copilot_screen.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/resume_scoring_screen.dart';
import 'support/fake_ai_repository.dart';
import 'support/figma_job_fixture.dart';

void main() {
  testWidgets('AI-01 failure is visible; retry does not duplicate question', (
    tester,
  ) async {
    final repo = FakeAiRepository()
      ..failure = 'Dịch vụ AI đang không khả dụng.';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AiCopilotScreen(repository: repo),
      ),
    );
    await tester.enterText(find.byKey(const Key('ai_question')), 'Tìm việc');
    await tester.tap(find.byKey(const Key('ai_send')));
    await tester.pumpAndSettle();
    expect(find.text('Dịch vụ AI đang không khả dụng.'), findsOneWidget);
    expect(find.text('90% phù hợp'), findsNothing);
    repo.failure = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm việc'), findsOneWidget);
    expect(repo.messages.length, 2);
    await tester.enterText(find.byKey(const Key('ai_question')), 'Tư vấn CV');
    await tester.tap(find.byKey(const Key('ai_send')));
    await tester.pumpAndSettle();
    expect(repo.lastSessionId, 'session-123');
  });

  testWidgets(
    'AI-01 pending request prevents duplicate submit and can be stopped',
    (tester) async {
      final repo = _PendingAi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AiCopilotScreen(repository: repo),
        ),
      );
      await tester.tap(find.text('Gợi ý việc làm'));
      await tester.pump();
      final send = tester.widget<IconButton>(find.byKey(const Key('ai_send')));
      expect(send.onPressed, isNull);
      expect(repo.messages.length, 1);
      await tester.tap(find.text('Dừng'));
      await tester.pump();
      expect(repo.cancelled, isTrue);
      repo.reply.complete(
        const AiChatReply(response: 'Late response', sessionId: 'late'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Late response'), findsNothing);
      expect(find.text('Đã dừng yêu cầu.'), findsOneWidget);
    },
  );

  testWidgets(
    'SCORE-01 validates selection and displays only returned feedback',
    (tester) async {
      final repo = FakeAiRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ResumeScoringScreen(
            repository: repo,
            jobRepository: FigmaJobFixture(),
            cvPickerService: MockCvPickerService(
              predefinedFile: SelectedCvFile(
                name: 'cv.pdf',
                size: 3,
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('scoring_submit')));
      await tester.pumpAndSettle();
      expect(repo.scoreCalls, 0);
      expect(find.text('82 / 100'), findsNothing);
      await tester.tap(find.byKey(const Key('scoring_choose_job')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('UI/UX Designer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring_choose_cv')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring_submit')));
      await tester.pumpAndSettle();
      expect(repo.scoreCalls, 1);
      expect(find.text('82 / 100'), findsOneWidget);
      expect(find.text('Bổ sung kết quả dự án.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PendingAi extends FakeAiRepository {
  final reply = Completer<AiChatReply>();
  @override
  Future<AiChatReply> sendMessage(String message, {String? sessionId}) {
    messages.add(message);
    return reply.future;
  }
}
