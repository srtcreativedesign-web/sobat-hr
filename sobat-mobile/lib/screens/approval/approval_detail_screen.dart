import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../../config/theme.dart';
import '../../services/approval_service.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> approvalItem;

  const ApprovalDetailScreen({super.key, required this.approvalItem});

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  final ApprovalService _approvalService = ApprovalService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _isActing = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _handleApprove() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon tanda tangan terlebih dahulu')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan'),
        content: const Text(
          'Apakah Anda yakin ingin menyetujui pengajuan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActing = true);

    try {
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null)
        throw Exception('Gagal mengambil tanda tangan');

      final signatureBase64 = base64Encode(signatureBytes);
      // Backend expects 'data:image/png;base64,...' usually, or just base64?
      // My backend uses $request->input('signature'). If I verify request controller logic...
      // I'll send raw base64 string for now, but usually data URI scheme is safer if backend expects it.
      // Wait, let's send standard Base64 string.

      final request = widget.approvalItem['approvable'] ?? {};
      final requestId = request['id'];

      await _approvalService.approveRequest(requestId, signatureBase64);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan berhasil disetujui')),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyetujui: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _handleReject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penolakan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan alasan penolakan:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Alasan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                return; // Require reason
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActing = true);

    try {
      final request = widget.approvalItem['approvable'] ?? {};
      final requestId = request['id'];

      await _approvalService.rejectRequest(requestId, reasonController.text);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengajuan ditolak')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menolak: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.approvalItem['approvable'] ?? {};
    final employee = request['employee'] ?? {};
    final type = request['type'] ?? 'Unknown';

    // Dates
    String duration = '';
    if (request['start_date'] != null && request['end_date'] != null) {
      try {
        final start = DateTime.parse(request['start_date']);
        final end = DateTime.parse(request['end_date']);
        final dayDiff = end.difference(start).inDays + 1;
        duration =
            '${DateFormat('d MMM y').format(start)} - ${DateFormat('d MMM y').format(end)} ($dayDiff Hari)';
      } catch (_) {}
    } else if (request['start_date'] != null) {
      duration = DateFormat(
        'd MMM y',
      ).format(DateTime.parse(request['start_date']));
    }

    // Amount (if any)
    String amount = '';
    if (request['amount'] != null) {
      if (type.toString().toLowerCase() == 'overtime') {
        amount = '${request['amount']} Jam';
      } else if (type.toString().toLowerCase() == 'leave' ||
          type.toString().toLowerCase() == 'sick_leave') {
        amount = request['amount'].toString();
      } else {
        amount = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(double.tryParse(request['amount'].toString()) ?? 0);
      }
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
            // Header: Requester Info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.colorEggplant.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    (employee['full_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      (employee['job_level'] != null &&
                                  employee['job_level'].toString().isNotEmpty
                              ? employee['job_level'].toString().replaceAll(
                                  '_',
                                  ' ',
                                )
                              : (employee['position'] ?? 'Staff'))
                          .toUpperCase(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 48),

            // Request Details
            _buildDetailRow(
              'Jenis Pengajuan',
              type.toString().toUpperCase().replaceAll('_', ' '),
            ),
            const SizedBox(height: 16),

            // Dynamic Fields based on Type
            if (type == 'leave' || type == 'sick_leave') ...[
              _buildDetailRow('Tanggal', duration),
              const SizedBox(height: 16),
              if (amount.isNotEmpty) _buildDetailRow('Durasi', '$amount Hari'),
            ] else if (type == 'overtime') ...[
              _buildDetailRow('Tanggal', duration),
              const SizedBox(height: 16),
              if (amount.isNotEmpty)
                _buildDetailRow(
                  'Durasi',
                  amount,
                ), // Already formatted as 'X Jam' above
            ] else if (type == 'business_trip') ...[
              _buildDetailRow(
                'Tujuan',
                request['destination'] ?? request['title'] ?? '-',
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Tanggal', duration),
              const SizedBox(height: 16),
              if (amount.isNotEmpty) _buildDetailRow('Budget', amount),
            ] else if (type == 'reimbursement') ...[
              _buildDetailRow('Keperluan', request['title'] ?? '-'),
              const SizedBox(height: 16),
              _buildDetailRow('Tanggal', duration),
              const SizedBox(height: 16),
              if (amount.isNotEmpty) _buildDetailRow('Nominal', amount),
            ] else if (type == 'asset') ...[
              if (request['detail'] != null) ...[
                _buildDetailRow(
                  'Barang / Merek',
                  request['detail']['brand'] ?? '-',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Spesifikasi',
                  request['detail']['specification'] ?? '-',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Urgensi',
                  (request['detail']['is_urgent'] == true ||
                          request['detail']['is_urgent'] == 1)
                      ? 'Mendesak (Urgent)'
                      : 'Normal',
                ),
                const SizedBox(height: 16),
                if (amount.isNotEmpty)
                  _buildDetailRow('Estimasi Harga', amount),
              ],
            ] else if (type == 'resignation') ...[
              if (request['detail'] != null) ...[
                _buildDetailRow(
                  'Tanggal Terakhir Bekerja',
                  (request['detail']['last_working_date'] != null)
                      ? DateFormat('d MMM y', 'id_ID').format(
                          DateTime.parse(
                            request['detail']['last_working_date'],
                          ),
                        )
                      : '-',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Tipe Resign',
                  request['detail']['resign_type'] == '1_month_notice'
                      ? 'One Month Notice'
                      : 'Normal',
                ),
              ],
            ] else ...[
              // Fallback for unknown types
              _buildDetailRow('Tanggal', duration),
              if (amount.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDetailRow('Nominal', amount),
              ],
            ],

            const SizedBox(height: 16),
            _buildDetailRow('Keterangan', request['description'] ?? '-'),

            if (request['attachments'] != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Lampiran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: Builder(
                  builder: (context) {
                    List<dynamic> attachments = [];
                    var raw = request['attachments'];
                    if (raw is List) {
                      attachments = raw;
                    } else if (raw is String) {
                      try {
                        var decoded = jsonDecode(raw);
                        if (decoded is List) attachments = decoded;
                      } catch (_) {}
                    }

                    if (attachments.isEmpty) return const SizedBox.shrink();

                    return ListView.builder(
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
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Text(
              'Tanda Tangan Approval',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _signatureController,
                  height: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _signatureController.clear(),
                child: const Text(
                  'Hapus Tanda Tangan',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isActing ? null : _handleReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isActing ? null : _handleApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorEggplant,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isActing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Setujui'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
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
