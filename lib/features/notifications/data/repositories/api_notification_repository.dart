import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/mock_fallback.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'mock_notification_repository.dart';

/// Remote API implementation of [INotificationRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Strictly prohibits direct calls to internal microservice ports (e.g. 5006).
///
/// Mock data is only reachable when the build enables it
/// (`--dart-define=ENABLE_MOCKS=true`) and the failure is a transport failure or
/// a 5xx. Writes (device token, read state) never report success for a request
/// the server rejected.
class ApiNotificationRepository implements INotificationRepository {
  final Dio _dio;
  final MockNotificationRepository _fallbackMockRepository =
      MockNotificationRepository();
  final bool _enableMocks;

  ApiNotificationRepository({Dio? dio, bool? enableMockFallback})
    : _dio = dio ?? DioProvider.instance.dio,
      _enableMocks = enableMockFallback ?? kEnableMocks;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _dio.post(
        '/api/notifications/devices',
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        if (kDebugMode) {
          debugPrint(
            'Device token registration through Gateway failed '
            '(${e.response?.statusCode ?? e.type}).',
          );
        }
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('Device token registration unavailable, recording locally.');
      }
      await _fallbackMockRepository.registerDeviceToken(
        token: token,
        platform: platform,
      );
    }
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    try {
      final encodedToken = Uri.encodeComponent(token);
      await _dio.delete('/api/notifications/devices/$encodedToken');
    } on DioException catch (e) {
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        if (kDebugMode) {
          debugPrint(
            'Device token unregistration failed '
            '(${e.response?.statusCode ?? e.type}).',
          );
        }
        rethrow;
      }
      await _fallbackMockRepository.unregisterDeviceToken(token);
    }
  }

  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int size = 20,
    bool? unreadOnly,
  }) async {
    try {
      final response = await _dio.get(
        '/api/notifications',
        queryParameters: {
          'page': page,
          'pageSize': size,
          'unreadOnly': ?unreadOnly,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw StateError(
          'Unexpected notifications response (${response.statusCode})',
        );
      }

      final dynamic raw = response.data;
      List<dynamic> items = [];
      if (raw is List) {
        items = raw;
      } else if (raw is Map<String, dynamic>) {
        items = (raw['items'] ?? raw['data'] ?? []) as List<dynamic>;
      }

      await MockNotificationRepository.ensureLoaded();
      return items.map((item) {
        final notif = AppNotification.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        if (MockNotificationRepository.isMarkedReadLocally(notif.id)) {
          return notif.copyWith(isRead: true);
        }
        return notif;
      }).toList();
    } on DioException catch (e) {
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        debugPrint(
          'Fetch notifications via Gateway failed '
          '(${e.response?.statusCode ?? e.type}).',
        );
        rethrow;
      }
      debugPrint('Notifications unavailable, using mock data.');
      return _fallbackMockRepository.getNotifications(
        page: page,
        size: size,
        unreadOnly: unreadOnly,
      );
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _dio.put('/api/notifications/$id/read');
    } on DioException catch (e) {
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        debugPrint(
          'Mark notification read via Gateway failed '
          '(${e.response?.statusCode ?? e.type}).',
        );
        rethrow;
      }
      await _fallbackMockRepository.markAsRead(id);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/api/notifications/read-all');
    } on DioException catch (e) {
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        debugPrint(
          'Mark all notifications read via Gateway failed '
          '(${e.response?.statusCode ?? e.type}).',
        );
        rethrow;
      }
      await _fallbackMockRepository.markAllAsRead();
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/api/notifications/unread-count');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map) {
          return (response.data['count'] ?? response.data['unread_count'] ?? 0)
              as int;
        } else if (response.data is int) {
          return response.data as int;
        }
      }
      return 0;
    } on DioException catch (e) {
      if (!shouldUseMockFallback(
        enabled: _enableMocks,
        statusCode: e.response?.statusCode,
      )) {
        debugPrint(
          'Get unread count via Gateway failed '
          '(${e.response?.statusCode ?? e.type}).',
        );
        rethrow;
      }
      return _fallbackMockRepository.getUnreadCount();
    }
  }
}
