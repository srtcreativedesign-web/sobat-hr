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
  Map<String, dynamic>? _todayAttendance;
  bool _isLoadingAttendance = true;
  int _leaveBalance = 0;
  int _leaveQuota = 12;
  bool _isEligibleLeave = true;
  bool _isLoadingLeave = true;

  @override
  void initState() {
    super.initState();
    // Data is loaded by AuthProvider in main.dart
    _loadTodayAttendance();
    _loadLeaveBalance();
    _loadLastPayroll();
    _loadAnnouncements();
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
      }
    } catch (e) {
      print('Error loading announcements: $e');
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

                  // Banner - REMOVED
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 24),
                  //   child: _buildBanner(),
                  // ),

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
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.colorCyan.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            (user?.name != null && user!.name.isNotEmpty)
                                ? user.name.substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colorEggplant,
                            ),
                          ),
                        ),
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
                                    ? user!.jobLevel!
                                    : (user?.role?.toUpperCase() ?? 'STAFF'))
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

                  // Notification Bell
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textDark,
                      size: 24,
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
    // Only show if user has office placement (and thus coordinates)
    // Using hasOfficeLocation field we added to User model
    // if (user == null || !user.hasOfficeLocation) {
    //   return const SizedBox.shrink();
    // }
    if (user == null) return const SizedBox.shrink(); // Safety check only

    // Format Date
    final now = DateTime.now();
    // Using intl package
    final formattedDate = DateFormat('EEEE, d MMM y', 'id_ID').format(now);

    // Determine Status
    String status = 'Belum Hadir';
    Color statusColor = Colors.orange;
    Color buttonColor = AppTheme.colorCyan;
    String buttonText = 'Clock In Sekarang';
    IconData buttonIcon = Icons.login;
    bool isButtonDisabled = false;

    // Weekend Check
    bool isWeekend =
        (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday);
    if (isWeekend) {
      status = 'Libur Akhir Pekan';
      statusColor = Colors.red;
      // Disable button or allow Overtime? User asked for "Sabtu Minggu Libur".
      // Let's disable for now to reflect "Libur".
      isButtonDisabled = true;
      buttonColor = Colors.grey;
      buttonText = 'Libur';
    }

    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayAttendance != null) {
      if (_todayAttendance!['check_out'] != null) {
        status = 'Sudah Selesai';
        statusColor = Colors.green;
        buttonText = 'Absen Selesai';
        isButtonDisabled = true;
        buttonColor = Colors.grey;
        buttonIcon = Icons.check_circle;
      } else if (_todayAttendance!['check_in'] != null) {
        // Only if check_in is valid
        status = 'Sedang Bekerja';
        statusColor = Colors.blue;
        buttonText = 'Clock Out Sekarang';
        buttonColor = AppTheme.colorEggplant;
        buttonIcon = Icons.logout;
        isButtonDisabled =
            false; // Enable if working, even on weekends if data exists?
        // If data exists on weekend, assume they are working overtime.
      }
      // If check_in is null but record exists, we treat as default/error, or 'Belum Hadir'.
      // With isWeekend check above, 'Libur' might be overwritten if record exists?
      // If record exists (someone checked in on weekend), we should show status.
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KEHADIRAN HARI INI',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Times
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.login,
                            size: 16,
                            color: AppTheme.colorCyan,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'JAM MASUK',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                  : _todayAttendance!['check_in'].toString())
                            : '--:--',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 16,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'JAM KELUAR',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                  : _todayAttendance!['check_out'].toString())
                            : '--:--',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isButtonDisabled
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        '/attendance',
                      ).then((_) => _loadTodayAttendance());
                    },
              icon: Icon(buttonIcon),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                                ? NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(
                                    double.tryParse(
                                          _lastPayroll!['net_salary']
                                              .toString(),
                                        ) ??
                                        0,
                                  )
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
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final item = _announcements[index];
                final isNews = item['category'] == 'news';

                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isNews
                          ? [
                              AppTheme.colorEggplant.withValues(alpha: 0.9),
                              AppTheme.colorEggplant.withValues(alpha: 0.7),
                            ]
                          : [Colors.orange.shade800, Colors.orange.shade600],
                    ),
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
                      // Decorative Circles
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isNews ? 'PENGUMUMAN' : 'KEBIJAKAN',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Text(
                                    item['title'] ?? 'No Title',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildQuickActions() {
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
              onTap: () {
                // Navigate to full menu or show bottom sheet
                Navigator.pushNamed(context, '/submission/menu');
              },
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colorEggplant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              Icons.description_outlined,
              'Slip Gaji',
              AppTheme.colorEggplant,
              onTap: _navigateToPayroll,
            ),
            _buildActionItem(
              Icons.flight_takeoff,
              _isLoadingLeave ? 'Cuti' : 'Cuti ($_leaveBalance)',
              Colors.blue,
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/submission/create',
                  arguments: 'Cuti',
                );
                _loadLeaveBalance(); // Refresh on return
              },
            ),
            _buildActionItem(
              Icons.attach_money,
              'Klaim',
              Colors.teal,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/submission/create',
                  arguments: 'Reimbursement',
                );
              },
            ),
            _buildActionItem(
              Icons.history_outlined,
              'Riwayat Kehadiran',
              Colors.orange,
              onTap: () {
                Navigator.pushNamed(context, '/attendance/history');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () {},
              borderRadius: BorderRadius.circular(16),
              child: Center(child: Icon(icon, color: color, size: 28)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
      ],
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
            Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.colorEggplant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              children: [
                _buildTimelineItem(
                  Icons.check_circle,
                  Colors.green,
                  'Cuti Tahunan Disetujui',
                  '2j yang lalu',
                  'Pengajuan cuti Anda untuk tanggal 24-25 Okt telah disetujui.',
                ),
                _buildTimelineItem(
                  Icons.schedule,
                  Colors.orange,
                  'Reimbursement Diproses',
                  '09:00',
                  'Klaim transportasi Anda sedang dalam peninjauan.',
                ),
                _buildTimelineItem(
                  Icons.payments,
                  Colors.blue,
                  'Gaji Masuk',
                  '25 Sep',
                  'Slip gaji periode September telah diterbitkan.',
                ),
              ],
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
}
