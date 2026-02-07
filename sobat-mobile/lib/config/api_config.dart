import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ==========================================================================
  // 🔧 CONFIGURATION (AUTO-DETECTED)
  // ---------------------------------------------------------------------------
  // ⚠️ PENTING: Ganti IP ini sesuai dengan IP Laptop/Komputer Anda saat ini
  // Cara cek di Terminal: ifconfig | grep "inet " | grep -v 127.0.0.1
  // ---------------------------------------------------------------------------
  static const String _hostIp = '192.168.0.102'; // Updated IP for new Wifi
  static const String _port = '8000';

  // Base URL Logic
  static String get baseUrl {
    // 1. Web Support
    if (kIsWeb) {
      debugPrint('🌐 Environment: Web Browser');
      return 'http://127.0.0.1:$_port/api';
    }

    // 2. Android Support
    if (Platform.isAndroid) {
      debugPrint('🤖 Environment: Android Device Detected');
      // Note: Menggunakan Host IP agar jalan di Emulator MAUPUN Fisik
      // Jika pakai 10.0.2.2 hanya jalan di Emulator
      debugPrint(
        '👉 Config: Using Host IP ($_hostIp) for Android compatibility',
      );
      return 'http://$_hostIp:$_port/api';
    }

    // 3. iOS Support
    if (Platform.isIOS) {
      debugPrint('🍎 Environment: iOS Device Detected');
      // Note: iOS Simulator bisa localhost, tapi Fisik butuh IP
      // Kita gunakan IP Host agar universal
      debugPrint('👉 Config: Using Host IP ($_hostIp) for iOS compatibility');
      return 'http://$_hostIp:$_port/api';
    }

    // 4. Fallback (MacOS/Windows Desktop)
    debugPrint('💻 Environment: Desktop/Other');
    return 'http://127.0.0.1:$_port/api';
  }

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
}
