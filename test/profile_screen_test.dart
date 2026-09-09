import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:job_platform_mobile/features/profile/presentation/profile_screen.dart';

void main() {
  late MockProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockProfileRepository();
    mockRepo.reset();
  });

  testWidgets(
    'ProfileScreen renders header, completion score, skills, experience, and education (MOB-01-05)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(profileRepository: mockRepo),
        ),
      );

      // Initial loading
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);

      // Settle async fetch
      await tester.pumpAndSettle();

      // Verify Candidate Name & Headline
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(
        find.text('Senior Flutter & Cross-Platform Mobile Engineer'),
        findsOneWidget,
      );

      // Verify Completion card
      expect(find.text('Độ hoàn thiện hồ sơ'), findsOneWidget);

      // Verify Sections
      expect(find.textContaining('Kỹ năng chuyên môn'), findsOneWidget);
      expect(find.text('Flutter & Dart'), findsOneWidget);

      expect(find.textContaining('Kinh nghiệm làm việc'), findsOneWidget);
      expect(find.text('FPT Software'), findsOneWidget);

      expect(find.textContaining('Học vấn & Bằng cấp'), findsOneWidget);
      expect(find.text('Đại học Bách Khoa - Đại học Đà Nẵng'), findsOneWidget);

      // Verify Quick access to application history
      expect(find.text('Lịch sử ứng tuyển'), findsOneWidget);
    },
  );

  testWidgets('Tapping edit profile icon opens EditProfileDialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileScreen(profileRepository: mockRepo),
      ),
    );

    await tester.pumpAndSettle();

    // Tap edit icon in app bar
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Verify Edit dialog is opened
    expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('Tapping add skill opens AddSkillDialog', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileScreen(profileRepository: mockRepo),
      ),
    );

    await tester.pumpAndSettle();

    // Find first "+ Thêm" button in skills section
    final addButtons = find.text('Thêm');
    expect(addButtons, findsWidgets);

    final firstAdd = addButtons.first;
    await tester.ensureVisible(firstAdd);
    await tester.tap(firstAdd);
    await tester.pumpAndSettle();

    // Verify AddSkillDialog is opened
    expect(find.text('Thêm kỹ năng chuyên môn'), findsOneWidget);
    expect(find.text('Tên kỹ năng *'), findsOneWidget);
  });
}
