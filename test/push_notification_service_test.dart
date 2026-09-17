import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/services/push_notification_service.dart';
import 'package:job_platform_mobile/features/notifications/data/repositories/mock_notification_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationService Tests (PUSH-01)', () {
    test('Singleton instance is non-null and persistent', () {
      final instance1 = PushNotificationService.instance;
      final instance2 = PushNotificationService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test(
      'initializes and handles background handler safely without crashing',
      () async {
        final service = PushNotificationService.instance;

        // Simulate initialization with mock repository (in unit test environment, safely falls back)
        final mockRepo = MockNotificationRepository();
        await service.initialize(repository: mockRepo);

        // Background handler can process messages without throwing
        await firebaseMessagingBackgroundHandler(
          const RemoteMessage(
            messageId: 'bg-test-msg-1',
            data: {'job_id': 'job-001'},
          ),
        );

        // Verify unregisterTokenOnLogout executes safely
        await service.unregisterTokenOnLogout();
      },
    );
  });
}
