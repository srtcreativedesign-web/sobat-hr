import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/approval_service.dart';
import 'approval_detail_screen.dart';

class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  final ApprovalService _approvalService = ApprovalService();
  List<dynamic> _approvals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _approvalService.getPendingApprovals();
      setState(() {
        _approvals = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Daftar Persetujuan',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadApprovals,
        color: AppTheme.colorEggplant,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.colorEggplant),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadApprovals,
                      child: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorEggplant,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : _approvals.isEmpty
            ? ListView(
                // ListView allows RefreshIndicator to work
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada persetujuan tertunda',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _approvals.length,
                itemBuilder: (context, index) {
                  final item = _approvals[index];
                  // item structure: {id, approvable_type, approvable: {request details with employee}}
                  final request = item['approvable'] ?? {};
                  final employee = request['employee'] ?? {};
                  final type = request['type'] ?? 'Unknown';

                  // Parse date safely
                  String dateText = '-';
                  if (request['start_date'] != null) {
                    try {
                      final date = DateTime.parse(request['start_date']);
                      dateText = DateFormat('d MMM y', 'id_ID').format(date);
                    } catch (_) {}
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ApprovalDetailScreen(approvalItem: item),
                          ),
                        );
                        if (result == true) {
                          _loadApprovals();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.colorEggplant
                                      .withValues(alpha: 0.1),
                                  child: Text(
                                    (employee['full_name'] ?? 'U')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.colorEggplant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee['full_name'] ?? 'Unknown User',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        (employee['job_level'] != null &&
                                                    employee['job_level']
                                                        .toString()
                                                        .isNotEmpty
                                                ? employee['job_level']
                                                      .toString()
                                                      .replaceAll('_', ' ')
                                                : (employee['position'] ??
                                                      'Employee'))
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Level ${item['level']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tipe Pengajuan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request['type'] == 'reimbursement' &&
                                              request['title'] != null
                                          ? request['title']
                                                .toString()
                                                .toUpperCase()
                                          : type.toString().toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    if (request['type'] == 'reimbursement' &&
                                        request['amount'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'id_ID',
                                          symbol: 'Rp ',
                                          decimalDigits: 0,
                                        ).format(
                                          double.tryParse(
                                                request['amount'].toString(),
                                              ) ??
                                              0,
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.colorCyan,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tanggal Mulai',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
