import 'package:logger/logger.dart';

/// Application logger configuration
/// Provides centralized logging for the entire app
class AppLogger {
  static late Logger _logger;
  static bool _initialized = false;

  /// Initialize the logger with custom configuration
  static void init() {
    if (_initialized) return;

    _logger = Logger(
      printer: SimplePrinter(),
    );

    _initialized = true;
    _logger.i('AppLogger initialized');
  }

  /// Log a debug message
  static void d(String message) {
    _ensureInitialized();
    _logger.d(message);
  }

  /// Log an info message
  static void i(String message) {
    _ensureInitialized();
    _logger.i(message);
  }

  /// Log a warning message
  static void w(String message) {
    _ensureInitialized();
    _logger.w(message);
  }

  /// Log an error message
  static void e(String message, [dynamic error]) {
    _ensureInitialized();
    if (error != null) {
      _logger.e('$message\nError: $error');
    } else {
      _logger.e(message);
    }
  }

  /// Log a fatal error message
  static void f(String message, [dynamic error]) {
    _ensureInitialized();
    if (error != null) {
      _logger.f('$message\nError: $error');
    } else {
      _logger.f(message);
    }
  }

  /// Log API requests
  static void api(String method, String url, {int? statusCode, String? responseBody}) {
    _ensureInitialized();
    if (statusCode != null) {
      _logger.i('API $method $url - Status: $statusCode');
      if (responseBody != null && responseBody.length > 500) {
        _logger.d('API Response (truncated): ${responseBody.substring(0, 500)}...');
      } else if (responseBody != null) {
        _logger.d('API Response: $responseBody');
      }
    } else {
      _logger.d('API $method $url');
    }
  }

  /// Log user actions
  static void userAction(String action) {
    _ensureInitialized();
    _logger.i('User Action: $action');
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    _ensureInitialized();
    _logger.i('Performance: $operation took ${duration.inMilliseconds}ms');
  }

  /// Ensure logger is initialized before use
  static void _ensureInitialized() {
    if (!_initialized) {
      // Fallback initialization if not properly initialized
      _logger = Logger(
        printer: SimplePrinter(),
      );
      _initialized = true;
    }
  }
}