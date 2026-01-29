import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for base64Decode
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> submission;

  const SubmissionDetailScreen({super.key, required this.submission});

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  bool _isDownloading = false;

  Future<void> _downloadProof() async {
    setState(() => _isDownloading = true);
    try {
      final id = widget.submission['id'];
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/Proof-REQ-$id.pdf';

      await dio.download(
        '${ApiConfig.baseUrl}/requests/$id/proof',
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf',
          },
        ),
      );

      await OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  List<dynamic> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Extract data
    final type =
        widget.submission['type']
            ?.toString()
            .replaceAll('_', ' ')
            .toUpperCase() ??
        'PENGAJUAN';
    final status =
        widget.submission['status']?.toString().toLowerCase() ?? 'pending';
    final reason =
        widget.submission['reason'] ?? widget.submission['description'] ?? '-';

    // Parse Lists safely
    final attachments = _parseList(widget.submission['attachments']);
    final approvals = _parseList(widget.submission['approvals']);

    // Dates
    String duration = '';
    if (widget.submission['start_date'] != null &&
        widget.submission['end_date'] != null) {
      try {
        final start = DateTime.parse(widget.submission['start_date']);
        final end = DateTime.parse(widget.submission['end_date']);
        final dayDiff = end.difference(start).inDays + 1;
        duration =
            '${DateFormat('d MMM y', 'id_ID').format(start)} - ${DateFormat('d MMM y', 'id_ID').format(end)} ($dayDiff Hari)';
      } catch (_) {
        duration =
            '${widget.submission['start_date']} - ${widget.submission['end_date']}';
      }
    } else if (widget.submission['start_date'] != null) {
      try {
        duration = DateFormat(
          'd MMM y',
          'id_ID',
        ).format(DateTime.parse(widget.submission['start_date']));
      } catch (_) {
        duration = widget.submission['start_date'];
      }
    }

    // Amount
    String amount = '';
    if (widget.submission['amount'] != null) {
      amount = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(double.tryParse(widget.submission['amount'].toString()) ?? 0);
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
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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

            if (status == 'approved') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadProof,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _isDownloading ? 'Mengunduh...' : 'Download Bukti Approval',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

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

            // Asset Details
            if (widget.submission['type'] == 'asset' &&
                widget.submission['detail'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Barang / Merek',
                widget.submission['detail']['brand'] ?? '-',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Spesifikasi',
                widget.submission['detail']['specification'] ?? '-',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Urgensi',
                (widget.submission['detail']['is_urgent'] == true ||
                        widget.submission['detail']['is_urgent'] == 1)
                    ? 'Mendesak (Urgent)'
                    : 'Normal',
              ),
            ],

            // Resignation Details
            if (widget.submission['type'] == 'resignation' &&
                widget.submission['detail'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Tanggal Terakhir Bekerja',
                (widget.submission['detail']['last_working_date'] != null)
                    ? DateFormat('d MMM y', 'id_ID').format(
                        DateTime.parse(
                          widget.submission['detail']['last_working_date'],
                        ),
                      )
                    : '-',
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Tipe Resign', 'Normal One Month Notice'),
            ],

            // Attachments
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Lampiran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final att = attachments[index];
                    if (att is String && att.startsWith('data:image')) {
                      final base64String = att.split(',').last;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      child: Image.memory(
                                        base64Decode(base64String),
                                      ),
                                    ),
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        onPressed: () => Navigator.pop(ctx),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(base64String),
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) {
                                return Container(
                                  width: 200,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),
            if (approvals.isNotEmpty) ...[
              const Text(
                'Riwayat Persetujuan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...((approvals).map((approval) {
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
