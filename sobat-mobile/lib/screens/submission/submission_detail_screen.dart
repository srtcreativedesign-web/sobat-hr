import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert'; // Added for base64Encode
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../l10n/app_localizations.dart';
import '../../services/request_service.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> submission;

  const SubmissionDetailScreen({super.key, required this.submission});

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  bool _isDownloading = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final RequestService _requestService = RequestService();
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.submission['status'] == 'spl_open') {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mapTypeToTitle(BuildContext context, String? type) {
    if (type == 'leave') return AppLocalizations.of(context)!.leave;
    if (type == 'permit') return AppLocalizations.of(context)!.permitLabel;
    if (type == 'sick' || type == 'sick_leave') return AppLocalizations.of(context)!.sick;
    if (type == 'reimbursement') return AppLocalizations.of(context)!.reimbursement;
    if (type == 'business_trip') return AppLocalizations.of(context)!.businessTrip;
    if (type == 'overtime') return AppLocalizations.of(context)!.overtime;
    if (type == 'asset') return AppLocalizations.of(context)!.assetLabel;
    if (type == 'resignation') return AppLocalizations.of(context)!.resignationLabel;
    return type?.replaceAll('_', ' ').toUpperCase() ?? AppLocalizations.of(context)!.submissions.toUpperCase();
  }

  String _mapStatusToLabel(BuildContext context, String? status) {
    status = status?.toLowerCase();
    if (status == 'approved') return AppLocalizations.of(context)!.approved;
    if (status == 'rejected') return AppLocalizations.of(context)!.rejected;
    return AppLocalizations.of(context)!.pending;
  }

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
        '${ApiConfig.baseUrl}requests/$id/proof',
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
            content: Text(AppLocalizations.of(context)!.downloadFailed(e.toString())),
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
    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';

    // Extract data
    final rawType = widget.submission['type']?.toString().toLowerCase() ?? '';
    final typeStr = _mapTypeToTitle(context, rawType);
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
            '${DateFormat('d MMM y', localeName).format(start)} - ${DateFormat('d MMM y', localeName).format(end)} (${AppLocalizations.of(context)!.daysCount(dayDiff.toString())})';
      } catch (_) {
        duration =
            '${widget.submission['start_date']} - ${widget.submission['end_date']}';
      }
    } else if (widget.submission['start_date'] != null) {
      try {
        duration = DateFormat(
          'd MMM y',
          localeName,
        ).format(DateTime.parse(widget.submission['start_date']));
      } catch (_) {
        duration = widget.submission['start_date'];
      }
    }

    // Amount
    String amount = '';
    if (widget.submission['amount'] != null) {
      amount = NumberFormat.currency(
        locale: localeName,
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(double.tryParse(widget.submission['amount'].toString()) ?? 0);
    }

    // Status Color
    Color statusColor;
    String statusLabel;
    if (status == 'approved') {
      statusColor = AppTheme.colorCyan;
      statusLabel = AppLocalizations.of(context)!.approved;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = AppLocalizations.of(context)!.rejected;
    } else if (status == 'spl_approved') {
      statusColor = Colors.blue;
      statusLabel = 'SPL APPROVED (Menunggu Mulai)';
    } else if (status == 'spl_open') {
      statusColor = Colors.green;
      statusLabel = 'LEMBUR BERJALAN';
    } else if (status == 'pending_final') {
      statusColor = Colors.orange;
      statusLabel = 'MENUNGGU APPROVAL FINAL';
    } else {
      statusColor = Colors.orange;
      statusLabel = AppLocalizations.of(context)!.pending;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: ((status == 'spl_open' || status == 'pending_final' || status == 'approved' || status == 'spl_approved') && widget.submission['type'] == 'overtime') ? Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isUploading ? null : (status == 'spl_approved' ? _startOvertime : _showUploadModal),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.colorCyan,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isUploading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
              : Text(status == 'spl_approved' ? 'Mulai Lembur' : (status == 'spl_open' ? 'Selesaikan Lembur' : 'Upload Foto Susulan'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ) : null,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.submissionDetailTitle,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            // Status Card (Boarding Pass Ticket Design)
            CustomPaint(
              painter: TicketPainter(
                bgColor: Colors.white,
                borderColor: statusColor.withValues(alpha: 0.3),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Top Section (Header)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status == 'approved'
                                ? Icons.check_circle_outline
                                : status == 'rejected'
                                ? Icons.cancel_outlined
                                : Icons.flight_takeoff,
                            color: statusColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30), // Spacing to align with the hole (holeY is 65)
                    
                    // Bottom Section (Timer)
                    if (status == 'spl_open' && widget.submission['detail']?['start_time'] != null) ...[
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          try {
                            final stString = widget.submission['detail']['start_time'];
                            final dtString = widget.submission['detail']['date'] ?? widget.submission['start_date'];
                            final st = DateTime.parse('${dtString.split("T")[0]} $stString');
                            final diff = _now.difference(st);
                            final h = diff.inHours.toString().padLeft(2, '0');
                            final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
                            final s = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
                            final durString = diff.isNegative ? '00:00:00' : '$h:$m:$s';
                            return Column(
                              children: [
                                Text(
                                  durString,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                    letterSpacing: 2,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Mulai: $stString  •  Sekarang: ${DateFormat('HH:mm:ss').format(_now)}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } catch (e) {
                            return const SizedBox();
                          }
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        status == 'spl_approved' 
                            ? 'MENUNGGU MULAI' 
                            : (status == 'pending' || status == 'pending_final')
                                ? 'MENUNGGU PERSETUJUAN'
                                : status == 'approved'
                                    ? 'SELESAI'
                                    : status == 'rejected'
                                        ? 'DITOLAK'
                                        : 'SELESAI',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
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
                    _isDownloading
                        ? AppLocalizations.of(context)!.downloading
                        : AppLocalizations.of(context)!.downloadProofButton,
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

            _buildDetailRow(AppLocalizations.of(context)!.submissionType, typeStr, Icons.category_outlined),
            const SizedBox(height: 16),
            _buildDetailRow(AppLocalizations.of(context)!.date, duration, Icons.calendar_today_outlined),
            if (amount.isNotEmpty &&
                ![
                  'leave',
                  'sick',
                  'sick_leave',
                  'business_trip',
                  'overtime',
                ].contains(rawType)) ...[
              const SizedBox(height: 16),
              _buildDetailRow(AppLocalizations.of(context)!.nominalLabel, amount, Icons.attach_money_outlined),
            ],
            if (widget.submission['type'] == 'business_trip' &&
                widget.submission['detail'] != null &&
                widget.submission['detail']['destination'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Tujuan',
                widget.submission['detail']['destination'].toString(),
                Icons.location_on_outlined,
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(AppLocalizations.of(context)!.description, reason, Icons.description_outlined),

            // Asset Details
            if (widget.submission['type'] == 'asset' &&
                widget.submission['detail'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.brandOrMake,
                widget.submission['detail']['brand'] ?? '-',
                Icons.devices_outlined,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.specification,
                widget.submission['detail']['specification'] ?? '-',
                Icons.info_outline,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.urgency,
                (widget.submission['detail']['is_urgent'] == true ||
                        widget.submission['detail']['is_urgent'] == 1)
                    ? AppLocalizations.of(context)!.urgencyUrgent
                    : AppLocalizations.of(context)!.urgencyNormal,
                Icons.priority_high_outlined,
              ),
            ],

            // Exit Permit Details
            if (widget.submission['type'] == 'exit_permit' &&
                widget.submission['detail'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Keperluan',
                (widget.submission['detail']['permit_type'] ?? '-').toString().toUpperCase(),
                Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Tujuan',
                widget.submission['detail']['destination'] ?? '-',
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'No Polisi',
                widget.submission['detail']['vehicle_plate'] ?? '-',
                Icons.directions_car_outlined,
              ),
              if (widget.submission['detail']['signature'] != null && widget.submission['detail']['signature'].toString().contains(',')) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tanda Tangan Pemohon',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.memory(
                    base64Decode(widget.submission['detail']['signature'].toString().split(',').last),
                    height: 100,
                    errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image),
                  ),
                ),
              ],
            ],

            // Resignation Details
            if (widget.submission['type'] == 'resignation' &&
                widget.submission['detail'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.lastWorkingDate,
                (widget.submission['detail']['last_working_date'] != null)
                    ? DateFormat('d MMM y', localeName).format(
                        DateTime.parse(
                          widget.submission['detail']['last_working_date'],
                        ),
                      )
                    : '-',
                Icons.work_history_outlined,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(AppLocalizations.of(context)!.resignationType, AppLocalizations.of(context)!.resignationDefaultType, Icons.exit_to_app_outlined),
            ],

            // Proof Image Done
            if (widget.submission['detail'] != null && 
                widget.submission['detail']['proof_image_done'] != null && 
                (widget.submission['detail']['proof_image_done'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Bukti Selesai Lembur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (widget.submission['detail']['proof_image_done'] as List).length,
                  itemBuilder: (context, index) {
                    final att = (widget.submission['detail']['proof_image_done'] as List)[index];
                    String imageUrl = '';
                    bool isBase64 = false;
                    
                    if (att is String) {
                      if (att.startsWith('data:image')) {
                        isBase64 = true;
                        imageUrl = att.split(',').last;
                      } else {
                        imageUrl = '${ApiConfig.baseUrl.replaceAll('/api/', '')}/storage/$att';
                      }
                    } else {
                      return const SizedBox.shrink();
                    }

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
                                    child: isBase64
                                      ? Image.memory(base64Decode(imageUrl))
                                      : Image.network(imageUrl),
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
                          child: isBase64 
                            ? Image.memory(
                                base64Decode(imageUrl),
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                imageUrl,
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, _) => Container(
                                  width: 200,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.broken_image)),
                                ),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Attachments
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.attachment,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              errorBuilder: (ctx, _, _) {
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
              Text(
                AppLocalizations.of(context)!.approvalHistory,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        Text('Level $lvl • ${_mapStatusToLabel(context, st).toUpperCase()}'),
                        if (note != null && note != 'null')
                          Text(
                            '${AppLocalizations.of(context)!.notes}: $note',
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.colorCyan, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startOvertime() async {
    setState(() => _isUploading = true);
    try {
      final response = await _requestService.startOvertime(widget.submission['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Lembur berhasil dimulai'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Go back and refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Bukti Selesai Lembur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.colorCyan),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 30,
      );
      if (picked != null) {
        _submitFinishOvertime(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitFinishOvertime(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      List<String> attachmentsList = ['data:image/jpeg;base64,$base64String'];
      
      final storage = const FlutterSecureStorage();
      String? token = await storage.read(key: 'auth_token');

      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}requests/${widget.submission['id']}/overtime-finish',
        data: {
          'proof_image': jsonEncode(attachmentsList)
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembur berhasil diselesaikan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = e.message ?? 'Unknown error';
        if (e.response?.data is Map) {
          msg = e.response?.data['message'] ?? msg;
        } else if (e.response?.statusCode == 413) {
          msg = 'Ukuran file foto terlalu besar. Silakan coba lagi.';
        } else if (e.response?.data is String && e.response!.data.toString().isNotEmpty) {
          msg = 'Terjadi kesalahan pada server (${e.response?.statusCode}).';
        }
        
        if (mounted) setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $msg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class TicketPainter extends CustomPainter {
  final Color bgColor;
  final Color borderColor;

  TicketPainter({required this.bgColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const radius = 16.0;
    const holeRadius = 12.0;
    const holeY = 65.0; // Fixed y position for the hole (between header and body)

    // Start at top-left
    path.moveTo(radius, 0);
    // Top line
    path.lineTo(size.width - radius, 0);
    // Top-right corner
    path.arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius));
    
    // Right line down to hole
    path.lineTo(size.width, holeY - holeRadius);
    // Right hole (anti-clockwise)
    path.arcToPoint(Offset(size.width, holeY + holeRadius), radius: const Radius.circular(holeRadius), clockwise: false);
    
    // Right line down to bottom
    path.lineTo(size.width, size.height - radius);
    // Bottom-right corner
    path.arcToPoint(Offset(size.width - radius, size.height), radius: const Radius.circular(radius));
    
    // Bottom line
    path.lineTo(radius, size.height);
    // Bottom-left corner
    path.arcToPoint(Offset(0, size.height - radius), radius: const Radius.circular(radius));
    
    // Left line up to hole
    path.lineTo(0, holeY + holeRadius);
    // Left hole (anti-clockwise)
    path.arcToPoint(Offset(0, holeY - holeRadius), radius: const Radius.circular(holeRadius), clockwise: false);
    
    // Left line up to top
    path.lineTo(0, radius);
    // Top-left corner
    path.arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius));
    
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 8.0, true);
    // Draw background
    canvas.drawPath(path, paint);
    // Draw border
    canvas.drawPath(path, borderPaint);

    // Draw dashed line
    final dashPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashWidth = 6, dashSpace = 4, startX = holeRadius + 10;
    while (startX < size.width - holeRadius - 10) {
      canvas.drawLine(Offset(startX, holeY), Offset(startX + dashWidth, holeY), dashPaint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

