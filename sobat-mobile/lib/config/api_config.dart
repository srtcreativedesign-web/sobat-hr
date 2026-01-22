import 'dart:io';

class ApiConfig {
  // Base URL for API
  // Android Emulator: use 10.0.2.2 instead of localhost
  // iOS Simulator & Web: use localhost (127.0.0.1)

  static String get baseUrl {
    if (Platform.isAndroid) {
      // 10.0.2.2 is for Android Emulator to access localhost
      // Use 192.168.x.x for Physical Android Device
      // Detected Local IP: 192.168.1.3
      return 'http://10.0.2.2:8000/api';
    } else if (Platform.isIOS) {
      // iOS Simulator: use localhost
      // For Physical iOS Device, change to your machine's IP
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  // API Endpoints
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
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
