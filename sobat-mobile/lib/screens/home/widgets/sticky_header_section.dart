import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../models/user.dart';

class StickyHeaderSection extends StatelessWidget {
  final User? user;
  final int notificationCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final String greeting;

  const StickyHeaderSection({
    super.key,
    required this.user,
    required this.notificationCount,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    final formattedDate = DateFormat('EEEE, d MMMM', localeName).format(DateTime.now());
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _GradientHeaderDelegate(
        user: user,
        notificationCount: notificationCount,
        onProfileTap: onProfileTap,
        onNotificationTap: onNotificationTap,
        greeting: greeting,
        formattedDate: formattedDate,
        topPadding: topPadding,
      ),
    );
  }
}

class _GradientHeaderDelegate extends SliverPersistentHeaderDelegate {
  final User? user;
  final int notificationCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final String greeting;
  final String formattedDate;
  final double topPadding;

  _GradientHeaderDelegate({
    required this.user,
    required this.notificationCount,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.greeting,
    required this.formattedDate,
    required this.topPadding,
  });

  @override
  double get minExtent => topPadding + 104.0;

  @override
  double get maxExtent => topPadding + 180.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double expandRatio = 1.0 - (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Container(
      color: const Color(0xFFF8FAFC), // Scaffold background color
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C3ECA), // AppTheme.colorPrimary
                Color(0xFF4F70E6), // Slightly lighter blue
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C3ECA).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top Row (Always visible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                              ? CachedNetworkImageProvider(ApiConfig.getStorageUrl(user!.avatar!) ?? '')
                              : null,
                          child: (user?.avatar == null || (user?.avatar?.isEmpty ?? true))
                              ? Text(
                                  (user?.name != null && user!.name.isNotEmpty) ? user!.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (user?.jobLevel?.isNotEmpty == true
                                    ? user!.jobLevel!.replaceAll('_', ' ')
                                    : (user?.position?.isNotEmpty == true
                                        ? user!.position!
                                        : (user?.role?.toUpperCase() ?? 'STAFF')))
                                .toUpperCase() +
                                (user?.organization != null ? ' • ${user!.organization}' : ''),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            if (notificationCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
              
              // Bottom Row (Fades out and translates down)
              if (expandRatio > 0)
                Positioned(
                  top: 48 + 20, // Avatar height + spacing
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: expandRatio,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - expandRatio)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting, ${(user?.name.split(' ').first ?? 'User').toLowerCase()}!',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$formattedDate • Stay consistent, make progress.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GradientHeaderDelegate oldDelegate) {
    return oldDelegate.user != user ||
        oldDelegate.notificationCount != notificationCount ||
        oldDelegate.greeting != greeting ||
        oldDelegate.formattedDate != formattedDate ||
        oldDelegate.topPadding != topPadding;
  }
}
