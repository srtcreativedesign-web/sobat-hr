import 'package:sobat_hr/config/api_config.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

import 'package:intl/intl.dart';
import '../profile/enroll_face_screen.dart'; // Added
import '../approval/approval_list_screen.dart'; // Added
import '../../services/approval_service.dart'; // Added for badge
import '../../services/notification_service.dart'; // Added for notif badge

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
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = true;

  // Carousel State
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentAnnouncementIndex = 0;
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    // Data is loaded by AuthProvider in main.dart
    _loadTodayAttendance();
    _loadLeaveBalance();
    _loadLastPayroll();
    _loadAnnouncements();
    _loadRecentActivities();
    _checkFaceEnrollment();
    _loadPendingApprovals();
    _loadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAnnouncement();
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
                              child: Image.network(
                                ApiConfig.getStorageUrl(banner['image_path']) ??
                                    '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (ctx, err, stack) {
                                  debugPrint(
                                    'Error loading banner image: $err',
                                  );
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
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.colorEggplant,
                                        value:
                                            progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                            : null,
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
      debugPrint('Error checking announcement: $e');
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
      debugPrint('Error loading recent activity: $e');
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
      print('Error loading pending approvals: $e');
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
      print('Error loading leave: $e');
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
      print('Error loading attendance: $e');
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
      debugPrint('Error loading announcements: $e');
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
          debugPrint('Failed to sort payrolls in home: $e');
        }

        setState(() {
          _lastPayroll = payrolls.isNotEmpty ? payrolls.first : null;
          _isLoadingPayroll = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingPayroll = false);
      }
    } catch (e) {
      debugPrint('Error loading last payroll: $e');
      if (mounted) setState(() => _isLoadingPayroll = false);
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
        debugPrint('Error loading attendance history: $e');
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
        debugPrint('Error loading requests: $e');
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
        debugPrint('Error loading payrolls activity: $e');
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
      debugPrint('Error consolidating activities: $e');
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
                  Navigator.pushNamed(context, '/profile').then((_) {
                    if (mounted) setState(() => _selectedIndex = 0);
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
    ]);
  }

  Widget _buildDashboardContent(User? user) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.colorEggplant,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure scroll even if content is short
        slivers: [
          // 1. Sticky Header
          _buildStickyHeader(user),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ringkasan aktivitas dan data penting Anda.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Attendance Card
                  // Attendance Card (hidden for operational staff)
                  if (user?.track != 'operational') _buildAttendanceCard(user),
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

                  // Bottom padding for floating nav
                  const SizedBox(height: 120),
                ],
              ),
            ),
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
                              ? NetworkImage(
                                  ApiConfig.getStorageUrl(user.avatar!) ?? '',
                                )
                              : null,
                          child: (user?.avatar == null || user!.avatar!.isEmpty)
                              ? Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name[0].toUpperCase()
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
    String status = 'Belum Hadir';
    Color statusColor = Colors.orange;
    String buttonText = 'Clock In Sekarang';
    IconData buttonIcon = Icons.login;
    bool isButtonDisabled = false;

    // Weekend Check
    bool isWeekend =
        (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday);
    if (isWeekend) {
      status = 'Libur Akhir Pekan';
      statusColor = Colors.redAccent;
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
        status = 'Sudah Selesai';
        statusColor = Colors.lightGreenAccent;
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
          debugPrint('Error parsing check_in time: $e');
        }

        if (statusStr == 'pending') {
          if (isLate) {
            status = 'Telat - Menunggu Approval';
            statusColor = Colors.orangeAccent;
            buttonText = 'Menunggu Approval';
            buttonIcon = Icons.timer;
            isButtonDisabled = true;
          } else {
            status = 'Menunggu Approval';
            statusColor = Colors.amberAccent;
            buttonText = 'Clock Out Sekarang';
            buttonIcon = Icons.logout;
            isButtonDisabled = false;
          }
        } else if (statusStr == 'rejected') {
          status = 'Absensi Ditolak';
          statusColor = Colors.redAccent;
          buttonText = 'Ditolak';
          isButtonDisabled = true;
          buttonIcon = Icons.cancel;
        } else {
          // Present / Approved
          status = 'Sedang Bekerja';
          statusColor = Colors.lightBlueAccent;
          buttonText = 'Clock Out Sekarang';
          buttonIcon = Icons.logout;
          isButtonDisabled = false;
        }
      }
    }

    // Gradient Colors based on status (simplified)
    // Gradient & Text Colors
    List<Color> gradientColors = AppTheme.gradientDefault;
    Color textColor = AppTheme.colorEggplant;
    Color subTextColor = AppTheme.colorEggplant.withValues(alpha: 0.7);
    Color glassBorderColor = AppTheme.colorEggplant.withValues(alpha: 0.1);
    Color buttonTextColor = AppTheme.colorEggplant;

    if (status == 'Sedang Bekerja') {
      gradientColors = AppTheme.gradientWorking;
      textColor = Colors.white;
      subTextColor = Colors.white.withValues(alpha: 0.7);
      glassBorderColor = Colors.white.withValues(alpha: 0.1);
      buttonTextColor = gradientColors[0];
    } else if (status == 'Sudah Selesai') {
      gradientColors = AppTheme.gradientFinished;
      textColor = Colors.white;
      subTextColor = Colors.white.withValues(alpha: 0.7);
      glassBorderColor = Colors.white.withValues(alpha: 0.1);
      buttonTextColor = gradientColors[0];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional subtle circles)
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Real-time Clock
                        StreamBuilder(
                          stream: Stream.periodic(
                            const Duration(seconds: 1),
                            (i) => i,
                          ),
                          builder: (context, snapshot) {
                            return Text(
                              DateFormat('HH:mm:ss').format(DateTime.now()),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: statusColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Times Container (Glassmorphism)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: glassBorderColor),
                  ),
                  child: Row(
                    children: [
                      // Check In
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  color: subTextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'JAM MASUK',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_todayAttendance != null &&
                                      _todayAttendance!['check_in'] != null)
                                  ? (_todayAttendance!['check_in']
                                                .toString()
                                                .length >=
                                            5
                                        ? _todayAttendance!['check_in']
                                              .toString()
                                              .substring(0, 5)
                                        : _todayAttendance!['check_in']
                                              .toString())
                                  : '--:--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: glassBorderColor),
                      const SizedBox(width: 16),
                      // Check Out
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: subTextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'JAM KELUAR',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_todayAttendance != null &&
                                      _todayAttendance!['check_out'] != null)
                                  ? (_todayAttendance!['check_out']
                                                .toString()
                                                .length >=
                                            5
                                        ? _todayAttendance!['check_out']
                                              .toString()
                                              .substring(0, 5)
                                        : _todayAttendance!['check_out']
                                              .toString())
                                  : '--:--',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isButtonDisabled
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              '/attendance',
                            ).then((_) => _loadTodayAttendance());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Widget _buildHorizontalCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Card 1: Leave Balance
          Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
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
                                    : (_isEligibleLeave
                                          ? '$_leaveBalance '
                                          : '- '),
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
                          transform: const GradientRotation(
                            -1.57,
                          ), // Start from top
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppTheme.success,
                      ),
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
                      // Wrap text with InkWell or similar
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
          ),

          // Card 2: Salary Slip (Dark Gradient)
          Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.colorEggplant,
                  AppTheme.colorEggplant.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colorEggplant.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: _navigateToPayroll,
              child: Stack(
                children: [
                  Positioned(
                    top: -10,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Slip Gaji Terakhir',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLoadingPayroll
                                    ? 'Memuat...'
                                    : _lastPayroll != null
                                    ? () {
                                        final periodStr =
                                            _lastPayroll!['period'] ??
                                            _lastPayroll!['period_start'];
                                        if (periodStr != null) {
                                          // Handle YYYY-MM format by appending -01
                                          final dateStr =
                                              periodStr.toString().length == 7
                                              ? '$periodStr-01'
                                              : periodStr.toString();
                                          return 'Periode ${DateFormat('MMM yyyy', 'id_ID').format(DateTime.parse(dateStr))}';
                                        }
                                        return 'Belum ada data';
                                      }()
                                    : 'Belum ada data',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingPayroll
                                ? '...'
                                : _lastPayroll != null
                                ? 'Rp  * * * * * *'
                                : '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '*Ketuk untuk melihat detail',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Builder(
                              builder: (context) {
                                final status = _lastPayroll != null
                                    ? _lastPayroll!['status']
                                    : 'pending';
                                Color color;
                                String text;

                                if (status == 'paid') {
                                  color = const Color(0xFF86EFAC); // Green
                                  text = 'Sudah Ditransfer';
                                } else if (status == 'approved') {
                                  color = Colors.lightBlueAccent; // Blue
                                  text = 'Disetujui';
                                } else {
                                  color = Colors.amberAccent; // Orange/Yellow
                                  text = 'Proses';
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: color,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                                image: NetworkImage(imageUrl),
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
    // final jobLevel = user?.jobLevel?.toLowerCase() ?? ''; // Removed
    // final role = user?.role?.toLowerCase() ?? ''; // Removed
    final canApprove = user?.canApprove ?? false;

    final menuItems = <Map<String, dynamic>>[
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Slip Gaji',
        'subtitle': 'Lihat slip',
        'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        'onTap': _navigateToPayroll,
      },
      {
        'icon': Icons.flight_takeoff_rounded,
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
        'icon': Icons.history_rounded,
        'label': 'Riwayat',
        'subtitle': 'Kehadiran',
        'gradient': [const Color(0xFFF6D365), const Color(0xFFFDA085)],
        'onTap': () => Navigator.pushNamed(context, '/attendance/history'),
      },
      if (canApprove)
        {
          'icon': Icons.verified_rounded,
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
        },
    ];

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
              item['icon'] as IconData,
              item['label'] as String,
              item['gradient'] as List<Color>,
              subtitle: item['subtitle'] as String,
              badgeCount: (item['badge'] as int?) ?? 0,
              onTap: item['onTap'] as VoidCallback?,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    List<Color> gradientColors, {
    String subtitle = '',
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
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
                      if (activity['title'] == 'Absen Keluar')
                        color = Colors.orange;
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

                  return _buildTimelineItem(
                    icon,
                    color,
                    activity['title'],
                    timeStr,
                    activity['desc'],
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    Color color,
    String title,
    String time,
    String desc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(User? user) {
    if (user == null || user.contractEnd == null)
      return const SizedBox.shrink();

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
}
