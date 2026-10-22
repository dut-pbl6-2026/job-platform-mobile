import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/login_screen.dart';
import 'package:job_platform_mobile/features/auth/register_screen.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/ai_copilot_screen.dart';
import '../support/fake_ai_repository.dart';
import '../support/load_fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  final screens = <String, Widget Function()>{
    'login': () => const LoginScreen(),
    'register_role': () => const RegisterScreen(),
    'ai_welcome': () => AiCopilotScreen(repository: FakeAiRepository()),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} regression baseline at Figma viewport', (
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
            data: MediaQueryData(
              size: const Size(345, 680),
              padding: entry.key == 'ai_welcome'
                  ? const EdgeInsets.only(top: 52, bottom: 34)
                  : EdgeInsets.zero,
            ),
            child: entry.value(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/${entry.key}_345x680.png'),
      );
    });
  }
}
