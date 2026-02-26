import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/thr_service.dart';
import '../../providers/auth_provider.dart';
import '../security/pin_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

class ThrScreen extends StatefulWidget {
  const ThrScreen({super.key});

  @override
  State<ThrScreen> createState() => _ThrScreenState();
}

class _ThrScreenState extends State<ThrScreen> {
  final ThrService _thrService = ThrService();
  bool _isLoading = true;
  bool _pinVerified = false;
  List<dynamic> _thrs = [];

  @override
  void initState() {
    super.initState();
    // Show PIN screen after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPinVerification();
    });
  }

  void _showPinVerification() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: user.hasPin ? PinMode.verify : PinMode.setup,
          onSuccess: () {
            Navigator.pop(context); // Close PIN Screen
            setState(() => _pinVerified = true);
            _loadThrs();
          },
        ),
      ),
    );
  }

  Future<void> _loadThrs() async {
    setState(() => _isLoading = true);
    try {
      final data = await _thrService.getThrs();
      setState(() {
        _thrs = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data THR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDownload(Map<String, dynamic> thr) {
    final id = thr['id'];
    final year = int.parse(thr['year'].toString());
    final details = thr['details'] ?? {};
    final storedSignature = details['employee_signature'];

    if (storedSignature != null && storedSignature.toString().isNotEmpty) {
      // Already signed — download directly (no signature page)
      _downloadThrSlip(id, year, null);
    } else {
      // First time — show signature page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _SignaturePage(
            onSigned: (Uint8List signatureBytes) async {
              Navigator.pop(context); // Close signature page
              await _downloadThrSlip(id, year, signatureBytes);
              // Refresh data so next time it skips signature
              _loadThrs();
            },
          ),
        ),
      );
    }
  }

  Future<void> _downloadThrSlip(
    int id,
    int year,
    Uint8List? signatureBytes,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // Convert signature bytes to base64 data URI
      String? signatureBase64;
      if (signatureBytes != null) {
        signatureBase64 =
            'data:image/png;base64,${base64Encode(signatureBytes)}';
      }

      final filename = 'Slip_THR_$year.pdf';
      await _thrService.downloadThrSlip(
        id,
        filename,
        employeeSignature: signatureBase64,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slip THR berhasil diunduh'),
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
      appBar: AppBar(
        backgroundColor: AppTheme.colorEggplant,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Tunjangan Hari Raya (THR)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: !_pinVerified
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verifikasi PIN diperlukan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showPinVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorEggplant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Masukkan PIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.colorEggplant),
            )
          : RefreshIndicator(
              onRefresh: _loadThrs,
              color: AppTheme.colorEggplant,
              child: _thrs.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _thrs.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildThrCard(_thrs[index]);
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
            Icons.card_giftcard_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada slip THR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Slip THR tahunan Anda akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildThrCard(Map<String, dynamic> thr) {
    final year = thr['year'];
    final amount = thr['amount'] ?? 0;
    final details = thr['details'] ?? {};
    final keterangan = details['keterangan'] ?? 'THR Idul Fitri $year';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THR TAHUN $year',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keterangan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(
                  'Jumlah THR',
                  _formatCurrency(
                    amount is String ? num.parse(amount) : amount,
                  ),
                  isTotal: true,
                ),
                if (details['masa_kerja'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Masa Kerja', details['masa_kerja']),
                ],
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showDetailSheet(thr),
                        icon: const Icon(Icons.info_outline, size: 20),
                        label: const Text('Detail'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textLight,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _handleDownload(thr),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Download PDF'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.colorEggplant,
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
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppTheme.textDark : AppTheme.textLight,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppTheme.colorEggplant : AppTheme.textDark,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  void _showDetailSheet(Map<String, dynamic> thr) {
    final amount = thr['amount'] ?? 0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail THR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildDetailItem('Tahun', thr['year'].toString()),
            _buildDetailItem(
              'Jumlah THR',
              _formatCurrency(amount is String ? num.parse(amount) : amount),
            ),
            _buildDetailItem(
              'Status',
              (thr['status'] ?? 'draft').toString().toUpperCase(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorEggplant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textLight)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Signature Page - shown before downloading THR slip
class _SignaturePage extends StatefulWidget {
  final Future<void> Function(Uint8List signatureBytes) onSigned;

  const _SignaturePage({required this.onSigned});

  @override
  State<_SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<_SignaturePage> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
    exportPenColor: Colors.black,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDownload() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tanda tangan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final signatureBytes = await _controller.toPngBytes();
      if (signatureBytes != null) {
        await widget.onSigned(signatureBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.colorEggplant,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Tanda Tangan Digital',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.clear(),
            tooltip: 'Hapus tanda tangan',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.colorEggplant.withValues(alpha: 0.05),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.draw_rounded,
                  size: 48,
                  color: AppTheme.colorEggplant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tanda Tangan Penerima',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Silakan tanda tangan di area bawah ini sebelum download slip THR',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Signature pad area
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Tanda tangan menggunakan jari Anda',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _confirmAndDownload,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isSaving ? 'Memproses...' : 'Download Slip THR',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorEggplant,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
