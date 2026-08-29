import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'domain/models/user_model.dart';
import 'domain/repositories/auth_repository.dart';

/// Register Screen - Create new candidate or recruiter account
/// Features:
/// - Full name input with validation
/// - Email input with format validation
/// - Password and Confirm Password with visibility toggle
/// - Role selection (User / Recruiter) using Material 3 SegmentedButton
/// - Client-side validation
/// - MockAuthRepository integration (with simulated 2s delay)
/// - Navigation to Home on success
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.authRepository,
  });

  final IAuthRepository? authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final IAuthRepository _authRepository;
  UserRole _selectedRole = UserRole.user;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = AppColors.textHint;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? MockAuthRepository();
    _passwordController.addListener(_onPasswordChanged);
  }

  /// Recalculate password strength on every keystroke.
  void _onPasswordChanged() {
    final password = _passwordController.text;
    final result = _calculatePasswordStrength(password);
    setState(() {
      _passwordStrength = result.strength;
      _passwordStrengthLabel = result.label;
      _passwordStrengthColor = result.color;
    });
  }

  /// Evaluate password strength based on 5 criteria:
  /// length ≥ 8, has uppercase, has lowercase, has digit, has special char.
  /// Returns a normalized score (0.0–1.0) with label and color.
  ({double strength, String label, Color color}) _calculatePasswordStrength(
    String password,
  ) {
    if (password.isEmpty) {
      return (strength: 0.0, label: '', color: AppColors.textHint);
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    return switch (score) {
      1 => (strength: 0.2, label: 'Rất yếu', color: AppColors.error),
      2 => (strength: 0.4, label: 'Yếu', color: AppColors.error),
      3 => (strength: 0.6, label: 'Trung bình', color: AppColors.warning),
      4 => (strength: 0.8, label: 'Mạnh', color: AppColors.primary),
      5 => (strength: 1.0, label: 'Rất mạnh', color: AppColors.success),
      _ => (strength: 0.0, label: '', color: AppColors.textHint),
    };
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate full name
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
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

  /// Validate password confirmation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận lại mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Handle register submit
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authRepository.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đăng ký tài khoản ${result.user.role.displayName} thành công!',
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $e'),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Title section
              Text(
                'Tạo tài khoản mới',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tham gia nền tảng tuyển dụng và tìm việc hàng đầu',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              // Role selector section
              _buildRoleSelector(),

              const SizedBox(height: 24),

              // Register form
              _buildRegisterForm(),

              const SizedBox(height: 28),

              // Register submit button
              _buildSubmitButton(),

              const SizedBox(height: 24),

              // Login navigation link
              _buildLoginLink(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn là ai?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<UserRole>(
          segments: const [
            ButtonSegment<UserRole>(
              value: UserRole.user,
              label: Text('Ứng viên'),
              icon: Icon(Icons.person_search_outlined),
            ),
            ButtonSegment<UserRole>(
              value: UserRole.recruiter,
              label: Text('Nhà tuyển dụng'),
              icon: Icon(Icons.business_outlined),
            ),
          ],
          selected: {_selectedRole},
          onSelectionChanged: (newSelection) {
            setState(() {
              _selectedRole = newSelection.first;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return AppColors.surfaceVariant;
              },
            ),
            foregroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.textPrimary;
              },
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name field
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            validator: _validateName,
            decoration: const InputDecoration(
              labelText: 'Họ và tên',
              hintText: 'Nguyễn Văn A',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),

          const SizedBox(height: 16),

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
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Tối thiểu 8 ký tự',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
          ),

          // Password strength indicator
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPasswordStrengthIndicator(),
          ],

          const SizedBox(height: 16),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _handleRegister(),
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Password strength indicator with animated bar and per-criteria checklist.
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;

    // Individual criteria checks for the checklist
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar =
        RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _passwordStrength),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                    );
                  },
                ),
              ),
            ),
            if (_passwordStrengthLabel.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                _passwordStrengthLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _passwordStrengthColor,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Per-criteria checklist
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _buildCriteriaChip('≥ 8 ký tự', hasMinLength),
            _buildCriteriaChip('Chữ hoa (A-Z)', hasUppercase),
            _buildCriteriaChip('Chữ số (0-9)', hasDigit),
            _buildCriteriaChip('Ký tự đặc biệt', hasSpecialChar),
          ],
        ),
      ],
    );
  }

  /// Single criteria chip with check/cross icon.
  Widget _buildCriteriaChip(String label, bool passed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: passed ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: passed ? AppColors.success : AppColors.textHint,
            fontWeight: passed ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _selectedRole == UserRole.recruiter
                    ? 'Đăng ký Nhà tuyển dụng'
                    : 'Đăng ký Ứng viên',
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Đã có tài khoản? ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.login);
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
