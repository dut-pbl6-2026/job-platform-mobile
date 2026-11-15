import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/join_request.dart';

/// Colour-coded label for a join-request status. Colours follow the app palette:
/// waiting states are amber/blue, final states are green/red, expiry is muted.
class JoinRequestStatusChip extends StatelessWidget {
  const JoinRequestStatusChip({super.key, required this.status});

  final JoinRequestStatus status;

  Color get _color => switch (status) {
    JoinRequestStatus.pending => AppColors.warning,
    JoinRequestStatus.approved ||
    JoinRequestStatus.supportApproved => AppColors.success,
    JoinRequestStatus.rejected ||
    JoinRequestStatus.supportRejected => AppColors.error,
    JoinRequestStatus.expired => AppColors.textHint,
    JoinRequestStatus.escalated => AppColors.primary,
    JoinRequestStatus.unknown => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _color.withValues(alpha: 0.35)),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _color,
      ),
    ),
  );
}

/// Formats a join-request timestamp as `dd/MM/yyyy HH:mm` (SRS 4.1).
String formatJoinRequestDate(DateTime? date) {
  if (date == null) return '—';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}
