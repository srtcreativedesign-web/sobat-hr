import 'package:flutter/material.dart';
import 'dart:io';
import 'package:screen_protector/screen_protector.dart';
import '../../config/theme.dart';
import '../../services/payroll_service.dart';
import 'package:intl/intl.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final PayrollService _payrollService = PayrollService();
  bool _isLoading = true;
  List<dynamic> _payrolls = [];
  int? _selectedYear; // Null means "All Years"

  // Selected payroll for detail view in bottom sheet
  Map<String, dynamic>? _selectedPayroll;

  @override
  void initState() {
    super.initState();
    _loadPayrolls();
  }

  Future<void> _loadPayrolls() async {
    setState(() => _isLoading = true);
    try {
      final data = await _payrollService.getPayrolls(year: _selectedYear);
      setState(() {
        _payrolls = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadSlip(int id, String period, {String? division}) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final filename = 'Slip_Gaji_$period.pdf';
      debugPrint('Downloading slip: $filename, division: $division');

      await _payrollService.downloadSlip(id, filename, division: division);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slip gaji berhasil diunduh dan dibuka'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal download: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Header
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.colorEggplant,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPayrolls,
                        color: AppTheme.colorEggplant,
                        child: ListView(
                          padding: const EdgeInsets.only(top: 24, bottom: 24),
                          children: [
                            _buildYearFilter(),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Riwayat Gaji',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total ${_payrolls.length} Slip',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_payrolls.isEmpty)
                              _buildEmptyState()
                            else
                              ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _payrolls.length,
                                separatorBuilder: (c, i) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _buildPayrollCard(_payrolls[index]);
                                },
                              ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          // Back Button (Floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Calculate latest net salary (first item if available)
    double lastSalary = 0;
    String lastDate = '-';
    if (_payrolls.isNotEmpty) {
      final payroll = _payrolls[0];
      final isCellular = payroll['division'] == 'celluller';
      lastSalary =
          double.tryParse(
            (isCellular
                    ? (payroll['final_payment'] ?? payroll['net_salary'])
                    : payroll['net_salary'])
                .toString(),
          ) ??
          0;
      // Handle both 'period' (FnB) and 'period_start' (generic)
      final periodStr = _payrolls[0]['period'] ?? _payrolls[0]['period_start'];
      if (periodStr != null) {
        // If period is YYYY-MM format, append -01 for valid DateTime parsing
        final dateStr = periodStr.toString().length == 7
            ? '$periodStr-01'
            : periodStr.toString();
        lastDate = DateFormat(
          'd MMM yyyy',
          'id_ID',
        ).format(DateTime.parse(dateStr));
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 30,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.colorEggplant, Color(0xFF2D1B22)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decor circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.colorCyan.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gaji Bersih Terakhir',
                style: TextStyle(
                  color: AppTheme.colorCyan.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const SizedBox(
                  height: 40,
                  width: 150,
                  child: LinearProgressIndicator(color: Colors.white24),
                )
              else
                Text(
                  _formatCurrency(lastSalary),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Periode $lastDate',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    final currentYear = DateTime.now().year;
    final years = [null, currentYear, currentYear - 1, currentYear - 2];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: years.map((year) {
          final isSelected = _selectedYear == year;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(year?.toString() ?? 'Semua'),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() => _selectedYear = year);
                  _loadPayrolls();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.colorEggplant,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada slip gaji',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Slip gaji Anda akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(Map<String, dynamic> payroll) {
    // Handle both 'period' (FnB: YYYY-MM) and 'period_start' (generic: YYYY-MM-DD)
    final periodStr = payroll['period'] ?? payroll['period_start'];

    // Default to current date if no period found
    DateTime periodDate;
    if (periodStr == null) {
      periodDate = DateTime.now();
    } else {
      // If period is YYYY-MM format, append -01 for valid DateTime parsing
      final dateStr = periodStr.toString().length == 7
          ? '$periodStr-01'
          : periodStr.toString();
      periodDate = DateTime.parse(dateStr);
    }

    final monthName = DateFormat('MMMM', 'id_ID').format(periodDate);
    final status = payroll['status'] ?? 'pending';

    // Status config
    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    IconData statusIcon = Icons.access_time;

    if (status == 'paid') {
      statusColor = AppTheme.success;
      statusText = 'Lunas';
      statusIcon = Icons.check_circle;
    } else if (status == 'approved') {
      statusColor = Colors.blue;
      statusText = 'Disetujui';
      statusIcon = Icons.thumb_up;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailSheet(payroll),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Box
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.colorCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.calendar_today,
                          color: AppTheme.colorEggplant,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: #SLIP-${periodDate.year}${periodDate.month.toString().padLeft(2, '0')}-${payroll['id']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _formatCurrency(
                                  double.tryParse(
                                        (payroll['division'] == 'celluller'
                                                    ? (payroll['final_payment'] ??
                                                          payroll['net_salary'])
                                                    : payroll['net_salary'])
                                                ?.toString() ??
                                            '0',
                                      ) ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showDetailSheet(payroll),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Lihat Detail'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.colorEggplant,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDetailSheet(Map<String, dynamic> payroll) async {
    if (Platform.isAndroid) {
      await ScreenProtector.preventScreenshotOn();
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Gaji',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Attendance Summary (for FnB payroll)
                  if (payroll['attendance'] != null &&
                      payroll['attendance'] is Map) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DATA KEHADIRAN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (payroll['attendance'] as Map).entries
                                .map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          entry.value.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // PENDAPATAN SECTION
                  const Text(
                    'Pendapatan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.colorCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Gaji Pokok', payroll['basic_salary']),

                  // DETAILED ALLOWANCES (FnB structured data)
                  if (payroll['allowances'] != null &&
                      payroll['allowances'] is Map) ...[
                    ...(payroll['allowances'] as Map).entries.map((entry) {
                      final value = entry.value;
                      double amount = 0;

                      // Handle nested objects (like Kehadiran, Transport, Lembur with amount field)
                      if (value is Map && value['amount'] != null) {
                        amount =
                            double.tryParse(value['amount'].toString()) ?? 0;
                      } else {
                        amount = double.tryParse(value.toString()) ?? 0;
                      }

                      if (amount > 0 && entry.key != 'Lembur') {
                        // Lembur shown separately
                        return _buildDetailRow(entry.key, amount, isPlus: true);
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ],

                  // OVERTIME (if available)
                  if (payroll['allowances'] != null &&
                      payroll['allowances'] is Map) ...[
                    Builder(
                      builder: (context) {
                        final allowances = payroll['allowances'] as Map;
                        if (allowances['Lembur'] != null) {
                          final lembur = allowances['Lembur'];
                          final amount = lembur is Map
                              ? (double.tryParse(lembur['amount'].toString()) ??
                                    0)
                              : (double.tryParse(lembur.toString()) ?? 0);

                          // Extract hours
                          final rawHours = lembur is Map
                              ? (lembur['hours'] ?? 0)
                              : 0;
                          final hours =
                              double.tryParse(rawHours.toString()) ?? 0;

                          if (amount > 0) {
                            return _buildDetailRow(
                              hours > 0 ? 'Lembur ($hours Jam)' : 'Lembur',
                              amount,
                              isPlus: true,
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ] else if (payroll['overtime_pay'] != null) ...[
                    // Generic Payroll Overtime
                    Builder(
                      builder: (context) {
                        final amount =
                            double.tryParse(
                              payroll['overtime_pay'].toString(),
                            ) ??
                            0;
                        final details = payroll['details'];
                        var hours = 0;
                        if (details != null &&
                            details is Map &&
                            details['overtime_hours'] != null) {
                          hours =
                              int.tryParse(
                                details['overtime_hours'].toString(),
                              ) ??
                              0;
                        }

                        if (amount > 0) {
                          return _buildDetailRow(
                            hours > 0 ? 'Lembur ($hours Jam)' : 'Lembur',
                            amount,
                            isPlus: true,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],

                  const Divider(height: 32),

                  // POTONGAN SECTION
                  const Text(
                    'Potongan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // DETAILED DEDUCTIONS (FnB structured data)
                  if (payroll['deductions'] != null &&
                      payroll['deductions'] is Map) ...[
                    ...(payroll['deductions'] as Map).entries.map((entry) {
                      final amount =
                          double.tryParse(entry.value.toString()) ?? 0;
                      if (amount > 0) {
                        return _buildDetailRow(
                          entry.key,
                          amount,
                          isMinus: true,
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ] else ...[
                    // Generic payroll deductions
                    if ((payroll['bpjs_health'] ?? 0) > 0)
                      _buildDetailRow(
                        'BPJS Kesehatan',
                        payroll['bpjs_health'],
                        isMinus: true,
                      ),
                    if ((payroll['bpjs_employment'] ?? 0) > 0)
                      _buildDetailRow(
                        'BPJS Ketenagakerjaan',
                        payroll['bpjs_employment'],
                        isMinus: true,
                      ),
                    if ((payroll['tax'] ?? 0) > 0)
                      _buildDetailRow('PPh 21', payroll['tax'], isMinus: true),
                  ],

                  // EWA Display (for FnB)
                  if (payroll['ewa_amount'] != null) ...[
                    Builder(
                      builder: (context) {
                        final ewaAmount =
                            double.tryParse(payroll['ewa_amount'].toString()) ??
                            0;
                        if (ewaAmount > 0) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EWA (KASBON)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total EWA'),
                                    Text(
                                      '- ${_formatCurrency(ewaAmount)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],

                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Diterima',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        _formatCurrency(
                          double.tryParse(
                                (payroll['division'] == 'celluller'
                                            ? (payroll['final_payment'] ??
                                                  payroll['net_salary'])
                                            : payroll['net_salary'])
                                        ?.toString() ??
                                    '0',
                              ) ??
                              0,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colorEggplant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Download Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final periodStr =
                        payroll['period'] ?? payroll['period_start'];
                    if (periodStr != null) {
                      // If period is YYYY-MM format, append -01 for valid DateTime parsing
                      final dateStr = periodStr.toString().length == 7
                          ? '$periodStr-01'
                          : periodStr.toString();
                      _downloadSlip(
                        payroll['id'],
                        DateFormat(
                          'MMM_yyyy',
                          'id_ID',
                        ).format(DateTime.parse(dateStr)),
                        division: payroll['division'],
                      );
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Slip Gaji'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorEggplant,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (Platform.isAndroid) {
      await ScreenProtector.preventScreenshotOff();
    }
  }

  Widget _buildDetailRow(
    String label,
    dynamic value, {
    bool isPlus = false,
    bool isMinus = false,
  }) {
    Color valueColor = AppTheme.textDark;
    String prefix = '';

    if (isPlus) {
      valueColor = Colors.green;
      prefix = '+ ';
    } else if (isMinus) {
      valueColor = Colors.red;
      prefix = '- ';
    }

    // Parse value to double to handle both String and num types
    final numValue = double.tryParse(value?.toString() ?? '0') ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textLight)),
          Text(
            '$prefix${_formatCurrency(numValue)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
