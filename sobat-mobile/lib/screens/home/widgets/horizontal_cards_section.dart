import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/payroll_service.dart';
import '../../../widgets/payroll_cards.dart';
import '../../security/pin_screen.dart';
import '../../submission/create_submission_screen.dart';

class HorizontalCardsSection extends StatefulWidget {
  final int leaveBalance;
  final int leaveQuota;
  final bool isEligibleLeave;
  final bool isLoadingLeave;
  final bool isLoadingPayroll;
  final Map<String, dynamic>? lastPayroll;
  final bool isLoadingThr;
  final Map<String, dynamic>? lastThr;
  final VoidCallback onRefreshLeave;

  const HorizontalCardsSection({
    super.key,
    required this.leaveBalance,
    required this.leaveQuota,
    required this.isEligibleLeave,
    required this.isLoadingLeave,
    required this.isLoadingPayroll,
    required this.lastPayroll,
    required this.isLoadingThr,
    required this.lastThr,
    required this.onRefreshLeave,
  });

  @override
  State<HorizontalCardsSection> createState() => _HorizontalCardsSectionState();
}

class _HorizontalCardsSectionState extends State<HorizontalCardsSection> {
  late PageController _dashboardController;
  Timer? _dashboardTimer;
  int _currentDashboardIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardController = PageController(viewportFraction: 0.92);
    _startDashboardAutoScroll();
  }

  @override
  void dispose() {
    _dashboardTimer?.cancel();
    _dashboardController.dispose();
    super.dispose();
  }

  void _startDashboardAutoScroll() {
    _dashboardTimer?.cancel();
    _dashboardTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_dashboardController.hasClients) {
        int nextPage = _currentDashboardIndex + 1;
        if (nextPage >= 3) {
          nextPage = 0;
        }
        _dashboardController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView(
            controller: _dashboardController,
            onPageChanged: (index) {
              setState(() {
                _currentDashboardIndex = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: [
              _buildLeaveBalanceCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildNewPayrollCard(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildNewThrCard(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentDashboardIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentDashboardIndex == index
                    ? AppTheme.colorEggplant
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.leaveBalanceLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.isLoadingLeave
                              ? '...'
                              : (widget.isEligibleLeave ? '${widget.leaveBalance} ' : '- '),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.days,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Conic Chart Simulation
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [AppTheme.colorCyan, Colors.grey.shade100],
                    stops: const [0.75, 0.75],
                    transform: const GradientRotation(-1.57),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.percent,
                        size: 16,
                        color: AppTheme.colorEggplant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 12, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.validUntilDec,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEligibleLeave
                    ? AppLocalizations.of(context)!.leaveTotal(widget.leaveQuota)
                    : AppLocalizations.of(context)!.notEligible,
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateSubmissionScreen(type: 'Cuti'),
                    ),
                  ).then((_) {
                    widget.onRefreshLeave();
                  });
                },
                child: Text(
                  '${AppLocalizations.of(context)!.applyLeave} →',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorEggplant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPayrollCard() {
    if (widget.isLoadingPayroll) {
      return const SlipGajiCard(
        data: SlipGajiData(
          periode: 'Memuat...',
          status: SlipGajiStatus.belumAda,
        ),
      );
    }

    if (widget.lastPayroll == null) {
      return SlipGajiCard(
        data: SlipGajiData(
          periode: 'Belum ada data',
          status: SlipGajiStatus.belumAda,
          onDetail: () => Navigator.pushNamed(context, '/payroll'),
        ),
      );
    }

    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    final period = (widget.lastPayroll!['period'] ?? widget.lastPayroll!['period_start'] ?? '').toString();
    String formattedPeriod = period;
    try {
      if (period.contains('-')) {
        final date = DateTime.parse('$period-01');
        formattedPeriod = DateFormat('MMMM yyyy', localeName).format(date);
      }
    } catch (_) {}

    final status = widget.lastPayroll!['status'] == 'selesai' || widget.lastPayroll!['status'] == 'paid'
        ? SlipGajiStatus.selesai
        : SlipGajiStatus.proses;

    return SlipGajiCard(
      data: SlipGajiData(
        periode: formattedPeriod,
        gajiPokok: widget.lastPayroll!['basic_salary']?.toString(),
        tunjangan: widget.lastPayroll!['allowance']?.toString(),
        total: widget.lastPayroll!['net_salary']?.toString() ?? widget.lastPayroll!['total_salary']?.toString(),
        status: status,
        updatedAt: widget.lastPayroll!['updated_at'] != null 
            ? DateFormat('d MMM HH:mm', localeName).format(DateTime.parse(widget.lastPayroll!['updated_at']))
            : '',
        onUnduh: () async {
          final user = Provider.of<AuthProvider>(context, listen: false).user;
          if (user == null) return;

          final pinVerified = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => PinScreen(
                mode: user.hasPin ? PinMode.verify : PinMode.setup,
                onSuccess: () => Navigator.pop(context, true),
              ),
            ),
          );

          if (pinVerified == true) {
            await PayrollService().downloadSlip(
              widget.lastPayroll!['id'],
              'Slip_Gaji_$period.pdf',
              division: widget.lastPayroll!['division'],
            );
          }
        },
        onDetail: () => Navigator.pushNamed(context, '/payroll'),
      ),
    );
  }

  Widget _buildNewThrCard() {
    if (widget.isLoadingThr) {
      return const SlipThrCard(
        data: SlipThrData(
          tahun: '...',
        ),
      );
    }

    if (widget.lastThr == null) {
      return SlipThrCard(
        data: SlipThrData(
          tahun: DateTime.now().year.toString(),
          isAvailable: false,
          onDetail: () => Navigator.pushNamed(context, '/payroll/thr'),
        ),
      );
    }

    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    return SlipThrCard(
      data: SlipThrData(
        tahun: widget.lastThr!['year']?.toString() ?? '',
        isAvailable: widget.lastThr!['status'] == 'paid',
        updatedAt: widget.lastThr!['paid_at'] != null
            ? DateFormat('d MMM yyyy', localeName).format(DateTime.parse(widget.lastThr!['paid_at']))
            : '',
        onDetail: () => Navigator.pushNamed(context, '/payroll/thr'),
      ),
    );
  }
}
