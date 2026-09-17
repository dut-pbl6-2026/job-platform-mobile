import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/notifications/domain/models/app_notification.dart';

void main() {
  group('AppNotification Model Tests (PUSH-01)', () {
    test('fromJson parses application_status notification properly', () {
      final json = {
        'id': 'notif-123',
        'title': 'Hồ sơ đã được xem',
        'body': 'Nhà tuyển dụng đã xem hồ sơ của bạn',
        'type': 'application_status',
        'is_read': false,
        'created_at': '2026-09-17T10:30:00Z',
        'data': {
          'application_id': 'app-999',
          'job_id': 'job-888',
          'route': '/applications/app-999',
        },
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-123');
      expect(notif.title, 'Hồ sơ đã được xem');
      expect(notif.body, 'Nhà tuyển dụng đã xem hồ sơ của bạn');
      expect(notif.type, NotificationType.applicationStatus);
      expect(notif.isRead, false);
      expect(notif.applicationId, 'app-999');
      expect(notif.jobId, 'job-888');
      expect(notif.route, '/applications/app-999');
    });

    test('fromJson parses new_job_match properly', () {
      final json = {
        'id': 'notif-456',
        'title': 'Việc làm phù hợp',
        'body': 'Có việc làm mới phù hợp với bạn',
        'type': 'new_job_match',
        'isRead': true,
        'createdAt': '2026-09-17T12:00:00Z',
        'data': {'jobId': 'job-777'},
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-456');
      expect(notif.type, NotificationType.newJobMatch);
      expect(notif.isRead, true);
      expect(notif.jobId, 'job-777');
    });

    test('toJson serializes correctly and is reversible', () {
      final notif = AppNotification(
        id: 'notif-1',
        title: 'Title',
        body: 'Body',
        type: NotificationType.interviewInvite,
        isRead: false,
        createdAt: DateTime.parse('2026-09-17T08:00:00Z'),
        data: {'application_id': 'app-1'},
      );

      final json = notif.toJson();
      expect(json['id'], 'notif-1');
      expect(json['type'], 'interview_invite');
      expect(json['is_read'], false);

      final restored = AppNotification.fromJson(json);
      expect(restored.id, notif.id);
      expect(restored.type, notif.type);
      expect(restored.applicationId, 'app-1');
    });

    test('copyWith updates specified fields correctly', () {
      final original = AppNotification(
        id: 'notif-1',
        title: 'Old Title',
        body: 'Old Body',
        type: NotificationType.system,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(isRead: true, title: 'New Title');

      expect(updated.id, original.id);
      expect(updated.title, 'New Title');
      expect(updated.body, 'Old Body');
      expect(updated.isRead, true);
      expect(updated.type, NotificationType.system);
    });

    test('NotificationType.fromString handles case and variants', () {
      expect(
        NotificationType.fromString('application_status'),
        NotificationType.applicationStatus,
      );
      expect(
        NotificationType.fromString('new_job_match'),
        NotificationType.newJobMatch,
      );
      expect(
        NotificationType.fromString('interview_invite'),
        NotificationType.interviewInvite,
      );
      expect(NotificationType.fromString('system'), NotificationType.system);
      expect(
        NotificationType.fromString('unknown_type'),
        NotificationType.system,
      );
    });
  });
}
