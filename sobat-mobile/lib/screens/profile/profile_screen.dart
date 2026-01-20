import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate-50 background
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // 1. Sticky Header
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      toolbarHeight: 70,
                      title: Text(
                        'Profil Saya',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      centerTitle: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {},
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 16),
                      ],
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Profile Card
                            _buildProfileCard(context, user),

                            const SizedBox(height: 24),

                            // Account Section
                            _buildSectionTitle('Akun'),
                            const SizedBox(height: 12),
                            _buildStandardCard(
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.person_outline,
                                    title: 'Edit Profil',
                                    subtitle: 'Ubah informasi pribadi Anda',
                                    onTap: () async {
                                      final res = await Navigator.of(
                                        context,
                                      ).pushNamed('/profile/edit');
                                      if (res == true) _refresh();
                                    },
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.lock_outline,
                                    title: 'Ubah Password',
                                    subtitle: 'Perbarui kata sandi Anda',
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/profile/change-password');
                                    },
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.notifications_outlined,
                                    title: 'Notifikasi',
                                    subtitle: 'Atur preferensi notifikasi',
                                    trailing: Switch(
                                      value: true,
                                      onChanged: (value) =>
                                          _showComingSoon(context),
                                      activeColor: AppTheme.colorCyan,
                                      activeTrackColor: AppTheme.colorCyan
                                          .withValues(alpha: 0.2),
                                    ),
                                    onTap: null,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // App Section
                            _buildSectionTitle('Aplikasi'),
                            const SizedBox(height: 12),
                            _buildStandardCard(
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.language,
                                    title: 'Bahasa',
                                    subtitle: 'Indonesia',
                                    onTap: () => _showComingSoon(context),
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.dark_mode_outlined,
                                    title: 'Tema',
                                    subtitle: 'Light Mode',
                                    onTap: () => _showComingSoon(context),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Support Section
                            _buildSectionTitle('Bantuan & Dukungan'),
                            const SizedBox(height: 12),
                            _buildStandardCard(
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.help_outline,
                                    title: 'Pusat Bantuan',
                                    subtitle: 'FAQ dan panduan penggunaan',
                                    onTap: () => _showHelpCenter(context),
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.feedback_outlined,
                                    title: 'Kirim Feedback',
                                    subtitle: 'Bantu kami untuk lebih baik',
                                    onTap: () => _showComingSoon(context),
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.privacy_tip_outlined,
                                    title: 'Kebijakan Privasi',
                                    subtitle: 'Perlindungan data Anda',
                                    onTap: () => _showPrivacyPolicy(context),
                                  ),
                                  _buildDivider(),
                                  _buildMenuItem(
                                    icon: Icons.description_outlined,
                                    title: 'Syarat & Ketentuan',
                                    subtitle: 'Ketentuan penggunaan aplikasi',
                                    onTap: () => _showTermsConditions(context),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Logout Button
                            _buildStandardCard(
                              child: InkWell(
                                onTap: () => _confirmLogout(context, auth),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: AppTheme.error,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Keluar',
                                        style: TextStyle(
                                          color: AppTheme.error,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                '© 2026 SOBAT HR v1.0.0\nMade with ❤️ in Indonesia',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Navbar Overlay
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 32,
                  child: CustomNavbar(
                    currentIndex: 4,
                    onTap: (index) {
                      if (index == 0)
                        Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ),

                // Floating FAB
                Positioned(
                  bottom: 56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height: 64,
                      width: 64,
                      child: FloatingActionButton(
                        heroTag: 'profile_fab',
                        onPressed: () {},
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

  // STANDARD CARD STYLE
  Widget _buildStandardCard({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  // PROFILE CARD WITH GRADIENT
  Widget _buildProfileCard(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.colorEggplant,
            AppTheme.colorEggplant.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colorEggplant.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(
                    (user?.name?.isNotEmpty == true)
                        ? user!.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.colorCyan,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.colorEggplant, width: 2),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: AppTheme.colorEggplant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (user?.jobLevel != null)
                ? (user!.jobLevel!.toUpperCase().replaceAll('_', ' '))
                : (user?.role?.toUpperCase() ?? 'STAFF'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1,
            ),
          ),
          if (user?.organization != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.organization!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  user?.employeeId ?? 'ID: -',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.colorCyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.colorCyan, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.withValues(alpha: 0.1),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini akan segera hadir!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: AppTheme.colorCyan),
                  const SizedBox(width: 12),
                  const Text(
                    'Pusat Bantuan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildHelpItem(
                    'Bagaimana cara mengajukan cuti?',
                    'Buka menu Quick Actions > Pilih Cuti > Isi formulir pengajuan cuti',
                  ),
                  _buildHelpItem(
                    'Bagaimana cara melihat slip gaji?',
                    'Buka menu Dokumen > Pilih Slip Gaji > Pilih bulan yang ingin dilihat',
                  ),
                  _buildHelpItem(
                    'Lupa password, apa yang harus dilakukan?',
                    'Klik "Lupa Password" di halaman login, kemudian ikuti instruksi untuk reset password',
                  ),
                  _buildHelpItem(
                    'Bagaimana cara update profil?',
                    'Buka menu Profile > Edit Profil > Ubah informasi yang diperlukan',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.colorCyan),
            const SizedBox(width: 12),
            const Text('Kebijakan Privasi'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOBAT HR menghormati privasi Anda dan berkomitmen untuk melindungi data pribadi Anda.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildPolicySection(
                'Pengumpulan Data',
                'Kami mengumpulkan informasi yang Anda berikan saat mendaftar dan menggunakan aplikasi, termasuk nama, email, dan data kepegawaian.',
              ),
              _buildPolicySection(
                'Penggunaan Data',
                'Data Anda digunakan untuk menyediakan layanan HR, memproses pengajuan, dan komunikasi internal perusahaan.',
              ),
              _buildPolicySection(
                'Keamanan Data',
                'Kami menggunakan enkripsi dan praktik keamanan terbaik untuk melindungi data Anda dari akses yang tidak sah.',
              ),
              _buildPolicySection(
                'Hak Anda',
                'Anda memiliki hak untuk mengakses, memperbarui, atau menghapus data pribadi Anda kapan saja.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTermsConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: AppTheme.colorCyan),
            const SizedBox(width: 12),
            const Text('Syarat & Ketentuan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPolicySection(
                '1. Penggunaan Aplikasi',
                'Aplikasi ini hanya untuk karyawan resmi perusahaan. Setiap penyalahgunaan dapat berakibat pada tindakan disipliner.',
              ),
              _buildPolicySection(
                '2. Akun Pengguna',
                'Anda bertanggung jawab untuk menjaga kerahasiaan akun dan password Anda.',
              ),
              _buildPolicySection(
                '3. Konten',
                'Semua konten dalam aplikasi adalah milik perusahaan dan tidak boleh disebarluaskan tanpa izin.',
              ),
              _buildPolicySection(
                '4. Perubahan Layanan',
                'Kami berhak untuk mengubah atau menghentikan layanan tanpa pemberitahuan sebelumnya.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.colorCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business, color: AppTheme.colorCyan, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('SOBAT HR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Versi 1.0.0',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aplikasi Human Resource Management System yang memudahkan pengelolaan kepegawaian, absensi, cuti, dan payroll.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Dikembangkan oleh:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'SOBAT Development Team',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  onPressed: () => _showComingSoon(context),
                  color: AppTheme.colorCyan,
                ),
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => _showComingSoon(context),
                  color: AppTheme.colorCyan,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showComingSoon(context),
                  color: AppTheme.colorCyan,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
