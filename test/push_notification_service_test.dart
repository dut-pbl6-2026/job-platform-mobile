import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
import 'package:job_platform_mobile/core/services/push_notification_service.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
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
            data: {'jobId': 'job-001'},
          ),
        );

        // Verify unregisterTokenOnLogout executes safely
        await service.unregisterTokenOnLogout();
      },
    );

    test(
      'resolveNotificationRoute supports job:// deep links, appId, role-aware routing, and blocks untrusted URLs (PUSH-01-06, SEC-05)',
      () {
        expect(
          PushNotificationService.resolveNotificationRoute({
            'route': 'job://job/job-123',
          }),
          '/jobs/job-123',
        );
        expect(
          PushNotificationService.resolveNotificationRoute({
            'route': 'job://application/app-456',
          }, role: UserRole.user),
          '/applications/app-456',
        );
        expect(
          PushNotificationService.resolveNotificationRoute({
            'appId': 'app-789',
          }, role: UserRole.user),
          '/applications/app-789',
        );
        expect(
          PushNotificationService.resolveNotificationRoute({
            'appId': 'app-789',
            'jobId': 'job-55',
          }, role: UserRole.recruiter),
          '${AppRoutes.recruiterCandidates}?jobId=job-55',
        );
        // External / untrusted route strings fall back safely to /home
        expect(
          PushNotificationService.resolveNotificationRoute({
            'route': 'https://evil.example/phish',
          }),
          AppRoutes.home,
        );
        expect(
          PushNotificationService.resolveNotificationRoute({
            'route': '//evil.example/path',
          }),
          AppRoutes.home,
        );
        // camelCase keys work while snake_case keys are ignored
        expect(
          PushNotificationService.resolveNotificationRoute({
            'deepLink': '/jobs/job-camel',
          }),
          '/jobs/job-camel',
        );
        expect(
          PushNotificationService.resolveNotificationRoute({
            'deep_link': '/jobs/job-snake',
            'job_id': 'job-snake-2',
            'application_id': 'app-snake-2',
          }),
          AppRoutes.home,
        );
      },
    );
  });
}
