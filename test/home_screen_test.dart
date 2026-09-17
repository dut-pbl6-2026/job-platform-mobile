import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/home/home_screen.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthSession.instance.clearSession();
  });

  tearDown(() {
    AuthSession.instance.clearSession();
  });

  testWidgets(
    'HomeScreen renders Tạo CV button and shows coming soon SnackBar on tap for candidate',
    (tester) async {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'candidate-1',
            name: 'Nguyễn Văn A',
            email: 'candidate@example.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: 'test-token',
          refreshToken: 'test-refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final mockAuth = MockAuthRepository();
      final mockJob = MockJobRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(authRepository: mockAuth, jobRepository: mockJob),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and user info
      expect(find.text('Nguyễn Văn A'), findsOneWidget);

      // Check filter pills has 'Tất cả'
      expect(find.text('Tất cả'), findsOneWidget);

      // Check shortcuts: 'Tạo CV', 'Hồ sơ', 'Ứng tuyển'
      expect(find.text('Tạo CV'), findsOneWidget);
      expect(find.text('Mẫu chuẩn ATS'), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Ứng tuyển'), findsOneWidget);

      // Tap 'Tạo CV'
      await tester.tap(find.text('Tạo CV'));
      await tester.pump();

      // Verify SnackBar appears
      expect(
        find.text('Tính năng Tạo CV (Đang phát triển trong Sprint tiếp theo)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'HomeScreen displays Đăng tin button when logged in as recruiter',
    (tester) async {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'recruiter-1',
            name: 'HR Tech Corp',
            email: 'recruiter@techcorp.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: 'test-token',
          refreshToken: 'test-refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final mockAuth = MockAuthRepository();
      final mockJob = MockJobRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(authRepository: mockAuth, jobRepository: mockJob),
        ),
      );

      await tester.pumpAndSettle();

      // Recruiter should see 'Đăng tin'
      expect(find.text('Đăng tin'), findsOneWidget);
      expect(find.text('Tuyển dụng mới'), findsOneWidget);
    },
  );
}
