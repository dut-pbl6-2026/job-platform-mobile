import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Model representing a recruiter connection invitation per Figma #2069:832, #2090:963, #2090:993
class RecruiterInvite {
  final String id;
  final String companyName;
  final String positionTitle;
  final String location;
  final String salaryRange;
  final String note;
  final String status; // 'pending', 'responded', 'expired'
  final String deadlineText;
  final String? responseText;

  const RecruiterInvite({
    required this.id,
    required this.companyName,
    required this.positionTitle,
    required this.location,
    required this.salaryRange,
    required this.note,
    required this.status,
    required this.deadlineText,
    this.responseText,
  });
}

/// Commercial Employer Connections Screen ("NTD kết nối")
/// Faithful implementation of Figma frames:
/// - NTD kết nối / Chờ phản hồi (#2069:832)
/// - NTD kết nối / Đã phản hồi (#2090:963)
/// - NTD kết nối / Quá hạn (#2090:993)
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  int _activeTabIndex = 0; // 0: Chờ phản hồi, 1: Đã phản hồi, 2: Quá hạn

  late List<RecruiterInvite> _invites;

  @override
  void initState() {
    super.initState();
    _invites = [
      const RecruiterInvite(
        id: 'inv_1',
        companyName: 'Badoo Inc.',
        positionTitle: 'UI/UX Designer',
        location: 'Đà Nẵng · Toàn thời gian',
        salaryRange: '20.000.000 - 35.000.000 ₫',
        note: 'Hồ sơ của bạn rất phù hợp với sản phẩm mới của chúng tôi. Mời bạn trao đổi nhanh về vị trí này nhé!',
        status: 'pending',
        deadlineText: 'Còn 3 ngày để phản hồi',
      ),
      const RecruiterInvite(
        id: 'inv_2',
        companyName: 'Meta Inc.',
        positionTitle: 'Product Designer',
        location: 'TP. Hồ Chí Minh · Hybrid',
        salaryRange: '30.000.000 - 50.000.000 ₫',
        note: 'Chào bạn, phòng thiết kế Meta Việt Nam muốn kết nối để mời bạn tham gia vòng phỏng vấn sớm.',
        status: 'pending',
        deadlineText: 'Còn 5 ngày để phản hồi',
      ),
      const RecruiterInvite(
        id: 'inv_3',
        companyName: 'FPT Software',
        positionTitle: 'Senior Frontend Developer',
        location: 'Đà Nẵng · Onsite',
        salaryRange: '25.000.000 - 40.000.000 ₫',
        note: 'Mời ứng viên tham gia dự án Fintech thị trường Nhật Bản.',
        status: 'responded',
        deadlineText: 'Đã chấp nhận kết nối',
        responseText: 'Bạn đã đồng ý kết nối vào 08/10/2026. Nhà tuyển dụng sẽ gửi lịch hẹn phỏng vấn.',
      ),
      const RecruiterInvite(
        id: 'inv_4',
        companyName: 'VNG Corporation',
        positionTitle: 'Mobile Flutter Engineer',
        location: 'TP. Hồ Chí Minh · Toàn thời gian',
        salaryRange: '28.000.000 - 45.000.000 ₫',
        note: 'Đã phản hồi lịch trao đổi trực tuyến.',
        status: 'responded',
        deadlineText: 'Đã hoàn tất trao đổi',
        responseText:
            'Đã hoàn tất cuộc trao đổi online lúc 14:00 ngày 05/10/2026.',
      ),
      const RecruiterInvite(
        id: 'inv_5',
        companyName: 'Netflix Inc.',
        positionTitle: 'Sr. UI Designer',
        location: 'Remote · Quốc tế',
        salaryRange: '40.000.000 - 70.000.000 ₫',
        note: 'Lời mời Sr. UI Designer đã hết hạn phản hồi.',
        status: 'expired',
        deadlineText: 'Đã quá hạn 2 ngày trước',
      ),
    ];
  }

  List<RecruiterInvite> get _filteredInvites {
    return switch (_activeTabIndex) {
      0 => _invites.where((i) => i.status == 'pending').toList(),
      1 => _invites.where((i) => i.status == 'responded').toList(),
      2 => _invites.where((i) => i.status == 'expired').toList(),
      _ => [],
    };
  }

  void _handleAcceptInvite(RecruiterInvite invite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chấp nhận kết nối'),
        content: Text(
          'Bạn đồng ý chia sẻ thông tin liên hệ và CV với ${invite.companyName} cho vị trí ${invite.positionTitle}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _invites.indexWhere((i) => i.id == invite.id);
                if (index != -1) {
                  _invites[index] = RecruiterInvite(
                    id: invite.id,
                    companyName: invite.companyName,
                    positionTitle: invite.positionTitle,
                    location: invite.location,
                    salaryRange: invite.salaryRange,
                    note: invite.note,
                    status: 'responded',
                    deadlineText: 'Đã chấp nhận kết nối',
                    responseText: 'Bạn đã đồng ý kết nối. Nhà tuyển dụng sẽ sớm gửi lịch hẹn.',
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã chấp nhận kết nối với ${invite.companyName}!',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _handleDeclineInvite(RecruiterInvite invite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối lời mời'),
        content: Text('Bạn muốn từ chối lời mời từ ${invite.companyName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _invites.indexWhere((i) => i.id == invite.id);
                if (index != -1) {
                  _invites[index] = RecruiterInvite(
                    id: invite.id,
                    companyName: invite.companyName,
                    positionTitle: invite.positionTitle,
                    location: invite.location,
                    salaryRange: invite.salaryRange,
                    note: invite.note,
                    status: 'responded',
                    deadlineText: 'Đã từ chối lời mời',
                    responseText:
                        'Bạn đã từ chối lời mời này một cách lịch sự.',
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi thông báo từ chối đến nhà tuyển dụng.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Từ chối',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _invites.where((i) => i.status == 'pending').length;
    final respondedCount = _invites
        .where((i) => i.status == 'responded')
        .length;
    final expiredCount = _invites.where((i) => i.status == 'expired').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'NTD kết nối',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push(AppRoutes.notifications),
            tooltip: 'Thông báo',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Intro Hero Banner (Figma #2090:1057)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0085FF), Color(0xFF0768E1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0085FF).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lời mời từ Nhà tuyển dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pendingCount > 0
                                ? 'Bạn có $pendingCount lời mời đang chờ phản hồi'
                                : 'Hồ sơ của bạn đang được các nhà tuyển dụng quan tâm',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Segmented Status Tabs (Figma #2090:1061)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildTabItem(0, 'Chờ phản hồi', pendingCount),
                    _buildTabItem(1, 'Đã phản hồi', respondedCount),
                    _buildTabItem(2, 'Quá hạn', expiredCount),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Section Title with count
              Text(
                switch (_activeTabIndex) {
                  0 => '$pendingCount lời mời đang chờ',
                  1 => '$respondedCount lời mời đã phản hồi',
                  2 => '$expiredCount lời mời quá hạn',
                  _ => '',
                },
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // 4. Invites List
              if (_filteredInvites.isEmpty)
                _buildEmptyState()
              else
                ..._filteredInvites.map(_buildInviteCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, int count) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(RecruiterInvite invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Company Logo initial + Name + Deadline badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    invite.companyName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invite.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: invite.status == 'pending'
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : invite.status == 'responded'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invite.deadlineText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: invite.status == 'pending'
                        ? AppColors.primary
                        : invite.status == 'responded'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Position & Salary
          Text(
            invite.positionTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                invite.salaryRange,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Message snippet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              invite.responseText ?? invite.note,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),

          // Actions if pending
          if (invite.status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeclineInvite(invite),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Từ chối',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAcceptInvite(invite),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Chấp nhận kết nối',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có lời mời nào trong mục này',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hoàn thiện hồ sơ và kỹ năng để nhận thêm kết nối từ nhà tuyển dụng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
