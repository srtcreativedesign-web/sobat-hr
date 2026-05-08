import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/attendance_service.dart';
import '../../widgets/attendance_badge.dart';
import 'attendance_screen.dart';
import 'selfie_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  List<dynamic> _history = [];
  List<dynamic> _unclosedAttendance = [];

  // Filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _attendanceService.getHistory(
        month: _selectedMonth,
        year: _selectedYear,
      );

      final unclosed = await _attendanceService.getUnclosedAttendance();

      setState(() {
        _history = data;
        _unclosedAttendance = unclosed;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _needsCheckout(Map<String, dynamic> item) {
    if (item['check_out'] != null) return false;
    final status = item['status']?.toString().toLowerCase() ?? '';
    return status == 'present' || status == 'late' || status == 'pending';
  }

  Future<void> _navigateToClockIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AttendanceScreen()),
    );
    _loadHistory();
  }

  Future<void> _navigateToCheckout(Map<String, dynamic> attendance) async {
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(
          address: attendance['location_address'] ?? '',
          shiftName: 'Regular Morning',
          isShifting: false,
          status: 'Clock Out Susulan',
        ),
      ),
    );

    if (photoPath == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _attendanceService.checkOut(
        attendanceId: attendance['id'],
        checkOutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        photo: File(photoPath),
        status: 'present',
        attendanceType: attendance['attendance_type'],
        fieldNotes: attendance['field_notes'],
      );

      if (!mounted) return;
      Navigator.pop(context);

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Berhasil!',
        desc: 'Clock Out Susulan berhasil!',
        btnOkColor: Colors.green,
        btnOkOnPress: () {},
      ).show();

      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Gagal!',
        desc: e.toString(),
        btnOkColor: Colors.red,
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Unclosed Attendance Banner
          if (_unclosedAttendance.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_unclosedAttendance.length} absensi belum checkout',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Klik tombol "Clock Out Susulan" di bawah untuk menyelesaikannya',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          DateFormat(
                            'MMMM',
                            'id_ID',
                          ).format(DateTime(2024, index + 1)),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                        _loadHistory();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _loadHistory();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(_history[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isWeekend ? null : _navigateToClockIn,
        backgroundColor: isWeekend ? Colors.grey : AppTheme.colorEggplant,
        icon: const Icon(Icons.fingerprint, color: Colors.white),
        label: Text(
          isWeekend ? 'Libur Akhir Pekan' : 'Absen Sekarang',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada riwayat absensi',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final date = DateTime.parse(item['date']);
    final checkIn = item['check_in'] != null
        ? item['check_in'].toString().substring(0, 5)
        : '-';
    final checkOut = item['check_out'] != null
        ? item['check_out'].toString().substring(0, 5)
        : '-';

    final needsCheckout = _needsCheckout(item);

    Color statusColor;
    switch (item['status']) {
      case 'present':
        statusColor = Colors.green;
        break;
      case 'late':
        statusColor = Colors.orange;
        break;
      case 'absent':
        statusColor = Colors.red;
        break;
      case 'leave':
        statusColor = Colors.blue;
        break;
      case 'sick':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: needsCheckout
            ? Border.all(color: Colors.orange.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Date Box
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'id_ID').format(date),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM y', 'id_ID').format(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            fontSize: 14,
                          ),
                        ),
                        AttendanceBadge(
                          status: item['status'] == 'late'
                              ? AttendanceStatus.late
                              : (item['status'] == 'absent'
                                  ? AttendanceStatus.absent
                                  : AttendanceStatus.onTime),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.login,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          checkIn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.logout,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          checkOut,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (needsCheckout) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCheckout(item),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Clock Out Susulan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
