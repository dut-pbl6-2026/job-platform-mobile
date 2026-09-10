import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/applications/data/repositories/mock_application_repository.dart';
import 'package:job_platform_mobile/features/applications/presentation/application_history_screen.dart';

void main() {
  late MockApplicationRepository mockRepo;

  setUp(() {
    mockRepo = MockApplicationRepository();
    mockRepo.clear();
  });

  testWidgets(
    'ApplicationHistoryScreen renders title, filter chips, and application cards (MOB-01-06)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ApplicationHistoryScreen(applicationRepository: mockRepo),
        ),
      );

      // Initial pump: loading
      expect(find.text('Lịch sử ứng tuyển'), findsOneWidget);

      // Settle async fetch
      await tester.pumpAndSettle();

      // Verify filter chips exist
      expect(find.widgetWithText(FilterChip, 'Tất cả'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Chờ duyệt'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Đã xem'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Phù hợp'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Trúng tuyển'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Từ chối'), findsOneWidget);

      // Verify application cards are rendered
      expect(
        find.text('Senior Flutter Developer (Cross-Platform)'),
        findsOneWidget,
      );
      expect(find.text('FPT Software'), findsOneWidget);
      expect(find.text('VNG Corporation'), findsOneWidget);
    },
  );

  testWidgets('ApplicationHistoryScreen filtering by status updates the list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ApplicationHistoryScreen(applicationRepository: mockRepo),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on "Đã xem" filter chip specifically
    await tester.tap(find.widgetWithText(FilterChip, 'Đã xem'));
    await tester.pumpAndSettle();

    // Verify FPT Software (reviewed) is displayed, VNG (shortlisted) is hidden
    expect(
      find.text('Senior Flutter Developer (Cross-Platform)'),
      findsOneWidget,
    );
    expect(find.text('VNG Corporation'), findsNothing);
  });

  testWidgets(
    'Tapping an application card navigates to ApplicationDetailScreen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ApplicationHistoryScreen(applicationRepository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Tap first application card (FPT Software)
      await tester.tap(find.text('Senior Flutter Developer (Cross-Platform)'));
      await tester.pumpAndSettle();

      // Verify ApplicationDetailScreen rendered
      expect(find.text('Chi tiết ứng tuyển'), findsOneWidget);
      expect(find.text('Tiến độ xét duyệt'), findsOneWidget);
      expect(find.text('Hồ sơ CV đã nộp'), findsOneWidget);
    },
  );
}
