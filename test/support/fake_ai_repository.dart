import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';

/// Deterministic fixtures for tests only; production always uses the Gateway.
class FakeAiRepository implements IAiRepository {
  String? failure;
  final List<String> messages = [];
  String? lastSessionId;
  String? lastClearedSessionId;
  int scoreCalls = 0;
  bool cancelled = false;

  @override
  Future<AiChatReply> sendMessage(String message, {String? sessionId}) async {
    messages.add(message);
    lastSessionId = sessionId;
    if (failure != null) throw AiFailure(failure!);
    return const AiChatReply(
      response: 'Phản hồi kiểm thử từ Gateway.',
      sessionId: 'session-123',
    );
  }

  @override
  Stream<AiChatChunk> streamChat(String message, {String? sessionId}) async* {
    final reply = await sendMessage(message, sessionId: sessionId);
    if (cancelled) return;
    final words = reply.response.split(' ');
    for (var i = 0; i < words.length; i++) {
      if (cancelled) return;
      final delta = i == 0 ? words[i] : ' ${words[i]}';
      yield AiChatChunk(delta: delta, sessionId: reply.sessionId);
    }
    yield AiChatChunk(delta: '', sessionId: reply.sessionId, done: true);
  }

  @override
  Future<void> clearSession(String sessionId) async {
    lastClearedSessionId = sessionId;
  }

  @override
  Future<ResumeFeedback> scoreResume(
    AiCvInput cv, {
    required String jobId,
  }) async {
    scoreCalls++;
    if (failure != null) throw AiFailure(failure!);
    return const ResumeFeedback(
      score: 82,
      matchingSkills: ['Figma'],
      missingSkills: ['User Research'],
      suggestions: ['Bổ sung kết quả dự án.'],
    );
  }

  @override
  void cancelCurrentRequest() => cancelled = true;
}
