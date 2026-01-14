class ApiConfig {
  // Base URL for API
  // Android Emulator: use 10.0.2.2 instead of localhost
  // iOS Simulator: use localhost
  // Physical Device: use your computer's IP address
  // static const String baseUrl = 'http://192.168.1.7:8000/api'; // Old IP
  // Use 10.0.2.2 for Android Emulator to access localhost
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // Physical Device (Your IP: 192.168.1.8)
  static const String baseUrl = 'http://192.168.1.8:8000/api';

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
