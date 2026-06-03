import 'package:sobat_hr/config/api_config.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/custom_navbar.dart';
import '../../models/user.dart';
import '../../l10n/app_localizations.dart';

import '../../screens/submission/submission_screen.dart';
import '../../services/announcement_service.dart';

import 'package:intl/intl.dart';
import '../profile/enroll_face_screen.dart'; // Added
import '../../services/offline_attendance_service.dart';
import '../finance/finance_coming_soon_screen.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/sticky_header_section.dart';
import 'widgets/banner_section.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/announcements_section.dart';
import 'widgets/horizontal_cards_section.dart';
import 'widgets/attendance_card_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkFaceEnrollment();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch all dashboard data via HomeProvider
      Provider.of<HomeProvider>(context, listen: false).reloadAllData();
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
            title: Text(AppLocalizations.of(context)!.faceEnrollTitle),
            content: Text(AppLocalizations.of(context)!.faceEnrollDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppLocalizations.of(context)!.faceEnrollLater,
                  style: const TextStyle(color: Colors.grey),
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
                child: Text(AppLocalizations.of(context)!.faceEnrollNow),
              ),
            ],
          ),
        );
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppLocalizations.of(context)!.goodMorning;
    } else if (hour < 17) {
      return AppLocalizations.of(context)!.goodAfternoon;
    } else {
      return AppLocalizations.of(context)!.goodEvening;
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
    // Reload all data using HomeProvider
    await Provider.of<HomeProvider>(context, listen: false).reloadAllData();
    await OfflineAttendanceService().syncAllUnsyncedAttendances();
  }

  Widget _buildDashboardContent(User? user) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
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
              StickyHeaderSection(
                user: user,
                notificationCount: homeProvider.notificationCount,
                onProfileTap: () {
                  Navigator.pushNamed(context, '/profile').then((_) {
                    if (!mounted) return;
                    Provider.of<AuthProvider>(context, listen: false).refreshProfile();
                  });
                },
                onNotificationTap: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  homeProvider.loadNotifications();
                },
              ),

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
                                    localeName,
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
                                        TextSpan(text: '${AppLocalizations.of(context)!.greetingHello} '),
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
                                    '👌🏻',
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
                      AttendanceCardSection(
                        user: user,
                        todayAttendance: homeProvider.todayAttendance,
                        isLoadingAttendance: homeProvider.isLoadingAttendance,
                        onRefreshAttendance: () => homeProvider.loadTodayAttendance(),
                      ),
                      const SizedBox(height: 24),

                      // Horizontal Cards (Carousel)
                      HorizontalCardsSection(
                        leaveBalance: homeProvider.leaveBalance,
                        leaveQuota: homeProvider.leaveQuota,
                        isEligibleLeave: homeProvider.isEligibleLeave,
                        isLoadingLeave: homeProvider.isLoadingLeave,
                        isLoadingPayroll: homeProvider.isLoadingPayroll,
                        lastPayroll: homeProvider.lastPayroll,
                        isLoadingThr: homeProvider.isLoadingThr,
                        lastThr: homeProvider.lastThr,
                        onRefreshLeave: () => homeProvider.loadLeaveBalance(),
                      ),

                      const SizedBox(height: 32),

                      // Announcements
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AnnouncementsSection(
                          announcements: homeProvider.announcements,
                          isLoadingAnnouncements: homeProvider.isLoadingAnnouncements,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: QuickActionsSection(
                          user: user,
                          pendingApprovalsCount: homeProvider.pendingApprovalsCount,
                          leaveBalance: homeProvider.leaveBalance,
                          isLoadingLeave: homeProvider.isLoadingLeave,
                          onRefreshLeave: () => homeProvider.loadLeaveBalance(),
                          onRefreshApprovals: () => homeProvider.loadPendingApprovals(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: BannerSection(
                          user: user,
                        ),
                      ),

                      // const SizedBox(height: 32);

                      // Recent Activity
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: RecentActivitySection(
                          activities: homeProvider.recentActivities,
                          isLoading: homeProvider.isLoadingRecentActivities,
                        ),
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
}
