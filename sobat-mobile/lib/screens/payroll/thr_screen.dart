import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/thr_service.dart';
import 'package:intl/intl.dart';

class ThrScreen extends StatefulWidget {
  const ThrScreen({super.key});

  @override
  State<ThrScreen> createState() => _ThrScreenState();
}

class _ThrScreenState extends State<ThrScreen> {
  final ThrService _thrService = ThrService();
  bool _isLoading = true;
  List<dynamic> _thrs = [];

  @override
  void initState() {
    super.initState();
    _loadThrs();
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

  Future<void> _downloadThrSlip(int id, int year) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final filename = 'Slip_THR_$year.pdf';
      await _thrService.downloadThrSlip(id, filename);

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
      body: _isLoading
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
    final nominal = thr['net_nominal'] ?? thr['nominal'] ?? 0;
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
                colors: [
                  const Color(0xFF06B6D4), // Cyan 500
                  const Color(0xFF3B82F6), // Blue 500
                ],
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
                  'Nominal Bersih',
                  _formatCurrency(nominal),
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
                        onPressed: () => _downloadThrSlip(thr['id'], year),
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
              'Nominal Kotor',
              _formatCurrency(thr['nominal'] ?? 0),
            ),
            _buildDetailItem(
              'Potongan Pajak',
              _formatCurrency(thr['tax'] ?? 0),
            ),
            const Divider(height: 32),
            _buildDetailItem(
              'Nominal Diterima',
              _formatCurrency(thr['net_nominal'] ?? 0),
              isBold: true,
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
