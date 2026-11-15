import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_invite_code_repository.dart';

/// Company creator issues single-use recruiter invite codes (SRS AUTH-01-09).
/// The code is shown once; the server keeps only its hash.
class InviteCodeScreen extends StatefulWidget {
  final ApiInviteCodeRepository? repository;

  const InviteCodeScreen({super.key, this.repository});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  late final ApiInviteCodeRepository _repository =
      widget.repository ?? ApiInviteCodeRepository();

  IssuedInviteCode? _issued;
  String? _error;
  bool _loading = false;

  String? get _companyId =>
      AuthSession.instance.currentUser?.companyId ??
      AuthSession.instance.companyId;

  Future<void> _create() async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final issued = await _repository.createInviteCode(companyId);
      if (!mounted) return;
      setState(() => _issued = issued);
    } on InviteCodeException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép mã mời')));
  }

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasCompany = (_companyId ?? '').isNotEmpty;
    final issued = _issued;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mã mời đăng ký',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Cấp mã mời để đồng nghiệp đăng ký nhà tuyển dụng cho công ty. '
              'Mỗi mã dùng được một lần và hết hạn sau 7 ngày.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (!hasCompany)
              const _Notice(
                text:
                    'Tài khoản của bạn chưa gắn với công ty nên chưa tạo được mã mời.',
              ),
            if (_error != null) _Notice(text: _error!),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: (!hasCompany || _loading) ? null : _create,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo mã mời'),
            ),
            if (issued != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Mã mời mới',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SelectableText(
                issued.code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hết hạn ngày ${_formatDate(issued.expiresAt)}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _copy(issued.code),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Sao chép mã'),
              ),
              const SizedBox(height: 12),
              const _Notice(
                text:
                    'Mã chỉ hiển thị một lần. Hãy sao chép và gửi cho người cần đăng ký; sau khi rời màn hình bạn không xem lại được mã này.',
                info: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final bool info;

  const _Notice({required this.text, this.info = false});

  @override
  Widget build(BuildContext context) {
    final color = info ? AppColors.primary : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
