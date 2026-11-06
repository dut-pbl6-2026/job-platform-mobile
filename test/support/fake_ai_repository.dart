import 'package:job_platform_mobile/features/ai_copilot/domain/ai_repository.dart';

/// Deterministic fixtures for tests only; production always uses the Gateway.
class FakeAiRepository implements IAiRepository {
  String? failure;
  final List<String> messages = [];
  String? lastSessionId;
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
