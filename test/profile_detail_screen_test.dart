import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:job_platform_mobile/features/profile/domain/models/profile_model.dart';
import 'package:job_platform_mobile/features/profile/presentation/profile_detail_screen.dart';
import 'package:job_platform_mobile/features/profile/presentation/widgets/edit_profile_dialog.dart';

void main() {
  late MockProfileRepository mockRepo;

  setUp(() async {
    mockRepo = MockProfileRepository();
    mockRepo.reset();
    await AuthSession.instance.setSession(
      AuthResult(
        user: UserModel(
          id: 'candidate-1',
          name: 'Nguyễn Văn An',
          email: 'an@example.com',
          role: UserRole.user,
          createdAt: DateTime.now(),
        ),
        token: 'test-token',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  });

  tearDown(() async {
    await AuthSession.instance.clearSession();
  });

  testWidgets(
    'ProfileDetailScreen renders header, completion score, skills, experience, and education (MOB-01-05)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileDetailScreen(profileRepository: mockRepo),
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
        home: ProfileDetailScreen(profileRepository: mockRepo),
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
        home: ProfileDetailScreen(profileRepository: mockRepo),
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
    'Tapping application history navigates to applications route via context.go',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: AppRoutes.profile,
        routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) =>
                ProfileDetailScreen(profileRepository: mockRepo),
          ),
          GoRoute(
            path: AppRoutes.applications,
            builder: (context, state) =>
                const Scaffold(body: Text('Ứng tuyển Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      );

      await tester.pumpAndSettle();

      // Tap application history card
      final historyCard = find.text('Lịch sử ứng tuyển');
      await tester.ensureVisible(historyCard);
      await tester.tap(historyCard);
      await tester.pumpAndSettle();

      // Verify it navigated to applications screen branch
      expect(find.text('Ứng tuyển Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'EditProfileDialog clears optional fields and dateOfBirth to null on save',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ProfileModel? savedProfile;
      final initialProfile = ProfileModel(
        id: 'p-1',
        userId: 'u-1',
        fullName: 'Nguyễn Văn An',
        headline: 'Old Headline',
        phone: '0905123456',
        address: 'Đà Nẵng',
        dateOfBirth: DateTime(1998, 5, 20),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EditProfileDialog(
              profile: initialProfile,
              onSave: (p) => savedProfile = p,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear headline (2nd field) and clear dateOfBirth
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.byKey(const Key('clear_dob_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(savedProfile, isNotNull);
      expect(savedProfile!.headline, isNull);
      expect(savedProfile!.dateOfBirth, isNull);
    },
  );
}
