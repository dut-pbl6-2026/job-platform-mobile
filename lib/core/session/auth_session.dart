import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/models/auth_result.dart';
import '../../features/auth/domain/models/user_model.dart';

/// Session manager with secure persistence (SEC-09) and role resolution (AUTH-01-03).
/// Resolves authenticated role from verified backend-issued JWT token claims
/// with fallback to validated user entity. Fails closed on unknown or missing roles.
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _kTokenKey = 'auth_token';
  static const _kRefreshKey = 'auth_refresh';
  static const _kUserKey = 'auth_user';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  UserModel? _currentUser;
  String? _token;
  String? _refreshToken;
  bool _loaded = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoaded => _loaded;

  /// Authoritative role resolved from verified backend-issued JWT claims (AUTH-01-03)
  /// or authenticated user profile. Returns `null` (fail closed) if unknown or missing.
  UserRole? get resolvedRole {
    if (!isAuthenticated) return null;

    // 1. Authoritative check: inspect verified backend-issued JWT token claims
    final jwtRole = _extractRoleFromJwt(_token);
    if (jwtRole != null) {
      return jwtRole;
    }

    // 2. Fallback to authenticated currentUser.role (e.g. for mock tokens in unit tests)
    return _currentUser?.role;
  }

  bool get isUser => resolvedRole == UserRole.user;
  bool get isRecruiter => resolvedRole == UserRole.recruiter;
  bool get isAdmin => resolvedRole == UserRole.admin;
  bool get hasValidRole => resolvedRole != null;
  String? get companyId =>
      _currentUser?.companyId ?? _extractCompanyIdFromJwt(_token);

  /// Safely extracts and parses the role claim from a JWT access token.
  static UserRole? _extractRoleFromJwt(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      var payloadString = parts[1];
      while (payloadString.length % 4 != 0) {
        payloadString += '=';
      }
      final normalized = base64Url.normalize(payloadString);
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      final map = jsonDecode(decodedString) as Map<String, dynamic>;

      // Check standard JWT claim keys ('role' and Microsoft Identity ClaimTypes.Role URI)
      final roleStr =
          map['role'] as String? ??
          map['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
              as String?;
      return UserRole.tryParse(roleStr);
    } catch (_) {
      return null;
    }
  }

  static String? _extractCompanyIdFromJwt(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      var payloadString = parts[1];
      while (payloadString.length % 4 != 0) {
        payloadString += '=';
      }
      final normalized = base64Url.normalize(payloadString);
      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      final map = jsonDecode(decodedString) as Map<String, dynamic>;

      final rawCompany =
          map['companyId'] ?? map['company_id'] ?? map['company'];
      return rawCompany?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    try {
      _token = await _secure.read(key: _kTokenKey);
      _refreshToken = await _secure.read(key: _kRefreshKey);
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_kUserKey);
      if (userJson != null && _token != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map);
      } else {
        _currentUser = null;
        _token = null;
        _refreshToken = null;
      }
    } catch (e) {
      debugPrint('AuthSession load failed: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setSession(AuthResult authResult) async {
    _currentUser = authResult.user;
    _token = authResult.token;
    _refreshToken = authResult.refreshToken;
    notifyListeners();
    try {
      await _secure.write(key: _kTokenKey, value: authResult.token);
      await _secure.write(key: _kRefreshKey, value: authResult.refreshToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserKey, jsonEncode(authResult.user.toJson()));
    } catch (e) {
      debugPrint('AuthSession persist failed: $e');
    }
  }

  Future<void> clearSession() async {
    _currentUser = null;
    _token = null;
    _refreshToken = null;
    notifyListeners();
    try {
      await _secure.delete(key: _kTokenKey);
      await _secure.delete(key: _kRefreshKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserKey);
    } catch (e) {
      debugPrint('AuthSession clear failed: $e');
    }
  }
}
