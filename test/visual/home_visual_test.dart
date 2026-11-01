import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/home/main_navigation_screen.dart';
import 'package:job_platform_mobile/features/home/home_screen.dart';
import 'package:job_platform_mobile/features/notifications/data/repositories/mock_notification_repository.dart';
import '../support/figma_job_fixture.dart';
import '../support/golden_tolerance.dart';
import '../support/load_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Home regression baseline at canonical Figma viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(345, 680);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(345, 680),
            padding: EdgeInsets.only(top: 52),
          ),
          child: MainNavigationScreen(
            homeScreen: HomeScreen(
              jobRepository: FigmaJobFixture(),
              notificationRepository: MockNotificationRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/figma/nav-selected.png'),
        tester.element(find.byType(MainNavigationScreen)),
      ),
    );
    await tester.pumpAndSettle();

    await expectGoldenWithinTolerance(
      tester,
      find.byType(MainNavigationScreen),
      goldenFile: 'goldens/home_figma_345x680.png',
      maxDiffRate: 0.06,
    );
  });
}
