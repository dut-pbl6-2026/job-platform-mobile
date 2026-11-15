import 'package:flutter/material.dart';

import '../../../core/constants/company_self_serve_strings.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/repositories/api_company_join_request_repository.dart';
import '../domain/models/join_request.dart';
import '../domain/repositories/company_join_request_repository.dart';
import 'widgets/join_request_status_chip.dart';

/// Company admin view of join requests (SRS AUTH-01-12, AUTH-01-13).
///
/// Only the company creator is the admin in this version; job-svc enforces it
/// and answers `403` for anyone else, so the screen shows that message instead
/// of hiding the entry point from other recruiters. Approving links the
/// requester to the company; rejecting is final for that account.
class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key, this.repository, this.companyId});

  final ICompanyJoinRequestRepository? repository;

  /// Overrides the company id from the session (used by tests).
  final String? companyId;

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  late final ICompanyJoinRequestRepository _repository =
      widget.repository ?? ApiCompanyJoinRequestRepository();

  List<CompanyJoinRequest> _requests = const [];
  bool _loading = true;
  String? _error;
  String? _busyRequestId;

  String? get _companyId =>
      widget.companyId ??
      AuthSession.instance.currentUser?.companyId ??
      AuthSession.instance.companyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await _repository.listForCompany(companyId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } on JoinRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _approve(CompanyJoinRequest request) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return;
    setState(() => _busyRequestId = request.id);
    try {
      await _repository.approve(companyId: companyId, requestId: request.id);
      if (!mounted) return;
      _showSnack(JoinRequestStrings.approved, AppColors.success);
      await _load();
    } on JoinRequestException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, AppColors.error);
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  Future<void> _reject(CompanyJoinRequest request) async {
    final companyId = _companyId;
    if (companyId == null || companyId.isEmpty) return;
    final reason = await _askRejectReason();
    // A null result means the dialog was dismissed: no request is sent.
    if (reason == null || !mounted) return;
    setState(() => _busyRequestId = request.id);
    try {
      await _repository.reject(
        companyId: companyId,
        requestId: request.id,
        reason: reason,
      );
      if (!mounted) return;
      _showSnack(JoinRequestStrings.rejected, AppColors.success);
      await _load();
    } on JoinRequestException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, AppColors.error);
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  Future<String?> _askRejectReason() => showDialog<String>(
    context: context,
    builder: (dialogContext) => const _RejectReasonDialog(),
  );

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCompany = (_companyId ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          JoinRequestStrings.adminTitle,
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
              const Text(
                JoinRequestStrings.adminDescription,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              if (!hasCompany)
                const _Notice(text: JoinRequestStrings.noCompany)
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _Notice(
                  text: _error!,
                  action: OutlinedButton(
                    key: const Key('join_requests_retry'),
                    onPressed: _load,
                    child: const Text(JoinRequestStrings.retry),
                  ),
                )
              else if (_requests.isEmpty)
                const _Notice(text: JoinRequestStrings.adminEmpty, info: true)
              else
                for (final request in _requests)
                  _JoinRequestCard(
                    request: request,
                    busy: _busyRequestId == request.id,
                    onApprove: () => _approve(request),
                    onReject: () => _reject(request),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final CompanyJoinRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// The list endpoint carries only the requester's user id, so the card shows
  /// a short reference instead of inventing a name or email.
  String get _requesterRef {
    final id = request.userId.replaceAll('-', '');
    if (id.isEmpty) return '—';
    return '${JoinRequestStrings.requesterRefPrefix} '
        '#${id.substring(0, id.length < 8 ? id.length : 8)}';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _requesterRef,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            JoinRequestStatusChip(status: request.status),
          ],
        ),
        const SizedBox(height: 8),
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
        if (request.decisionReason != null &&
            request.decisionReason!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${JoinRequestStrings.reasonLabel}: ${request.decisionReason}',
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
        if (request.status.isPending) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: Key('join_request_approve_${request.id}'),
                  onPressed: busy ? null : onApprove,
                  child: busy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(JoinRequestStrings.approve),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  key: Key('join_request_reject_${request.id}'),
                  onPressed: busy ? null : onReject,
                  child: const Text(JoinRequestStrings.reject),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(JoinRequestStrings.reject),
    content: TextField(
      key: const Key('join_request_reject_reason'),
      controller: _controller,
      maxLines: 3,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: JoinRequestStrings.rejectReasonLabel,
        hintText: JoinRequestStrings.rejectReasonHint,
        border: OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(JoinRequestStrings.cancel),
      ),
      FilledButton(
        key: const Key('join_request_reject_confirm'),
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: const Text(JoinRequestStrings.rejectConfirm),
      ),
    ],
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
