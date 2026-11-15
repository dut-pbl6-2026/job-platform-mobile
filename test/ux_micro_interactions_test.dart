import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/widgets/fade_slide_transition.dart';
import 'package:job_platform_mobile/core/widgets/pressable_card.dart';
import 'package:job_platform_mobile/features/home/main_navigation_screen.dart';

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
  });
}
