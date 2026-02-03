import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../feedback/feedback_screen.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck && isSupported;
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Section
            _buildSectionTitle(AppLocalizations.of(context)!.account),
            const SizedBox(height: 12),
            _buildStandardCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: AppLocalizations.of(context)!.changePassword,
                    subtitle: AppLocalizations.of(context)!.changePasswordDesc,
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed('/profile/change-password');
                    },
                  ),
                  if (_canCheckBiometrics) ...[
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.fingerprint,
                      title: 'Biometric Authentication',
                      subtitle: 'Enable fingerprint/face unlock',
                      trailing: Switch(
                        value: auth.biometricEnabled,
                        activeThumbColor: AppTheme.colorCyan,
                        onChanged: (val) =>
                            _handleBiometricToggle(context, auth, val),
                      ),
                      onTap: () => _handleBiometricToggle(
                        context,
                        auth,
                        !auth.biometricEnabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Section
            _buildSectionTitle(AppLocalizations.of(context)!.application),
            const SizedBox(height: 12),
            _buildStandardCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.language,
                    title: AppLocalizations.of(context)!.language,
                    subtitle: localeProvider.locale?.languageCode == 'en'
                        ? AppLocalizations.of(context)!.english
                        : AppLocalizations.of(context)!.indonesian,
                    onTap: () => _showLanguageSelector(context, localeProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSectionTitle(AppLocalizations.of(context)!.helpSupport),
            const SizedBox(height: 12),
            _buildStandardCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: AppLocalizations.of(context)!.helpCenter,
                    subtitle: AppLocalizations.of(context)!.helpCenterDesc,
                    onTap: () => _showHelpCenter(context),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.feedback_outlined,
                    title: AppLocalizations.of(context)!.sendFeedback,
                    subtitle: AppLocalizations.of(context)!.sendFeedbackDesc,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: AppLocalizations.of(context)!.privacyPolicy,
                    subtitle: AppLocalizations.of(context)!.privacyPolicyDesc,
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: AppLocalizations.of(context)!.termsConditions,
                    subtitle: AppLocalizations.of(context)!.termsConditionsDesc,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppTheme.error, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.logout,
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
                '© 2026 SOBAT HR v1.0.0\n${AppLocalizations.of(context)!.madeWithLove}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
            ),
          ],
        ),
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

  // --- Helper Methods (Copied from ProfileScreen logic) ---

  Future<void> _handleBiometricToggle(
    BuildContext context,
    AuthProvider auth,
    bool value,
  ) async {
    if (value) {
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometrics',
          persistAcrossBackgrounding: true,
          biometricOnly: false,
          sensitiveTransaction: false,
        );
        if (didAuthenticate) {
          await auth.toggleBiometric(true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      await auth.toggleBiometric(false);
    }
  }

  void _showLanguageSelector(BuildContext context, LocaleProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(context)!.indonesian),
                trailing: provider.locale?.languageCode == 'id'
                    ? Icon(Icons.check, color: AppTheme.colorCyan)
                    : null,
                onTap: () {
                  provider.setLocale(const Locale('id'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text(AppLocalizations.of(context)!.english),
                trailing: provider.locale?.languageCode == 'en'
                    ? Icon(Icons.check, color: AppTheme.colorCyan)
                    : null,
                onTap: () {
                  provider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(AppLocalizations.of(context)!.logout),
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
              const Text(
                'Dengan menggunakan aplikasi SOBAT HR, Anda menyetujui syarat dan ketentuan berikut:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildPolicySection(
                'Penggunaan Aplikasi',
                'Aplikasi ini hanya untuk penggunaan internal karyawan perusahaan. Dilarang keras menyalahgunakan akses atau data dalam aplikasi.',
              ),
              _buildPolicySection(
                'Akurasi Data',
                'Anda bertanggung jawab untuk memberikan data yang akurat dan terkini. Data palsu dapat mengakibatkan sanksi administratif.',
              ),
              _buildPolicySection(
                'Kerahasiaan Akun',
                'Anda bertanggung jawab menjaga kerahasiaan password akun Anda. Jangan berikan akses akun Anda kepada orang lain.',
              ),
              _buildPolicySection(
                'Pembaruan Ketentuan',
                'Perusahaan berhak mengubah syarat dan ketentuan ini sewaktu-waktu tanpa pemberitahuan sebelumnya.',
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

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.colorCyan,
            ),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
