import 'package:flutter/foundation.dart';

/// Supported types of push / app notifications (PUSH-01)
enum NotificationType {
  applicationStatus,
  newJobMatch,
  interviewInvite,
  system;

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'application_status':
      case 'applicationstatus':
      case 'application':
        return NotificationType.applicationStatus;
      case 'new_job_match':
      case 'newjobmatch':
      case 'job':
      case 'job_recommendation':
        return NotificationType.newJobMatch;
      case 'interview_invite':
      case 'interviewinvite':
      case 'interview':
        return NotificationType.interviewInvite;
      default:
        return NotificationType.system;
    }
  }

  String toSnakeCase() {
    switch (this) {
      case NotificationType.applicationStatus:
        return 'application_status';
      case NotificationType.newJobMatch:
        return 'new_job_match';
      case NotificationType.interviewInvite:
        return 'interview_invite';
      case NotificationType.system:
        return 'system';
    }
  }
}

/// Notification entity model representing a push or in-app notification (PUSH-01)
@immutable
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  /// Helper to extract associated jobId from payload data
  String? get jobId =>
      data['job_id']?.toString() ?? data['jobId']?.toString();

  /// Helper to extract associated applicationId from payload data
  String? get applicationId =>
      data['application_id']?.toString() ??
      data['applicationId']?.toString();

  /// Target route if provided by notification payload
  String? get route => data['route']?.toString();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic> parsedData = const {};
    if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    } else if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    }

    return AppNotification(
      id: (json['id'] ?? json['notification_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      type: NotificationType.fromString(
        json['type']?.toString() ?? parsedData['type']?.toString(),
      ),
      data: parsedData,
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toSnakeCase(),
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          type == other.type &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      type.hashCode ^
      isRead.hashCode ^
      createdAt.hashCode;
}
