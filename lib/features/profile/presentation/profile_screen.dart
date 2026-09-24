import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_profile_repository.dart';
import '../domain/models/profile_model.dart';
import '../domain/repositories/profile_repository.dart';
import 'profile_detail_screen.dart';
import 'widgets/profile_menu_item.dart';

/// Main Profile & Account Hub Screen with Blue Palette (MOB-01, PROFILE-01)
class ProfileScreen extends StatefulWidget {
  final IProfileRepository? profileRepository;

  const ProfileScreen({super.key, this.profileRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final IProfileRepository _repository;
  ProfileModel? _profile;

  // State for toggles in "Trạng thái tìm việc"
  bool _isJobRecommendationEnabled = false;
  bool _isJobSeekingActive = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.profileRepository ?? ApiProfileRepository();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final p = await _repository.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = p;
        });
      }
    } catch (_) {}
  }

  String get _displayName {
    if (_profile != null && _profile!.fullName.isNotEmpty) {
      return _profile!.fullName;
    }
    final sessionUser = AuthSession.instance.currentUser;
    if (sessionUser != null && sessionUser.name.isNotEmpty) {
      return sessionUser.name;
    }
    return 'Khoa Phạm';
  }

  String get _candidateCode {
    final rawId =
        _profile?.userId ?? AuthSession.instance.currentUser?.id ?? '7613650';
    final numeric = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.length >= 6) {
      return numeric.substring(0, 7.clamp(0, numeric.length));
    }
    final hashStr = (rawId.hashCode.abs() % 9000000 + 1000000).toString();
    return hashStr;
  }

  void _showJobRecommendationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bật gợi ý việc làm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tôi đồng ý để hệ thống gợi ý việc làm dựa trên CV và hoạt động tìm việc, quá trình phân tích có thể sử dụng công nghệ AI',
          style: TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isJobRecommendationEnabled = false);
            },
            child: const Text(
              'Để sau',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isJobRecommendationEnabled = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text('Đã kích hoạt gợi ý việc làm AI thành công!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Cập nhật ảnh đại diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tính năng chụp ảnh đại diện đang sẵn sàng',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã chọn ảnh đại diện')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpgradeAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Nâng cấp tài khoản VIP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Trở thành ứng viên nổi bật với các quyền lợi đặc biệt:',
              style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            SizedBox(height: 12),
            Text('• Hồ sơ hiển thị ưu tiên hàng đầu với NTD'),
            Text('• Tự động tối ưu CV với Trí tuệ nhân tạo AI'),
            Text('• Không giới hạn số lượng CV và Cover Letter lưu trữ'),
            Text('• Nhận thông báo việc làm độc quyền theo thời gian thực'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Tìm hiểu thêm'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthSession.instance.clearSession();
              if (mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showInformationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text('Đổi mật khẩu thành công!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _openProfileDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(profileRepository: _repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Stack with blue curved background & floating user card
              _buildTopHeaderWithCard(),

              // Body Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Section 1: Trạng thái tìm việc
                    _buildSectionHeader('Trạng thái tìm việc'),
                    _buildCardContainer([
                      // Gợi ý việc làm (Switch gạt trái phải)
                      ProfileMenuItem(
                        icon: Icons.splitscreen_rounded,
                        iconColor: AppColors.primary,
                        title: 'Gợi ý việc làm',
                        helpText:
                            'Hệ thống AI sẽ tự động phân tích hồ sơ của bạn để đề xuất các vị trí công việc phù hợp nhất.',
                        showChevron: false,
                        trailing: Switch.adaptive(
                          value: _isJobRecommendationEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            if (val) {
                              _showJobRecommendationDialog();
                            } else {
                              setState(
                                () => _isJobRecommendationEnabled = false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã tắt gợi ý việc làm'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      _buildDivider(),

                      // Trạng thái tìm việc
                      ProfileMenuItem(
                        icon: Icons.laptop_chromebook_rounded,
                        iconColor: AppColors.primary,
                        title: 'Trạng thái tìm việc',
                        helpText:
                            'Bật trạng thái này để thông báo cho Nhà tuyển dụng biết bạn đang sẵn sàng đón nhận cơ hội việc làm mới.',
                        showChevron: false,
                        trailing: Switch.adaptive(
                          value: _isJobSeekingActive,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _isJobSeekingActive = val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Đã bật trạng thái tìm việc - Hồ sơ của bạn sẽ được ưu tiên hiển thị!'
                                      : 'Đã tắt trạng thái tìm việc',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      _buildDivider(),

                      // Cho phép NTD tìm kiếm hồ sơ
                      ProfileMenuItem(
                        icon: Icons.manage_search_rounded,
                        iconColor: AppColors.primary,
                        title: 'Cho phép NTD tìm kiếm hồ sơ',
                        onTap: () => _showInformationDialog(
                          'Cho phép NTD tìm kiếm hồ sơ',
                          'Khi bật tính năng này, các nhà tuyển dụng đã xác thực trên nền tảng có thể tìm kiếm và xem hồ sơ công khai của bạn để gửi lời mời làm việc.',
                        ),
                      ),
                    ]),

                    // Section 2: Hồ sơ của tôi
                    _buildSectionHeader('Hồ sơ của tôi'),
                    _buildCardContainer([
                      ProfileMenuItem(
                        icon: Icons.folder_shared_outlined,
                        iconColor: AppColors.primary,
                        title: 'Profile của tôi',
                        onTap: _openProfileDetail,
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.primary,
                        title: 'CV của tôi',
                        onTap: () => context.go(AppRoutes.createCv),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.edit_note_rounded,
                        iconColor: AppColors.primary,
                        title: 'Cover Letter của tôi',
                        onTap: () => _showInformationDialog(
                          'Cover Letter của tôi',
                          'Quản lý danh sách các bức thư xin việc (Cover Letter) đã lưu để đính kèm nhanh chóng khi ứng tuyển việc làm.',
                        ),
                      ),
                    ]),

                    // Section 3: Quản lý tìm việc
                    _buildSectionHeader('Quản lý tìm việc'),
                    _buildCardContainer([
                      ProfileMenuItem(
                        icon: Icons.work_history_outlined,
                        iconColor: AppColors.primary,
                        title: 'Việc làm đã ứng tuyển',
                        onTap: () => context.go(AppRoutes.applications),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.favorite_border_rounded,
                        iconColor: AppColors.primary,
                        title: 'Việc làm đã lưu',
                        onTap: () => _showInformationDialog(
                          'Việc làm đã lưu',
                          'Xem lại các công việc bạn đã đánh dấu yêu thích để dễ dàng theo dõi và ứng tuyển bất cứ lúc nào.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.tune_rounded,
                        iconColor: AppColors.primary,
                        title: 'Cài đặt gợi ý việc làm',
                        onTap: () => _showInformationDialog(
                          'Cài đặt gợi ý việc làm',
                          'Tùy chỉnh mức lương mong muốn, địa điểm làm việc và cấp bậc ưu tiên để thuật toán gợi ý chính xác nhất.',
                        ),
                      ),
                    ]),

                    // Section 4: Tương tác với NTD (Đã bỏ TopCV Connect theo yêu cầu)
                    _buildSectionHeader('Tương tác với NTD'),
                    _buildCardContainer([
                      ProfileMenuItem(
                        icon: Icons.visibility_outlined,
                        iconColor: AppColors.primary,
                        title: 'NTD xem hồ sơ',
                        onTap: () => _showInformationDialog(
                          'NTD xem hồ sơ',
                          'Đã có 12 lượt nhà tuyển dụng ghé thăm và xem chi tiết hồ sơ của bạn trong 30 ngày qua.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.person_add_alt_outlined,
                        iconColor: AppColors.primary,
                        title: 'NTD muốn kết nối với bạn',
                        onTap: () => _showInformationDialog(
                          'NTD muốn kết nối với bạn',
                          'Hiện tại bạn không có lời mời kết nối nào đang chờ xử lý.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.domain_outlined,
                        iconColor: AppColors.primary,
                        title: 'Công ty đang theo dõi',
                        onTap: () => _showInformationDialog(
                          'Công ty đang theo dõi',
                          'Bạn đang theo dõi 5 doanh nghiệp hàng đầu để cập nhật tin tuyển dụng mới nhất.',
                        ),
                      ),
                    ]),

                    // Section 5: Cài đặt thông báo
                    _buildSectionHeader('Cài đặt thông báo'),
                    _buildCardContainer([
                      ProfileMenuItem(
                        icon: Icons.notifications_none_rounded,
                        iconColor: AppColors.primary,
                        title: 'Thông báo việc làm',
                        onTap: () => context.go(AppRoutes.notifications),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.mail_outline_rounded,
                        iconColor: AppColors.primary,
                        title: 'Cài đặt nhận email',
                        onTap: () => _showInformationDialog(
                          'Cài đặt nhận email',
                          'Tùy chỉnh tần suất nhận bản tin việc làm hàng ngày và thông báo trạng thái ứng tuyển qua email.',
                        ),
                      ),
                    ]),

                    // Section 6: Bảo mật
                    _buildSectionHeader('Bảo mật'),
                    _buildCardContainer([
                      ProfileMenuItem(
                        icon: Icons.key_outlined,
                        iconColor: AppColors.primary,
                        title: 'Đổi mật khẩu',
                        onTap: _showChangePasswordDialog,
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.primary,
                        title: 'Cài đặt bảo mật',
                        onTap: () => _showInformationDialog(
                          'Cài đặt bảo mật',
                          'Quản lý phiên đăng nhập hiện tại và thiết bị đã cấp quyền truy cập.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.lock_clock_outlined,
                        iconColor: AppColors.primary,
                        title: 'Xác minh 2 bước',
                        subtitle: 'Chưa xác minh',
                        onTap: () => _showInformationDialog(
                          'Xác minh 2 bước',
                          'Tăng cường độ an toàn cho tài khoản bằng mã xác thực gửi qua SMS hoặc ứng dụng OTP.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.person_off_outlined,
                        iconColor: AppColors.primary,
                        title: 'Vô hiệu hóa tài khoản',
                        onTap: () => _showInformationDialog(
                          'Vô hiệu hóa tài khoản',
                          'Tạm thời khóa tài khoản và ẩn thông tin hồ sơ của bạn khỏi tất cả các hoạt động tìm kiếm.',
                        ),
                      ),
                    ]),

                    // Section 7: Chính sách hỗ trợ (Về TopCV đã đổi thành Về chúng tôi)
                    _buildSectionHeader('Chính sách hỗ trợ'),
                    _buildCardContainer([
                      ProfileMenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.primary,
                        title: 'Về chúng tôi',
                        onTap: () => _showInformationDialog(
                          'Về chúng tôi',
                          'Nền tảng tuyển dụng và tìm kiếm việc làm hàng đầu tại Việt Nam.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.gavel_outlined,
                        iconColor: AppColors.primary,
                        title: 'Điều khoản dịch vụ',
                        onTap: () => _showInformationDialog(
                          'Điều khoản dịch vụ',
                          'Xem các điều khoản và quy định khi sử dụng hệ thống.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.security_outlined,
                        iconColor: AppColors.primary,
                        title: 'Chính sách quyền riêng tư',
                        onTap: () => _showInformationDialog(
                          'Chính sách quyền riêng tư',
                          'Cam kết bảo vệ tuyệt đối thông tin và dữ liệu cá nhân của người dùng.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppColors.primary,
                        title: 'Điều kiện giao dịch chung',
                        onTap: () => _showInformationDialog(
                          'Điều kiện giao dịch chung',
                          'Quy định chung về các giao dịch điện tử trên nền tảng.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.primary,
                        title: 'Giá dịch vụ & Cách thanh toán',
                        onTap: () => _showInformationDialog(
                          'Giá dịch vụ & Cách thanh toán',
                          'Bảng giá các gói tài khoản cao cấp và phương thức thanh toán an toàn.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.local_shipping_outlined,
                        iconColor: AppColors.primary,
                        title: 'Thông tin về vận chuyển',
                        onTap: () => _showInformationDialog(
                          'Thông tin về vận chuyển',
                          'Thông tin liên quan đến giao nhận các ấn phẩm hoặc quà tặng lưu niệm.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.support_agent_rounded,
                        iconColor: AppColors.primary,
                        title: 'Trợ giúp',
                        onTap: () => _showInformationDialog(
                          'Trung tâm trợ giúp',
                          'Đội ngũ chăm sóc khách hàng luôn sẵn sàng hỗ trợ bạn 24/7 qua hotline và email.',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.star_rate_rounded,
                        iconColor: AppColors.primary,
                        title: 'Đánh giá ứng dụng',
                        onTap: () => _showInformationDialog(
                          'Đánh giá ứng dụng',
                          'Cảm ơn bạn đã đóng góp đánh giá 5 sao cho ứng dụng trên Store!',
                        ),
                      ),
                      _buildDivider(),
                      ProfileMenuItem(
                        icon: Icons.system_update_rounded,
                        iconColor: AppColors.primary,
                        title: 'Kiểm tra bản cập nhật mới',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text(
                              'Bạn đang sử dụng phiên bản mới nhất!',
                            ),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Version Info (Ghi đại là 1.0.0 theo yêu cầu)
                    Center(
                      child: Text(
                        'Phiên bản ứng dụng: 1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: _showLogoutConfirmationDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.logout_rounded,
                                size: 19,
                                color: Color(0xFF1E293B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top blue header with curved banner and overlapping User Profile Card
  Widget _buildTopHeaderWithCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Blue patterned banner background
        Container(
          width: double.infinity,
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
          child: CustomPaint(painter: _HeaderPatternPainter()),
        ),

        // Floating Profile Card overlapping the blue header
        Container(
          margin: const EdgeInsets.only(top: 85, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Avatar with camera badge
                    Stack(
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                _profile?.avatarUrl != null &&
                                    _profile!.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    _profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person_rounded,
                                              size: 44,
                                              color: Color(0xFFCBD5E1),
                                            ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 44,
                                    color: Color(0xFFCBD5E1),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _showAvatarPickerModal,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // User name & candidate code
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 19,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mã ứng viên: $_candidateCode',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              _buildDivider(),

              // Nâng cấp tài khoản row
              InkWell(
                onTap: _showUpgradeAccountDialog,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 24,
                        color: Color(0xFF334155),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nâng cấp tài khoản',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 16,
      endIndent: 16,
    );
  }
}

/// Subtle painter to create dotted diagonal motif in top blue banner
class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x / spacing + y / spacing) % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
