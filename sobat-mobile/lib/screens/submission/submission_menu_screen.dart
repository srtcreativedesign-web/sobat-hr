import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SubmissionMenuScreen extends StatelessWidget {
  const SubmissionMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppTheme.textDark),
        centerTitle: true,
        title: const Text(
          'Menu Pengajuan',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          const Text(
            'Mau mengajukan\napa hari ini?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih jenis pengajuan yang sesuai dengan kebutuhan Anda.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Section 1: Kehadiran
          _buildSectionTitle('KEHADIRAN'),
          const SizedBox(height: 16),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildLargeCard(
                context,
                'Cuti',
                Icons.calendar_month,
                const Color(0xFFEA580C),
                const Color(0xFFFFF7ED),
              ),
              _buildLargeCard(
                context,
                'Sakit',
                Icons.thermostat,
                const Color(0xFFE11D48),
                const Color(0xFFFFF1F2),
              ),
              _buildLargeCard(
                context,
                'Lembur',
                Icons.schedule,
                AppTheme.info,
                AppTheme.info.withValues(alpha: 0.1),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Section 2: Administrasi
          _buildSectionTitle('ADMINISTRASI'),
          const SizedBox(height: 16),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3, // Slightly shorter cards for administration
            children: [
              _buildSmallCard(
                context,
                'Perjalanan Dinas',
                Icons.flight_takeoff,
                AppTheme.colorEggplant,
                AppTheme.colorCyan.withValues(alpha: 0.2),
              ),
              _buildSmallCard(
                context,
                'Reimbursement',
                Icons.attach_money,
                const Color(0xFF059669),
                const Color(0xFFD1FAE5),
              ),
              _buildSmallCard(
                context,
                'Pengajuan Aset',
                Icons.devices_other,
                const Color(0xFF7C3AED), // Violet 600
                const Color(0xFFEDE9FE), // Violet 100
              ),
              _buildSmallCard(
                context,
                'Resign',
                Icons.output,
                Colors.grey,
                Colors.grey.shade100,
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.colorCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/submission/create',
          arguments: label,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Color bgColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
