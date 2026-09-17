import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/presentation/search_screen.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_card.dart';

void main() {
  testWidgets(
    'SearchScreen renders search input, trending keywords, and performs search',
    (tester) async {
      final mockJobRepo = MockJobRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SearchScreen(jobRepository: mockJobRepo),
        ),
      );

      // Settle initial load
      await tester.pumpAndSettle();

      // Check search input hint
      expect(find.text('Tên công việc, vị trí, công ty...'), findsOneWidget);

      // Check location selector bar
      expect(find.text('Tất cả địa điểm (Toàn quốc)'), findsOneWidget);

      // Check trending searches section
      expect(find.text('Từ khóa tìm kiếm phổ biến'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('ReactJS'), findsOneWidget);

      // Tap on 'Flutter' trending tag
      await tester.tap(find.text('Flutter'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify search results are displayed
      expect(find.byType(JobCard), findsWidgets);
      expect(find.textContaining('Tìm thấy'), findsOneWidget);
    },
  );

  testWidgets(
    'SearchScreen displays auto-complete suggestions when typing in search input',
    (tester) async {
      final mockJobRepo = MockJobRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SearchScreen(jobRepository: mockJobRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Type 'Flu' into search box
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên công việc, vị trí, công ty...'),
        'Flu',
      );
      await tester.pumpAndSettle();

      // Suggestion overlay should appear with 'Flutter Developer'
      expect(find.text('Flutter Developer'), findsOneWidget);

      // Tap suggestion to search
      await tester.tap(find.text('Flutter Developer'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Search results displayed
      expect(find.byType(JobCard), findsWidgets);
    },
  );

  testWidgets(
    'SearchScreen opens location picker bottom sheet and selects a location',
    (tester) async {
      final mockJobRepo = MockJobRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SearchScreen(jobRepository: mockJobRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on location selector bar
      await tester.tap(find.text('Tất cả địa điểm (Toàn quốc)'));
      await tester.pumpAndSettle();

      // Bottom sheet for selecting location should appear
      expect(find.text('Chọn địa điểm làm việc'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'TP Đà Nẵng'), findsOneWidget);

      // Tap on 'TP Đà Nẵng' chip in bottom sheet
      await tester.tap(find.widgetWithText(ChoiceChip, 'TP Đà Nẵng'));
      await tester.pumpAndSettle();

      // Location bar should now show 'Địa điểm: Đà Nẵng'
      expect(find.text('Địa điểm: Đà Nẵng'), findsOneWidget);
    },
  );

  testWidgets('SearchScreen shows empty state when no matching results', (
    tester,
  ) async {
    final mockJobRepo = MockJobRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SearchScreen(jobRepository: mockJobRepo),
      ),
    );

    await tester.pumpAndSettle();

    // Enter a query that yields no results
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên công việc, vị trí, công ty...'),
      'nonexistent_query_xyz_123456',
    );
    // Wait for debounce timer (400ms)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('Không tìm thấy việc làm phù hợp'), findsOneWidget);
  });
}
