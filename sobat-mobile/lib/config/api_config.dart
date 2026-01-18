import 'dart:io';

class ApiConfig {
  // Base URL for API
  // Android Emulator: use 10.0.2.2 instead of localhost
  // iOS Simulator & Web: use localhost (127.0.0.1)

  static String get baseUrl {
    if (Platform.isAndroid) {
      // return 'http://10.0.2.2/sobat-hr/sobat-api/public/api'; // For Emulator (XAMPP Port 80)
      return 'http://192.168.0.105/sobat-hr/sobat-api/public/api'; // For Physical Device (XAMPP Port 80)
    }
    // iOS Simulator, Physical device
    return 'http://192.168.0.105/sobat-hr/sobat-api/public/api';
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
