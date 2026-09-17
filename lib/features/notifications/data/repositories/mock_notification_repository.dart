import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Mock in-memory implementation of [INotificationRepository] (PUSH-01)
class MockNotificationRepository implements INotificationRepository {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif-001',
      title: 'Hồ sơ đã được tiếp nhận',
      body:
          'Nhà tuyển dụng VinAI Research đã duyệt hồ sơ ứng tuyển vị trí Senior Flutter Engineer của bạn.',
      type: NotificationType.applicationStatus,
      data: {
        'application_id': 'app-001',
        'job_id': 'job-001',
        'route': '/applications/app-001',
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'notif-002',
      title: 'Việc làm mới phù hợp với bạn',
      body:
          'Vị trí Mobile Tech Lead (Flutter/Dart) tại FPT Software phù hợp 95% với kỹ năng hồ sơ của bạn.',
      type: NotificationType.newJobMatch,
      data: {'job_id': 'job-002', 'route': '/jobs/job-002'},
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-003',
      title: 'Lời mời phỏng vấn',
      body:
          'VNG Corporation gửi lời mời phỏng vấn trực tuyến vòng 1 vào lúc 09:30 ngày 25/09/2026.',
      type: NotificationType.interviewInvite,
      data: {
        'application_id': 'app-002',
        'job_id': 'job-003',
        'route': '/applications/app-002',
      },
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'notif-004',
      title: 'Chào mừng bạn đến với Job Platform',
      body:
          'Hoàn thiện hồ sơ cá nhân và kỹ năng để tăng cơ hội tiếp cận nhà tuyển dụng hàng đầu.',
      type: NotificationType.system,
      data: {'route': '/profile'},
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  final Set<String> _registeredTokens = {};

  Set<String> get registeredTokens => Set.unmodifiable(_registeredTokens);

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    _registeredTokens.add(token);
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    _registeredTokens.remove(token);
  }

  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int size = 20,
    bool? unreadOnly,
  }) async {
    var filtered = List<AppNotification>.from(_notifications);
    if (unreadOnly == true) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = (page - 1) * size;
    if (start >= filtered.length) {
      return [];
    }
    final end = (start + size) > filtered.length ? filtered.length : start + size;
    return filtered.sublist(start, end);
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Helper to push a test notification (used in tests or simulation)
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
  }
}
