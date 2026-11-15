import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_content.dart';
import '../../../core/widgets/design_asset.dart';
import '../data/api_ai_repository.dart';
import '../domain/ai_repository.dart';

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  String text;
  final bool isUser;
  bool isStreaming;
}

class AiCopilotScreen extends StatefulWidget {
  const AiCopilotScreen({super.key, this.repository});
  final IAiRepository? repository;

  @override
  State<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends State<AiCopilotScreen> {
  late final IAiRepository _repository;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  String? _sessionId;
  String? _error;
  String? _failedQuestion;
  bool _waiting = false;
  int _requestId = 0;
  StreamSubscription<AiChatChunk>? _streamSubscription;

  static const _prompts = [
    (
      title: 'Gợi ý việc làm',
      subtitle: 'Theo kỹ năng và mong muốn của bạn',
      glyph: '⌕',
      question: 'Gợi ý việc làm phù hợp với kỹ năng và mong muốn của tôi.',
    ),
    (
      title: 'Cải thiện CV',
      subtitle: 'Chọn mẫu và hoàn thiện nội dung',
      glyph: '▣',
      question: 'Làm sao để cải thiện nội dung CV khi ứng tuyển?',
    ),
    (
      title: 'Luyện phỏng vấn',
      subtitle: 'Câu hỏi phù hợp vị trí ứng tuyển',
      glyph: '✦',
      question:
          'Hãy giúp tôi chuẩn bị phỏng vấn cho vị trí tôi muốn ứng tuyển.',
    ),
  ];

  static const _quickFollowUps = [
    'Gợi ý việc làm khác',
    'Mẹo đàm phán lương',
    'Kỹ năng cần bổ sung',
    'Chuẩn bị phỏng vấn',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiAiRepository();
  }

  @override
  void dispose() {
    _requestId++;
    _streamSubscription?.cancel();
    _repository.cancelCurrentRequest();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(position);
      } else {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String question, {bool retry = false}) async {
    final text = question.trim();
    if (text.isEmpty || _waiting) return;
    final requestId = ++_requestId;
    _controller.clear();

    final botMessage = _ChatMessage(text: '', isUser: false, isStreaming: true);

    setState(() {
      if (!retry) {
        _messages.add(_ChatMessage(text: text, isUser: true));
      } else {
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.removeLast();
        }
      }
      _messages.add(botMessage);
      _waiting = true;
      _error = null;
      _failedQuestion = null;
    });
    _scrollToBottom();

    final completer = Completer<void>();
    try {
      final stream = _repository.streamChat(text, sessionId: _sessionId);
      _streamSubscription = stream.listen(
        (chunk) {
          if (!mounted || requestId != _requestId) return;
          setState(() {
            if (chunk.sessionId != null && chunk.sessionId!.isNotEmpty) {
              _sessionId = chunk.sessionId;
            }
            if (chunk.delta.isNotEmpty) {
              botMessage.text += chunk.delta;
              _scrollToBottom();
            }
            if (chunk.done) {
              botMessage.isStreaming = false;
            }
          });
        },
        onError: (err) {
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
      if (botMessage.text.trim().isEmpty) {
        throw const AiFailure('Phản hồi AI không hợp lệ. Vui lòng thử lại.');
      }
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        botMessage.isStreaming = false;
        if (botMessage.text.trim().isEmpty) {
          _messages.remove(botMessage);
        }
        _error = error is AiFailure
            ? error.message
            : 'Không thể nhận phản hồi AI. Vui lòng thử lại.';
        _failedQuestion = text;
      });
    } finally {
      _streamSubscription?.cancel();
      _streamSubscription = null;
      if (mounted && requestId == _requestId) {
        setState(() {
          botMessage.isStreaming = false;
          _waiting = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _cancel() {
    _repository.cancelCurrentRequest();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _requestId++;
    setState(() {
      _waiting = false;
      _error = 'Đã dừng yêu cầu.';
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.last.isStreaming = false;
        if (_messages.last.text.trim().isEmpty) {
          _messages.removeLast();
        }
      }
      _failedQuestion = null;
      for (var i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
          _failedQuestion = _messages[i].text;
          break;
        }
      }
    });
  }

  Future<void> _startNewSession() async {
    if (_waiting) return;
    final sid = _sessionId;
    setState(() {
      _messages.clear();
      _sessionId = null;
      _error = null;
      _failedQuestion = null;
    });
    if (sid != null) {
      try {
        await _repository.clearSession(sid);
      } catch (_) {
        // Ignore background clear failure
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bắt đầu phiên hội thoại mới.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép phản hồi vào bộ nhớ tạm.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          AppContent(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left, size: 30),
                  ),
                  const _AiSymbol(size: 36),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trợ lý việc làm AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Sẵn sàng hỗ trợ bạn',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn AI',
                    onSelected: (value) {
                      if (value == 'score') {
                        context.push(AppRoutes.resumeScoring);
                      } else {
                        _startNewSession();
                      }
                    },
                    enabled: !_waiting,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'new', child: Text('Hội thoại mới')),
                      PopupMenuItem(
                        value: 'score',
                        child: Text('Chấm CV với việc làm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F7)),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: AppContent(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: _messages.isEmpty ? _welcome() : _conversation(),
                ),
              ),
            ),
          ),
          if (_error != null)
            AppContent(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_failedQuestion != null)
                      TextButton(
                        onPressed: () => _send(_failedQuestion!, retry: true),
                        child: const Text('Thử lại'),
                      ),
                  ],
                ),
              ),
            ),
          if (_messages.isNotEmpty && !_waiting) _quickFollowUpStrip(),
          _composer(),
        ],
      ),
    ),
  );

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        constraints: const BoxConstraints(minHeight: 154),
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F7FF),
          border: Border.all(color: const Color(0xFFE3EDFA)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AiSymbol(size: 34),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chào bạn 👋',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Text(
              'Mình có thể giúp bạn tìm việc phù hợp, cải thiện CV và chuẩn bị phỏng vấn.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Hãy chọn một câu hỏi bên dưới để bắt đầu.',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Bạn muốn bắt đầu với gì?',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 12),
      for (final prompt in _prompts) ...[
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE3EDFA)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _send(prompt.question),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: DesignAsset('ai-prompt'),
                      ),
                      if (prompt.glyph == '⌕')
                        const Icon(
                          Icons.search,
                          size: 17,
                          color: AppColors.primary,
                        )
                      else
                        Text(
                          prompt.glyph,
                          style: const TextStyle(
                            fontFamily: 'NotoSymbols',
                            fontSize: 17,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          prompt.subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 23,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _conversation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_messages.length >= 20) _contextWindowNotice(),
      for (final message in _messages)
        Align(
          alignment: message.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: message.isUser ? 560 : 640),
            margin: EdgeInsets.only(bottom: 16, left: message.isUser ? 52 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: message.isUser
                  ? AppColors.primary
                  : const Color(0xFFF2F7FF),
              borderRadius: BorderRadius.circular(16),
              border: message.isUser
                  ? null
                  : Border.all(color: const Color(0xFFE3EDFA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser) ...[
                  Row(
                    children: [
                      const _AiSymbol(size: 30),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          'Trợ lý việc làm AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!message.isStreaming && message.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Sao chép',
                          icon: const Icon(
                            Icons.copy_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _copyToClipboard(message.text),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _renderMessageText(message),
                if (!message.isUser) ...[
                  if (!message.isStreaming)
                    _renderJobRecommendations(message.text),
                  const SizedBox(height: 8),
                  const Text(
                    'Nội dung AI chỉ mang tính tham khảo.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      if (_waiting)
        Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('AI đang trả lời...', style: TextStyle(fontSize: 12)),
            ),
            TextButton(onPressed: _cancel, child: const Text('Dừng')),
          ],
        ),
    ],
  );

  Widget _renderMessageText(_ChatMessage message) {
    final text = message.text;
    final isStreaming = message.isStreaming;

    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          if (isStreaming)
            const TextSpan(
              text: ' ▊',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      style: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: message.isUser ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _renderJobRecommendations(String text) {
    final hasJobRecommendation =
        text.contains('/jobs/') ||
        text.contains('việc làm') ||
        text.contains('công việc') ||
        text.contains('ứng tuyển');

    if (!hasJobRecommendation || text.length < 25) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          ActionChip(
            avatar: const Icon(
              Icons.search,
              size: 14,
              color: AppColors.primary,
            ),
            label: const Text(
              'Tìm việc liên quan',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFCBDDF7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => context.push(AppRoutes.search),
          ),
          ActionChip(
            avatar: const Icon(
              Icons.document_scanner_outlined,
              size: 14,
              color: AppColors.primary,
            ),
            label: const Text(
              'Chấm điểm CV',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFCBDDF7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () => context.push(AppRoutes.resumeScoring),
          ),
        ],
      ),
    );
  }

  Widget _contextWindowNotice() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFE082)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 18, color: Color(0xFFF57F17)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Hội thoại đã dài (đạt 20 tin nhắn). Hãy bắt đầu phiên mới để có phản hồi nhận biết ngữ cảnh chính xác nhất.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: _waiting ? null : _startNewSession,
          child: const Text(
            'Bắt đầu lại',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  Widget _quickFollowUpStrip() => Container(
    height: 38,
    margin: const EdgeInsets.only(bottom: 6),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _quickFollowUps.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final prompt = _quickFollowUps[index];
        return ActionChip(
          label: Text(
            prompt,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
          ),
          backgroundColor: const Color(0xFFF2F7FF),
          side: const BorderSide(color: Color(0xFFE3EDFA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () => _send(prompt),
        );
      },
    ),
  );

  Widget _composer() => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE8F0F7))),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: AppContent(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 13, right: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FF),
              border: Border.all(color: const Color(0xFFE3EDFA)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('ai_question'),
                    controller: _controller,
                    enabled: !_waiting,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi cho AI...',
                      hintStyle: TextStyle(fontSize: 11),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('ai_send'),
                  tooltip: 'Gửi câu hỏi',
                  onPressed: _waiting ? null : () => _send(_controller.text),
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 35,
                        height: 35,
                        child: DesignAsset('ai-send'),
                      ),
                      Icon(
                        Icons.send,
                        size: 16,
                        color: _waiting ? Colors.white54 : Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AiSymbol extends StatelessWidget {
  const _AiSymbol({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: size,
        height: size,
        child: const DesignAsset('ai-avatar'),
      ),
      Text(
        '✦',
        style: TextStyle(
          fontFamily: 'NotoSymbols',
          fontSize: size * .52,
          color: Colors.white,
        ),
      ),
    ],
  );
}
