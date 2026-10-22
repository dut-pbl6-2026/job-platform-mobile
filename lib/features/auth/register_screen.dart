import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import 'data/repositories/api_auth_repository.dart';
import 'domain/models/user_model.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/widgets/auth_layout.dart';

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
  const RegisterScreen({super.key, this.authRepository});

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
  final _companyIdController = TextEditingController();

  late final IAuthRepository _authRepository;
  UserRole _selectedRole = UserRole.user;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _showForm = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = AppColors.textHint;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? ApiAuthRepository();
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
    _companyIdController.dispose();
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

  /// Validate companyId for recruiter
  String? _validateCompanyId(String? value) {
    if (_selectedRole == UserRole.recruiter &&
        (value == null || value.trim().isEmpty)) {
      return 'Vui lòng nhập mã công ty';
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
        companyId: _companyIdController.text.trim().isEmpty
            ? null
            : _companyIdController.text.trim(),
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
        final msg = e is AuthFailure
            ? authFailureToMessage(e)
            : e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $msg'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AuthBrand(),
            if (_showForm)
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _showForm = false),
                child: const Text('Đổi vai trò'),
              ),
          ],
        ),
        const SizedBox(height: 23),
        Text(
          !_showForm
              ? 'Tạo tài khoản'
              : _selectedRole == UserRole.user
              ? 'Đăng ký ứng viên'
              : 'Đăng ký nhà tuyển dụng',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Color(0xFF141A24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          !_showForm
              ? 'Bắt đầu bằng cách cho chúng tôi biết bạn là\nai.'
              : _selectedRole == UserRole.user
              ? 'Tạo hồ sơ để tìm công việc phù hợp.'
              : 'Tạo tài khoản để đăng tin và tìm ứng viên.',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666B7A),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (!_showForm)
          _buildRoleSelector()
        else ...[
          _buildRegisterForm(),
          const SizedBox(height: 14),
          _buildSubmitButton(),
        ],
        const SizedBox(height: 40),
        _buildLoginLink(),
      ],
    ),
  );

  Widget _buildRoleSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Bạn là ai?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 20),
      for (final role in [UserRole.user, UserRole.recruiter]) ...[
        Material(
          color: role == _selectedRole ? const Color(0xFFF2FAFF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: role == _selectedRole
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: InkWell(
            key: Key('register_role_${role.name}'),
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() {
              _selectedRole = role;
              _showForm = true;
            }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: role == _selectedRole
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            role == UserRole.user
                                ? 'Tìm kiếm và ứng tuyển việc làm phù hợp.'
                                : 'Đăng tin và tìm kiếm ứng viên.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ],
  );

  Widget _buildRegisterForm() => AutofillGroup(
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          AuthField(
            label: 'Họ và tên',
            child: TextFormField(
              controller: _nameController,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: _validateName,
              decoration: const InputDecoration(hintText: 'Nhập họ và tên'),
            ),
          ),
          const SizedBox(height: 10),
          AuthField(
            label: 'Email',
            child: TextFormField(
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: _validateEmail,
              decoration: const InputDecoration(hintText: 'Nhập email của bạn'),
            ),
          ),
          const SizedBox(height: 10),
          AuthField(
            label: 'Mật khẩu',
            child: TextFormField(
              controller: _passwordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: _validatePassword,
              decoration: InputDecoration(
                hintText: 'Tạo mật khẩu',
                suffixIcon: IconButton(
                  tooltip: _isPasswordVisible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
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
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPasswordStrengthIndicator(),
          ],
          const SizedBox(height: 10),
          AuthField(
            label: 'Xác nhận mật khẩu',
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              validator: _validateConfirmPassword,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                hintText: 'Nhập lại mật khẩu',
                suffixIcon: IconButton(
                  tooltip: _isConfirmPasswordVisible
                      ? 'Ẩn mật khẩu'
                      : 'Hiện mật khẩu',
                  onPressed: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          if (_selectedRole == UserRole.recruiter) ...[
            const SizedBox(height: 10),
            AuthField(
              label: 'Mã công ty',
              child: TextFormField(
                controller: _companyIdController,
                enabled: !_isLoading,
                validator: _validateCompanyId,
                decoration: const InputDecoration(hintText: 'Nhập mã công ty'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;

    // Individual criteria checks for the checklist
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar = RegExp(
      r'[!@#\$%^&*(),.?":{}|<>]',
    ).hasMatch(password);

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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _passwordStrengthColor,
                      ),
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
        style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
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
