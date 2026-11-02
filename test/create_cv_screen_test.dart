import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/cv/presentation/create_cv_screen.dart';

void main() {
  testWidgets('CreateCvScreen renders banner, categories, and template cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const CreateCvScreen()),
    );

    // Verify AppBar
    expect(find.text('Tạo CV xin việc'), findsOneWidget);

    // Verify Hero Banner
    expect(find.textContaining('CHUẨN ATS VIỆT NAM'), findsOneWidget);
    expect(find.textContaining('Tạo CV Chuyên Nghiệp'), findsOneWidget);

    // Verify Sprint notice
    expect(
      find.textContaining('Tính năng chỉnh sửa và xuất file PDF trực tuyến'),
      findsOneWidget,
    );

    // Verify Category chips
    expect(find.text('Tất cả'), findsWidgets);
    expect(find.text('Công nghệ IT'), findsWidgets);
    expect(find.text('Marketing'), findsWidgets);

    // Verify Template cards
    expect(find.text('Modern Tech ATS'), findsOneWidget);
    expect(find.text('Executive Business'), findsOneWidget);

    // Tap template action 'Chọn mẫu'
    await tester.tap(find.text('Chọn mẫu').first);
    await tester.pumpAndSettle();

    // Verify modal bottom sheet opens with CV form
    expect(find.text('Điền thông tin CV'), findsOneWidget);
  });
}
