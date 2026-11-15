import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/auth_repository.dart';

const int _cooldownSeconds = 60;

/// The server answers 202 for every address, so the message says "if", never "sent".
const String _sentMessage =
    'Nếu email này đang chờ xác minh, một liên kết mới đã được gửi.';
const String _sendFailedMessage =
    'Chưa gửi được email xác minh. Vui lòng thử lại.';

/// Asks auth-svc for a new verification link. After a successful send the button
/// stays disabled for 60 seconds.
class ResendVerificationButton extends StatefulWidget {
  const ResendVerificationButton({
    super.key,
    required this.email,
    required this.authRepository,
  });

  final String email;
  final IAuthRepository authRepository;

  @override
  State<ResendVerificationButton> createState() =>
      _ResendVerificationButtonState();
}

class _ResendVerificationButtonState extends State<ResendVerificationButton> {
  bool _sending = false;
  int _cooldown = 0;
  Timer? _timer;
  String? _notice;
  bool _noticeIsError = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  String _messageFor(Object error) {
    if (error is AuthFailure) {
      if (error.code == AuthFailure.rateLimited) return rateLimitedMessage;
      if (error.code == AuthFailure.networkError) {
        return authFailureToMessage(error);
      }
    }
    return _sendFailedMessage;
  }

  Future<void> _send() async {
    if (_sending || _cooldown > 0) return;
    setState(() {
      _sending = true;
      _notice = null;
    });
    try {
      await widget.authRepository.resendVerification(email: widget.email);
      if (!mounted) return;
      setState(() {
        _notice = _sentMessage;
        _noticeIsError = false;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notice = _messageFor(e);
        _noticeIsError = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_sending && _cooldown <= 0;
    final label = _sending
        ? 'Đang gửi…'
        : _cooldown > 0
        ? 'Gửi lại sau $_cooldown giây'
        : 'Gửi lại email xác minh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(onPressed: canSend ? _send : null, child: Text(label)),
        if (_notice != null) ...[
          const SizedBox(height: 8),
          Text(
            _notice!,
            style: TextStyle(
              fontSize: 13,
              color: _noticeIsError ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ],
    );
  }
}
