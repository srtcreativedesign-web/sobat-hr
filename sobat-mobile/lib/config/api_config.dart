class ApiConfig {
  // Base URL - ganti dengan IP komputer untuk testing di device fisik
  static const String baseUrl = 'http://localhost:8000/api';
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  
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
