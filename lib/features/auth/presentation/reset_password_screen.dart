import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_validator.dart';
import '../data/repositories/api_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.authRepository, this.token});
  final IAuthRepository? authRepository;
  final String? token;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();
  late final IAuthRepository _repo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.authRepository ?? ApiAuthRepository();
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      _tokenController.text = widget.token!.trim();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _pwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validatePwd(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (!isPasswordStrong(v)) {
      return 'Mật khẩu tối thiểu 8 ký tự, gồm 1 chữ hoa và 1 chữ số';
    }
    return null;
  }

  String? get _routeOrPropToken {
    if (widget.token != null && widget.token!.trim().isNotEmpty) {
      return widget.token!.trim();
    }
    final state = GoRouter.maybeOf(context) != null
        ? GoRouterState.of(context)
        : null;
    final queryToken = state?.uri.queryParameters['token']?.trim();
    return (queryToken != null && queryToken.isNotEmpty) ? queryToken : null;
  }

  String? get _effectiveToken =>
      _routeOrPropToken ??
      (_tokenController.text.trim().isNotEmpty
          ? _tokenController.text.trim()
          : null);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final t = _effectiveToken;
    if (t == null || t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token không hợp lệ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.resetPassword(token: t, newPassword: _pwd.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công, vui lòng đăng nhập'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.login);
    } catch (e) {
      final msg = failureMessage(
        e,
        fallback: 'Không đặt lại được mật khẩu. Vui lòng thử lại.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPresetToken = _routeOrPropToken != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!hasPresetToken) ...[
                TextFormField(
                  controller: _tokenController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập mã khôi phục từ email'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Mã khôi phục mật khẩu',
                    hintText: 'Dán mã token nhận được trong email',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _pwd,
                obscureText: true,
                validator: _validatePwd,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                validator: (v) =>
                    v != _pwd.text ? 'Mật khẩu xác nhận không khớp' : null,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đặt lại'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Quay về đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
