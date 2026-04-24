import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../config/api_config.dart';

/// Centralized Dio factory that configures HTTP client properly.
///
/// This factory configures Dio with proper SSL certificate validation
/// using the platform's certificate store for secure connections.
class DioFactory {
  /// Creates a pre-configured Dio instance with proper SSL validation.
  static Dio create({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: connectTimeout ?? ApiConfig.connectTimeout,
        receiveTimeout: receiveTimeout ?? ApiConfig.receiveTimeout,
        headers: headers ??
            {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-Platform': 'mobile',
            },
      ),
    );

    // Configure HTTP client with proper SSL validation for mobile platforms
    if (!_isWeb) {
      _configureHttpClient(dio);
    }

    return dio;
  }

  static bool get _isWeb {
    try {
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Configure HTTP client with proper SSL certificate validation.
  /// Uses platform's certificate store for secure connections.
  static void _configureHttpClient(Dio dio) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      // Apply connection timeout
      if (dio.options.connectTimeout != null) {
        client.connectionTimeout = dio.options.connectTimeout;
      }

      // ✅ SECURE: Use platform's default SSL certificate validation
      // No custom badCertificateCallback - let platform handle validation
      return client;
    };
  }
}
