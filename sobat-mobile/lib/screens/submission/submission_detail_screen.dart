import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class SubmissionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> submission;

  const SubmissionDetailScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    // Extract data
    final type =
        submission['type']?.toString().replaceAll('_', ' ').toUpperCase() ??
        'PENGAJUAN';
    final status = submission['status']?.toString().toLowerCase() ?? 'pending';
    final reason = submission['reason'] ?? submission['description'] ?? '-';

    // Dates
    String duration = '';
    if (submission['start_date'] != null && submission['end_date'] != null) {
      try {
        final start = DateTime.parse(submission['start_date']);
        final end = DateTime.parse(submission['end_date']);
        final dayDiff = end.difference(start).inDays + 1;
        duration =
            '${DateFormat('d MMM y', 'id_ID').format(start)} - ${DateFormat('d MMM y', 'id_ID').format(end)} ($dayDiff Hari)';
      } catch (_) {
        duration = '${submission['start_date']} - ${submission['end_date']}';
      }
    } else if (submission['start_date'] != null) {
      try {
        duration = DateFormat(
          'd MMM y',
          'id_ID',
        ).format(DateTime.parse(submission['start_date']));
      } catch (_) {
        duration = submission['start_date'];
      }
    }

    // Amount
    String amount = '';
    if (submission['amount'] != null) {
      amount = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(submission['amount']);
    }

    // Status Color
    Color statusColor;
    String statusLabel;
    if (status == 'approved') {
      statusColor = AppTheme.colorCyan;
      statusLabel = 'Disetujui';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'Ditolak';
    } else {
      statusColor = Colors.orange;
      statusLabel = 'Menunggu';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Pengajuan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    status == 'approved'
                        ? Icons.check_circle_outline
                        : status == 'rejected'
                        ? Icons.cancel_outlined
                        : Icons.hourglass_empty,
                    color: statusColor,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildDetailRow('Jenis Pengajuan', type),
            const SizedBox(height: 16),
            _buildDetailRow('Tanggal', duration),
            if (amount.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Nominal', amount),
            ],
            const SizedBox(height: 16),
            _buildDetailRow('Keterangan', reason),

            const SizedBox(height: 32),
            if (submission['approvals'] != null &&
                (submission['approvals'] as List).isNotEmpty) ...[
              const Text(
                'Riwayat Persetujuan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...((submission['approvals'] as List).map((approval) {
                final approver = approval['approver'] != null
                    ? (approval['approver']['full_name'] ?? 'Approver')
                    : 'System';
                final lvl = approval['level'] ?? 1;
                final st = approval['status'] ?? 'pending';
                final note = approval['note'];

                Color stColor = Colors.grey;
                IconData stIcon = Icons.circle_outlined;
                if (st == 'approved') {
                  stColor = Colors.green;
                  stIcon = Icons.check_circle;
                }
                if (st == 'rejected') {
                  stColor = Colors.red;
                  stIcon = Icons.cancel;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Icon(stIcon, color: stColor),
                    title: Text(approver),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level $lvl • ${st.toString().toUpperCase()}'),
                        if (note != null && note != 'null')
                          Text(
                            'Note: $note',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                );
              })),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
