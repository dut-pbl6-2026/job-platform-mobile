import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_mapper.dart';
import '../../../core/error/failures.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
import 'widgets/resend_verification_button.dart';

/// Vietnamese copy for the verify-email screen. The web app has the same states
/// in English; this copy is the Vietnamese equivalent.
const String verifyEmailTitle = 'Xác minh email';
const String verifyingMessage = 'Đang xác minh email của bạn…';
const String verifiedMessage =
    'Email của bạn đã được xác minh. Bạn có thể đăng nhập ngay bây giờ.';
const String invalidLinkMessage =
    'Liên kết xác minh không hợp lệ, đã hết hạn hoặc đã được sử dụng.';
const String genericVerifyFailedMessage =
    'Xác thực thất bại. Vui lòng thử lại.';
const String resendPromptMessage =
    'Nhập email của bạn để nhận liên kết xác minh mới.';
const String resendEmailLabel = 'Email';
const String resendEmailInvalidMessage = 'Email không hợp lệ';
const String retryLabel = 'Thử lại';
const String goToLoginLabel = 'Đăng nhập';
const String backToLoginLabel = 'Quay về đăng nhập';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum _VerifyState { verifying, verified, invalid, retryable }

/// Landing screen for the verification link: `/verify-email?token=...`.
/// Redeems the token once, then shows one of four states. Only a 400 from the
/// server means the link is invalid; network and server failures keep the
/// user on a retry screen so they are not told the link expired.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.token, this.authRepository});

  final String? token;
  final IAuthRepository? authRepository;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final IAuthRepository _repo;
  final _emailController = TextEditingController();
  _VerifyState _state = _VerifyState.verifying;
  String? _retryMessage;
  String _resendEmail = '';
  bool _inFlight = false;

  String? get _token {
    final t = widget.token?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.authRepository ?? ApiAuthRepository();
    // A missing token never reaches the server.
    if (_token == null) {
      _state = _VerifyState.invalid;
    } else {
      _verify();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _token;
    if (token == null || _inFlight) return;
    _inFlight = true;
    setState(() {
      _state = _VerifyState.verifying;
      _retryMessage = null;
    });
    try {
      await _repo.verifyEmail(token: token);
      if (!mounted) return;
      setState(() => _state = _VerifyState.verified);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applyFailure(e));
    } finally {
      _inFlight = false;
    }
  }

  /// Must run inside setState. Classifies by HTTP status, not by message text.
  void _applyFailure(Object error) {
    if (error is AuthFailure) {
      if (error.statusCode == 400) {
        _state = _VerifyState.invalid;
        return;
      }
      if (error.statusCode == 429) {
        _state = _VerifyState.retryable;
        _retryMessage = rateLimitedMessage;
        return;
      }
      if (error.code == AuthFailure.networkError) {
        _state = _VerifyState.retryable;
        _retryMessage = authFailureToMessage(error);
        return;
      }
    }
    _state = _VerifyState.retryable;
    _retryMessage = genericVerifyFailedMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(verifyEmailTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (_state) {
                _VerifyState.verifying => _buildVerifying(),
                _VerifyState.verified => _buildVerified(),
                _VerifyState.invalid => _buildInvalid(),
                _VerifyState.retryable => _buildRetryable(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifying() {
    return const Column(
      children: [
        SizedBox(height: 32),
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(verifyingMessage, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildVerified() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 48,
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        const Text(verifiedMessage, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text(goToLoginLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildInvalid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        const Text(invalidLinkMessage, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const Text(resendPromptMessage),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: resendEmailLabel),
          onChanged: (value) => setState(() => _resendEmail = value.trim()),
        ),
        const SizedBox(height: 12),
        if (_resendEmail.isEmpty)
          const SizedBox.shrink()
        else if (!_emailPattern.hasMatch(_resendEmail))
          const Text(
            resendEmailInvalidMessage,
            style: TextStyle(fontSize: 13, color: AppColors.error),
          )
        else
          ResendVerificationButton(email: _resendEmail, authRepository: _repo),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text(backToLoginLabel),
        ),
      ],
    );
  }

  Widget _buildRetryable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          _retryMessage ?? genericVerifyFailedMessage,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _verify,
            child: const Text(retryLabel),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text(backToLoginLabel),
        ),
      ],
    );
  }
}
