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
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Log out current active user
  Future<void> logout();

  /// Retrieve the current logged-in user profile if authenticated
  Future<UserModel?> getCurrentUser();
}
