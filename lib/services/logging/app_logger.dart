import 'package:flutter/foundation.dart';

/// Minimal structured logger used across services.
///
/// The logger keeps log format consistent and supports optional error details.
class AppLogger {
  /// Creates a namespaced logger instance.
  const AppLogger({required this.namespace});

  /// Logical subsystem name used as log prefix.
  final String namespace;

  /// Emits a debug-level message.
  void debug(String message) {
    _emit(level: 'DEBUG', message: message);
  }

  /// Emits an info-level message.
  void info(String message) {
    _emit(level: 'INFO', message: message);
  }

  /// Emits a warning-level message.
  void warning(String message, {Object? error}) {
    _emit(level: 'WARN', message: message, error: error);
  }

  /// Emits an error-level message with optional stack trace.
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _emit(
      level: 'ERROR',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Formats and prints a structured log line.
  void _emit({
    required String level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer('[$namespace][$level] $message');
    if (error != null) {
      buffer.write(' | error=$error');
    }
    debugPrint(buffer.toString());
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
