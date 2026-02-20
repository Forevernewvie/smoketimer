/// Base exception type for domain/application-level failures.
class AppException implements Exception {
  /// Creates an application exception with a stable code and message.
  const AppException({required this.code, required this.message, this.cause});

  /// Stable machine-readable error code for logging/diagnostics.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Original exception when this wraps a lower-level failure.
  final Object? cause;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Exception for local persistence operations.
class RepositoryException extends AppException {
  /// Creates a repository exception for load/save/clear failures.
  const RepositoryException({
    required super.code,
    required super.message,
    super.cause,
  });
}

/// Exception for local notification operations.
class NotificationOperationException extends AppException {
  /// Creates a notification operation exception.
  const NotificationOperationException({
    required super.code,
    required super.message,
    super.cause,
  });
}
