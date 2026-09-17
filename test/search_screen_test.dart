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
      expect(find.text('Tìm công việc, công ty, kỹ năng...'), findsOneWidget);

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
      find.byType(TextField),
      'nonexistent_query_xyz_123456',
    );
    // Wait for debounce timer (400ms)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('Không tìm thấy việc làm phù hợp'), findsOneWidget);
  });
}
