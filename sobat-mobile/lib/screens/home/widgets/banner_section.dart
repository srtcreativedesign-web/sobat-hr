import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';

class BannerSection extends StatelessWidget {
  final User? user;

  const BannerSection({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null || user!.contractEnd == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final contractDate = DateTime(
      user!.contractEnd!.year,
      user!.contractEnd!.month,
      user!.contractEnd!.day,
    );

    final difference = contractDate.difference(today).inDays;

    if (difference > 30 || difference < -30) {
      return const SizedBox.shrink();
    }

    Color bgColor = Colors.orange.shade50;
    Color borderColor = Colors.orange.shade200;
    Color textColor = Colors.orange.shade800;
    IconData icon = Icons.warning_amber_rounded;
    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    String message = AppLocalizations.of(context)!.contractExpiringIn(
      difference.toString(),
      DateFormat('d MMM y', localeName).format(contractDate),
    );

    if (difference <= 7 && difference >= 0) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade800;
      icon = Icons.error_outline_rounded;
      message = AppLocalizations.of(context)!.contractExpiringUrgent(difference.toString());
    } else if (difference < 0) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade800;
      icon = Icons.error_outline_rounded;
      message = AppLocalizations.of(context)!.contractExpired(
        DateFormat('d MMM y', localeName).format(contractDate),
      );
    } else if (difference == 0) {
      message = AppLocalizations.of(context)!.contractExpiredToday;
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
