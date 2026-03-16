import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';

/// Centralized error handler for user-friendly messages
/// Never expose raw server errors or technical details to users
class AppErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Generic user-friendly messages (no technical details)
  static const String _networkError =
      'Tidak ada koneksi internet. Periksa koneksi Anda.';
  static const String _timeoutError =
      'Koneksi timeout. Server sedang sibuk, silakan coba lagi.';
  static const String _serverError =
      'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
  static const String _authError = 'Email atau password salah.';
  static const String _validationError = 'Data yang dimasukkan tidak valid.';
  static const String _forbiddenError = 'Anda tidak memiliki akses.';
  static const String _notFoundError = 'Data tidak ditemukan.';
  static const String _genericError = 'Terjadi kesalahan. Silakan coba lagi.';

  /// Widget to show when an error occurs during build
  static Widget get errorWidget => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 50),
              SizedBox(height: 16),
              Text('Telah terjadi kesalahan pada aplikasi', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

  /// Show internal error for framework/platform exceptions
  static void showInternalError(Object exception, StackTrace? stack) {
    debugPrint('Internal Error: $exception');
    if (stack != null) debugPrint('Stack: $stack');
    
    // Only show dialog if we have a context via navigatorKey
    if (navigatorKey.currentContext != null) {
      showErrorDialog(getErrorMessage(exception));
    }
  }

  /// Convert any error to user-friendly message
  static String getErrorMessage(dynamic error) {
    // Network errors
    if (error is DioException) {
      return _handleDioException(error);
    }

    // Generic errors
    if (error is Exception) {
      final message = error.toString().replaceAll('Exception: ', '');
      return _sanitizeMessage(message);
    }

    // Unknown errors
    return _genericError;
  }

  /// Handle DioException with specific error types
  static String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _timeoutError;

      case DioExceptionType.connectionError:
        return _networkError;

      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';

      default:
        return _networkError;
    }
  }

  /// Handle HTTP status codes with user-friendly messages
  static String _handleBadResponse(int? statusCode) {
    switch (statusCode) {
      case 401:
        return _authError;
      case 403:
        return _forbiddenError;
      case 404:
        return _notFoundError;
      case 422:
        return _validationError;
      case 500:
      case 502:
      case 503:
        return _serverError;
      default:
        return _genericError;
    }
  }

  /// Sanitize any error message to remove technical details
  static String _sanitizeMessage(String message) {
    // Remove technical patterns
    final patternsToRemove = [
      'Exception: ',
      'Error: ',
      'DioException: ',
      'HttpException: ',
      'SocketException: ',
      'TimeoutException: ',
      RegExp(r'raw:.*'), // Remove raw data
      RegExp(r'\[.*\]'), // Remove bracketed technical info
      RegExp(r'http[s]?://\S+'), // Remove URLs
      RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'), // Remove IP addresses
    ];

    String sanitized = message;
    for (var pattern in patternsToRemove) {
      if (pattern is String) {
        sanitized = sanitized.replaceAll(pattern, '');
      } else if (pattern is RegExp) {
        sanitized = sanitized.replaceAll(pattern, '');
      }
    }

    // Trim and limit length
    sanitized = sanitized.trim();
    if (sanitized.isEmpty) return _genericError;
    if (sanitized.length > 100) {
      sanitized = '${sanitized.substring(0, 100)}...';
    }

    return sanitized;
  }

  /// Show user-friendly error dialog
  static void showErrorDialog(String error, {VoidCallback? onOk}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: 'Oops!',
      desc: error,
      btnOkOnPress: () {
        onOk?.call();
      },
      btnOkColor: const Color(0xFFEF4444),
      btnOkText: 'Tutup',
    ).show();
  }
}

// Legacy support - redirect to new class
@Deprecated('Use AppErrorHandler instead')
typedef ErrorHandler = AppErrorHandler;
