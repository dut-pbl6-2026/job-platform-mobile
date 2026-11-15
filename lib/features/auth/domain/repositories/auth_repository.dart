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
  /// companyId required for Recruiter per SRS AUTH-01-06.
  /// Registration does not sign the user in: the account must be verified
  /// by email first, so no tokens are issued or stored.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
  });

  /// Asks for a new verification link. The server answers the same for every
  /// address; throws [AuthFailure] with `rateLimited` on 429.
  Future<void> resendVerification({required String email});

  /// Redeems the one-time token from the verification link. Throws [AuthFailure]
  /// with statusCode 400 when the token is invalid, expired or already used.
  Future<void> verifyEmail({required String token});

  /// Forgot password (AUTH-01-07) anti-enumeration always success
  Future<void> forgotPassword({required String email});

  /// Reset password (AUTH-01-08) single-use 15m revokes all tokens
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Log out current active user
  Future<void> logout();

  /// Retrieve the current logged-in user profile if authenticated
  Future<UserModel?> getCurrentUser();
}
