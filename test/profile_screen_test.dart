import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
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

  testWidgets(
    'Tapping application history navigates to applications route via context.go and profile tab resets state',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: AppRoutes.profile,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return Scaffold(
                body: navigationShell,
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: navigationShell.currentIndex,
                  onTap: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history_edu),
                      label: 'Ứng tuyển',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Hồ sơ',
                    ),
                  ],
                ),
              );
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.applications,
                    builder: (context, state) =>
                        const Scaffold(body: Text('Ứng tuyển Screen')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.profile,
                    builder: (context, state) =>
                        ProfileScreen(profileRepository: mockRepo),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );

      await tester.pumpAndSettle();

      // Verify we are on Profile screen initially
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);

      // Tap application history card
      final historyCard = find.text('Lịch sử ứng tuyển');
      await tester.ensureVisible(historyCard);
      await tester.tap(historyCard);
      await tester.pumpAndSettle();

      // Verify it navigated to applications screen branch
      expect(find.text('Ứng tuyển Screen'), findsOneWidget);

      // Tap back on Hồ sơ tab in bottom bar
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();

      // Verify Profile screen is displayed cleanly as if nothing was clicked
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
    },
  );
}
