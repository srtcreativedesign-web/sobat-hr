import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../../services/sobat_outlet_service.dart';
import '../../utils/error_handler.dart';

class SobatOutletHistoryScreen extends StatefulWidget {
  const SobatOutletHistoryScreen({super.key});

  @override
  State<SobatOutletHistoryScreen> createState() => _SobatOutletHistoryScreenState();
}

class _SobatOutletHistoryScreenState extends State<SobatOutletHistoryScreen> {
  final SobatOutletService _outletService = SobatOutletService();
  
  List<dynamic> _historyList = [];
  bool _isLoading = true;
  String? _deviceUid;
  String? _secretKey;
  Timer? _refreshTimer;
  bool _isDownloading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    final data = await StorageService.getSobatOutletData();
    if (data != null) {
      _deviceUid = data['device_uid'];
      _secretKey = data['secret_key'];
      await _fetchHistory();
      
      // Auto refresh every 5 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) _fetchHistory(isAutoRefresh: true);
      });
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _fetchHistory({bool isAutoRefresh = false}) async {
    if (_deviceUid == null || _secretKey == null) return;
    
    if (!isAutoRefresh && mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final list = await _outletService.getHistory(_deviceUid!, _secretKey!, date: dateStr);
      if (mounted) {
        setState(() {
          _historyList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isAutoRefresh) {
        setState(() => _isLoading = false);
        AppErrorHandler.showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 6)), // Maksimal 7 hari (hari ini + 6 hari ke belakang)
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchHistory();
    }
  }

  Future<void> _downloadFile(bool isPdf) async {
    if (_deviceUid == null || _secretKey == null) return;
    
    setState(() => _isDownloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      
      final ext = isPdf ? 'pdf' : 'xlsx';
      final savePath = '${dir.path}/Riwayat_Absen_${dateStr}_$timestamp.$ext';
      
      if (isPdf) {
        await _outletService.downloadPdf(_deviceUid!, _secretKey!, savePath, date: dateStr);
      } else {
        await _outletService.downloadExcel(_deviceUid!, _secretKey!, savePath, date: dateStr);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isPdf ? 'PDF' : 'Excel'} berhasil diunduh. Membuka file...')),
        );
      }
      
      await OpenFile.open(savePath);
    } catch (e) {
      if (mounted) {
        AppErrorHandler.showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year && 
                    _selectedDate.month == DateTime.now().month && 
                    _selectedDate.day == DateTime.now().day;
    final dateDisplay = isToday ? 'Hari Ini' : DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _pickDate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Riwayat Absen', style: TextStyle(fontSize: 16)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dateDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.table_view_rounded, color: Colors.greenAccent),
              tooltip: 'Unduh Excel',
              onPressed: () => _downloadFile(false),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              tooltip: 'Unduh PDF',
              onPressed: () => _downloadFile(true),
            ),
          ]
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _fetchHistory(isAutoRefresh: false),
            child: _historyList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada absensi hari ini',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    final employee = item['employee'] ?? {};
                    
                    String formatTime(dynamic timeString) {
                      if (timeString == null) return '-';
                      try {
                        // If it's just a time like "13:22:27"
                        if (timeString.toString().length <= 8) {
                          final parts = timeString.toString().split(':');
                          if (parts.length >= 2) {
                            return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
                          }
                        }
                        // If it's a full ISO string
                        return DateFormat('HH:mm').format(DateTime.parse(timeString.toString()).toLocal());
                      } catch (e) {
                        return timeString.toString().substring(0, 5); // fallback
                      }
                    }

                    final checkIn = formatTime(item['check_in']);
                    final checkOut = formatTime(item['check_out']);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              child: Text(
                                (employee['full_name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employee['full_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    employee['employee_code'] ?? '-',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildTimeBadge('IN ', checkIn, Colors.green),
                                const SizedBox(height: 8),
                                _buildTimeBadge('OUT', checkOut, Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _buildTimeBadge(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
