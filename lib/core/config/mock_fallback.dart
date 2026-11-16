/// Compile-time switch for the development mock fallbacks.
///
/// Off unless the build explicitly passes `--dart-define=ENABLE_MOCKS=true`.
/// A release build never fabricates data: a fabricated job catalogue or a
/// "saved" profile edit that never reached the server is worse than an error.
/// The flag exists only for local runs without a gateway.
const bool kEnableMocks = bool.fromEnvironment('ENABLE_MOCKS');

/// Whether a repository may answer with mock data after a failed call.
///
/// Only when [enabled] (the flag above, or an explicit test injection) and the
/// failure is a transport failure ([statusCode] is null) or a 5xx. A 4xx is
/// always a real answer from the server - in particular 401/403 - and must
/// reach the caller instead of being hidden behind invented data.
bool shouldUseMockFallback({required bool enabled, int? statusCode}) {
  if (!enabled) return false;
  if (statusCode == null) return true;
  return statusCode >= 500 && statusCode <= 599;
}
