import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/organisms/attendance_badge.dart';

class RecentActivitySection extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;

  const RecentActivitySection({
    super.key,
    required this.activities,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.recentActivity,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              AppLocalizations.of(context)!.noRecentActivity,
              style: const TextStyle(color: Colors.grey),
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
                children: activities.map((activity) {
                  IconData? icon;
                  String? assetIcon;
                  Color color;
                  String title = '';
                  String desc = '';

                  final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
                  final date = activity['date'] as DateTime;

                  switch (activity['type']) {
                    case 'attendance':
                      icon = Icons.access_time;
                      color = activity['action'] == 'check_in'
                          ? (activity['status'] == 'success' ? Colors.green : Colors.orange)
                          : Colors.orange;
                      
                      final action = activity['action'];
                      final time = activity['time'] ?? '';
                      if (action == 'check_in') {
                        title = AppLocalizations.of(context)!.attendanceCheckIn;
                        desc = AppLocalizations.of(context)!.attendanceCheckInDesc(time);
                      } else {
                        title = AppLocalizations.of(context)!.attendanceCheckOut;
                        desc = AppLocalizations.of(context)!.attendanceCheckOutDesc(time);
                      }
                      break;

                    case 'request':
                      final reqType = activity['req_type'] ?? '';
                      final reqStatus = activity['req_status'] ?? 'pending';

                      // Translate type
                      String typeLabel = reqType;
                      final lowerType = reqType.toString().toLowerCase();
                      if (lowerType == 'leave' || lowerType == 'cuti') {
                        typeLabel = AppLocalizations.of(context)!.leave;
                        assetIcon = 'assets/icons/leave.png';
                        color = const Color(0xFF534AB7);
                      } else if (lowerType == 'sick_leave' || lowerType == 'sick' || lowerType == 'sakit') {
                        typeLabel = AppLocalizations.of(context)!.sick;
                        assetIcon = 'assets/icons/sick.png';
                        color = const Color(0xFFA32D2D);
                      } else if (lowerType == 'overtime' || lowerType == 'lembur') {
                        typeLabel = AppLocalizations.of(context)!.overtime;
                        assetIcon = 'assets/icons/overtime.png';
                        color = const Color(0xFF854F0B);
                      } else if (lowerType == 'business_trip' || lowerType == 'perjalanan dinas') {
                        typeLabel = AppLocalizations.of(context)!.businessTrip;
                        assetIcon = 'assets/icons/bussines-trip.png';
                        color = const Color(0xFF3B6D11);
                      } else if (lowerType == 'reimbursement') {
                        typeLabel = AppLocalizations.of(context)!.reimbursement;
                        assetIcon = 'assets/icons/reimburse.png';
                        color = const Color(0xFF534AB7);
                      } else if (lowerType == 'asset' || lowerType == 'pengajuan aset') {
                        typeLabel = AppLocalizations.of(context)!.assetLabel;
                        icon = Icons.description;
                        color = Colors.blue;
                      } else if (lowerType == 'resignation' || lowerType == 'resign') {
                        typeLabel = AppLocalizations.of(context)!.resignationLabel;
                        icon = Icons.description;
                        color = Colors.red;
                      } else {
                        icon = Icons.description;
                        color = activity['status'] == 'success'
                            ? Colors.green
                            : (activity['status'] == 'error'
                                  ? Colors.red
                                  : Colors.blue);
                      }

                      // Translate status
                      String statusLabel = reqStatus;
                      if (reqStatus == 'approved') {
                        statusLabel = AppLocalizations.of(context)!.approved;
                      } else if (reqStatus == 'rejected') {
                        statusLabel = AppLocalizations.of(context)!.rejected;
                      } else {
                        statusLabel = AppLocalizations.of(context)!.submitted;
                      }

                      title = '$typeLabel $statusLabel';

                      // Format date
                      String formattedDate = '-';
                      try {
                        if (activity['start_date'] != null) {
                          final dateObj = DateTime.parse(activity['start_date']);
                          formattedDate = DateFormat('d MMM y', localeName).format(dateObj);
                        } else if (activity['created_at'] != null) {
                          final dateObj = DateTime.parse(activity['created_at']);
                          formattedDate = DateFormat('d MMM y', localeName).format(dateObj);
                        }
                      } catch (_) {}

                      desc = AppLocalizations.of(context)!.submissionOf(typeLabel, formattedDate);
                      break;

                    case 'payroll':
                      assetIcon = 'assets/icons/payslip.png';
                      color = Colors.purple;
                      title = AppLocalizations.of(context)!.salaryTitle(DateFormat('MMMM', localeName).format(date));
                      desc = AppLocalizations.of(context)!.payslipPublished;
                      break;

                    default:
                      icon = Icons.notifications;
                      color = Colors.grey;
                      title = activity['title'] ?? 'Notification';
                      desc = activity['desc'] ?? '';
                  }

                  // Format time relative or absolute
                  final timeStr = activity['type'] == 'payroll'
                      ? DateFormat('dd MMM yyyy', localeName).format(date)
                      : DateFormat('dd MMM, HH:mm', localeName).format(date);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        assetIcon != null
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.asset(assetIcon, fit: BoxFit.contain),
                              )
                            : Icon(icon, color: color, size: 24),
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
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  if (activity['type'] == 'attendance')
                                    AttendanceBadge(
                                      status: activity['action'] == 'check_in' 
                                        ? (activity['status'] == 'success' ? AttendanceStatus.onTime : AttendanceStatus.late)
                                        : AttendanceStatus.onTime, // Assuming check out is usually onTime for now
                                      showDot: false,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
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
}
