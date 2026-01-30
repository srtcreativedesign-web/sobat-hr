import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

class SubmissionMenuScreen extends StatelessWidget {
  const SubmissionMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Cool Gray 50
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppTheme.textDark),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.submissions,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        children: [
          // Header
          const Text(
            'Layanan\nMandiri',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola kebutuhan kerja Anda dengan mudah.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textDark, // Uses darkened text color
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Section 1: Kehadiran (Colored Cards)
          _buildSectionTitle('KEHADIRAN & WAKTU'),
          const SizedBox(height: 16),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0, // Square-ish cards
            children: [
              _buildModernCard(
                context,
                AppLocalizations.of(context)!.leave,
                Icons.calendar_month_rounded,
                const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)], // Orange
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildModernCard(
                context,
                AppLocalizations.of(context)!.sick,
                Icons.medication_rounded,
                const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFE11D48)], // Rose
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildModernCard(
                context,
                AppLocalizations.of(context)!.overtime,
                Icons.timer_rounded,
                const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildModernCard(
                context,
                AppLocalizations.of(context)!.history,
                Icons.history_rounded,
                const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // Violet
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () =>
                    Navigator.pushNamed(context, '/attendance/history'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Section 2: Administrasi (Clean Light Cards)
          _buildSectionTitle('ADMINISTRASI & LAINNYA'),
          const SizedBox(height: 16),
          _buildUtilityCard(
            context,
            'Perjalanan Dinas',
            'Business Trip',
            Icons.flight_takeoff_rounded,
            AppTheme.colorEggplant,
          ),
          const SizedBox(height: 12),
          /*
          _buildUtilityCard(
            context,
            'Reimbursement',
            'Klaim Biaya',
            Icons.receipt_long_rounded,
            const Color(0xFF059669),
          ),
          const SizedBox(height: 12),
          _buildUtilityCard(
            context,
            'Pengajuan Aset',
            'Pinjam Barang',
            Icons.devices_rounded,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 12),
          _buildUtilityCard(
            context,
            'Resign',
            'Pengunduran Diri',
            Icons.logout_rounded,
            AppTheme.textLight,
          ),
          */
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textLight,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildModernCard(
    BuildContext context,
    String label,
    IconData icon,
    Gradient gradient, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () => Navigator.pushNamed(
              context,
              '/submission/create',
              arguments: label,
            ),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (gradient.colors.first).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityCard(
    BuildContext context,
    String label,
    String subLabel,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/submission/create',
          arguments: label,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
            ), // Adjusted from shade100
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                // Fixed const
                Icons.chevron_right_rounded,
                color: AppTheme.textLight, // Fixed color
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
