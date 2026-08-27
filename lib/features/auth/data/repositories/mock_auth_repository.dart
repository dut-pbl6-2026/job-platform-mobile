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

    // Basic simulation check
    if (password.length < 6) {
      throw Exception('Mật khẩu không chính xác hoặc tài khoản không tồn tại.');
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
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Simulate network delay of 2 seconds
    await Future.delayed(const Duration(seconds: 2));

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
