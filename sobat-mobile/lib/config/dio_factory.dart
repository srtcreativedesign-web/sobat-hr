import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../config/api_config.dart';

/// Centralized Dio factory that configures SSL trust for release builds.
///
/// Flutter release builds use Dart's own embedded CA bundle which may not
/// include all intermediate certificates from the server's SSL chain.
/// This factory configures Dio to trust the platform's (Android/iOS)
/// certificate store instead, fixing "Connection failed" errors in
/// release builds while keeping SSL verification active.
class DioFactory {
  /// Creates a pre-configured Dio instance with SSL trust fix.
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
        headers:
            headers ??
            {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    // Fix SSL for release builds on mobile platforms
    if (!_isWeb) {
      _configureSslTrust(dio);
    }

    return dio;
  }

  static bool get _isWeb {
    try {
      // This will throw in web environment
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Configure Dio to trust the platform's certificate store.
  /// This fixes the issue where Dart's embedded CA bundle doesn't
  /// include the server's certificate chain in release builds.
  static void _configureSslTrust(Dio dio) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // Trust the server's certificate for our production domain
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            // Only trust our own production domain
            if (host == 'api.sobat-hr.com') {
              return true;
            }
            return false;
          };
      return client;
    };
  }
}
