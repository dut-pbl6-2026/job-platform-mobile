import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/models/join_request.dart';
import '../../domain/repositories/company_join_request_repository.dart';

/// Gateway-only implementation of [ICompanyJoinRequestRepository].
///
/// Every call goes through YARP (`/api/companies/...`), never a service port.
/// job-svc authorises with the identity forwarded by the gateway, so no company
/// or user id is invented on the client.
class ApiCompanyJoinRequestRepository implements ICompanyJoinRequestRepository {
  final Dio _dio;

  ApiCompanyJoinRequestRepository({Dio? dio})
    : _dio = dio ?? DioProvider.instance.dio;

  @override
  Future<List<CompanyJoinRequest>> listForCompany(String companyId) async {
    try {
      final response = await _dio.get(
        '/api/companies/$companyId/join-requests',
        queryParameters: const {'page': 1, 'size': 100},
      );
      final data = response.data;
      final List<dynamic> items = data is Map
          ? (data['items'] as List<dynamic>? ?? const [])
          : (data as List<dynamic>? ?? const []);
      return items
          .whereType<Map>()
          .map(
            (item) =>
                CompanyJoinRequest.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: _listFallback);
    }
  }

  @override
  Future<void> approve({
    required String companyId,
    required String requestId,
  }) async {
    try {
      await _dio.post(
        '/api/companies/$companyId/join-requests/$requestId/approve',
      );
    } on DioException catch (e) {
      throw _toException(e, fallback: _decideFallback);
    }
  }

  @override
  Future<void> reject({
    required String companyId,
    required String requestId,
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    try {
      await _dio.post(
        '/api/companies/$companyId/join-requests/$requestId/reject',
        data: {if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed},
      );
    } on DioException catch (e) {
      throw _toException(e, fallback: _decideFallback);
    }
  }

  @override
  Future<MyJoinRequest?> getMine() async {
    try {
      final response = await _dio.get('/api/companies/me/join-request');
      final data = response.data;
      if (data is! Map) return null;
      return MyJoinRequest.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      // No request for this account is a normal state, not an error.
      if (e.response?.statusCode == 404) return null;
      throw _toException(e, fallback: _mineFallback);
    }
  }

  @override
  Future<void> escalate() async {
    try {
      await _dio.post('/api/companies/me/join-request/escalate');
    } on DioException catch (e) {
      throw _toException(e, fallback: _escalateFallback);
    }
  }

  static const _listFallback =
      'Không tải được danh sách yêu cầu tham gia. Vui lòng thử lại.';
  static const _decideFallback =
      'Không xử lý được yêu cầu tham gia. Vui lòng thử lại.';
  static const _mineFallback =
      'Không tải được trạng thái yêu cầu tham gia. Vui lòng thử lại.';
  static const _escalateFallback =
      'Không gửi được yêu cầu hỗ trợ. Vui lòng thử lại.';

  static const _forbidden =
      'Chỉ người tạo công ty mới được quản lý yêu cầu tham gia.';
  static const _notFound = 'Không tìm thấy yêu cầu tham gia này.';
  static const _stateInvalid = 'Yêu cầu không còn ở trạng thái có thể xử lý.';
  static const _alreadyHasCompany = 'Tài khoản này đã thuộc một công ty khác.';
  static const _unavailable =
      'Dịch vụ tài khoản tạm thời không khả dụng. Vui lòng thử lại sau.';

  JoinRequestException _toException(
    DioException e, {
    required String fallback,
  }) {
    if (e.response == null) {
      return const JoinRequestException('Lỗi kết nối mạng, vui lòng thử lại');
    }
    switch (e.response!.statusCode) {
      case 403:
        return const JoinRequestException(_forbidden);
      case 404:
        return const JoinRequestException(_notFound);
      case 409:
        return JoinRequestException(_conflictMessage(e) ?? _stateInvalid);
      case 503:
        return const JoinRequestException(_unavailable);
    }
    return JoinRequestException(fallback);
  }

  /// `409` is used both for a request that is no longer decidable and for an
  /// account that already belongs to another company. The server's stable
  /// `errorCode` tells them apart; the free-text detail is never shown.
  String? _conflictMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['errorCode'] == 'ACCOUNT_ALREADY_HAS_COMPANY') {
      return _alreadyHasCompany;
    }
    return null;
  }
}
