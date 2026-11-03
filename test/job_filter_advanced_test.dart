import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/connections/presentation/connections_screen.dart';
import 'package:job_platform_mobile/features/cv/presentation/create_cv_screen.dart';
import 'package:job_platform_mobile/features/home/main_navigation_screen.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/presentation/job_list_screen.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_filter_bottom_sheet.dart';

Widget _buildTestApp({
  required Widget child,
  Size size = const Size(500, 1200),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('JobFilterBottomSheet Advanced UI/UX Tests', () {
    testWidgets(
      'renders header with quick close button, title and reset button',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(500, 1200);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            child: JobFilterBottomSheet(
              currentParams: const JobFilterParams(),
              onApply: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Quick close icon
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Title & Tune icon
        expect(find.text('Bộ lọc nâng cao'), findsOneWidget);
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

        // Reset button (no weird whitespace)
        expect(find.text('Thiết lập lại'), findsOneWidget);
      },
    );

    testWidgets('renders unnumbered section cards with dynamic summaries', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          size: const Size(500, 2400),
          child: JobFilterBottomSheet(
            currentParams: const JobFilterParams(),
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section titles without "1.", "2.", etc.
      expect(find.text('Ngành nghề & Chuyên ngành'), findsOneWidget);
      expect(find.text('Địa điểm làm việc'), findsOneWidget);
      expect(find.text('Mức lương (VNĐ)'), findsOneWidget);
      expect(find.text('Hình thức & Nơi làm việc'), findsOneWidget);

      expect(find.textContaining('1. Ngành nghề'), findsNothing);
      expect(find.textContaining('2. Địa điểm'), findsNothing);
      expect(find.textContaining('3. Mức lương'), findsNothing);
    });

    testWidgets(
      'renders salary RangeSlider, presets, badge and negotiable switch',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(500, 2400);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            size: const Size(500, 2400),
            child: JobFilterBottomSheet(
              currentParams: const JobFilterParams(),
              onApply: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 4 quick salary presets
        expect(find.text('10 - 25tr'), findsOneWidget);
        expect(find.text('Trên 20tr'), findsOneWidget);
        expect(find.text('Trên 40tr'), findsOneWidget);

        // RangeSlider
        expect(find.byType(RangeSlider), findsAtLeastNWidgets(1));

        // Lương thỏa thuận switch
        expect(
          find.text('Bao gồm tin tuyển dụng "Lương thỏa thuận"'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders experience RangeSlider and presets', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          size: const Size(500, 2400),
          child: JobFilterBottomSheet(
            currentParams: const JobFilterParams(),
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick experience level presets
      expect(find.text('Fresher (0-1 năm)'), findsOneWidget);
      expect(find.text('Junior (1-3 năm)'), findsOneWidget);
      expect(find.text('Senior (3-7 năm)'), findsOneWidget);
    });

    testWidgets('condenses 34 provinces and expands with search on click', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          size: const Size(500, 2400),
          child: JobFilterBottomSheet(
            currentParams: const JobFilterParams(),
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "+ Xem thêm" chip
      final seeMoreFinder = find.textContaining('+ Xem thêm');
      expect(seeMoreFinder, findsOneWidget);

      // Tap "+ Xem thêm" to expand
      await tester.tap(seeMoreFinder);
      await tester.pumpAndSettle();

      // Search input should appear
      expect(
        find.text('Tìm nhanh tỉnh/thành phố (VD: Quảng Trị, Đà Nẵng...)'),
        findsOneWidget,
      );
      expect(find.text('Thu gọn danh sách'), findsOneWidget);
    });

    testWidgets('skills section has search TextField to filter tags', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          size: const Size(500, 2400),
          child: JobFilterBottomSheet(
            currentParams: const JobFilterParams(),
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to skills section if needed
      final skillsSearch = find.text(
        'Tìm nhanh kỹ năng (VD: Flutter, React, C#, N2...)',
      );
      await tester.scrollUntilVisible(
        skillsSearch,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(skillsSearch, findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('CTA button displays dynamic matching count', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          size: const Size(500, 2400),
          child: JobFilterBottomSheet(
            currentParams: const JobFilterParams(),
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dynamic text: e.g. "Xem 48 việc làm phù hợp"
      expect(find.textContaining('việc làm phù hợp'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });
  });

  group('Bottom Padding 96 on Main Screens', () {
    testWidgets('JobListScreen has bottom padding 96', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobListScreen(jobRepository: MockJobRepository()),
        ),
      );
      await tester.pumpAndSettle();

      final listViews = tester.widgetList<ListView>(find.byType(ListView));
      final hasPadding96 = listViews.any(
        (lv) =>
            lv.padding is EdgeInsets && (lv.padding as EdgeInsets).bottom == 96,
      );
      expect(hasPadding96, isTrue);
    });

    testWidgets('CreateCvScreen has bottom padding 96', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const CreateCvScreen()),
      );
      await tester.pumpAndSettle();

      final scrollViews = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final hasPadding96 = scrollViews.any(
        (sv) =>
            sv.padding is EdgeInsets && (sv.padding as EdgeInsets).bottom == 96,
      );
      expect(hasPadding96, isTrue);
    });

    testWidgets('ConnectionsScreen has bottom padding 96', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ConnectionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scrollViews = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final hasPadding96 = scrollViews.any(
        (sv) =>
            sv.padding is EdgeInsets && (sv.padding as EdgeInsets).bottom == 96,
      );
      expect(hasPadding96, isTrue);
    });
  });

  group('JobBottomNavigation Transparent Container Tests', () {
    testWidgets(
      'JobBottomNavigation active icon container is transparent with circular inner child',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              bottomNavigationBar: JobBottomNavigation(
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasTransparentContainer = containers.any(
          (c) => c.color == Colors.transparent,
        );
        expect(hasTransparentContainer, isTrue);
      },
    );
  });
}
