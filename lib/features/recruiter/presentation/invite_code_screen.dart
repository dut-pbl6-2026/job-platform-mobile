import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/company_self_serve_strings.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_invite_code_repository.dart';

/// Company creator issues single-use recruiter invite codes bound to one email
/// address (SRS AUTH-01-09, AUTH-01-15). The code is shown once; the server
/// keeps only its hash, and only an account registering with the bound address
/// can redeem it.
class InviteCodeScreen extends StatefulWidget {
  final ApiInviteCodeRepository? repository;

  const InviteCodeScreen({super.key, this.repository});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  late final ApiInviteCodeRepository _repository =
      widget.repository ?? ApiInviteCodeRepository();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  IssuedInviteCode? _issued;
  String? _error;
  bool _loading = false;

  String? get _companyId =>
      AuthSession.instance.currentUser?.companyId ??
      AuthSession.instance.companyId;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return InviteCodeStrings.emailRequired;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return InviteCodeStrings.emailInvalid;
    return null;
  }

  Future<void> _create() async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      // The issued code is shown exactly once and cannot be recovered, so the
      // previous one stays on screen until a new one actually arrives. A failed
      // reissue must not take away a code already sent to a colleague.
    });
    try {
      final issued = await _repository.createInviteCode(
        companyId: companyId,
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _issued = issued);
    } on InviteCodeException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = InviteCodeStrings.failed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(InviteCodeStrings.copied)));
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
          InviteCodeStrings.title,
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
              InviteCodeStrings.description,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (!hasCompany) const _Notice(text: InviteCodeStrings.noCompany),
            if (_error != null) _Notice(text: _error!),
            Form(
              key: _formKey,
              child: TextFormField(
                key: const Key('invite_code_email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: hasCompany && !_loading,
                validator: _validateEmail,
                onFieldSubmitted: (_) => _create(),
                decoration: const InputDecoration(
                  labelText: InviteCodeStrings.emailLabel,
                  hintText: InviteCodeStrings.emailHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('invite_code_submit'),
              onPressed: (!hasCompany || _loading) ? null : _create,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(InviteCodeStrings.submit),
            ),
            if (issued != null) ...[
              const SizedBox(height: 24),
              const Text(
                InviteCodeStrings.issuedTitle,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                issued.email,
                style: const TextStyle(color: AppColors.textPrimary),
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
                '${InviteCodeStrings.expiresPrefix} '
                '${_formatDate(issued.expiresAt)}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _copy(issued.code),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(InviteCodeStrings.copy),
              ),
              const SizedBox(height: 12),
              const _Notice(text: InviteCodeStrings.showOnce, info: true),
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
