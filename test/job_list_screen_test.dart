import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/presentation/job_list_screen.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_card.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_search_bar.dart';

void main() {
  testWidgets('JobListScreen renders search bar, filters and jobs correctly', (tester) async {
    final mockRepo = MockJobRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: JobListScreen(jobRepository: mockRepo),
      ),
    );

    // Initial pump: Shimmer loading is displayed
    expect(find.byType(JobSearchBar), findsOneWidget);

    // Wait for mock data fetch to complete
    await tester.pumpAndSettle();

    // Verify Job cards are rendered
    expect(find.byType(JobCard), findsWidgets);
    expect(find.text('Tìm việc làm'), findsOneWidget);
    expect(find.text('Tất cả'), findsWidgets);
    expect(find.text('IT / Phần mềm'), findsOneWidget);

    // Verify search input interaction
    await tester.enterText(find.byType(TextField), 'Flutter');
    // Allow debounce timer (350ms) to trigger
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // After debounce search, verify matching jobs are displayed
    expect(find.byType(JobCard), findsWidgets);
  });
}
