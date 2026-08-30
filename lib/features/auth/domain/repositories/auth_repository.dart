import '../models/auth_result.dart';
import '../models/user_model.dart';

/// Abstract interface for Authentication Repository.
/// Following Repository Pattern to easily swap between [MockAuthRepository]
/// and [ApiAuthRepository] (communicating via YARP Gateway).
abstract class IAuthRepository {
  /// Sign in with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Register a new user account with role selection (User / Recruiter)
  /// companyId required for Recruiter per SRS AUTH-01-06
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
  });

  /// Forgot password (AUTH-01-07) anti-enumeration always success
  Future<void> forgotPassword({required String email});

  /// Reset password (AUTH-01-08) single-use 15m revokes all tokens
  Future<void> resetPassword({required String token, required String newPassword});

  /// Log out current active user
  Future<void> logout();

  /// Retrieve the current logged-in user profile if authenticated
  Future<UserModel?> getCurrentUser();
}
