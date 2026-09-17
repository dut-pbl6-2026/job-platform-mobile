import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'mock_notification_repository.dart';

/// Remote API implementation of [INotificationRepository] communicating exclusively
/// via API Gateway (YARP) per architectural constraint (Section 1.1 / Section 4).
/// Strictly prohibits direct calls to internal microservice ports (e.g. 5006).
class ApiNotificationRepository implements INotificationRepository {
  final Dio _dio;
  final MockNotificationRepository _fallbackMockRepository =
      MockNotificationRepository();

  ApiNotificationRepository({Dio? dio})
    : _dio = dio ?? DioProvider.instance.dio;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _dio.post(
        '/api/notifications/devices',
        data: {'token': token, 'platform': platform},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          'API Gateway notification token registration returned status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Device token registration through Gateway failed: $e');
      // Record in local fallback so app remains functional in dev/offline
      await _fallbackMockRepository.registerDeviceToken(
        token: token,
        platform: platform,
      );
    } catch (e) {
      debugPrint('Unexpected error registering device token: $e');
    }
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _dio.delete('/api/notifications/devices/$token');
    } on DioException catch (e) {
      debugPrint('Device token unregistration failed: $e');
      await _fallbackMockRepository.unregisterDeviceToken(token);
    } catch (e) {
      debugPrint('Unexpected error unregistering device token: $e');
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

      if (response.statusCode == 200 && response.data != null) {
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
      }
      return await _fallbackMockRepository.getNotifications(
        page: page,
        size: size,
        unreadOnly: unreadOnly,
      );
    } on DioException catch (e) {
      debugPrint(
        'Fetch notifications via Gateway error: $e, falling back to mock.',
      );
      return await _fallbackMockRepository.getNotifications(
        page: page,
        size: size,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      debugPrint('Unexpected error fetching notifications: $e');
      return await _fallbackMockRepository.getNotifications(
        page: page,
        size: size,
        unreadOnly: unreadOnly,
      );
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    await _fallbackMockRepository.markAsRead(id);
    try {
      await _dio.put('/api/notifications/$id/read');
    } on DioException catch (e) {
      debugPrint('Mark notification read via Gateway error: $e');
    } catch (e) {
      debugPrint('Unexpected error marking notification read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await _fallbackMockRepository.markAllAsRead();
    try {
      await _dio.put('/api/notifications/read-all');
    } on DioException catch (e) {
      debugPrint('Mark all notifications read via Gateway error: $e');
    } catch (e) {
      debugPrint('Unexpected error marking all notifications read: $e');
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
      return await _fallbackMockRepository.getUnreadCount();
    } on DioException catch (e) {
      debugPrint('Get unread count via Gateway error: $e');
      return await _fallbackMockRepository.getUnreadCount();
    } catch (e) {
      debugPrint('Unexpected error getting unread count: $e');
      return await _fallbackMockRepository.getUnreadCount();
    }
  }
}
