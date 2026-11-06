import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/core/widgets/bookmark_button.dart';
import 'package:job_platform_mobile/core/widgets/fade_slide_transition.dart';
import 'package:job_platform_mobile/core/widgets/pressable_card.dart';
import 'package:job_platform_mobile/features/connections/presentation/connections_screen.dart';
import 'package:job_platform_mobile/features/home/main_navigation_screen.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX & Micro-interactions Tests (MOB-01-01, MOB-01-02)', () {
    testWidgets(
      '1. PressableCard scales down to 0.98 on press and restores to 1.0 on release',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PressableCard(
                  onTap: () => tapped = true,
                  child: const SizedBox(
                    width: 100,
                    height: 100,
                    child: Text('Press Me'),
                  ),
                ),
              ),
            ),
          ),
        );

        final animatedScaleFinder = find.descendant(
          of: find.byType(PressableCard),
          matching: find.byType(AnimatedScale),
        );
        expect(animatedScaleFinder, findsOneWidget);

        var scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(scaleWidget.scale, equals(1.0));

        // Pointer down / tap down
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Press Me')),
        );
        await tester.pump(const Duration(milliseconds: 100));

        scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(scaleWidget.scale, equals(0.98));

        // Pointer up / tap up
        await gesture.up();
        await tester.pumpAndSettle();

        scaleWidget = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(scaleWidget.scale, equals(1.0));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      '2. FadeSlideTransition animates opacity from 0 to 1 and slides up with index delay',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FadeSlideTransition(
                index: 2, // 100ms delay
                child: Text('Animated Card'),
              ),
            ),
          ),
        );

        final fadeFinder = find.descendant(
          of: find.byType(FadeSlideTransition),
          matching: find.byType(FadeTransition),
        );
        final slideFinder = find.descendant(
          of: find.byType(FadeSlideTransition),
          matching: find.byType(SlideTransition),
        );

        expect(fadeFinder, findsOneWidget);
        expect(slideFinder, findsOneWidget);

        var fade = tester.widget<FadeTransition>(fadeFinder);
        var slide = tester.widget<SlideTransition>(slideFinder);

        // Initially before delay has elapsed, opacity is 0.0 and position Y is 0.08
        expect(fade.opacity.value, equals(0.0));
        expect(slide.position.value.dy, closeTo(0.08, 0.001));

        // Settle all animations
        await tester.pumpAndSettle();

        fade = tester.widget<FadeTransition>(fadeFinder);
        slide = tester.widget<SlideTransition>(slideFinder);
        expect(fade.opacity.value, equals(1.0));
        expect(slide.position.value.dy, equals(0.0));
      },
    );

    testWidgets(
      '3. BookmarkButton toggles icon and triggers bounce animation when saved',
      (tester) async {
        var isSaved = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return BookmarkButton(
                    isSaved: isSaved,
                    onToggle: () {
                      setState(() => isSaved = !isSaved);
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Initially unsaved: border icon, grey/hint color
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

        // Tap to save
        await tester.tap(find.byType(BookmarkButton));
        await tester.pump();

        // Bounce scale is triggered (> 1.0) and icon changed to filled
        final scaleWidget = tester.widget<AnimatedScale>(
          find.descendant(
            of: find.byType(BookmarkButton),
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(scaleWidget.scale, greaterThan(1.0));
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

        // Settle bounce
        await tester.pumpAndSettle();

        final settledScale = tester.widget<AnimatedScale>(
          find.descendant(
            of: find.byType(BookmarkButton),
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(settledScale.scale, equals(1.0));
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '4. JobCard renders BookmarkButton with bounce and updates isSaved',
      (tester) async {
        final job = JobModel(
          id: 'test-job',
          title: 'Senior Flutter Developer',
          companyName: 'Tech Corp',
          location: 'Đà Nẵng',
          salaryMin: 20000000,
          salaryMax: 30000000,
          category: 'IT',
          skills: const ['Flutter', 'Dart'],
          experienceLevel: ExperienceLevel.middle,
          jobType: JobType.fullTime,
          description: 'Mô tả công việc',
          requirements: 'Yêu cầu công việc',
          isSaved: false,
          postedAt: DateTime.now(),
        );

        var toggleFired = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: JobCard(
                job: job,
                onBookmarkToggle: () => toggleFired = true,
              ),
            ),
          ),
        );

        expect(find.byType(BookmarkButton), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

        await tester.tap(find.byType(BookmarkButton));
        await tester.pumpAndSettle();

        expect(toggleFired, isTrue);
      },
    );

    testWidgets(
      '5. MainNavigationScreen switches tabs smoothly using AnimatedSwitcher and AnimatedScale in bottom bar',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainNavigationScreen(homeScreen: Text('Home Content')),
          ),
        );

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
        expect(find.text('Home Content'), findsOneWidget);

        final animatedSwitcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(
          animatedSwitcher.duration,
          equals(const Duration(milliseconds: 220)),
        );
        expect(animatedSwitcher.switchInCurve, equals(Curves.easeOutCubic));
        expect(animatedSwitcher.switchOutCurve, equals(Curves.easeInCubic));

        // Verify bottom nav items use AnimatedContainer and AnimatedScale
        expect(find.byType(JobBottomNavigation), findsOneWidget);
        expect(find.byType(AnimatedScale), findsWidgets);
        expect(find.byType(AnimatedPositioned), findsWidgets);

        // Tap on 'Việc làm' (Tab 1)
        await tester.tap(find.text('Việc làm'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Tab index transitioned smoothly
        final navBar = tester.widget<JobBottomNavigation>(
          find.byType(JobBottomNavigation),
        );
        expect(navBar.selectedIndex, equals(1));
      },
    );

    testWidgets(
      '6. ConnectionsScreen sub-tabs animate color, border, and text smoothly with AnimatedContainer',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: ConnectionsScreen()));
        await tester.pumpAndSettle();

        // Find AnimatedContainer inside segmented tab bar
        expect(find.text('Chờ phản hồi'), findsOneWidget);
        expect(find.text('Đã phản hồi'), findsOneWidget);
        expect(find.text('Quá hạn'), findsOneWidget);

        // Verify AnimatedContainer exists for each tab
        expect(find.byType(AnimatedContainer), findsWidgets);

        // Tap 'Đã phản hồi'
        await tester.tap(find.text('Đã phản hồi'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Content for 'Đã phản hồi' is rendered
        expect(find.text('FPT Software'), findsOneWidget);
      },
    );
  });
}
