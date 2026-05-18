import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'invitation_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _connectivity = ConnectivityService();
  bool _isOnline = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isOnline;
    _subscription = _connectivity.onlineStatusStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD), // Match bottom gradient color
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE), // Sky 100
              Color(0xFFBAE6FD), // Sky 200
              Color(0xFF93C5FD), // Blue 300
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Offline Banner
              if (!_isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.orange.shade700,
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.offlineBannerLogin,
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      // 2. Logo / Title
                      const SizedBox(height: 20),
                const Text(
                  'SOBAT HR',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colorPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),

                // 3. Central Illustration
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Image.asset(
                      'assets/images/ilustrasi.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 4. Welcome Text
                Text(
                  AppLocalizations.of(context)!.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // 5. Action Buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(AppLocalizations.of(context)!.startNow),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _showInvitationDialog(context),
                  child: Text(
                    AppLocalizations.of(context)!.activationAccount,
                    style: const TextStyle(
                      color: AppTheme.colorPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvitationDialog(BuildContext context) {
    final linkController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.invitationTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.colorEggplant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.invitationDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: linkController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.invitationHint,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (linkController.text.isNotEmpty) {
                  Navigator.pop(context); // Close dialog
                  // Navigate to Invitation Webview
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          InvitationScreen(url: linkController.text.trim()),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.proceed),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
