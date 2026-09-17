import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:job_platform_mobile/features/notifications/domain/models/app_notification.dart';
import 'package:job_platform_mobile/features/notifications/presentation/notification_screen.dart';

void main() {
  group('NotificationScreen Widget Tests (PUSH-01)', () {
    late MockNotificationRepository mockRepo;

    setUp(() {
      mockRepo = MockNotificationRepository();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: NotificationScreen(repository: mockRepo),
      );
    }

    testWidgets('Renders AppBar, tabs, and list of notifications', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chưa đọc'), findsOneWidget);

      // Verify sample notification title is visible
      expect(find.text('Hồ sơ đã được tiếp nhận'), findsOneWidget);
      expect(find.text('Việc làm mới phù hợp với bạn'), findsOneWidget);
    });

    testWidgets('Switches to Chưa đọc tab and shows unread items only', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 'Chưa đọc' tab
      await tester.tap(find.text('Chưa đọc'));
      await tester.pumpAndSettle();

      // Unread items should remain visible
      expect(find.text('Hồ sơ đã được tiếp nhận'), findsOneWidget);

      // Read items (notif-003, notif-004) should not be displayed
      expect(find.text('Lời mời phỏng vấn'), findsNothing);
      expect(find.text('Chào mừng bạn đến với Job Platform'), findsNothing);
    });

    testWidgets('Tapping on a notification marks it as read', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final itemFinder = find.byKey(const Key('notification_item_notif-001'));
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Verify repository updated
      final unread = await mockRepo.getNotifications(unreadOnly: true);
      expect(unread.any((n) => n.id == 'notif-001'), isFalse);
    });

    testWidgets('Mark all read button marks all notifications as read', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final markAllButton = find.byKey(const Key('mark_all_read_button'));
      expect(markAllButton, findsOneWidget);

      await tester.tap(markAllButton);
      await tester.pumpAndSettle();

      // SnackBar should be displayed
      expect(find.text('Đã đánh dấu tất cả thông báo là đã đọc'), findsOneWidget);

      // All items in repo should now be read
      final unreadCount = await mockRepo.getUnreadCount();
      expect(unreadCount, 0);
    });

    testWidgets('Shows empty state when there are no notifications', (tester) async {
      final emptyRepo = _EmptyNotificationRepository();
      await tester.pumpWidget(
        MaterialApp(home: NotificationScreen(repository: emptyRepo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
    });
  });
}

class _EmptyNotificationRepository extends MockNotificationRepository {
  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int size = 20,
    bool? unreadOnly,
  }) async {
    return [];
  }

  @override
  Future<int> getUnreadCount() async => 0;
}
