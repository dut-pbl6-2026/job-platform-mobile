import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Mock implementation of [INotificationRepository] with local persistent storage for read status (PUSH-01)
class MockNotificationRepository implements INotificationRepository {
  static const String _kReadIdsKey = 'read_notifications_ids';
  static const String _kAllReadKey = 'read_notifications_all';

  static final Set<String> _cachedReadIds = {};
  static bool _cachedAllRead = false;
  static bool _isLoaded = false;

  /// Loads persistent read notification state from SharedPreferences
  static Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 400),
      );
      final saved = prefs.getStringList(_kReadIdsKey);
      if (saved != null) {
        _cachedReadIds.addAll(saved);
      }
      _cachedAllRead = prefs.getBool(_kAllReadKey) ?? false;
      _isLoaded = true;
    } catch (_) {
      _isLoaded = true;
    }
  }

  /// Checks whether a notification ID has been marked as read locally
  static bool isMarkedReadLocally(String id) {
    return _cachedAllRead || _cachedReadIds.contains(id);
  }

  static Future<void> _savePersistentState() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 400),
      );
      await prefs.setStringList(_kReadIdsKey, _cachedReadIds.toList());
      await prefs.setBool(_kAllReadKey, _cachedAllRead);
    } catch (_) {}
  }

  /// Helper to reset static cache during tests
  static void resetCache() {
    _cachedReadIds.clear();
    _cachedAllRead = false;
    _isLoaded = false;
  }

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
    await ensureLoaded();

    var mapped = _notifications.map((n) {
      if (isMarkedReadLocally(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    if (unreadOnly == true) {
      mapped = mapped.where((n) => !n.isRead).toList();
    }
    mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = (page - 1) * size;
    if (start >= mapped.length) {
      return [];
    }
    final end = (start + size) > mapped.length ? mapped.length : start + size;
    return mapped.sublist(start, end);
  }

  @override
  Future<void> markAsRead(String id) async {
    await ensureLoaded();
    _cachedReadIds.add(id);
    await _savePersistentState();

    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await ensureLoaded();
    _cachedAllRead = true;
    for (final n in _notifications) {
      _cachedReadIds.add(n.id);
    }
    await _savePersistentState();

    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    await ensureLoaded();
    return _notifications
        .where((n) => !n.isRead && !isMarkedReadLocally(n.id))
        .length;
  }

  /// Helper to push a test notification (used in tests or simulation)
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
  }
}
