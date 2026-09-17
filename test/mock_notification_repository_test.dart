import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:job_platform_mobile/features/notifications/domain/models/app_notification.dart';

void main() {
  group('MockNotificationRepository Tests (PUSH-01)', () {
    late MockNotificationRepository repository;

    setUp(() {
      repository = MockNotificationRepository();
    });

    test('registerDeviceToken stores token correctly', () async {
      await repository.registerDeviceToken(
        token: 'fcm-device-token-123',
        platform: 'android',
      );

      expect(repository.registeredTokens.contains('fcm-device-token-123'), isTrue);
    });

    test('unregisterDeviceToken removes token on logout', () async {
      await repository.registerDeviceToken(
        token: 'fcm-token-to-remove',
        platform: 'android',
      );
      expect(repository.registeredTokens.contains('fcm-token-to-remove'), isTrue);

      await repository.unregisterDeviceToken('fcm-token-to-remove');
      expect(repository.registeredTokens.contains('fcm-token-to-remove'), isFalse);
    });

    test('getNotifications returns initial sample notifications', () async {
      final list = await repository.getNotifications();

      expect(list.isNotEmpty, isTrue);
      expect(list.length, greaterThanOrEqualTo(4));
    });

    test('getNotifications with unreadOnly filters unread items', () async {
      final unreadList = await repository.getNotifications(unreadOnly: true);

      for (final n in unreadList) {
        expect(n.isRead, isFalse);
      }
    });

    test('markAsRead updates isRead state for target notification', () async {
      final unreadBefore = await repository.getNotifications(unreadOnly: true);
      expect(unreadBefore.isNotEmpty, isTrue);
      final targetId = unreadBefore.first.id;

      await repository.markAsRead(targetId);

      final unreadAfter = await repository.getNotifications(unreadOnly: true);
      expect(unreadAfter.any((n) => n.id == targetId), isFalse);
    });

    test('markAllAsRead sets all items as read and unread count is zero', () async {
      await repository.markAllAsRead();

      final count = await repository.getUnreadCount();
      expect(count, 0);

      final unreadItems = await repository.getNotifications(unreadOnly: true);
      expect(unreadItems.isEmpty, isTrue);
    });

    test('addNotification prepends new notification to feed', () async {
      final initialCount = (await repository.getNotifications()).length;
      final newNotif = AppNotification(
        id: 'new-alert-999',
        title: 'Cảnh báo mới',
        body: 'Nội dung thông báo mới',
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      );

      repository.addNotification(newNotif);

      final updatedList = await repository.getNotifications();
      expect(updatedList.length, initialCount + 1);
      expect(updatedList.first.id, 'new-alert-999');
    });
  });
}
