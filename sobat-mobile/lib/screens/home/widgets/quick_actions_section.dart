import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../../approval/approval_list_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuickActionsSection extends StatelessWidget {
  final User? user;
  final int pendingApprovalsCount;
  final int leaveBalance;
  final bool isLoadingLeave;
  final VoidCallback onRefreshLeave;
  final VoidCallback onRefreshApprovals;

  const QuickActionsSection({
    super.key,
    required this.user,
    required this.pendingApprovalsCount,
    required this.leaveBalance,
    required this.isLoadingLeave,
    required this.onRefreshLeave,
    required this.onRefreshApprovals,
  });

  @override
  Widget build(BuildContext context) {
    final canApprove = user?.canApprove ?? false;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': 'assets/icons/payslip.png',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.payslip,
        'subtitle': AppLocalizations.of(context)!.viewPayslipShort,
        'color': const Color(0xFF667EEA),
        'onTap': () => Navigator.pushNamed(context, '/payroll'),
      },
      {
        'icon': 'assets/icons/anual_leave.svg',
        'isAsset': true,
        'label': isLoadingLeave 
            ? AppLocalizations.of(context)!.leave 
            : '${AppLocalizations.of(context)!.leave} ($leaveBalance)',
        'subtitle': AppLocalizations.of(context)!.applyLeave,
        'color': const Color(0xFF43E97B),
        'onTap': () async {
          await Navigator.pushNamed(
            context,
            '/submission/create',
            arguments: 'Cuti',
          );
          onRefreshLeave();
        },
      },
      {
        'icon': 'assets/icons/history.svg',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.history,
        'subtitle': AppLocalizations.of(context)!.attendance,
        'color': const Color(0xFFF6D365),
        'onTap': () => Navigator.pushNamed(context, '/attendance/history'),
      },
      {
        'icon': 'assets/icons/overtime.svg',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.overtime,
        'subtitle': AppLocalizations.of(context)!.applyOvertime,
        'color': const Color(0xFFFF9A9E),
        'onTap': () => Navigator.pushNamed(context, '/submission/create', arguments: 'Lembur'),
      },
      {
        'icon': 'assets/icons/BUSINESS TRIP.svg',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.businessTrip,
        'subtitle': AppLocalizations.of(context)!.businessTripShort,
        'color': const Color(0xFF84FAB0),
        'onTap': () => Navigator.pushNamed(context, '/submission/create', arguments: 'Perjalanan Dinas'),
      },
    ];

    if (canApprove) {
      menuItems.add({
        'icon': Icons.verified_rounded,
        'isAsset': false,
        'label': AppLocalizations.of(context)!.approvalLabel,
        'subtitle': pendingApprovalsCount > 0
            ? AppLocalizations.of(context)!.pendingCountText(pendingApprovalsCount.toString())
            : AppLocalizations.of(context)!.approvalSubtitle,
        'color': const Color(0xFFA18CD1),
        'badge': pendingApprovalsCount,
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApprovalListScreen()),
          );
          onRefreshApprovals();
        },
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.quickMenu,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/submission/menu'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.colorEggplant.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.allLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colorEggplant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.colorEggplant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.35, // Wider rectangular tiles
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildFeatureTile(
                item['icon'],
                item['label'] as String,
                item['color'] as Color,
                subtitle: item['subtitle'] as String,
                badgeCount: (item['badge'] as int?) ?? 0,
                isAsset: (item['isAsset'] as bool?) ?? false,
                onTap: item['onTap'] as VoidCallback?,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    dynamic icon,
    String label,
    Color baseColor, {
    String subtitle = '',
    VoidCallback? onTap,
    int badgeCount = 0,
    bool isAsset = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Faded Background Illustration
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Opacity(
                    opacity: 0.15,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: isAsset
                          ? (icon as String).endsWith('.svg')
                              ? SvgPicture.asset(icon)
                              : Image.asset(icon, fit: BoxFit.contain)
                          : Icon(icon as IconData, size: 80, color: baseColor),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon & Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: isAsset
                                ? (icon as String).endsWith('.svg')
                                    ? SvgPicture.asset(
                                        icon,
                                      )
                                    : Image.asset(
                                        icon,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.error_outline_rounded,
                                          color: baseColor,
                                          size: 24,
                                        ),
                                      )
                                : Icon(icon as IconData, color: baseColor, size: 36),
                          ),
                          const Spacer(),
                          if (badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Bottom Row: Label & Subtitle
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textLight.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
