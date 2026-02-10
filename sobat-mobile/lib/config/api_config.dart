import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ==========================================================================
  // 🔧 ENVIRONMENT CONFIGURATION
  // ---------------------------------------------------------------------------
  // Cara pakai:
  //   Development : flutter run
  //   Production  : flutter run --dart-define=ENV=prod
  //
  // ⚠️ Untuk Development, ganti _hostIp sesuai IP WiFi Anda:
  //   Terminal: ifconfig | grep "inet " | grep -v 127.0.0.1
  // ==========================================================================

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String _hostIp = '192.168.0.127';
  static const String _port = '8000';

  // Production URL
  static const String _prodUrl = 'https://api.sobat-hr.com/api';

  // Base URL Logic
  static String get baseUrl {
    if (_env == 'prod') {
      debugPrint('🚀 Environment: PRODUCTION');
      return _prodUrl;
    }

    // DEVELOPMENT
    debugPrint('🛠️ Environment: DEVELOPMENT');

    // Web
    if (kIsWeb) {
      debugPrint('🌐 Platform: Web Browser');
      return 'http://127.0.0.1:$_port/api';
    }

    // Android
    if (Platform.isAndroid) {
      debugPrint('🤖 Platform: Android → IP: $_hostIp');
      return 'http://$_hostIp:$_port/api';
    }

    // iOS
    if (Platform.isIOS) {
      debugPrint('🍎 Platform: iOS → IP: $_hostIp');
      return 'http://$_hostIp:$_port/api';
    }

    // Fallback
    return 'http://127.0.0.1:$_port/api';
  }

  /// Check if running in production
  static bool get isProduction => _env == 'prod';

  // ==========================================================================
  // 🔌 ENDPOINTS
  // ==========================================================================

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';

  // Dashboard
  static const String analytics = '/dashboard/analytics';
  static const String turnover = '/dashboard/turnover';
  static const String attendanceHeatmap = '/dashboard/attendance-heatmap';
  static const String contractExpiring = '/dashboard/contract-expiring';

  // Employees
  static const String employees = '/employees';

  // Attendance
  static const String attendance = '/attendance';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceCheckIn = '/attendance/check-in';
  static const String attendanceCheckOut = '/attendance/check-out';

  // Leave Requests
  static const String leaveRequests = '/leave-requests';

  // Payroll
  static const String payroll = '/payrolls';

  // Timeout configuration
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Helper to construct storage URL safely
  /// Handles null, full URLs, path normalization
  static String? getStorageUrl(dynamic path) {
    if (path == null || path.toString().isEmpty) return null;

    String p = path.toString();

    // Already a full URL
    if (p.startsWith('http')) return p;

    // Get base URL without trailing /api (use regex to avoid stripping /api from subdomain)
    final base = baseUrl.replaceFirst(RegExp(r'/api$'), '');

    // Remove leading slash
    if (p.startsWith('/')) p = p.substring(1);

    // Remove 'storage/' prefix if already present
    if (p.startsWith('storage/')) p = p.substring(8);

    return '$base/storage/$p';
  }
}
