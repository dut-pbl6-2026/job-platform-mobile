import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/app.dart';
import 'package:job_platform_mobile/features/auth/register_screen.dart';

void main() {
  testWidgets('App renders splash and navigates to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    // Verify initial splash screen
    expect(find.text('Job Platform'), findsOneWidget);
    expect(find.text('Nền tảng Việc làm Việt Nam'), findsOneWidget);

    // Advance splash screen timer (2.5s)
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should navigate to LoginScreen
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('RegisterScreen validates inputs properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    // Initial state check
    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    expect(find.text('Ứng viên'), findsOneWidget);
    expect(find.text('Nhà tuyển dụng'), findsOneWidget);

    // Try submitting without filling any field
    await tester.tap(find.text('Đăng ký Ứng viên'));
    await tester.pump();

    // Verify validation errors are shown
    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(find.text('Vui lòng xác nhận lại mật khẩu'), findsOneWidget);
  });
}
