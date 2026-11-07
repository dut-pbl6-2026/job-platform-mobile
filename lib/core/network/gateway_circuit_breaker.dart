import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Circuit Breaker States for Gateway connectivity.
enum CircuitState {
  /// Gateway is reachable and healthy. All network requests proceed normally.
  closed,

  /// Gateway connection failure detected. All network requests fast-fail immediately
  /// during the cooldown window without opening sockets.
  open,

  /// Cooldown expired. Exactly ONE probe request is permitted to test Gateway reachability.
  /// Concurrent requests during probe continue to fast-fail.
  halfOpen,
}

/// Thrown when a request is fast-failed by the [GatewayCircuitBreaker] while in [CircuitState.open]
/// or when another probe is already executing in [CircuitState.halfOpen].
class GatewayCircuitBreakerException implements Exception {
  final String message;
  const GatewayCircuitBreakerException(this.message);

  @override
  String toString() => 'GatewayCircuitBreakerException: $message';
}

/// Centralized Gateway Circuit Breaker managing backend connectivity state.
/// Prevents cascading connection timeouts when the API Gateway is offline or unreachable.
class GatewayCircuitBreaker {
  static GatewayCircuitBreaker _instance = GatewayCircuitBreaker();
  static GatewayCircuitBreaker get instance => _instance;

  @visibleForTesting
  static set instance(GatewayCircuitBreaker custom) => _instance = custom;

  /// Duration to remain in [CircuitState.open] before transitioning to [CircuitState.halfOpen].
  final Duration cooldown;

  /// Optional clock provider for deterministic unit testing.
  final DateTime Function() _clock;

  CircuitState _state = CircuitState.closed;
  DateTime? _lastFailureTime;
  bool _isProbing = false;

  GatewayCircuitBreaker({
    this.cooldown = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Returns the current circuit state, updating from [CircuitState.open] to [CircuitState.halfOpen]
  /// if the cooldown period has elapsed.
  CircuitState get state {
    _evaluateState();
    return _state;
  }

  /// Whether the circuit breaker is currently open (fast-failing requests).
  bool get isOpen => state == CircuitState.open;

  /// Timestamp of the most recent gateway connection failure.
  DateTime? get lastFailureTime => _lastFailureTime;

  /// Evaluates whether cooldown has elapsed to transition OPEN -> HALF_OPEN.
  void _evaluateState() {
    if (_state == CircuitState.open && _lastFailureTime != null) {
      final elapsed = _clock().difference(_lastFailureTime!);
      if (elapsed >= cooldown) {
        _state = CircuitState.halfOpen;
        _isProbing = false;
      }
    }
  }

  /// Checks whether a request can be executed through the Gateway.
  /// - CLOSED: returns `true`.
  /// - OPEN: returns `false` (fast-fail).
  /// - HALF_OPEN: allows exactly ONE probe request (`true`); concurrent calls return `false`.
  bool canExecute() {
    _evaluateState();
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        return false;
      case CircuitState.halfOpen:
        if (!_isProbing) {
          _isProbing = true;
          return true;
        }
        return false;
    }
  }

  /// Records a successful connection to the Gateway.
  /// Resets state to [CircuitState.closed].
  void recordSuccess() {
    _state = CircuitState.closed;
    _lastFailureTime = null;
    _isProbing = false;
  }

  /// Records a connection failure (connection timeout or connection refused).
  /// Trips state to [CircuitState.open] and initiates cooldown.
  void recordFailure() {
    _state = CircuitState.open;
    _lastFailureTime = _clock();
    _isProbing = false;
  }

  /// Resets probe in-flight flag if a probe request was cancelled or aborted.
  void recordProbeAborted() {
    if (_state == CircuitState.halfOpen) {
      _isProbing = false;
    }
  }

  /// Manually resets circuit breaker to [CircuitState.closed].
  /// Invoked during user Pull-to-refresh to force re-probing Gateway.
  void reset() {
    _state = CircuitState.closed;
    _lastFailureTime = null;
    _isProbing = false;
  }

  /// Evaluates whether a [DioException] represents a true Gateway connection outage
  /// rather than an HTTP error response, client cancellation, or certificate issue.
  bool isGatewayConnectionFailure(DioException err) {
    // If the server responded with an HTTP status code (200-599), the Gateway IS reachable!
    if (err.response != null && err.response!.statusCode != null) {
      return false;
    }

    // Client-side cancellation is not a server failure
    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    // Fast-fail exception from the Circuit Breaker itself does not re-trip
    if (err.error is GatewayCircuitBreakerException) {
      return false;
    }

    // Bad certificate is a TLS issue, not an offline gateway
    if (err.type == DioExceptionType.badCertificate) {
      return false;
    }

    // Only true network connection failures (connection refused, host unreachable, socket closed)
    // or TCP connection timeouts trigger the circuit breaker.
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
