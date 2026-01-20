import 'package:flutter/material.dart';
import '../config/theme.dart';

class SubmissionCard extends StatelessWidget {
  final String title;
  final String date;
  final String status; // 'pending', 'approved', 'rejected'
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String detailLabel;
  final VoidCallback? onTap;

  const SubmissionCard({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.detailLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        statusColor = const Color(0xFF059669); // Emerald 700
        statusBgColor = const Color(0xFFD1FAE5); // Emerald 100
        statusText = 'Disetujui';
        break;
      case 'rejected':
      case 'ditolak':
        statusColor = const Color(0xFFBE123C); // Rose 700
        statusBgColor = const Color(0xFFFFE4E6); // Rose 100
        statusText = 'Ditolak';
        break;
      case 'pending':
      case 'menunggu':
      default:
        statusColor = const Color(0xFFC2410C); // Orange 700
        statusBgColor = const Color(0xFFFFEDD5); // Orange 100
        statusText = 'Menunggu';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    // Title & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      detailLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textLight,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppTheme.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
