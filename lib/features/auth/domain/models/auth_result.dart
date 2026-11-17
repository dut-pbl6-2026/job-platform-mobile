import 'user_model.dart';

/// Authentication response result
class AuthResult {
  final String token;
  final String refreshToken;
  final UserModel user;
  final DateTime expiresAt;

  const AuthResult({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  factory AuthResult.fromJson(
    Map<String, dynamic> json, {
    UserModel? fallbackUser,
  }) {
    // Backend 2026: AuthResponse {accessToken, refreshToken, user:{id,email,fullName,role}}
    // Token refresh response {accessToken, refreshToken} omits user (SRS 3.2.3).
    final token =
        json['accessToken'] as String? ?? json['token'] as String? ?? '';
    final refresh = json['refreshToken'] as String? ?? '';
    final userRaw = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final hasInlineUser =
        json['userId'] != null ||
        json['email'] != null ||
        json['fullName'] != null ||
        json['name'] != null;
    final user = userRaw != null
        ? UserModel.fromJson(userRaw)
        : (!hasInlineUser && fallbackUser != null)
        ? fallbackUser
        : UserModel(
            id: json['userId'] as String? ?? 'unknown',
            name: json['fullName'] as String? ?? json['name'] as String? ?? '',
            email: json['email'] as String? ?? '',
            role: UserRole.tryParse(json['role'] as String?),
            createdAt: DateTime.now(),
          );
    return AuthResult(
      token: token,
      refreshToken: refresh,
      user: user,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
