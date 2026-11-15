import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/company_self_serve_strings.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/error/failures.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
import 'widgets/auth_layout.dart';

/// Company self-serve sign-up (SRS AUTH-01-10, AUTH-01-11).
///
/// The server answers `202` with one fixed message for a new sign-up, an
/// existing email, a taken company name or tax code, and a work domain that
/// already belongs to a company. The screen therefore shows one response for
/// all of them and never tells the user which case applied. Only a free public
/// email domain (`422 WORK_EMAIL_REQUIRED`) and a failed lookup (`503`) are
/// shown as errors; the `503` is retryable.
class CompanySignUpScreen extends StatefulWidget {
  const CompanySignUpScreen({super.key, this.authRepository});

  final IAuthRepository? authRepository;

  @override
  State<CompanySignUpScreen> createState() => _CompanySignUpScreenState();
}

class _CompanySignUpScreenState extends State<CompanySignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final IAuthRepository _authRepository =
      widget.authRepository ?? ApiAuthRepository();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  /// Server-side error for the email field (`422 WORK_EMAIL_REQUIRED`).
  String? _emailServerError;

  /// Retryable failure (`503`). The form stays filled and can be submitted again.
  String? _retryableError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearEmailServerError);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailServerError);
    _companyNameController.dispose();
    _taxCodeController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearEmailServerError() {
    if (_emailServerError == null) return;
    setState(() => _emailServerError = null);
  }

  String? _validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CompanySignUpStrings.companyNameRequired;
    }
    return null;
  }

  String? _validateTaxCode(String? value) {
    if (value != null && value.trim().length > 32) {
      return CompanySignUpStrings.taxCodeTooLong;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CompanySignUpStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return CompanySignUpStrings.emailInvalid;
    }
    return _emailServerError;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CompanySignUpStrings.fullNameRequired;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return CompanySignUpStrings.passwordRequired;
    }
    // Same rule as registration (SRS AUTH-01-01).
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return CompanySignUpStrings.passwordTooWeak;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return CompanySignUpStrings.confirmRequired;
    }
    if (value != _passwordController.text) {
      return CompanySignUpStrings.confirmMismatch;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _retryableError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authRepository.registerCompany(
        companyName: _companyNameController.text.trim(),
        taxCode: _taxCodeController.text.trim().isEmpty
            ? null
            : _taxCodeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showAcceptedDialog();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (error is AuthFailure) {
          if (error.code == AuthFailure.workEmailRequired) {
            _emailServerError = authFailureToMessage(error);
          } else if (error.code == AuthFailure.serviceUnavailable) {
            _retryableError = CompanySignUpStrings.serviceUnavailable;
          } else {
            _retryableError = authFailureToMessage(error);
          }
        } else {
          _retryableError = CompanySignUpStrings.serviceUnavailable;
        }
      });
      // Re-run validation so the server-side email error appears inline.
      _formKey.currentState?.validate();
    }
  }

  /// One response for every outcome: a new sign-up, an existing email, a taken
  /// company name or tax code, or a domain match.
  Future<void> _showAcceptedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(CompanySignUpStrings.title),
        content: const Text(CompanySignUpStrings.accepted),
        actions: [
          TextButton(
            key: const Key('company_signup_accepted_continue'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(CompanySignUpStrings.backToLogin),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.go(AppRoutes.login, extra: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(alignment: Alignment.centerLeft, child: AuthBrand()),
            const SizedBox(height: 23),
            const Text(
              CompanySignUpStrings.title,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141A24),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              CompanySignUpStrings.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666B7A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            AuthField(
              label: CompanySignUpStrings.companyNameLabel,
              child: TextFormField(
                key: const Key('company_signup_company_name'),
                controller: _companyNameController,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                validator: _validateCompanyName,
                decoration: const InputDecoration(
                  hintText: CompanySignUpStrings.companyNameHint,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AuthField(
              label: CompanySignUpStrings.taxCodeLabel,
              child: TextFormField(
                key: const Key('company_signup_tax_code'),
                controller: _taxCodeController,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                validator: _validateTaxCode,
                decoration: const InputDecoration(
                  hintText: CompanySignUpStrings.taxCodeHint,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AuthField(
              label: CompanySignUpStrings.emailLabel,
              child: TextFormField(
                key: const Key('company_signup_email'),
                controller: _emailController,
                autofillHints: const [AutofillHints.email],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  hintText: CompanySignUpStrings.emailHint,
                  helperText: CompanySignUpStrings.emailHelper,
                  helperMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AuthField(
              label: CompanySignUpStrings.fullNameLabel,
              child: TextFormField(
                key: const Key('company_signup_full_name'),
                controller: _fullNameController,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                validator: _validateFullName,
                decoration: const InputDecoration(
                  hintText: CompanySignUpStrings.fullNameHint,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AuthField(
              label: CompanySignUpStrings.passwordLabel,
              child: TextFormField(
                key: const Key('company_signup_password'),
                controller: _passwordController,
                autofillHints: const [AutofillHints.newPassword],
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                validator: _validatePassword,
                decoration: InputDecoration(
                  hintText: CompanySignUpStrings.passwordHint,
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
            const SizedBox(height: 10),
            AuthField(
              label: CompanySignUpStrings.confirmPasswordLabel,
              child: TextFormField(
                key: const Key('company_signup_confirm_password'),
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: CompanySignUpStrings.confirmPasswordHint,
                  suffixIcon: IconButton(
                    tooltip: _isConfirmPasswordVisible
                        ? 'Ẩn mật khẩu'
                        : 'Hiện mật khẩu',
                    onPressed: () => setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
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
            if (_retryableError != null) ...[
              const SizedBox(height: 14),
              _ErrorNotice(
                message: _retryableError!,
                onRetry: _isLoading ? null : _submit,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('company_signup_submit'),
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(CompanySignUpStrings.submit),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(AppRoutes.login),
                child: const Text(CompanySignUpStrings.backToLogin),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Retryable error banner (`503`, network). The form keeps its values.
class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('company_signup_retry'),
          onPressed: onRetry,
          child: const Text(CompanySignUpStrings.retry),
        ),
      ],
    ),
  );
}
