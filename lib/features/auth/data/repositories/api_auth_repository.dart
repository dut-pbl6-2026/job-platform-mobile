import 'package:dio/dio.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';
import 'package:job_platform_mobile/core/network/dio_provider.dart';
import 'package:job_platform_mobile/core/services/push_notification_service.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/utils/password_validator.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/auth/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements IAuthRepository {
  final Dio _dio;

  ApiAuthRepository({Dio? dio}) : _dio = dio ?? DioProvider.instance.dio;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final res = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password, 'rememberMe': rememberMe},
      );
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data as Map);
      final auth = AuthResult.fromJson(data);
      await AuthSession.instance.setSession(auth);
      return auth;
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? inviteCode,
    String? inviteEmail,
  }) async {
    if (!isPasswordStrong(password)) {
      throw const AuthFailure(
        code: AuthFailure.weakPassword,
        statusCode: 400,
        rawMessage: 'Weak password',
      );
    }
    final code = inviteCode?.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (role == UserRole.recruiter && (code == null || code.isEmpty)) {
      throw const AuthFailure(
        code: AuthFailure.invalidInviteCode,
        statusCode: 422,
        rawMessage: 'inviteCode required for Recruiter',
      );
    }
    // AUTH-01-15: the code is bound to one address and job-svc only accepts it
    // with that address. The registration email is the address sent for the
    // check and the redeem, so a different invite email can never succeed.
    final boundEmail = inviteEmail?.trim().toLowerCase();
    if (role == UserRole.recruiter &&
        boundEmail != null &&
        boundEmail.isNotEmpty &&
        boundEmail != email.trim().toLowerCase()) {
      throw const AuthFailure(
        code: AuthFailure.invalidInviteCode,
        statusCode: 422,
        rawMessage: 'Invite code is bound to another email',
      );
    }
    try {
      final payload = <String, dynamic>{
        'email': email,
        'password': password,
        'fullName': name,
        'role': role.value,
        if (role == UserRole.recruiter) 'inviteCode': code,
      };
      // 202 Accepted with { message }. No user id and no tokens: the caller
      // must not log in or store anything until the email is verified.
      await _dio.post('/api/auth/register', data: payload);
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        throw const AuthFailure(
          code: AuthFailure.inviteUnavailable,
          statusCode: 503,
          rawMessage: 'invite code service unavailable',
        );
      }
      throw _toFailure(e);
    }
  }

  @override
  Future<void> registerCompany({
    required String companyName,
    String? taxCode,
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!isPasswordStrong(password)) {
      throw const AuthFailure(
        code: AuthFailure.weakPassword,
        statusCode: 422,
        rawMessage: 'Weak password',
      );
    }
    final tax = taxCode?.trim();
    try {
      // Every outcome (new sign-up, existing email, taken name or tax code,
      // domain match) is the same 202 and the same message, so the response body
      // is deliberately not interpreted.
      await _dio.post(
        '/api/auth/register-company',
        data: {
          'companyName': companyName.trim(),
          if (tax != null && tax.isNotEmpty) 'taxCode': tax,
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        throw const AuthFailure(
          code: AuthFailure.serviceUnavailable,
          statusCode: 503,
          rawMessage: 'company sign-up service unavailable',
        );
      }
      throw _toFailure(e);
    }
  }

  @override
  Future<void> resendVerification({required String email}) async {
    try {
      // 202 for every address, so the response body is not read.
      await _dio.post('/api/auth/resend-verification', data: {'email': email});
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> verifyEmail({required String token}) async {
    try {
      // 200 with { message } on success. The token is single-use, so callers must not resend it blindly.
      await _dio.post('/api/auth/verify-email', data: {'token': token});
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (!isPasswordStrong(newPassword)) {
      throw const AuthFailure(
        code: AuthFailure.weakPassword,
        statusCode: 400,
        rawMessage: 'Weak password',
      );
    }
    try {
      await _dio.post(
        '/api/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await PushNotificationService.instance.unregisterTokenOnLogout();
    } catch (_) {}
    try {
      final rt = AuthSession.instance.refreshToken;
      if (rt != null) {
        await _dio.post('/api/auth/logout', data: {'refreshToken': rt});
      }
    } catch (_) {}
    await AuthSession.instance.clearSession();
  }

  /// Checks a session restored from secure storage against the server.
  /// Clears it when the server rejects or deactivates the account; updates
  /// cached user profile on success; keeps it when offline.
  Future<void> validateRestoredSession() async {
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      final user = await getCurrentUser();
      if (user == null) {
        await AuthSession.instance.clearSession();
      } else {
        await AuthSession.instance.updateUser(user);
      }
    } on AuthFailure {
      // Server reachable with transient 5xx: keep the local session.
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _dio.get('/api/auth/me');
      // backend returns UserMeDto {id,email,fullName,role,isActive}
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : Map<String, dynamic>.from(res.data as Map);
      // Normalize to UserModel shape
      final userMap = data.containsKey('user') && data['user'] is Map
          ? (data['user'] is Map<String, dynamic>
                ? data['user'] as Map<String, dynamic>
                : Map<String, dynamic>.from(data['user'] as Map))
          : data;
      if (userMap['isActive'] == false || data['isActive'] == false) {
        return null;
      }
      return UserModel.fromJson(userMap);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return null;
      }
      if (e.response == null) {
        return AuthSession.instance.currentUser;
      }
      throw mapDioToFailure(e);
    } catch (_) {
      return AuthSession.instance.currentUser;
    }
  }

  /// A request that got no HTTP response is a network failure, whatever
  /// the Dio exception type. Raw exception text never reaches the UI.
  AuthFailure _toFailure(DioException e) {
    if (e.response == null) {
      return AuthFailure(code: AuthFailure.networkError, rawMessage: e.message);
    }
    return mapDioToFailure(e);
  }
}
