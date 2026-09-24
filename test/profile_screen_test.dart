import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:job_platform_mobile/features/profile/presentation/profile_screen.dart';

void main() {
  late MockProfileRepository mockRepo;

  setUp(() async {
    await AuthSession.instance.clearSession();
    mockRepo = MockProfileRepository();
    mockRepo.reset();
  });

  testWidgets(
    'ProfileScreen renders candidate header, candidate code, verified badge, and all 7 sections',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(profileRepository: mockRepo),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify Candidate Name from mock profile
      expect(find.text('Nguyễn Văn An'), findsOneWidget);

      // Verify Verified Badge
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // Verify Candidate Code
      expect(find.textContaining('Mã ứng viên:'), findsOneWidget);

      // Verify Upgrade account row
      expect(find.text('Nâng cấp tài khoản'), findsOneWidget);

      // Verify Section 1: Trạng thái tìm việc
      expect(find.text('Trạng thái tìm việc'), findsWidgets);
      expect(find.text('Gợi ý việc làm'), findsOneWidget);
      expect(find.text('Cho phép NTD tìm kiếm hồ sơ'), findsOneWidget);

      // Verify Section 2: Hồ sơ của tôi
      expect(find.text('Hồ sơ của tôi'), findsOneWidget);
      expect(find.text('Profile của tôi'), findsOneWidget);
      expect(find.text('CV của tôi'), findsOneWidget);
      expect(find.text('Cover Letter của tôi'), findsOneWidget);

      // Verify Section 3: Quản lý tìm việc
      expect(find.text('Quản lý tìm việc'), findsOneWidget);
      expect(find.text('Việc làm đã ứng tuyển'), findsOneWidget);
      expect(find.text('Việc làm đã lưu'), findsOneWidget);
      expect(find.text('Cài đặt gợi ý việc làm'), findsOneWidget);

      // Verify Section 4: Tương tác với NTD (TopCV Connect removed)
      expect(find.text('Tương tác với NTD'), findsOneWidget);
      expect(find.text('NTD xem hồ sơ'), findsOneWidget);
      expect(find.text('NTD muốn kết nối với bạn'), findsOneWidget);
      expect(find.text('Công ty đang theo dõi'), findsOneWidget);
      expect(find.text('TopCV Connect'), findsNothing);

      // Verify Section 5: Cài đặt thông báo
      expect(find.text('Cài đặt thông báo'), findsOneWidget);
      expect(find.text('Thông báo việc làm'), findsOneWidget);
      expect(find.text('Cài đặt nhận email'), findsOneWidget);

      // Verify Section 6: Bảo mật
      expect(find.text('Bảo mật'), findsOneWidget);
      expect(find.text('Đổi mật khẩu'), findsOneWidget);
      expect(find.text('Cài đặt bảo mật'), findsOneWidget);
      expect(find.text('Xác minh 2 bước'), findsOneWidget);
      expect(find.text('Chưa xác minh'), findsOneWidget);
      expect(find.text('Vô hiệu hóa tài khoản'), findsOneWidget);

      // Verify Section 7: Chính sách hỗ trợ (Về chúng tôi instead of Về TopCV)
      expect(find.text('Chính sách hỗ trợ'), findsOneWidget);
      expect(find.text('Về chúng tôi'), findsOneWidget);
      expect(find.text('Về TopCV'), findsNothing);
      expect(find.text('Điều khoản dịch vụ'), findsOneWidget);
      expect(find.text('Chính sách quyền riêng tư'), findsOneWidget);
      expect(find.text('Trợ giúp'), findsOneWidget);
      expect(find.text('Đánh giá ứng dụng'), findsOneWidget);
      expect(find.text('Kiểm tra bản cập nhật mới'), findsOneWidget);

      // Verify Version 1.0.0 & Logout button
      expect(find.text('Phiên bản ứng dụng: 1.0.0'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    },
  );

  testWidgets(
    'Toggling Gợi ý việc làm switch opens confirmation dialog and updates state',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(profileRepository: mockRepo),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Find the switches (two switches: Gợi ý việc làm & Trạng thái tìm việc)
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      // First switch is "Gợi ý việc làm"
      final jobRecommendSwitch = switches.first;
      expect(tester.widget<Switch>(jobRecommendSwitch).value, isFalse);

      // Tap switch to turn on -> prompts confirmation dialog
      await tester.tap(jobRecommendSwitch);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Bật gợi ý việc làm'), findsOneWidget);
      expect(
        find.text(
          'Tôi đồng ý để hệ thống gợi ý việc làm dựa trên CV và hoạt động tìm việc, quá trình phân tích có thể sử dụng công nghệ AI',
        ),
        findsOneWidget,
      );
      expect(find.text('Để sau'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // Tap "Xác nhận"
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      // Verify switch is now ON
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);

      // User can toggle it off directly by tapping switch again
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Verify switch is now OFF
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    },
  );

  testWidgets('Toggling job search status Switch works smoothly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileScreen(profileRepository: mockRepo),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // The second switch is "Trạng thái tìm việc"
    final statusSwitchFinder = find.byType(Switch).last;

    // Initial state is false
    expect(tester.widget<Switch>(statusSwitchFinder).value, isFalse);

    // Tap switch to toggle on
    await tester.tap(statusSwitchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
  });

  testWidgets('Tapping Đăng xuất opens confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileScreen(profileRepository: mockRepo),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Scroll to and find "Đăng xuất"
    final logoutFinder = find.text('Đăng xuất');
    await tester.ensureVisible(logoutFinder);
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
    expect(
      find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
      findsOneWidget,
    );
    expect(find.text('Hủy'), findsOneWidget);
  });

  testWidgets(
    'Tapping Việc làm đã ứng tuyển navigates to applications route via context.go',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
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

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Tap 'Việc làm đã ứng tuyển'
      final appliedJobsCard = find.text('Việc làm đã ứng tuyển');
      await tester.ensureVisible(appliedJobsCard);
      await tester.tap(appliedJobsCard);
      await tester.pumpAndSettle();

      // Verify it navigated to applications screen branch
      expect(find.text('Ứng tuyển Screen'), findsOneWidget);
    },
  );
}
