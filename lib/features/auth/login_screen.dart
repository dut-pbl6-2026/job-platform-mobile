import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'data/repositories/api_auth_repository.dart';
import 'domain/repositories/auth_repository.dart';

/// Login Screen - Email/password form per SRS AUTH-01-02
/// Features:
/// - Email input with format validation
/// - Password input with visibility toggle
/// - "Quên mật khẩu?" link
/// - Login button with 2s mock latency
/// - Navigation to Register and Home
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authRepository,
  });

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
    if (!_formKey.currentState!.validate()) return;

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
        final msg = e is AuthFailure ? authFailureToMessage(e) : e.toString().replaceAll('Exception: ', '');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Header section
              _buildHeader(context),

              const SizedBox(height: 40),

              // Login form
              _buildLoginForm(context),

              const SizedBox(height: 16),

              // Remember me & Forgot password row
              _buildOptionsRow(context),

              const SizedBox(height: 24),

              // Login button
              _buildLoginButton(),

              const SizedBox(height: 32),

              // Divider
              _buildDivider(context),

              const SizedBox(height: 32),

              // Register link
              _buildRegisterLink(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Chào mừng trở lại!',
          style: Theme.of(context).textTheme.headlineLarge,
        ),

        const SizedBox(height: 8),

        Text(
          'Đăng nhập để tiếp tục tìm kiếm việc làm',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me checkbox
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Ghi nhớ đăng nhập',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
            ),
          ],
        ),

        // Forgot password link
        TextButton(
          onPressed: () {
            context.push(AppRoutes.forgotPassword);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Quên mật khẩu?',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Đăng nhập'),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Chưa có tài khoản? ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () {
              context.push(AppRoutes.register);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Đăng ký ngay',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
