import 'package:flutter/foundation.dart';
import '../../features/auth/domain/models/auth_result.dart';
import '../../features/auth/domain/models/user_model.dart';

/// In-memory session manager for managing authenticated user state and mock tokens.
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  UserModel? _currentUser;
  String? _token;
  String? _refreshToken;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _token != null && _currentUser != null;

  void setSession(AuthResult authResult) {
    _currentUser = authResult.user;
    _token = authResult.token;
    _refreshToken = authResult.refreshToken;
    notifyListeners();
  }

  void clearSession() {
    _currentUser = null;
    _token = null;
    _refreshToken = null;
    notifyListeners();
  }
}
