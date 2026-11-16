import 'package:flutter/material.dart';

import '../../../core/constants/company_self_serve_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_company_join_request_repository.dart';
import '../domain/models/join_request.dart';
import '../domain/repositories/company_join_request_repository.dart';
import 'widgets/join_request_status_chip.dart';

/// Requester view of their own company join request (SRS AUTH-01-13, AUTH-01-14).
///
/// The status comes from `GET /api/companies/me/join-request`; the server also
/// decides [MyJoinRequest.canEscalate] so the button never appears before the
/// waiting period has run out. Escalation is allowed once and only when the
/// request is expired; `409` is shown as the server's answer, not hidden.
class JoinRequestStatusScreen extends StatefulWidget {
  const JoinRequestStatusScreen({super.key, this.repository});

  final ICompanyJoinRequestRepository? repository;

  @override
  State<JoinRequestStatusScreen> createState() =>
      _JoinRequestStatusScreenState();
}

class _JoinRequestStatusScreenState extends State<JoinRequestStatusScreen> {
  late final ICompanyJoinRequestRepository _repository =
      widget.repository ?? ApiCompanyJoinRequestRepository();

  MyJoinRequest? _request;
  bool _loading = true;
  bool _escalating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final request = await _repository.getMine();
      if (!mounted) return;
      setState(() {
        _request = request;
        _loading = false;
      });
    } on JoinRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      // A payload change or any other throw must not leave the spinner up
      // forever: the screen shows the same retry as a mapped failure.
      if (!mounted) return;
      setState(() {
        _error = JoinRequestStrings.mineFailed;
        _loading = false;
      });
    }
  }

  Future<void> _escalate() async {
    if (_escalating) return;
    setState(() => _escalating = true);
    try {
      await _repository.escalate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(JoinRequestStrings.escalated),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } on JoinRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // The status may have changed on the server (for example it was decided
      // by support); reload so the screen matches the backend.
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(JoinRequestStrings.escalateFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _escalating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          JoinRequestStrings.myTitle,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: JoinRequestStrings.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _Notice(
                  text: _error!,
                  action: OutlinedButton(
                    key: const Key('join_request_status_retry'),
                    onPressed: _load,
                    child: const Text(JoinRequestStrings.retry),
                  ),
                )
              else if (request == null)
                const _Notice(text: JoinRequestStrings.myEmpty, info: true)
              else
                _StatusCard(
                  request: request,
                  escalating: _escalating,
                  onEscalate: _escalate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.request,
    required this.escalating,
    required this.onEscalate,
  });

  final MyJoinRequest request;
  final bool escalating;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                JoinRequestStrings.statusLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            JoinRequestStatusChip(status: request.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${JoinRequestStrings.createdLabel}: '
          '${formatJoinRequestDate(request.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          '${JoinRequestStrings.expiresLabel}: '
          '${formatJoinRequestDate(request.expiresAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (request.canEscalate) ...[
          const SizedBox(height: 16),
          const Text(
            JoinRequestStrings.escalateHint,
            style: TextStyle(color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('join_request_escalate'),
              onPressed: escalating ? null : onEscalate,
              child: escalating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(JoinRequestStrings.escalate),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.info = false, this.action});

  final String text;
  final bool info;
  final Widget? action;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(color: color)),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}
