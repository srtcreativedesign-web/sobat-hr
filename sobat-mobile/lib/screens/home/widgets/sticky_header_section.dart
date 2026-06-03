import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../config/api_config.dart';
import '../../../models/user.dart';

class StickyHeaderSection extends StatelessWidget {
  final User? user;
  final int notificationCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const StickyHeaderSection({
    super.key,
    required this.user,
    required this.notificationCount,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.colorCyan.withAlpha(50),
                          backgroundImage:
                              (currentUser?.avatar != null && currentUser!.avatar!.isNotEmpty)
                              ? CachedNetworkImageProvider(
                                  ApiConfig.getStorageUrl(currentUser.avatar!) ?? '',
                                )
                              : null,
                          child: (currentUser?.avatar == null || (currentUser?.avatar?.isEmpty ?? true))
                              ? Text(
                                  (currentUser?.name != null && currentUser!.name.isNotEmpty)
                                      ? currentUser.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.colorEggplant,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentUser?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              (currentUser?.jobLevel?.isNotEmpty == true
                                      ? currentUser!.jobLevel!.replaceAll('_', ' ')
                                      : (currentUser?.position?.isNotEmpty == true
                                            ? currentUser!.position!
                                            : (currentUser?.role?.toUpperCase() ??
                                                  'STAFF')))
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell
                  GestureDetector(
                    onTap: onNotificationTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: AppTheme.textDark,
                            size: 24,
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  notificationCount > 99
                                      ? '99+'
                                      : notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
