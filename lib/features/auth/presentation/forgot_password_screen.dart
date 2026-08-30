import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/error/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.authRepository});
  final IAuthRepository? authRepository;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final IAuthRepository _repo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.authRepository ?? ApiAuthRepository();
  }

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Email không đúng định dạng';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.forgotPassword(email: _email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nếu email tồn tại, liên kết đặt lại đã được gửi'), backgroundColor: AppColors.success));
      context.pop();
    } catch (e) {
      final msg = e is AuthFailure ? authFailureToMessage(e) : e.toString();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _email, validator: _validate, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Gửi liên kết'))),
          ]),
        ),
      ),
    );
  }
}
