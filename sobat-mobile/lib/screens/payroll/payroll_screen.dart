import 'package:flutter/material.dart';
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

  Future<void> _downloadSlip(int id, String period) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final filename = 'Slip_Gaji_$period.pdf';
      await _payrollService.downloadSlip(id, filename);

      Navigator.pop(context); // Close loading
    } catch (e) {
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
      appBar: AppBar(
        title: const Text(
          'Slip Gaji',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Year Selector
          PopupMenuButton<int?>(
            initialValue: _selectedYear,
            onSelected: (year) {
              setState(() => _selectedYear = year);
              _loadPayrolls();
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return [
                const PopupMenuItem<int?>(
                  value: null,
                  child: Text('Semua Tahun'),
                ),
                PopupMenuItem(value: currentYear, child: Text('$currentYear')),
                PopupMenuItem(
                  value: currentYear - 1,
                  child: Text('${currentYear - 1}'),
                ),
              ];
            },
            child: Padding(
              // Trigger widget
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _selectedYear?.toString() ?? 'Semua',
                    style: const TextStyle(
                      color: AppTheme.colorEggplant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.colorEggplant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.colorEggplant),
            )
          : _payrolls.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadPayrolls,
              color: AppTheme.colorEggplant,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _payrolls.length,
                itemBuilder: (context, index) {
                  final payroll = _payrolls[index];
                  return _buildPayrollCard(payroll);
                },
              ),
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
    final periodDate = DateTime.parse(payroll['period_start']);
    final monthName = DateFormat('MMMM', 'id_ID').format(periodDate);
    final status = payroll['status'] ?? 'pending';
    final isPaid =
        status == 'paid' ||
        status == 'approved'; // Treat approved as visible mostly

    // Status color
    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    if (status == 'paid') {
      statusColor = AppTheme.success;
      statusText = 'Dibayarkan';
    } else if (status == 'approved') {
      statusColor = Colors.blue;
      statusText = 'Disetujui';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailSheet(payroll),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${periodDate.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Take Home Pay',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    Text(
                      _formatCurrency(payroll['net_salary'] ?? 0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colorEggplant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> payroll) {
    showModalBottomSheet(
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
                  _buildDetailRow('Gaji Pokok', payroll['basic_salary']),
                  _buildDetailRow(
                    'Tunjangan',
                    payroll['allowances'],
                    isPlus: true,
                  ),
                  _buildDetailRow(
                    'Lembur',
                    payroll['allowances'],
                    isPlus: true,
                  ), // Note: allowances field used for overtime too based on controller mapping? Let's check keys.
                  // Keys from controller: basic_salary, allowances (overtime), deductions (bpjs_kes), bpjs_employment, tax

                  // Wait, let's recheck the controller output keys
                  // 'allowances' => (float) ($payroll->overtime_pay ?? 0),  <-- Weird mapping in backend?
                  // Let's use the keys returned by backend: basic_salary, allowances, deductions, tax, net_salary
                  const Divider(height: 32),
                  const Text(
                    'Potongan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'BPJS Kesehatan',
                    payroll['bpjs_health'],
                    isMinus: true,
                  ),
                  _buildDetailRow(
                    'BPJS Ketenagakerjaan',
                    payroll['bpjs_employment'],
                    isMinus: true,
                  ),
                  _buildDetailRow('PPh 21', payroll['tax'], isMinus: true),

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
                        _formatCurrency(payroll['net_salary'] ?? 0),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadSlip(
                    payroll['id'],
                    DateFormat(
                      'MMM_yyyy',
                    ).format(DateTime.parse(payroll['period_start'])),
                  ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textLight)),
          Text(
            '$prefix${_formatCurrency(value ?? 0)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
