// Modernized Submission Menu Screen
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/request_service.dart';

class SubmissionMenuScreen extends StatefulWidget {
  const SubmissionMenuScreen({super.key});

  @override
  State<SubmissionMenuScreen> createState() => _SubmissionMenuScreenState();
}

class _SubmissionMenuScreenState extends State<SubmissionMenuScreen> {
  int _leaveBalance = 0;
  bool _isLoadingBalance = true;
  final RequestService _requestService = RequestService();

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
  }

  Future<void> _loadLeaveBalance() async {
    try {
      final data = await _requestService.getLeaveBalance();
      if (mounted) {
        setState(() {
          _leaveBalance = data['balance'] ?? 0;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildWhiteSheet(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.0, -1.0),
          end: Alignment(0.0, 1.0),
          colors: [Color(0xFF1A1640), Color(0xFF2D2680), Color(0xFF4A3FA0)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Blobs
          Positioned(
            right: -30,
            top: -20,
            child: _buildBlob(160, const Color(0x597F77DD)),
          ),
          Positioned(
            left: -20,
            bottom: 20,
            child: _buildBlob(120, const Color(0x4D534AB7)),
          ),
          Positioned(
            right: 30,
            bottom: -10,
            child: _buildBlob(90, const Color(0x33AFA9EC)),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topbar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopButton(
                        Icons.chevron_left_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Submissions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xB2EEEDFE),
                          letterSpacing: 0.1,
                        ),
                      ),
                      _buildTopButton(Icons.search_rounded),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Hero Text
                  const Text(
                    'LAYANAN MANDIRI',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAFA9EC),
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola kebutuhan\nkerja kamu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEEEDFE),
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.calendar_today_rounded, '7 layanan'),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3C3489),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        Icons.access_time_rounded,
                        DateFormat('EEEE, d MMM', 'id_ID').format(DateTime.now()),
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

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }

  Widget _buildTopButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Icon(icon, color: const Color(0xFFEEEDFE), size: 18),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF7F77DD)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7F77DD)),
        ),
      ],
    );
  }

  Widget _buildWhiteSheet(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -28, 0),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F6F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Kehadiran & Waktu', '4 layanan'),
          const SizedBox(height: 14),
          _buildMenuItem(
            context,
            assetIcon: 'assets/icons/leave.png',
            iconColor: const Color(0xFF534AB7),
            bgColor: const Color(0xFFEEEDFE),
            title: 'Leave',
            subtitle: 'Ajukan cuti tahunan atau izin',
            trailingText: _isLoadingBalance ? '...' : '$_leaveBalance hari',
            isFirst: true,
            onTap:
                () => Navigator.pushNamed(
                  context,
                  '/submission/create',
                  arguments: 'Cuti',
                ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.medication_rounded,
            iconColor: const Color(0xFFA32D2D),
            bgColor: const Color(0xFFFFE4E4),
            title: 'Sick Leave',
            subtitle: 'Cuti sakit',
            onTap:
                () => Navigator.pushNamed(
                  context,
                  '/submission/create',
                  arguments: 'Sakit',
                ),
          ),
          _buildMenuItem(
            context,
            assetIcon: 'assets/icons/overtime.png',
            iconColor: const Color(0xFF854F0B),
            bgColor: const Color(0xFFFAEEDA),
            title: 'Overtime',
            subtitle: 'Ajukan lembur',
            onTap:
                () => Navigator.pushNamed(
                  context,
                  '/submission/create',
                  arguments: 'Lembur',
                ),
          ),
          _buildMenuItem(
            context,
            assetIcon: 'assets/icons/history.png',
            iconColor: const Color(0xFF3B6D11),
            bgColor: const Color(0xFFEAF3DE),
            title: 'History',
            subtitle: 'Riwayat pengajuan',
            isLast: true,
            onTap: () => Navigator.pushNamed(context, '/attendance/history'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Administrasi', '3 layanan'),
          const SizedBox(height: 14),
          _buildMenuItem(
            context,
            assetIcon: 'assets/icons/payslip.png',
            iconColor: const Color(0xFF854F0B),
            bgColor: const Color(0xFFFAEEDA),
            title: 'Slip THR',
            subtitle: 'Tunjangan Hari Raya',
            trailingText: 'Baru',
            isFirst: true,
            onTap: () => Navigator.pushNamed(context, '/payroll/thr'),
          ),
          _buildMenuItem(
            context,
            assetIcon: 'assets/icons/bussines-trip.png',
            iconColor: const Color(0xFF3B6D11),
            bgColor: const Color(0xFFEAF3DE),
            title: 'Perjalanan Dinas',
            subtitle: 'Business Trip',
          ),
          _buildMenuItem(
            context,
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF534AB7),
            bgColor: const Color(0xFFEEEDFE),
            title: 'Reimbursement',
            subtitle: 'Klaim pengeluaran',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2A)),
        ),
        Text(count, style: const TextStyle(fontSize: 11, color: Color(0xFF534AB7))),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    IconData? icon,
    String? assetIcon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    String? trailingText,
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD3D1C7), width: 0.5),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isFirst ? 16 : 4),
            bottom: Radius.circular(isLast ? 16 : 4),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: assetIcon != null
                  ? Image.asset(
                      assetIcon,
                      width: 44,
                      height: 44,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.error_outline_rounded, color: iconColor, size: 24),
                    )
                  : Container(
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB4B2A9), size: 14),
          ],
        ),
      ),
    );
  }
}
