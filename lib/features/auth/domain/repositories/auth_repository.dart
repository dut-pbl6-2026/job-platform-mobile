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
  /// Recruiter requires a valid [inviteCode] (SRS AUTH-01-06, AUTH-01-09); the company comes from the code.
  /// [inviteEmail] is the address the code was issued to (AUTH-01-15). job-svc
  /// checks and redeems the code against the registration address, so a value
  /// that differs from [email] is rejected before any request is sent.
  /// Registration does not sign the user in: the account must be verified
  /// by email first, so no tokens are issued or stored.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? inviteCode,
    String? inviteEmail,
  });

  /// Company self-serve sign-up (SRS AUTH-01-10, AUTH-01-11).
  /// The server answers `202` with one fixed message for every outcome: a new
  /// sign-up, an existing email, a taken company name or tax code, or a work
  /// domain that already belongs to a company. Callers must show that same
  /// message and never infer which case applied.
  /// Throws [AuthFailure] with `workEmailRequired` for a free public email
  /// domain (`422 WORK_EMAIL_REQUIRED`) and `serviceUnavailable` for `503`.
  Future<void> registerCompany({
    required String companyName,
    String? taxCode,
    required String email,
    required String password,
    required String fullName,
  });

  /// Asks for a new verification link. The server answers the same for every
  /// address; throws [AuthFailure] with `rateLimited` on 429.
  Future<void> resendVerification({required String email});

  /// Redeems the one-time token from the verification link. Throws [AuthFailure]
  /// with statusCode 422 when the token is invalid, expired or already used
  /// (`422 VERIFICATION_TOKEN_INVALID`).
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
