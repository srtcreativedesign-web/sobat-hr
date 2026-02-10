import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

import '../../widgets/custom_navbar.dart';
import '../../l10n/app_localizations.dart';

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
                        AppLocalizations.of(context)!.myProfile,
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
                          onPressed: () {
                            Navigator.pushNamed(context, '/settings');
                          },
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

                            // Account Action (Edit Profile)
                            _buildSectionTitle(
                              AppLocalizations.of(context)!.account,
                            ),
                            const SizedBox(height: 12),
                            _buildStandardCard(
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.person_outline,
                                    title: AppLocalizations.of(
                                      context,
                                    )!.editProfile,
                                    subtitle: AppLocalizations.of(
                                      context,
                                    )!.editProfileDesc,
                                    onTap: () async {
                                      final res = await Navigator.of(
                                        context,
                                      ).pushNamed('/profile/edit');
                                      if (res == true) _refresh();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                '© 2026 SOBAT HR v1.0.0\n${AppLocalizations.of(context)!.madeWithLove}',
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
                      if (index == 0) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      } else if (index == 1) {
                        Navigator.pushNamed(context, '/submission/list');
                      } else if (index == 3) {
                        // Wallet Button Disabled
                        // Navigator.pushNamed(context, '/payroll');
                      }
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
                        onPressed: () {
                          Navigator.pushNamed(context, '/submission/menu');
                        },
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C3ECA), // Deep Blue
            Color(0xFF60A5FA), // Soft Blue
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C3ECA).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Patterns
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Original Content
          Padding(
            padding: const EdgeInsets.all(24),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        backgroundImage: (user?.avatar != null)
                            ? NetworkImage(
                                ApiConfig.getStorageUrl(user!.avatar) ?? '',
                              )
                            : null,
                        child: (user?.avatar == null)
                            ? Text(
                                (user?.name?.isNotEmpty == true)
                                    ? user!.name.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/profile/edit');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF1C3ECA),
                          ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (user?.jobLevel != null && user!.jobLevel!.isNotEmpty)
                        ? (user!.jobLevel!.toUpperCase().replaceAll('_', ' '))
                        : (user?.position != null && user!.position!.isNotEmpty)
                        ? user!.position!.toUpperCase()
                        : (user?.role?.toUpperCase() ?? 'STAFF'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (user?.organization != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    user!.organization!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user?.employeeId ?? 'ID: -',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
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
}
