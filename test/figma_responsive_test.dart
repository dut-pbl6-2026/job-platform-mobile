import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/login_screen.dart';
import 'package:job_platform_mobile/features/auth/register_screen.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/ai_copilot_screen.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/resume_scoring_screen.dart';
import 'package:job_platform_mobile/features/home/home_screen.dart';
import 'package:job_platform_mobile/features/home/main_navigation_screen.dart';
import 'package:job_platform_mobile/features/notifications/data/repositories/mock_notification_repository.dart';

import 'support/figma_job_fixture.dart';
import 'support/load_fonts.dart';
import 'support/fake_ai_repository.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final size in [
    const Size(345, 680),
    const Size(360, 800),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Home/auth layout ${size.width}x${size.height}, text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final home = HomeScreen(
            jobRepository: FigmaJobFixture(),
            notificationRepository: MockNotificationRepository(),
          );
          for (final screen in [
            MainNavigationScreen(homeScreen: home),
            const LoginScreen(),
            const RegisterScreen(),
            AiCopilotScreen(repository: FakeAiRepository()),
            ResumeScoringScreen(repository: FakeAiRepository()),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: screen,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${screen.runtimeType}',
            );
            if (screen is RegisterScreen) {
              for (final role in ['user', 'recruiter']) {
                final roleTile = find.byKey(Key('register_role_$role'));
                await tester.ensureVisible(roleTile);
                await tester.tap(roleTile);
                await tester.pumpAndSettle();
                await tester.ensureVisible(find.byType(ElevatedButton));
                expect(tester.takeException(), isNull);
                await tester.ensureVisible(find.text('Đổi vai trò'));
                await tester.tap(find.text('Đổi vai trò'));
                await tester.pumpAndSettle();
              }
            }
          }
        },
      );
    }
  }
}
