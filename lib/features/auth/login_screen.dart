import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'data/repositories/api_auth_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/widgets/auth_layout.dart';

/// Login Screen - Email/password form per SRS AUTH-01-02
/// Features:
/// - Email input with format validation
/// - Password input with visibility toggle
/// - "Quên mật khẩu?" link
/// - Login button with 2s mock latency
/// - Navigation to Register and Home
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authRepository});

  final IAuthRepository? authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final IAuthRepository _authRepository;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? ApiAuthRepository();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate email format — accepts long TLDs and + tags.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Validate password per SRS AUTH-01-01:
  /// Minimum 8 characters, at least 1 uppercase letter and 1 digit.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Mật khẩu tối thiểu 8 ký tự, gồm ít nhất 1 chữ hoa và 1 chữ số';
    }
    return null;
  }

  /// Handle login submission
  Future<void> _handleLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thành công! Chào ${result.user.name}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navigate to Home screen
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e is AuthFailure
            ? authFailureToMessage(e)
            : e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: $msg'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBrand(),
        const SizedBox(height: 28),
        const Center(
          child: Text(
            'Chào mừng trở lại!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF09090D),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Đăng nhập để tiếp tục tìm kiếm công việc phù hợp với bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B707A),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AuthField(
                  label: 'Email',
                  child: TextFormField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.username],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Nhập email của bạn',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AuthField(
                  label: 'Mật khẩu',
                  child: TextFormField(
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.password],
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        tooltip: _isPasswordVisible
                            ? 'Ẩn mật khẩu'
                            : 'Hiện mật khẩu',
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _rememberMe = value ?? false),
                ),
                const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 12)),
              ],
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.forgotPassword),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Đăng nhập'),
        ),
        const SizedBox(height: 48),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Chưa có tài khoản?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text('Đăng ký'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 66),
        const Center(
          child: Text(
            'Job Search App',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
