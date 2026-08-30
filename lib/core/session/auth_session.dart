import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/models/auth_result.dart';
import '../../features/auth/domain/models/user_model.dart';

/// Session manager with secure persistence (SEC-09).
/// Workaround note: prod auto-deploy excludes mobile; this enables cold-start restoration for PBL6-16 E2E.
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

  Future<void> load() async {
    try {
      _token = await _secure.read(key: _kTokenKey);
      _refreshToken = await _secure.read(key: _kRefreshKey);
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_kUserKey);
      if (userJson != null && _token != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map);
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
