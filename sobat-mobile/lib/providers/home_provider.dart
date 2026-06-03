import 'package:flutter/foundation.dart';
import '../services/announcement_service.dart';
import '../services/payroll_service.dart';
import '../services/thr_service.dart';
import '../services/attendance_service.dart';
import '../services/request_service.dart';
import '../services/approval_service.dart';
import '../services/notification_service.dart';

class HomeProvider with ChangeNotifier {
  Map<String, dynamic>? _lastPayroll;
  bool _isLoadingPayroll = true;
  Map<String, dynamic>? _lastThr;
  bool _isLoadingThr = true;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = true;

  Map<String, dynamic>? _todayAttendance;
  bool _isLoadingAttendance = true;
  int _leaveBalance = 0;
  int _leaveQuota = 12;
  bool _isEligibleLeave = true;
  bool _isLoadingLeave = true;

  int _pendingApprovalsCount = 0;
  int _notificationCount = 0;

  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingRecentActivities = true;

  // Getters
  Map<String, dynamic>? get lastPayroll => _lastPayroll;
  bool get isLoadingPayroll => _isLoadingPayroll;
  Map<String, dynamic>? get lastThr => _lastThr;
  bool get isLoadingThr => _isLoadingThr;
  List<Map<String, dynamic>> get announcements => _announcements;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements;

  Map<String, dynamic>? get todayAttendance => _todayAttendance;
  bool get isLoadingAttendance => _isLoadingAttendance;
  int get leaveBalance => _leaveBalance;
  int get leaveQuota => _leaveQuota;
  bool get isEligibleLeave => _isEligibleLeave;
  bool get isLoadingLeave => _isLoadingLeave;

  int get pendingApprovalsCount => _pendingApprovalsCount;
  int get notificationCount => _notificationCount;

  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  bool get isLoadingRecentActivities => _isLoadingRecentActivities;

  void _safeNotifyListeners() {
    Future.microtask(() {
      try {
        notifyListeners();
      } catch (_) {}
    });
  }

  // Method to reload all data at once (refresh indicator)
  Future<void> reloadAllData() async {
    await Future.wait([
      loadTodayAttendance(),
      loadLeaveBalance(),
      loadLastPayroll(),
      loadLastThr(),
      loadAnnouncements(),
      loadRecentActivities(),
      loadPendingApprovals(),
      loadNotifications(),
    ]);
  }

  // Load individual sections
  Future<void> loadTodayAttendance() async {
    try {
      final data = await AttendanceService().getTodayAttendance();
      _todayAttendance = data;
      _isLoadingAttendance = false;
      _safeNotifyListeners();
    } catch (_) {
      _isLoadingAttendance = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadLeaveBalance() async {
    try {
      final data = await RequestService().getLeaveBalance();
      _leaveBalance = data['balance'] ?? 0;
      _leaveQuota = data['quota'] ?? 12;
      _isEligibleLeave = data['eligible'] ?? false;
      _isLoadingLeave = false;
      _safeNotifyListeners();
    } catch (_) {
      _isLoadingLeave = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadLastPayroll() async {
    try {
      final payrolls = await PayrollService().getPayrolls();
      if (payrolls.isNotEmpty) {
        try {
          payrolls.sort((a, b) {
            final aStr = (a['period'] ?? a['period_start'] ?? '').toString();
            final bStr = (b['period'] ?? b['period_start'] ?? '').toString();
            return bStr.compareTo(aStr);
          });
        } catch (_) {}
        _lastPayroll = payrolls.first;
      } else {
        _lastPayroll = null;
      }
      _isLoadingPayroll = false;
      _safeNotifyListeners();
    } catch (_) {
      _isLoadingPayroll = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadLastThr() async {
    try {
      final thrs = await ThrService().getThrs();
      if (thrs.isNotEmpty) {
        _lastThr = thrs.first;
      } else {
        _lastThr = null;
      }
      _isLoadingThr = false;
      _safeNotifyListeners();
    } catch (_) {
      _isLoadingThr = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadAnnouncements() async {
    try {
      final data = await AnnouncementService().getAnnouncements(category: 'news');
      _announcements = data;
      _isLoadingAnnouncements = false;
      _safeNotifyListeners();
    } catch (_) {
      _isLoadingAnnouncements = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    try {
      final notifs = await NotificationService().getNotifications();
      _notificationCount = notifs.where((n) => n['read_at'] == null).length;
      _safeNotifyListeners();
    } catch (_) {}
  }

  Future<void> loadPendingApprovals() async {
    try {
      final approvals = await ApprovalService().getPendingApprovals();
      _pendingApprovalsCount = approvals.length;
      _safeNotifyListeners();
    } catch (_) {}
  }

  Future<void> loadRecentActivities() async {
    _isLoadingRecentActivities = true;
    _safeNotifyListeners();

    try {
      final List<Map<String, dynamic>> activities = [];
      final now = DateTime.now();

      // 1. Fetch Attendance History (Current Month)
      try {
        final attendanceData = await AttendanceService().getHistory(
          month: now.month,
          year: now.year,
        );
        for (var item in attendanceData) {
          if (item['check_in'] != null) {
            activities.add({
              'type': 'attendance',
              'action': 'check_in',
              'date': DateTime.parse('${item['date']} ${item['check_in']}'),
              'time': item['check_in'] ?? '',
              'status': 'success',
            });
          }
          if (item['check_out'] != null) {
            activities.add({
              'type': 'attendance',
              'action': 'check_out',
              'date': DateTime.parse('${item['date']} ${item['check_out']}'),
              'time': item['check_out'] ?? '',
              'status': 'neutral',
            });
          }
        }
      } catch (_) {}

      // 2. Fetch Requests
      try {
        final requestsData = await RequestService().getRequests();
        for (var item in requestsData) {
          final date = DateTime.parse(item['created_at']);
          String status = item['status'] ?? 'pending';
          String type = item['type'] ?? 'Request';

          activities.add({
            'type': 'request',
            'date': date,
            'req_type': type,
            'req_status': status,
            'start_date': item['start_date'],
            'created_at': item['created_at'],
            'status': status == 'approved'
                ? 'success'
                : (status == 'rejected' ? 'error' : 'warning'),
          });
        }
      } catch (_) {}

      // 3. Fetch Payrolls
      try {
        final payrolls = await PayrollService().getPayrolls(year: now.year);
        for (var item in payrolls) {
          final period = item['period'] ?? item['period_start'];
          if (period != null) {
            final dateStr = '$period-25 00:00:00';
            DateTime date;
            try {
              date = DateTime.parse(dateStr);
            } catch (_) {
              date = now;
            }

            activities.add({
              'type': 'payroll',
              'date': date,
              'status': 'info',
            });
          }
        }
      } catch (_) {}

      // Sort by Date Descending
      activities.sort((a, b) => b['date'].compareTo(a['date']));

      _recentActivities = activities.take(3).toList();
      _isLoadingRecentActivities = false;
      _safeNotifyListeners();
    } catch (_) {
      _isLoadingRecentActivities = false;
      _safeNotifyListeners();
    }
  }
}
