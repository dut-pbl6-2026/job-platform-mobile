import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/notifications/data/repositories/api_notification_repository.dart';

void main() {
  group('ApiNotificationRepository Tests (PUSH-01)', () {
    test('Can instantiate ApiNotificationRepository', () {
      final repo = ApiNotificationRepository();
      expect(repo, isNotNull);
    });

    test('Falls back gracefully to mock repository when Gateway is offline', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Connection refused',
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
      final repo = ApiNotificationRepository(dio: dio);

      final notifications = await repo.getNotifications();
      expect(notifications.isNotEmpty, isTrue);

      final unreadCount = await repo.getUnreadCount();
      expect(unreadCount, greaterThanOrEqualTo(0));

      // Should not throw
      await repo.registerDeviceToken(
        token: 'test-fcm-token',
        platform: 'android',
      );
      await repo.unregisterDeviceToken('test-fcm-token');
      await repo.markAsRead('notif-001');
      await repo.markAllAsRead();
    });

    test('Parses successful API Gateway response correctly', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 'api-notif-1',
                      'title': 'Test Gateway Title',
                      'body': 'Test Gateway Body',
                      'type': 'application_status',
                      'is_read': false,
                      'created_at': '2026-09-17T12:00:00Z',
                      'data': {'job_id': 'job-123'},
                    },
                  ],
                ),
              );
            } else if (options.path == '/api/notifications/unread-count') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'count': 5},
                ),
              );
            }
            return handler.resolve(
              Response(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      final repo = ApiNotificationRepository(dio: dio);

      final notifs = await repo.getNotifications();
      expect(notifs.length, 1);
      expect(notifs.first.id, 'api-notif-1');
      expect(notifs.first.title, 'Test Gateway Title');
      expect(notifs.first.jobId, 'job-123');

      final count = await repo.getUnreadCount();
      expect(count, 5);
    });
  });
}
