import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/attendance_badge.dart';
import '../../attendance/offline_attendance_handler.dart';

class AttendanceCardSection extends StatefulWidget {
  final User? user;
  final Map<String, dynamic>? todayAttendance;
  final bool isLoadingAttendance;
  final VoidCallback onRefreshAttendance;

  const AttendanceCardSection({
    super.key,
    required this.user,
    required this.todayAttendance,
    required this.isLoadingAttendance,
    required this.onRefreshAttendance,
  });

  @override
  State<AttendanceCardSection> createState() => _AttendanceCardSectionState();
}

class _AttendanceCardSectionState extends State<AttendanceCardSection> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Live ticker updates clock and elapsed work duration in real-time
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) return const SizedBox.shrink();

    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM y', localeName).format(now);

    // Determine Status
    String buttonText = AppLocalizations.of(context)!.clockInNow;
    IconData buttonIcon = Icons.login;
    bool isButtonDisabled = false;

    // Weekend Check
    bool isWeekend = (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday);
    if (isWeekend) {
      isButtonDisabled = true;
      buttonText = AppLocalizations.of(context)!.dayOff;
    }

    if (widget.isLoadingAttendance) {
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

    if (widget.todayAttendance != null) {
      if (widget.todayAttendance!['check_out'] != null) {
        buttonText = AppLocalizations.of(context)!.attendanceDone;
        isButtonDisabled = true;
        buttonIcon = Icons.check_circle;
      } else if (widget.todayAttendance!['check_in'] != null) {
        String statusStr = widget.todayAttendance!['status']?.toString().toLowerCase() ?? '';
        String checkInTimeStr = widget.todayAttendance!['check_in'].toString();

        bool isLate = false;
        try {
          final parts = checkInTimeStr.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            if (hour > 8 || (hour == 8 && minute > 5)) {
              isLate = true;
            }
          }
        } catch (_) {}

        if (statusStr == 'pending') {
          if (isLate) {
            buttonText = AppLocalizations.of(context)!.waitingApproval;
            buttonIcon = Icons.timer;
            isButtonDisabled = true;
          } else {
            buttonText = AppLocalizations.of(context)!.clockOutNow;
            buttonIcon = Icons.logout;
            isButtonDisabled = false;
          }
        } else if (statusStr == 'rejected') {
          buttonText = AppLocalizations.of(context)!.attendanceRejected;
          isButtonDisabled = true;
          buttonIcon = Icons.cancel;
        } else {
          buttonText = AppLocalizations.of(context)!.clockOutNow;
          buttonIcon = Icons.logout;
          isButtonDisabled = false;
        }
      }
    }

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

    final bool hasShift = widget.user!.track != 'operational' && widget.user!.shiftStartTime != null && widget.user!.shiftEndTime != null;
    final shiftStart = hasShift
        ? parseShiftTime(widget.user!.shiftStartTime, DateTime(now.year, now.month, now.day, 8, 0))
        : DateTime(now.year, now.month, now.day, 8, 0);
    final shiftEnd = hasShift
        ? parseShiftTime(widget.user!.shiftEndTime, DateTime(now.year, now.month, now.day, 17, 0))
        : DateTime(now.year, now.month, now.day, 17, 0);
    final shiftLabel = hasShift
        ? "${AppLocalizations.of(context)!.shiftLabel} ${widget.user!.shiftStartTime!.substring(0, 5)} - ${widget.user!.shiftEndTime!.substring(0, 5)}"
        : '';

    // Attendance Data
    DateTime? checkInTime;
    DateTime? checkOutTime;
    if (widget.todayAttendance != null) {
      if (widget.todayAttendance!['check_in'] != null) {
        checkInTime = parseShiftTime(widget.todayAttendance!['check_in'].toString(), now);
      }
      if (widget.todayAttendance!['check_out'] != null) {
        checkOutTime = parseShiftTime(widget.todayAttendance!['check_out'].toString(), now);
      }
    }

    // Work Duration Calculation
    String durationLabel = AppLocalizations.of(context)!.durationHourMinute(0, 0);
    if (checkInTime != null) {
      final endTime = checkOutTime ?? now;
      final diff = endTime.difference(checkInTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      durationLabel = AppLocalizations.of(context)!.durationHourMinute(hours, minutes);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF89B4E1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF419CC3).withValues(alpha: 0.2),
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
                            color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Work Duration Badge
                    if (checkInTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.workDuration,
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
                if (hasShift)
                  _buildAttendanceTimeline(shiftStart, shiftEnd, checkInTime, checkOutTime),
              ],
            ),
          ),

          // Bottom Section: White
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 246, 246, 248),
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
                    if (hasShift)
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isButtonDisabled
                        ? null
                        : () {
                            if (widget.user!.track == 'operational') {
                              OfflineAttendanceHandler(context: context).startOfflineAttendance();
                            } else {
                              Navigator.pushNamed(context, '/attendance').then((_) => widget.onRefreshAttendance());
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF419CC3),
                      foregroundColor: const Color.fromARGB(255, 243, 243, 246),
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
                if (checkIn != null) _timelineDot(width * checkInProgress, const Color(0xFF97C459)),
                if (checkIn != null) _timelineDot(width * currentProgress, const Color(0xFFFBB03B)),
                _timelineDot(width, const Color(0xFF3C3489)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timelineLabelV2(
                  AppLocalizations.of(context)!.checkIn,
                  checkIn != null ? DateFormat('HH:mm').format(checkIn) : '--:--',
                  checkIn != null ? const Color(0xFF97C459) : null,
                ),
                _timelineLabelV2(
                  AppLocalizations.of(context)!.checkOut,
                  checkOut != null
                      ? DateFormat('HH:mm').format(checkOut)
                      : (checkIn != null ? DateFormat('HH:mm').format(DateTime.now()) : '--:--'),
                  checkIn != null ? const Color(0xFFFBB03B) : null,
                ),
                _timelineLabelV2(
                  AppLocalizations.of(context)!.doneLabel,
                  DateFormat('HH:mm').format(end),
                  Colors.white.withValues(alpha: 0.3),
                ),
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
      top: -2.5,
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

    if (widget.todayAttendance != null) {
      if (widget.todayAttendance!['check_out'] != null) {
        String statusStr = widget.todayAttendance!['status']?.toString().toLowerCase() ?? '';

        final user = Provider.of<AuthProvider>(context, listen: false).user;
        final shiftEndTimeStr = user?.shiftEndTime;
        if (shiftEndTimeStr != null && shiftEndTimeStr.contains(':')) {
          try {
            final now = DateTime.now();
            final parts = shiftEndTimeStr.split(':');
            final shiftEnd = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));

            String checkOutStr = widget.todayAttendance!['check_out'].toString();
            if (checkOutStr.length == 5) checkOutStr += ":00";

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
      } else if (widget.todayAttendance!['check_in'] != null) {
        badgeStatus = AttendanceStatus.inProgress;
      }
    } else if (isWeekend) {
      badgeStatus = AttendanceStatus.absent;
    }

    return AttendanceBadge(status: badgeStatus);
  }
}
