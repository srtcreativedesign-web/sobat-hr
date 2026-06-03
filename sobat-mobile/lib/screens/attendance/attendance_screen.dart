import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../providers/attendance_provider.dart';
import '../../services/offline_attendance_service.dart';

import 'package:intl/intl.dart';
import 'selfie_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  // State variables for UI
  final MapController _mapController = MapController();
  final TextEditingController _fieldNotesController = TextEditingController();

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      attendanceProvider.checkConnectivity();
      attendanceProvider.initLocations();
      if (user?.employeeRecordId != null) {
        attendanceProvider.fetchTodayAttendance(user!.employeeRecordId!);
      }
      attendanceProvider.checkPermissionsAndLocate(_mapController).catchError((err) {
        if (mounted) {
          if (err == 'permission_blocked') {
            _showPermissionHelpDialog();
          } else {
            _showErrorSnackBar(err.toString());
          }
        }
      });
    });

    // Pulse Animation for User Location
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  void _showPermissionHelpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Izin Akses Terblokir'),
        content: const Text(
          'SOBAT HR membutuhkan akses Lokasi (GPS) dan Kamera untuk melakukan proses absensi.\n\n'
          'Karena izin ini diblokir secara permanen sebelumnya, silakan aktifkan secara manual melalui Pengaturan Aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCyan,
            ),
            child: const Text(
              'Buka Pengaturan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fieldNotesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getLocationIcon(String locationId) {
    return switch (locationId) {
      'office' => Icons.business,
      'gudang_b3' => Icons.warehouse,
      'training_centre' => Icons.school,
      _ => Icons.location_on,
    };
  }

  // ... (Keep existing methods until build)

  Future<void> _handleCheckIn() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    if (attendanceProvider.currentPosition == null) {
      _showErrorSnackBar(
        'Lokasi tidak ditemukan. Pastikan GPS aktif dan sinyal stabil.',
      );
      return;
    }

    final user = context.read<AuthProvider>().user;

    // Bypass range check for QR-based attendance
    if (attendanceProvider.attendanceType == 'office' && !attendanceProvider.isWithinRange && user?.trackType != 'operational') {
      _showErrorSnackBar('Anda harus berada di salah satu area lokasi absensi!');
      return;
    }

    if (attendanceProvider.attendanceType == 'field' &&
        _fieldNotesController.text.trim().isEmpty) {
      _showErrorSnackBar('Wajib mengisi keterangan untuk Absen Luar!');
      return;
    }

    if (!mounted) return;

    // Hitung durasi terlambat
    bool isShifting = false;
    final now = DateTime.now();
    DateTime workStartTime;
    
    final currentUser = user;
    if (currentUser != null && currentUser.shiftStartTime != null) {
      final timeParts = currentUser.shiftStartTime!.split(':');
      workStartTime = DateTime(
          now.year, now.month, now.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
    } else {
      workStartTime = DateTime(now.year, now.month, now.day, 8, 0);
    }

    final lateDuration = now.difference(workStartTime).inMinutes;

    if (lateDuration > 60) {
      final confirmShifting = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi Jam Kerja'),
          content: const Text(
              'Anda terdeteksi terlambat lebih dari 1 jam. Apakah Anda memiliki jadwal shifting hari ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak, Saya Terlambat'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Saya Shifting'),
            ),
          ],
        ),
      );

      if (confirmShifting == null) return; // User membatalkan dialog
      isShifting = confirmShifting;
    }

    if (!mounted) return;

    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(
          address: attendanceProvider.currentAddress,
          shiftName: user?.shiftName ?? 'Regular Morning',
          isShifting: isShifting,
          status: 'Work from Office',
        ),
      ),
    );

    if (photoPath != null) {
      _submitAttendance(
        photoPath,
        isShifting: isShifting,
      );
    }
  }

  Future<void> _handleCheckOut() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    if (attendanceProvider.currentPosition == null) {
      _showErrorSnackBar(
        'Lokasi tidak ditemukan. Pastikan GPS aktif dan sinyal stabil.',
      );
      return;
    }

    if (attendanceProvider.todayAttendance == null) {
      _showErrorSnackBar('Data absensi hari ini tidak ditemukan.');
      return;
    }

    if (attendanceProvider.attendanceType == 'office' && !attendanceProvider.isWithinRange) {
      _showErrorSnackBar('Anda harus berada di salah satu area lokasi absensi untuk Absen Kantor!');
      return;
    }
    
    if (attendanceProvider.attendanceType == 'field' && _fieldNotesController.text.trim().isEmpty) {
      _showErrorSnackBar('Wajib mengisi keterangan untuk Absen Luar saat pulang!');
      return;
    }

    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(
          address: attendanceProvider.currentAddress,
          shiftName: user?.shiftName ?? 'Regular Morning',
          isShifting: false,
          status: attendanceProvider.attendanceType == 'office' 
            ? 'Work from Office' 
            : 'Work from Field',
        ),
      ),
    );

    if (photoPath == null) return; // User cancelled

    _showLoading();
    final bool wasPreviousDay = attendanceProvider.todayAttendance?['is_previous_day'] == true;

    try {
      await attendanceProvider.submitCheckOut(
        attendanceId: attendanceProvider.todayAttendance!['id'],
        checkOutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        photoPath: photoPath,
        employeeId: user!.employeeRecordId!,
        fieldNotes: attendanceProvider.attendanceType == 'field' ? _fieldNotesController.text : null,
        wasPreviousDay: wasPreviousDay,
      );

      _fieldNotesController.clear();
      
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      _showSuccessSnackBar(wasPreviousDay
          ? 'Clock Out kemarin berhasil! Silakan Clock In untuk hari ini.'
          : 'Check Out Berhasil!');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      _showErrorSnackBar(e.toString());
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showErrorSnackBar(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Gagal',
      desc: message,
      btnOkColor: Colors.red,
      btnOkOnPress: () {},
    ).show();
  }

  void _showSuccessSnackBar(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Berhasil',
      desc: message,
      btnOkColor: Colors.green,
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _submitAttendance(String photoPath, {bool isShifting = false}) async {
    _showLoading();

    try {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user?.employeeRecordId == null) {
        throw 'Data Karyawan tidak valid. Silakan login ulang.';
      }

      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.submitCheckIn(
        employeeId: user!.employeeRecordId!,
        photoPath: photoPath,
        trackType: user.trackType ?? 'office',
        isShifting: isShifting,
        fieldNotes: attendanceProvider.attendanceType == 'field' ? _fieldNotesController.text : null,
      );

      if (!mounted) return;
      Navigator.pop(context); // Pop loading

      if (attendanceProvider.attendanceType == 'field') {
        _showSuccessSnackBar('Check In Berhasil! Menunggu approval admin.');
      } else {
        _showSuccessSnackBar('Check In Berhasil!');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _manualSync() async {
    _showLoading();
    try {
      final user = context.read<AuthProvider>().user;
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final result = await attendanceProvider.manualSync(user!.employeeRecordId!);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success'] == true && result['synced'] > 0) {
        _showSuccessSnackBar('Berhasil menyinkronkan ${result['synced']} data!');
      } else if (result['synced'] == 0 && result['failed'] == 0) {
        _showSuccessSnackBar('Semua data sudah tersinkronisasi.');
      } else if (result['failed'] > 0) {
        _showErrorSnackBar('Gagal menyinkronkan ${result['failed']} data. Cek koneksi Anda.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Gagal sinkronisasi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final _todayAttendance = attendanceProvider.todayAttendance;
    final _isOnline = attendanceProvider.isOnline;
    final _isLoading = attendanceProvider.isLoading;
    final _isWithinRange = attendanceProvider.isWithinRange;
    final _matchedLocationName = attendanceProvider.matchedLocationName;
    final _locations = attendanceProvider.locations;
    final _currentPosition = attendanceProvider.currentPosition;
    final _currentAddress = attendanceProvider.currentAddress;
    final _attendanceType = attendanceProvider.attendanceType;

    // Logic for Buttons
    bool hasCheckedIn = _todayAttendance != null;
    bool hasCheckedOut = hasCheckedIn && _todayAttendance!['check_out'] != null;

    // Decoupled logic: can check in if no record today OR already checked out
    bool canCheckIn = !hasCheckedIn || hasCheckedOut;
    bool canCheckOut = hasCheckedIn && !hasCheckedOut;

    // Operational users skip location range check (QR code = location proof)
    final bool isOperational =
        context.read<AuthProvider>().user?.trackType == 'operational';

    // Check Late Logic
    bool isLateRestricted = false;
    if (hasCheckedIn &&
        !hasCheckedOut &&
        _todayAttendance!['check_in'] != null) {
      String statusStr =
          _todayAttendance!['status']?.toString().toLowerCase() ?? '';
      String checkInTimeStr = _todayAttendance!['check_in'].toString();

      bool isLate = false;
      try {
        // Parse HH:mm:ss
        final parts = checkInTimeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          // Check if after 08:05
          if (hour > 8 || (hour == 8 && minute > 5)) {
            isLate = true;
          }
        }
      } catch (_) {}

      // If late and still pending, prevent checkout
      if (isLate && statusStr == 'pending') {
        isLateRestricted = true;
        canCheckOut = false;
      }
    }

    // Gradient Colors based on status
    // Gradient & Text Colors
    List<Color> gradientColors = AppTheme.gradientDefault;
    Color textColor = AppTheme.colorEggplant;
    Color subTextColor = AppTheme.colorEggplant.withValues(alpha: 0.7);
    Color glassBorderColor = AppTheme.colorEggplant.withValues(alpha: 0.1);
    Color buttonTextColor = AppTheme.colorEggplant;

    if (canCheckOut) {
      gradientColors = AppTheme.gradientWorking;
      textColor = Colors.white;
      subTextColor = Colors.white.withValues(alpha: 0.7);
      glassBorderColor = Colors.white.withValues(alpha: 0.1);
      buttonTextColor = gradientColors[0];
    } else if (hasCheckedOut) {
      gradientColors = AppTheme.gradientFinished;
      textColor = Colors.white;
      subTextColor = Colors.white.withValues(alpha: 0.7);
      glassBorderColor = Colors.white.withValues(alpha: 0.1);
      buttonTextColor = gradientColors[0];
    }

    if (_locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presensi')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. FULL SCREEN MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                (_locations.first['latitude'] as num).toDouble(),
                (_locations.first['longitude'] as num).toDouble(),
              ),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sobat_hr',
              ),
              CircleLayer(
                circles: [
                  for (final loc in _locations)
                    CircleMarker(
                      point: LatLng(
                        (loc['latitude'] as num).toDouble(),
                        (loc['longitude'] as num).toDouble(),
                      ),
                      color: (loc['name'] == _matchedLocationName)
                          ? Colors.green.withValues(alpha: 0.2)
                          : AppTheme.colorCyan.withValues(alpha: 0.15),
                      borderColor: (loc['name'] == _matchedLocationName)
                          ? Colors.green
                          : AppTheme.colorCyan,
                      borderStrokeWidth: (loc['name'] == _matchedLocationName) ? 2 : 1,
                      useRadiusInMeter: true,
                      radius: (loc['radius_meters'] as num?)?.toDouble() ?? 100.0,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final loc in _locations)
                    Marker(
                      point: LatLng(
                        (loc['latitude'] as num).toDouble(),
                        (loc['longitude'] as num).toDouble(),
                      ),
                      width: 80,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (loc['name'] == _matchedLocationName)
                                  ? Colors.green
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Text(
                              loc['name'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: (loc['name'] == _matchedLocationName)
                                    ? Colors.white
                                    : AppTheme.colorEggplant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                            ),
                            child: Icon(
                              _getLocationIcon(loc['id'] as String? ?? ''),
                              color: (loc['name'] == _matchedLocationName)
                                  ? Colors.green
                                  : AppTheme.colorEggplant,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 100,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 40 * _pulseAnimation.value,
                                height: 40 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.colorCyan.withValues(
                                    alpha: 0.4 - (_pulseController.value * 0.4),
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.colorCyan,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Offline Banner
                  if (!_isOnline)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colorCyan.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.wifi_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mode Offline Aktif',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Absensi akan disimpan lokal dan terkirim otomatis saat online',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Manual Sync Button
                              IconButton(
                                icon: const Icon(Icons.sync, color: Colors.white),
                                onPressed: () => _manualSync(),
                                tooltip: 'Sinkronisasi Sekarang',
                              ),
                              // Show unsynced count
                              FutureBuilder<int>(
                                future: OfflineAttendanceService().getUnsyncedCount(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data! == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${snapshot.data} tertunda',
                                      style: TextStyle(
                                        color: AppTheme.colorCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Original Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: AppTheme.textDark,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        if (!_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isWithinRange
                                  ? Colors.green.withValues(alpha: 0.9)
                                  : Colors.red.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isWithinRange
                                      ? Icons.verified
                                      : Icons.location_off,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isWithinRange
                                      ? 'Di Area ${_matchedLocationName ?? 'Kantor'}'
                                      : 'Di Luar Area',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BOTTOM FLOATING CARD
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background Pattern
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Attendance Type (Visible if not finished today)
                        if (canCheckIn || canCheckOut) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => attendanceProvider.setAttendanceType('office'),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _attendanceType == 'office'
                                            ? textColor.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Absen Kantor',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _attendanceType == 'office'
                                              ? textColor
                                              : subTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => attendanceProvider.setAttendanceType('field'),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _attendanceType == 'field'
                                            ? textColor.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Absen Luar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _attendanceType == 'field'
                                              ? textColor
                                              : subTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Field Notes Input
                          if (_attendanceType == 'field') ...[
                            TextField(
                              controller: _fieldNotesController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'Keterangan (Wajib)',
                                labelStyle: TextStyle(color: subTextColor),
                                hintText: 'Contoh: Meeting dengan Client A',
                                hintStyle: TextStyle(
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.1),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],

                        // Show Active Check-in Type if already Checked In
                        if (hasCheckedIn) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: textColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: textColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  (_todayAttendance?['attendance_type'] ==
                                          'field')
                                      ? Icons.commute
                                      : Icons.store,
                                  size: 16,
                                  color: textColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (_todayAttendance?['attendance_type'] ==
                                          'field')
                                      ? 'Mode: Absen Luar (Dinas)'
                                      : 'Mode: Absen Kantor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                if (_todayAttendance?['is_offline_local'] == true) ...[
                                  const Spacer(),
                                  Icon(
                                    _todayAttendance?['is_synced'] == true
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    size: 14,
                                    color: textColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _todayAttendance?['is_synced'] == true
                                        ? 'Ter-sync'
                                        : 'Lokal',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: textColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Location Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: glassBorderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi Anda',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentAddress ?? 'Mencari lokasi...',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (canCheckIn &&
                                        !_isLoading &&
                                        (_attendanceType == 'field' ||
                                            _isWithinRange ||
                                            isOperational))
                                        ? _handleCheckIn
                                        : null,
                                icon: Icon(
                                  Icons.login,
                                  color: buttonTextColor,
                                ),
                                label: Text('Masuk'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: buttonTextColor,
                                  disabledBackgroundColor: Colors.white,
                                  disabledForegroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (canCheckOut &&
                                        (_attendanceType == 'field' || _isWithinRange || isOperational) &&
                                        !_isLoading)
                                        ? _handleCheckOut
                                        : null,
                                icon: Icon(
                                  Icons.logout,
                                  color: canCheckOut
                                      ? buttonTextColor
                                      : Colors.grey,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isLateRestricted
                                        ? 'Menunggu Approval'
                                        : 'Pulang',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: buttonTextColor,
                                  disabledBackgroundColor: Colors.white,
                                  disabledForegroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
