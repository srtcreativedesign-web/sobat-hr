import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../../approval/approval_list_screen.dart';

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
        'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        'onTap': () => Navigator.pushNamed(context, '/payroll'),
      },
      {
        'icon': 'assets/icons/leave.png',
        'isAsset': true,
        'label': isLoadingLeave 
            ? AppLocalizations.of(context)!.leave 
            : '${AppLocalizations.of(context)!.leave} ($leaveBalance)',
        'subtitle': AppLocalizations.of(context)!.applyLeave,
        'gradient': [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
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
        'icon': 'assets/icons/history.png',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.history,
        'subtitle': AppLocalizations.of(context)!.attendance,
        'gradient': [const Color(0xFFF6D365), const Color(0xFFFDA085)],
        'onTap': () => Navigator.pushNamed(context, '/attendance/history'),
      },
      {
        'icon': 'assets/icons/overtime.png',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.overtime,
        'subtitle': AppLocalizations.of(context)!.applyOvertime,
        'gradient': [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)],
        'onTap': () => Navigator.pushNamed(context, '/submission/create', arguments: 'Lembur'),
      },
      {
        'icon': 'assets/icons/bussines-trip.png',
        'isAsset': true,
        'label': AppLocalizations.of(context)!.businessTrip,
        'subtitle': AppLocalizations.of(context)!.businessTripShort,
        'gradient': [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)],
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
        'gradient': [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
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
        Row(
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
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: menuItems.length <= 3
              ? menuItems.length
              : (menuItems.length == 4 ? 4 : 3),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: menuItems.map((item) {
            return _buildActionItem(
              item['icon'],
              item['label'] as String,
              item['gradient'] as List<Color>,
              subtitle: item['subtitle'] as String,
              badgeCount: (item['badge'] as int?) ?? 0,
              isAsset: (item['isAsset'] as bool?) ?? false,
              onTap: item['onTap'] as VoidCallback?,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    dynamic icon,
    String label,
    List<Color> gradientColors, {
    String subtitle = '',
    VoidCallback? onTap,
    int badgeCount = 0,
    bool isAsset = false,
  }) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: isAsset
                          ? Image.asset(
                              icon as String,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.error_outline_rounded,
                                color: gradientColors[0],
                                size: 22,
                              ),
                            )
                          : Icon(icon as IconData, color: gradientColors[0], size: 28),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textLight.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
