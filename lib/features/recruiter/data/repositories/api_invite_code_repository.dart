import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';

/// An invite code issued by the company creator (SRS AUTH-01-09). The server keeps only a hash;
/// [code] is shown once.
class IssuedInviteCode {
  final String id;
  final String code;
  final DateTime expiresAt;

  const IssuedInviteCode({
    required this.id,
    required this.code,
    required this.expiresAt,
  });

  factory IssuedInviteCode.fromJson(Map<String, dynamic> json) {
    return IssuedInviteCode(
      id: json['id'] as String,
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
    );
  }
}

/// User-facing failure for the issue call. [message] is Vietnamese copy.
class InviteCodeException implements Exception {
  final String message;

  const InviteCodeException(this.message);

  @override
  String toString() => 'InviteCodeException: $message';
}

/// Creator-only issue call through the gateway. The server answers 403 when the caller is not the creator.
class ApiInviteCodeRepository {
  final Dio _dio;

  ApiInviteCodeRepository({Dio? dio}) : _dio = dio ?? DioProvider.instance.dio;

  Future<IssuedInviteCode> createInviteCode(String companyId) async {
    try {
      final response = await _dio.post(
        '/api/companies/$companyId/invite-codes',
      );
      return IssuedInviteCode.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const InviteCodeException(
          'Chỉ người tạo công ty mới được cấp mã mời.',
        );
      }
      throw const InviteCodeException(
        'Không tạo được mã mời. Vui lòng thử lại.',
      );
    }
  }
}
