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
      bottomNavigationBar: ((status == 'spl_open' || status == 'pending_final' || status == 'approved') && widget.submission['type'] == 'overtime') ? Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isUploading ? null : _showUploadModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.colorCyan,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isUploading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
              : Text(status == 'spl_open' ? 'Selesaikan Lembur' : 'Upload Foto Susulan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  if (status == 'spl_open' && widget.submission['detail']?['start_time'] != null) ...[
                    const SizedBox(height: 12),
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
                                  fontSize: 32,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Jam Mulai: $stString  |  Saat Ini: ${DateFormat('HH:mm:ss').format(_now)}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        } catch (e) {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
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

            _buildDetailRow(AppLocalizations.of(context)!.submissionType, typeStr),
            const SizedBox(height: 16),
            _buildDetailRow(AppLocalizations.of(context)!.date, duration),
            if (amount.isNotEmpty &&
                ![
                  'leave',
                  'sick',
                  'sick_leave',
                  'business_trip',
                  'overtime',
                ].contains(rawType)) ...[
              const SizedBox(height: 16),
              _buildDetailRow(AppLocalizations.of(context)!.nominalLabel, amount),
            ],
            if (widget.submission['type'] == 'business_trip' &&
                widget.submission['detail'] != null &&
                widget.submission['detail']['destination'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                'Tujuan',
                widget.submission['detail']['destination'].toString(),
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(AppLocalizations.of(context)!.description, reason),

            // Asset Details
            if (widget.submission['type'] == 'asset' &&
                widget.submission['detail'] != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.brandOrMake,
                widget.submission['detail']['brand'] ?? '-',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.specification,
                widget.submission['detail']['specification'] ?? '-',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                AppLocalizations.of(context)!.urgency,
                (widget.submission['detail']['is_urgent'] == true ||
                        widget.submission['detail']['is_urgent'] == 1)
                    ? AppLocalizations.of(context)!.urgencyUrgent
                    : AppLocalizations.of(context)!.urgencyNormal,
              ),
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
              ),
              const SizedBox(height: 16),
              _buildDetailRow(AppLocalizations.of(context)!.resignationType, AppLocalizations.of(context)!.resignationDefaultType),
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
