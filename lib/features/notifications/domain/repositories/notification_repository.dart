import '../models/app_notification.dart';

/// Abstract contract for Notification repository (PUSH-01)
abstract class INotificationRepository {
  /// Register FCM device token with Notification Service via API Gateway (PUSH-01)
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  /// Unregister FCM device token on logout (PUSH-01)
  Future<void> unregisterDeviceToken(String token);

  /// Fetch notifications list for current user with pagination and optional unread filter
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int size = 20,
    bool? unreadOnly,
  });

  /// Mark single notification as read
  Future<void> markAsRead(String id);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Get count of unread notifications for badge display
  Future<int> getUnreadCount();
}
