import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';

void main() {
  group('MockAuthRepository Tests', () {
    late MockAuthRepository repository;

    setUp(() {
      AuthSession.instance.clearSession();
      repository = MockAuthRepository();
    });

    test('login succeeds and stores session with mock token and user', () async {
      final result = await repository.login(
        email: 'candidate@test.com',
        password: 'password123',
      );

      expect(result.token, isNotEmpty);
      expect(result.user.email, 'candidate@test.com');
      expect(result.user.role, UserRole.user);
      expect(AuthSession.instance.isAuthenticated, isTrue);
      expect(AuthSession.instance.currentUser?.email, 'candidate@test.com');
    });

    test('login with recruiter keyword email assigns Recruiter role', () async {
      final result = await repository.login(
        email: 'recruiter.hr@techcorp.vn',
        password: 'password123',
      );

      expect(result.user.role, UserRole.recruiter);
    });

    test('register creates new account with selected role and token', () async {
      final result = await repository.register(
        name: 'Nguyen Van A',
        email: 'nguyenvana@gmail.com',
        password: 'Password123!',
        role: UserRole.recruiter,
      );

      expect(result.token, isNotEmpty);
      expect(result.user.name, 'Nguyen Van A');
      expect(result.user.email, 'nguyenvana@gmail.com');
      expect(result.user.role, UserRole.recruiter);
      expect(AuthSession.instance.currentUser?.role, UserRole.recruiter);
    });

    test('logout clears session', () async {
      await repository.login(
        email: 'test@user.com',
        password: 'password123',
      );
      expect(AuthSession.instance.isAuthenticated, isTrue);

      await repository.logout();
      expect(AuthSession.instance.isAuthenticated, isFalse);
      expect(AuthSession.instance.currentUser, isNull);
    });
  });
}
