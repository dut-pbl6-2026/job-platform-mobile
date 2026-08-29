import 'dart:convert';
import '../../../../core/session/auth_session.dart';
import '../../domain/models/auth_result.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock Implementation of [IAuthRepository]
/// Simulates backend network latency with a 2-second delay and generates mock JWT tokens.
/// Can be cleanly swapped with [ApiAuthRepository] connecting through the YARP Gateway.
class MockAuthRepository implements IAuthRepository {
  MockAuthRepository({AuthSession? session})
      : _session = session ?? AuthSession.instance;

  final AuthSession _session;

  /// Helper to generate a realistic mock JWT token string
  String _generateMockJwt({
    required String userId,
    required String email,
    required String role,
  }) {
    final header = base64Url.encode(
      utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
    );
    final payload = base64Url.encode(
      utf8.encode(
        jsonEncode({
          'sub': userId,
          'email': email,
          'role': role,
          'iss': 'job-platform-auth-svc',
          'aud': 'job-platform-mobile',
          'exp': DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        }),
      ),
    );
    const signature = 'mock_signature_dut_pbl6_jwt_token_hash';
    return '$header.$payload.$signature';
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // Simulate network delay of 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Validate password format per SRS AUTH-01-01
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      throw Exception(
        'Mật khẩu phải có tối thiểu 8 ký tự, gồm ít nhất 1 chữ hoa và 1 chữ số.',
      );
    }

    // Mock 401 Unauthorized for testing (AUTH-01-02)
    if (password == 'wrong_password' || email == 'invalid@test.com') {
      throw Exception(
        '401 Unauthorized: Email hoặc mật khẩu không chính xác.',
      );
    }

    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final isRecruiter = email.toLowerCase().contains('recruiter') ||
        email.toLowerCase().contains('hr');
    final role = isRecruiter ? UserRole.recruiter : UserRole.user;

    final user = UserModel(
      id: userId,
      name: email.split('@').first.toUpperCase(),
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    final mockToken = _generateMockJwt(
      userId: userId,
      email: email,
      role: role.value,
    );

    // SRS AUTH-01-04: rememberMe → 30 days, otherwise → 7 days
    final sessionDuration = rememberMe
        ? const Duration(days: 30)
        : const Duration(days: 7);

    final result = AuthResult(
      token: mockToken,
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      user: user,
      expiresAt: DateTime.now().add(sessionDuration),
    );

    _session.setSession(result);
    return result;
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Simulate network delay of 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // TODO(W2-BACKEND): Deferred to Week 2/3 pending Database schema and API endpoints for Recruiter companyId verification (AUTH-01-06).

    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      id: userId,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    final mockToken = _generateMockJwt(
      userId: userId,
      email: email,
      role: role.value,
    );

    final result = AuthResult(
      token: mockToken,
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      user: user,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    _session.setSession(result);
    return result;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _session.clearSession();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _session.currentUser;
  }
}
