import 'package:sobat_hr/config/api_config.dart';
import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_navbar.dart';
import '../../models/user.dart';

import '../../services/payroll_service.dart'; // Restored
import '../../services/attendance_service.dart';
import '../../services/announcement_service.dart'; // Restored
import '../../services/request_service.dart'; // Added
import '../../screens/security/pin_screen.dart';
import '../../screens/submission/submission_screen.dart';
import '../../screens/submission/create_submission_screen.dart'; // Added
import '../../screens/announcement/announcement_detail_screen.dart'; // Added

import '../../widgets/payroll_cards.dart';
import '../../services/thr_service.dart';
import 'package:intl/intl.dart';
import '../profile/enroll_face_screen.dart'; // Added
import '../approval/approval_list_screen.dart'; // Added
import '../../services/approval_service.dart'; // Added for badge
import '../../services/notification_service.dart'; // Added for notif badge
import '../attendance/offline_attendance_handler.dart'; // Added for operational track
import '../../services/offline_attendance_service.dart';
import '../finance/finance_coming_soon_screen.dart';
import '../../widgets/attendance_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Removed manual _authService and _user map
  // int _selectedIndex = 0; // Keeping index if needed, but actually we use CustomNavbar logic
  int _selectedIndex = 0;

  Map<String, dynamic>? _lastPayroll;
  bool _isLoadingPayroll = true;
  Map<String, dynamic>? _lastThr;
  bool _isLoadingThr = true;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = true;

  // Carousel State
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentAnnouncementIndex = 0;

  // Dashboard Cards Carousel State
  late PageController _dashboardController;
  Timer? _dashboardTimer;
  int _currentDashboardIndex = 0;

  Map<String, dynamic>? _todayAttendance;
  bool _isLoadingAttendance = true;
  int _leaveBalance = 0;
  int _leaveQuota = 12;
  bool _isEligibleLeave = true;
  bool _isLoadingLeave = true;

  int _pendingApprovalsCount = 0; // Added for badge
  int _notificationCount = 0; // Added for notif badge

  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingRecentActivities = true;

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _dashboardTimer?.cancel();
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _dashboardController = PageController(viewportFraction: 0.92);
    _startDashboardAutoScroll();
    // Data is loaded by AuthProvider in main.dart
    _loadTodayAttendance();
    _loadLeaveBalance();
    _loadLastPayroll();
    _loadLastThr();
    _loadAnnouncements();
    _loadRecentActivities();
    _checkFaceEnrollment();
    _loadPendingApprovals();
    _loadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAnnouncement();
      // Auto-sync offline attendance when app opens
      OfflineAttendanceService().syncAllUnsyncedAttendances();
    });
  }

  void _checkAnnouncement() async {
    try {
      final banner = await AnnouncementService().fetchActiveAnnouncement();

      // Check if widget is still mounted and banner exists
      if (!mounted || banner == null) return;

      showDialog(
        context: context,
        barrierDismissible: true, // Allow clicking outside to close
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  // Image Container
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          0.7, // Limit total height relative to screen
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    ApiConfig.getStorageUrl(
                                      banner['image_path'],
                                    ) ??
                                    '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget: (ctx, url, error) {
                                  return Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                progressIndicatorBuilder: (ctx, url, progress) {
                                  return SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.colorEggplant,
                                        value: progress.progress,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Description / Title if exists
                            if (banner['title'] != null ||
                                (banner['description'] != null &&
                                    banner['description']
                                        .toString()
                                        .isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (banner['title'] != null)
                                      Text(
                                        banner['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    if (banner['description'] != null &&
                                        banner['description']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        banner['description'],
                                        style: const TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Close Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom Close Button (Optional, for better UX)
              // ElevatedButton(
              //   onPressed: () => Navigator.pop(ctx),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.white,
              //     foregroundColor: AppTheme.colorEggplant,
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              //   ),
              //   child: const Text('Tutup'),
              // )
            ],
          ),
        ),
      );
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
    }
  }

  // Added method to fetch notifications count
  Future<void> _loadNotifications() async {
    try {
      final notifs = await NotificationService().getNotifications();

      if (mounted) {
        setState(() {
          // Only count unread notifications
          _notificationCount = notifs.where((n) => n['read_at'] == null).length;
        });
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
    }
  }

  // Added method to fetch pending approvals
  Future<void> _loadPendingApprovals() async {
    try {
      final approvals = await ApprovalService().getPendingApprovals();
      if (mounted) {
        setState(() {
          _pendingApprovalsCount = approvals.length;
        });
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
    }
  }

  Future<void> _loadLeaveBalance() async {
    try {
      final data = await RequestService().getLeaveBalance();
      if (mounted) {
        setState(() {
          _leaveBalance = data['balance'] ?? 0;
          _leaveQuota = data['quota'] ?? 12; // Or 0 if not eligible?
          _isEligibleLeave = data['eligible'] ?? false;
          _isLoadingLeave = false;
        });
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      if (mounted) setState(() => _isLoadingLeave = false);
    }
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final data = await AttendanceService().getTodayAttendance();
      if (mounted) {
        setState(() {
          _todayAttendance = data;
          _isLoadingAttendance = false;
        });
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (_announcements.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _currentAnnouncementIndex + 1;
          if (nextPage >= _announcements.length) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    }
  }

  void _startDashboardAutoScroll() {
    _dashboardTimer?.cancel();
    _dashboardTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_dashboardController.hasClients) {
        int nextPage = _currentDashboardIndex + 1;
        // Total cards = 3 (Leave, Salary, THR)
        if (nextPage >= 3) {
          nextPage = 0;
        }
        _dashboardController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await AnnouncementService().getAnnouncements(
        category: 'news',
      );
      if (mounted) {
        setState(() {
          _announcements = data;
          _isLoadingAnnouncements = false;
        });
        _startAutoScroll();
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      if (mounted) setState(() => _isLoadingAnnouncements = false);
    }
  }

  Future<void> _loadLastPayroll() async {
    try {
      final payrolls = await PayrollService().getPayrolls();
      if (payrolls.isNotEmpty && mounted) {
        // Sort by period/period_start descending (string comparison is safe)
        try {
          payrolls.sort((a, b) {
            final aStr = (a['period'] ?? a['period_start'] ?? '').toString();
            final bStr = (b['period'] ?? b['period_start'] ?? '').toString();
            return bStr.compareTo(aStr);
          });
        } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
        }

        setState(() {
          _lastPayroll = payrolls.isNotEmpty ? payrolls.first : null;
          _isLoadingPayroll = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingPayroll = false);
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      if (mounted) setState(() => _isLoadingPayroll = false);
    }
  }

  Future<void> _loadLastThr() async {
    try {
      final thrs = await ThrService().getThrs();
      if (thrs.isNotEmpty && mounted) {
        setState(() {
          _lastThr = thrs.first;
          _isLoadingThr = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingThr = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingThr = false);
    }
  }

  Future<void> _loadRecentActivities() async {
    if (!mounted) return;
    setState(() => _isLoadingRecentActivities = true);

    try {
      final List<Map<String, dynamic>> activities = [];

      // 1. Fetch Attendance History (Current Month)
      final now = DateTime.now();
      try {
        final attendanceData = await AttendanceService().getHistory(
          month: now.month,
          year: now.year,
        );
        for (var item in attendanceData) {
          if (item['check_in'] != null) {
            activities.add({
              'type': 'attendance',
              'date': DateTime.parse('${item['date']} ${item['check_in']}'),
              'title': 'Absen Masuk',
              'desc': 'Anda melakukan absen masuk pada ${item['check_in']}',
              'status': 'success',
            });
          }
          if (item['check_out'] != null) {
            activities.add({
              'type': 'attendance',
              'date': DateTime.parse('${item['date']} ${item['check_out']}'),
              'title': 'Absen Keluar',
              'desc': 'Anda melakukan absen keluar pada ${item['check_out']}',
              'status': 'neutral',
            });
          }
        }
      } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      }

      // 2. Fetch Requests (Leave/Permit)
      try {
        final requestsData = await RequestService().getRequests();
        for (var item in requestsData) {
          final date = DateTime.parse(item['created_at']);
          String status = item['status'] ?? 'pending';
          String type = item['type'] ?? 'Request';
          String title =
              '$type ${status == 'approved' ? 'Disetujui' : (status == 'rejected' ? 'Ditolak' : 'Diajukan')}';

          String formattedDate = '-';
          try {
            if (item['start_date'] != null) {
              final dateObj = DateTime.parse(item['start_date']);
              formattedDate = DateFormat('d MMM y', 'id_ID').format(dateObj);
            } else if (item['created_at'] != null) {
              final dateObj = DateTime.parse(item['created_at']);
              formattedDate = DateFormat('d MMM y', 'id_ID').format(dateObj);
            }
          } catch (_) {}

          activities.add({
            'type': 'request',
            'date': date,
            'title': title,
            'desc': 'Pengajuan $type tanggal $formattedDate',
            'status': status == 'approved'
                ? 'success'
                : (status == 'rejected' ? 'error' : 'warning'),
          });
        }
      } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      }

      // 3. Fetch Payrolls
      try {
        final payrolls = await PayrollService().getPayrolls(year: now.year);
        for (var item in payrolls) {
          final period = item['period'] ?? item['period_start'];
          if (period != null) {
            // Approximate date as 25th of the month or created_at if avail?
            final dateStr = '$period-25 00:00:00';
            DateTime date;
            try {
              date = DateTime.parse(dateStr);
            } catch (_) {
              date = now; // Fallback
            }

            activities.add({
              'type': 'payroll',
              'date': date,
              'title': 'Gaji Bulan ${DateFormat('MMMM', 'id_ID').format(date)}',
              'desc': 'Slip gaji telah diterbitkan.',
              'status': 'info',
            });
          }
        }
      } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      }

      // Sort by Date Descending
      activities.sort((a, b) => b['date'].compareTo(a['date']));

      // Take Top 3
      final recent = activities.take(3).toList();

      if (mounted) {
        setState(() {
          _recentActivities = recent;
          _isLoadingRecentActivities = false;
        });
      }
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      if (mounted) setState(() => _isLoadingRecentActivities = false);
    }
  }

  void _navigateToPayroll() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    if (user.hasPin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.verify,
            onSuccess: () {
              Navigator.pop(context); // Close PIN Screen
              Navigator.pushNamed(context, '/payroll');
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.setup,
            onSuccess: () {
              Navigator.pop(context); // Close PIN Screen
              Navigator.pushNamed(context, '/payroll');
            },
          ),
        ),
      );
    }
  }

  void _checkFaceEnrollment() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    // Skip face enrollment for operational staff (no attendance feature)
    if (user != null && user.track == 'operational') {
      return;
    }

    if (user != null && user.facePhotoPath == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Registrasi Wajah Diperlukan'),
            content: const Text(
              'Untuk melakukan absensi, Anda wajib mendaftarkan wajah terlebih dahulu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Nanti',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const EnrollFaceScreen(isFirstTime: false),
                    ),
                  ).then((result) {
                    if (result == true) {
                      auth.refreshProfile();
                    }
                  });
                },
                child: const Text('Daftarkan Sekarang'),
              ),
            ],
          ),
        );
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use AuthProvider
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.colorEggplant),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate-50 like background
      body: Stack(
        children: [
          // Body Content
          _selectedIndex == 0
              ? _buildDashboardContent(user)
              : _selectedIndex == 1
              ? const SubmissionScreen()
              : _selectedIndex == 3
              ? FinanceComingSoonScreen(onBack: () => setState(() => _selectedIndex = 0))
              : Center(child: Text('Coming Soon: Index $_selectedIndex')),

          // 3. Floating Bottom Nav
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: CustomNavbar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 4) {
                  Navigator.pushNamed(context, '/profile').then((result) {
                    if (mounted) {
                      if (result != null && result is int) {
                        setState(() => _selectedIndex = result);
                      } else {
                        setState(() => _selectedIndex = 0);
                      }
                    }
                  });
                } else {
                  setState(() => _selectedIndex = index);
                }
              },
            ),
          ),

          // 4. Floating FAB (Separated)
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 64,
                width: 64,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/submission/menu');
                  },
                  backgroundColor: AppTheme.colorEggplant,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    // Reload all data
    await Future.wait([
      _loadTodayAttendance(),
      _loadLeaveBalance(),
      _loadLastPayroll(),
      _loadAnnouncements(),
      _loadRecentActivities(),
      _loadRecentActivities(),
      _loadPendingApprovals(),
      _loadNotifications(),
      OfflineAttendanceService().syncAllUnsyncedAttendances(),
    ]);
  }

  Widget _buildDashboardContent(User? user) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.colorEggplant,
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.colorCyan.withValues(alpha: 0.15),
                    AppTheme.colorCyan.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.colorEggplant.withValues(alpha: 0.08),
                    AppTheme.colorEggplant.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Sticky Header
              _buildStickyHeader(user),

              // 2. Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getGreeting().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.colorCyan,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'EEEE, d MMM',
                                    'id_ID',
                                  ).format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textDark,
                                        letterSpacing: -1,
                                        fontFamily: 'Manrope',
                                      ),
                                      children: [
                                        const TextSpan(text: 'Halo, '),
                                        TextSpan(
                                          text:
                                              user?.name.split(' ').first ??
                                              'User',
                                          style: const TextStyle(
                                            color: AppTheme.colorEggplant,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '!',
                                          style: TextStyle(
                                            color: AppTheme.colorCyan,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '✨',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Attendance Card
                      _buildAttendanceCard(user),
                      const SizedBox(height: 24),

                      // Horizontal Cards (Carousel)
                      _buildHorizontalCards(),

                      const SizedBox(height: 32),

                      // Announcements
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildAnnouncements(),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildQuickActions(),
                      ),

                      const SizedBox(height: 32),

                      // Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildBanner(user),
                      ),

                      // const SizedBox(height: 32);

                      // Recent Activity
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildRecentActivity(),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(User? user) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile').then((_) {
                        if (!mounted) return;
                        // Refresh user data when returning from profile
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).refreshProfile();
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.colorCyan.withAlpha(50),
                          backgroundImage:
                              (user?.avatar != null && user!.avatar!.isNotEmpty)
                              ? CachedNetworkImageProvider(
                                  ApiConfig.getStorageUrl(user.avatar!) ?? '',
                                )
                              : null,
                          child: (user?.avatar == null || (user?.avatar?.isEmpty ?? true))
                              ? Text(
                                  (user?.name != null && user!.name.isNotEmpty)
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.colorEggplant,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              (user?.jobLevel?.isNotEmpty == true
                                      ? user!.jobLevel!.replaceAll('_', ' ')
                                      : (user?.position?.isNotEmpty == true
                                            ? user!.position!
                                            : (user?.role?.toUpperCase() ??
                                                  'STAFF')))
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/notifications');
                      _loadNotifications(); // Refresh on return
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: AppTheme.textDark,
                            size: 24,
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _notificationCount > 99
                                      ? '99+'
                                      : _notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(User? user) {
    if (user == null) return const SizedBox.shrink();

    // Format Date
    final now = DateTime.now();
    final formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'id_ID',
    ).format(now); // Full month name

    // Determine Status
    String buttonText = 'Clock In Sekarang';
    IconData buttonIcon = Icons.login;
    bool isButtonDisabled = false;

    // Weekend Check
    bool isWeekend =
        (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday);
    if (isWeekend) {
      isButtonDisabled = true;
      buttonText = 'Libur';
    }

    if (_isLoadingAttendance) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_todayAttendance != null) {
      if (_todayAttendance!['check_out'] != null) {
        buttonText = 'Absen Selesai';
        isButtonDisabled = true;
        buttonIcon = Icons.check_circle;
      } else if (_todayAttendance!['check_in'] != null) {
        String statusStr =
            _todayAttendance!['status']?.toString().toLowerCase() ?? '';
        String checkInTimeStr = _todayAttendance!['check_in'].toString();

        bool isLate = false;
        try {
          // Parse HH:mm:ss
          final parts = checkInTimeStr.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            // Check if after 08:05
            if (hour > 8 || (hour == 8 && minute > 5)) {
              isLate = true;
            }
          }
        } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
        }

        if (statusStr == 'pending') {
          if (isLate) {
            buttonText = 'Menunggu Approval';
            buttonIcon = Icons.timer;
            isButtonDisabled = true;
          } else {
            buttonText = 'Clock Out Sekarang';
            buttonIcon = Icons.logout;
            isButtonDisabled = false;
          }
        } else if (statusStr == 'rejected') {
          buttonText = 'Ditolak';
          isButtonDisabled = true;
          buttonIcon = Icons.cancel;
        } else {
          // Present / Approved
          buttonText = 'Clock Out Sekarang';
          buttonIcon = Icons.logout;
          isButtonDisabled = false;
        }
      }
    }

    // ─────────────────────────────────────────────
    //  New Attendance Card v2 Implementation
    // ─────────────────────────────────────────────

    // Helper: Parse HH:mm to DateTime for today
    DateTime parseShiftTime(String? timeStr, DateTime fallback) {
      if (timeStr == null || timeStr.isEmpty) return fallback;
      try {
        final parts = timeStr.split(':');
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      } catch (_) {
        return fallback;
      }
    }

    // Shift Times
    final shiftStart = parseShiftTime(user.shiftStartTime, DateTime(now.year, now.month, now.day, 8, 0));
    final shiftEnd = parseShiftTime(user.shiftEndTime, DateTime(now.year, now.month, now.day, 17, 0));
    final shiftLabel = "Shift ${user.shiftStartTime?.substring(0, 5) ?? '08:00'} - ${user.shiftEndTime?.substring(0, 5) ?? '17:00'}";

    // Attendance Data
    DateTime? checkInTime;
    DateTime? checkOutTime;
    if (_todayAttendance != null) {
      if (_todayAttendance!['check_in'] != null) {
        checkInTime = parseShiftTime(_todayAttendance!['check_in'].toString(), now);
      }
      if (_todayAttendance!['check_out'] != null) {
        checkOutTime = parseShiftTime(_todayAttendance!['check_out'].toString(), now);
      }
    }

    // Work Duration Calculation
    String durationLabel = "0j 0m";
    if (checkInTime != null) {
      final endTime = checkOutTime ?? now;
      final diff = endTime.difference(checkInTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      durationLabel = "${hours}j ${minutes}m";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2A6E), // Deep Blue/Eggplant from screenshot
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D2A6E).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Section: Dark Blue
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, _) => Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Work Duration Badge
                    if (checkInTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Durasi kerja',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              durationLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Timeline
                _buildAttendanceTimeline(shiftStart, shiftEnd, checkInTime, checkOutTime),
              ],
            ),
          ),

          // Bottom Section: White
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAttendanceStatusBadge(isWeekend),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          shiftLabel,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Action Button (Clock In/Out)
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isButtonDisabled ? null : () {
                      if (user.track == 'operational') {
                        OfflineAttendanceHandler(context: context).startOfflineAttendance();
                      } else {
                        Navigator.pushNamed(context, '/attendance').then((_) => _loadTodayAttendance());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D2A6E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTimeline(DateTime start, DateTime end, DateTime? checkIn, DateTime? checkOut) {
    final currentProgressTime = checkOut ?? DateTime.now();
    
    double calculateProgress(DateTime time) {
      final total = end.difference(start).inSeconds;
      if (total <= 0) return 0;
      final current = time.difference(start).inSeconds;
      return (current / total).clamp(0.0, 1.0);
    }

    final checkInProgress = checkIn != null ? calculateProgress(checkIn) : 0.0;
    final currentProgress = calculateProgress(currentProgressTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        return Column(
          children: [
            Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // Base Line
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Progress Segment
                if (checkIn != null)
                  Container(
                    height: 3,
                    width: width * currentProgress,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                
                // Dots
                _timelineDot(0, Colors.white.withValues(alpha: 0.3)),
                if (checkIn != null)
                  _timelineDot(width * checkInProgress, const Color(0xFF97C459)),
                if (checkIn != null)
                  _timelineDot(width * currentProgress, const Color(0xFFFBB03B)),
                _timelineDot(width, const Color(0xFF3C3489)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timelineLabelV2('Masuk', checkIn != null ? DateFormat('HH:mm').format(checkIn) : '--:--', checkIn != null ? const Color(0xFF97C459) : null),
                _timelineLabelV2('Keluar', checkOut != null ? DateFormat('HH:mm').format(checkOut) : (checkIn != null ? DateFormat('HH:mm').format(DateTime.now()) : '--:--'), checkIn != null ? const Color(0xFFFBB03B) : null),
                _timelineLabelV2('Selesai', DateFormat('HH:mm').format(end), Colors.white.withValues(alpha: 0.3)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _timelineDot(double left, Color color) {
    return Positioned(
      left: left - 4,
      top: -2.5, // Center vertically on 3px line (8px dot -> offset = (8-3)/2 = 2.5)
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2D2A6E), width: 1.5),
        ),
      ),
    );
  }

  Widget _timelineLabelV2(String label, String time, Color? color) {
    final textColor = color ?? Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusBadge(bool isWeekend) {
    AttendanceStatus badgeStatus = AttendanceStatus.absent;

    if (_todayAttendance != null) {
      if (_todayAttendance!['check_out'] != null) {
        String statusStr = _todayAttendance!['status']?.toString().toLowerCase() ?? '';
        
        // Check for Early Leave
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        final shiftEndTimeStr = user?.shiftEndTime;
        if (shiftEndTimeStr != null && shiftEndTimeStr.contains(':')) {
          try {
            final now = DateTime.now();
            final parts = shiftEndTimeStr.split(':');
            final shiftEnd = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
            
            // Format check-out correctly for parsing
            String checkOutStr = _todayAttendance!['check_out'].toString();
            if (checkOutStr.length == 5) checkOutStr += ":00"; // HH:mm -> HH:mm:ss
            
            final datePrefix = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
            final checkOut = DateTime.parse("$datePrefix $checkOutStr");
            
            if (checkOut.isBefore(shiftEnd.subtract(const Duration(minutes: 5)))) {
              badgeStatus = AttendanceStatus.earlyLeave;
            } else {
              badgeStatus = (statusStr == 'late') ? AttendanceStatus.late : AttendanceStatus.onTime;
            }
          } catch (_) {
            badgeStatus = (statusStr == 'late') ? AttendanceStatus.late : AttendanceStatus.onTime;
          }
        } else {
          badgeStatus = (statusStr == 'late') ? AttendanceStatus.late : AttendanceStatus.onTime;
        }
      } else if (_todayAttendance!['check_in'] != null) {
        badgeStatus = AttendanceStatus.inProgress;
      }
    } else if (isWeekend) {
      badgeStatus = AttendanceStatus.absent;
    }

    return AttendanceBadge(status: badgeStatus);
  }

  Widget _buildHorizontalCards() {
    return Column(
      children: [
        SizedBox(
          height: 280, // Increased height for new cards
          child: PageView(
            controller: _dashboardController,
            onPageChanged: (index) {
              setState(() {
                _currentDashboardIndex = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: [
              _buildLeaveBalanceCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildNewPayrollCard(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildNewThrCard(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentDashboardIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentDashboardIndex == index
                    ? AppTheme.colorEggplant
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SISA CUTI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _isLoadingLeave
                              ? '...'
                              : (_isEligibleLeave ? '$_leaveBalance ' : '- '),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        TextSpan(
                          text: 'Hari',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Conic Chart Simulation
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [AppTheme.colorCyan, Colors.grey.shade100],
                    stops: const [0.75, 0.75],
                    transform: const GradientRotation(-1.57), // Start from top
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.percent,
                        size: 16,
                        color: AppTheme.colorEggplant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  'Valid s/d Des',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEligibleLeave
                    ? 'Total jatah: $_leaveQuota hari'
                    : 'Belum Eligible',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateSubmissionScreen(type: 'Cuti'),
                    ),
                  ).then((_) {
                    _loadLeaveBalance(); // Refresh on return
                  });
                },
                child: Text(
                  'Ajukan →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorEggplant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildAnnouncements() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Informasi Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/announcements');
              },
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorEggplant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingAnnouncements)
          const Center(child: CircularProgressIndicator())
        else if (_announcements.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Text(
                  'Belum ada pengumuman terbaru',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _announcements.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentAnnouncementIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    final isNews = item['category'] == 'news';
                    final imagePath = item['image_path'];
                    final imageUrl = ApiConfig.getStorageUrl(imagePath);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: imageUrl == null
                            ? LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isNews
                                    ? [
                                        AppTheme.colorEggplant.withValues(
                                          alpha: 0.9,
                                        ),
                                        AppTheme.colorEggplant.withValues(
                                          alpha: 0.7,
                                        ),
                                      ]
                                    : [
                                        Colors.orange.shade800,
                                        Colors.orange.shade600,
                                      ],
                              )
                            : null,
                        image: imageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.3),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Gradient Overlay for Image
                          if (imageUrl != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.colorEggplant.withValues(
                                      alpha: 0.9,
                                    ),
                                  ],
                                  stops: const [0.3, 1.0],
                                ),
                              ),
                            ),

                          // Decorative Circles (Only if no image)
                          if (imageUrl == null) ...[
                            Positioned(
                              right: -10,
                              top: -10,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              right: -10,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                          ],

                          // Main Content
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AnnouncementDetailScreen(item: item),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isNews ? 'Berita' : 'Penting',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item['title'] ?? 'Pengumuman',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Baca selengkapnya',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_announcements.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentAnnouncementIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentAnnouncementIndex == index
                          ? AppTheme.colorEggplant
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final user = Provider.of<AuthProvider>(context).user;
    final canApprove = user?.canApprove ?? false;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': 'assets/icons/payslip.png',
        'isAsset': true,
        'label': 'Slip Gaji',
        'subtitle': 'Lihat slip',
        'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        'onTap': _navigateToPayroll,
      },
      {
        'icon': 'assets/icons/leave.png',
        'isAsset': true,
        'label': _isLoadingLeave ? 'Cuti' : 'Cuti ($_leaveBalance)',
        'subtitle': 'Ajukan cuti',
        'gradient': [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
        'onTap': () async {
          await Navigator.pushNamed(
            context,
            '/submission/create',
            arguments: 'Cuti',
          );
          _loadLeaveBalance();
        },
      },
      {
        'icon': 'assets/icons/history.png',
        'isAsset': true,
        'label': 'Riwayat',
        'subtitle': 'Kehadiran',
        'gradient': [const Color(0xFFF6D365), const Color(0xFFFDA085)],
        'onTap': () => Navigator.pushNamed(context, '/attendance/history'),
      },
      {
        'icon': 'assets/icons/overtime.png',
        'isAsset': true,
        'label': 'Lembur',
        'subtitle': 'Ajukan lembur',
        'gradient': [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)],
        'onTap': () => Navigator.pushNamed(context, '/submission/create', arguments: 'Lembur'),
      },
      {
        'icon': 'assets/icons/bussines-trip.png',
        'isAsset': true,
        'label': 'Dinas',
        'subtitle': 'Perjalanan',
        'gradient': [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)],
        'onTap': () => Navigator.pushNamed(context, '/submission/create', arguments: 'Dinas'),
      },
    ];

    if (canApprove) {
      menuItems.add({
        'icon': Icons.verified_rounded,
        'isAsset': false,
        'label': 'Approval',
        'subtitle': _pendingApprovalsCount > 0
            ? '$_pendingApprovalsCount pending'
            : 'Persetujuan',
        'gradient': [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
        'badge': _pendingApprovalsCount,
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApprovalListScreen()),
          );
          _loadPendingApprovals();
        },
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menu Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/submission/menu'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colorEggplant.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colorEggplant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppTheme.colorEggplant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: menuItems.length <= 3
              ? menuItems.length
              : (menuItems.length == 4 ? 4 : 3),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: menuItems.map((item) {
            return _buildActionItem(
              item['icon'],
              item['label'] as String,
              item['gradient'] as List<Color>,
              subtitle: item['subtitle'] as String,
              badgeCount: (item['badge'] as int?) ?? 0,
              isAsset: (item['isAsset'] as bool?) ?? false,
              onTap: item['onTap'] as VoidCallback?,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    dynamic icon,
    String label,
    List<Color> gradientColors, {
    String subtitle = '',
    VoidCallback? onTap,
    int badgeCount = 0,
    bool isAsset = false,
  }) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: isAsset
                          ? Image.asset(
                              icon as String,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.error_outline_rounded,
                                color: gradientColors[0],
                                size: 22,
                              ),
                            )
                          : Icon(icon as IconData, color: gradientColors[0], size: 28),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textLight.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terkini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            // Text(
            //   'Lihat Semua',
            //   style: TextStyle(
            //     fontSize: 12,
            //     fontWeight: FontWeight.bold,
            //     color: AppTheme.colorEggplant,
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingRecentActivities)
          const Center(child: CircularProgressIndicator())
        else if (_recentActivities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Belum ada aktivitas terkini.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Stack(
            children: [
              // Timeline Line
              Positioned(
                top: 16,
                bottom: 16,
                left: 19,
                child: Container(width: 2, color: Colors.grey.shade100),
              ),
              Column(
                children: _recentActivities.map((activity) {
                  IconData icon;
                  Color color;

                  switch (activity['type']) {
                    case 'attendance':
                      icon = Icons.access_time;
                      color = activity['status'] == 'success'
                          ? Colors.green
                          : Colors.orange;
                      if (activity['title'] == 'Absen Keluar') {
                        color = Colors.orange;
                      }
                      break;
                    case 'request':
                      icon = Icons.description;
                      color = activity['status'] == 'success'
                          ? Colors.green
                          : (activity['status'] == 'error'
                                ? Colors.red
                                : Colors.blue);
                      break;
                    case 'payroll':
                      icon = Icons.payments;
                      color = Colors.purple;
                      break;
                    default:
                      icon = Icons.notifications;
                      color = Colors.grey;
                  }

                  // Format time relative or absolute
                  final date = activity['date'] as DateTime;
                  final timeStr = DateFormat(
                    'dd MMM, HH:mm',
                    'id_ID',
                  ).format(date);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Circle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  if (activity['type'] == 'attendance')
                                    AttendanceBadge(
                                      status: activity['title'] == 'Absen Masuk' 
                                        ? (activity['status'] == 'success' ? AttendanceStatus.onTime : AttendanceStatus.late)
                                        : AttendanceStatus.onTime, // Assuming check out is usually onTime for now
                                      showDot: false,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity['desc'],
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }


  Widget _buildBanner(User? user) {
    if (user == null || user.contractEnd == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final contractDate = DateTime(
      user.contractEnd!.year,
      user.contractEnd!.month,
      user.contractEnd!.day,
    );

    final difference = contractDate.difference(today).inDays;

    if (difference > 30 || difference < -30) {
      return const SizedBox.shrink();
    }

    Color bgColor = Colors.orange.shade50;
    Color borderColor = Colors.orange.shade200;
    Color textColor = Colors.orange.shade800;
    IconData icon = Icons.warning_amber_rounded;
    String message =
        'Kontrak kerja Anda akan berakhir dalam $difference hari (${DateFormat('d MMM y', 'id_ID').format(contractDate)}). Silahkan hubungi HRD.';

    if (difference <= 7 && difference >= 0) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade800;
      icon = Icons.error_outline_rounded;
      message = 'URGENT: Kontrak berakhir dalam $difference hari!';
    } else if (difference < 0) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade800;
      icon = Icons.error_outline_rounded;
      message =
          'Kontrak kerja Anda telah berakhir pada ${DateFormat('d MMM y', 'id_ID').format(contractDate)}. Silahkan hubungi HRD.';
    } else if (difference == 0) {
      message = 'KONTRAK KERJA ANDA BERAKHIR HARI INI!';
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPayrollCard() {
    if (_isLoadingPayroll) {
      return SlipGajiCard(
        data: SlipGajiData(
          periode: 'Memuat...',
          status: SlipGajiStatus.belumAda,
        ),
      );
    }

    if (_lastPayroll == null) {
      return SlipGajiCard(
        data: SlipGajiData(
          periode: 'Belum ada data',
          status: SlipGajiStatus.belumAda,
          onDetail: () => Navigator.pushNamed(context, '/payroll'),
        ),
      );
    }

    final period = (_lastPayroll!['period'] ?? _lastPayroll!['period_start'] ?? '').toString();
    String formattedPeriod = period;
    try {
      if (period.contains('-')) {
        final date = DateTime.parse('$period-01');
        formattedPeriod = DateFormat('MMMM yyyy', 'id_ID').format(date);
      }
    } catch (_) {}

    final status = _lastPayroll!['status'] == 'selesai' || _lastPayroll!['status'] == 'paid'
        ? SlipGajiStatus.selesai
        : SlipGajiStatus.proses;

    return SlipGajiCard(
      data: SlipGajiData(
        periode: formattedPeriod,
        gajiPokok: _lastPayroll!['basic_salary']?.toString(),
        tunjangan: _lastPayroll!['allowance']?.toString(),
        total: _lastPayroll!['net_salary']?.toString() ?? _lastPayroll!['total_salary']?.toString(),
        status: status,
        updatedAt: _lastPayroll!['updated_at'] != null 
            ? DateFormat('d MMM HH:mm', 'id_ID').format(DateTime.parse(_lastPayroll!['updated_at']))
            : '',
        onUnduh: () => PayrollService().downloadSlip(
          _lastPayroll!['id'],
          'Slip_Gaji_$period.pdf',
          division: _lastPayroll!['division'],
        ),
        onDetail: () => Navigator.pushNamed(context, '/payroll'),
      ),
    );
  }

  Widget _buildNewThrCard() {
    if (_isLoadingThr) {
      return SlipThrCard(
        data: SlipThrData(
          tahun: '...',
        ),
      );
    }

    if (_lastThr == null) {
      return SlipThrCard(
        data: SlipThrData(
          tahun: DateTime.now().year.toString(),
          isAvailable: false,
          onDetail: () => Navigator.pushNamed(context, '/payroll/thr'),
        ),
      );
    }

    return SlipThrCard(
      data: SlipThrData(
        tahun: _lastThr!['year']?.toString() ?? '',
        isAvailable: _lastThr!['status'] == 'paid',
        updatedAt: _lastThr!['paid_at'] != null
            ? DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(_lastThr!['paid_at']))
            : '',
        onDetail: () => Navigator.pushNamed(context, '/payroll/thr'),
      ),
    );
  }
}
