import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../services/attendance_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_attendance_service.dart';
import 'offline_attendance_handler.dart';

import 'dart:io';
import 'package:intl/intl.dart';
import 'selfie_screen.dart';
import 'attendance_qr_scanner_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final AttendanceService _attendanceService = AttendanceService();
  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineAttendanceService _offlineService = OfflineAttendanceService();

  // State
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isOnline = true;

  String? _currentAddress;
  bool _isWithinRange = false;
  Map<String, dynamic>? _todayAttendance;

  // Field Attendance
  String _attendanceType = 'office'; // 'office' or 'field'
  final TextEditingController _fieldNotesController = TextEditingController();

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Attendance Locations (multi-location)
  List<Map<String, dynamic>> _locations = [];
  String? _matchedLocationName;

  @override
  void initState() {
    super.initState();
    _initLocations();
    _checkPermissionsAndLocate();
    _fetchTodayAttendance();
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onlineStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
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

  /// Hardcoded fallback locations (used when API is unreachable)
  static const List<Map<String, dynamic>> _fallbackLocations = [
    {'id': 'office', 'name': 'Office', 'latitude': -6.13778, 'longitude': 106.62295, 'radius_meters': 10},
    {'id': 'gudang_b3', 'name': 'Gudang B3', 'latitude': -6.134087, 'longitude': 106.623301, 'radius_meters': 10},
    {'id': 'training_centre', 'name': 'Training Centre', 'latitude': -6.133417, 'longitude': 106.629707, 'radius_meters': 10},
  ];

  Future<void> _initLocations() async {
    try {
      // Try fetching from API first
      final apiLocations = await _attendanceService.getAttendanceLocations();
      if (mounted) {
        setState(() {
          _locations =
              apiLocations.isNotEmpty
                  ? apiLocations
                  : _fallbackLocations
                      .map((l) => Map<String, dynamic>.from(l))
                      .toList();
        });

        // Re-check distance if position already available
        if (_currentPosition != null) {
          _checkDistance(_currentPosition!);
        }
      }
    } catch (e) {
      debugPrint('Error initializing locations: $e');
      if (mounted) {
        setState(() {
          _locations =
              _fallbackLocations
                  .map((l) => Map<String, dynamic>.from(l))
                  .toList();
        });
      }
    }
  }

  @override
  void dispose() {
    _fieldNotesController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodayAttendance() async {
    try {
      final attendance = await _attendanceService.getTodayAttendance();
      if (mounted) {
        setState(() {
          _todayAttendance = attendance;
          if (attendance != null && attendance['attendance_type'] != null) {
            _attendanceType = attendance['attendance_type'];
          }
        });
      }
    } catch (e) {
      debugPrint('Server fetch failed, checking local database: $e');
      if (!mounted) return;
      
      // If server fails (offline), check local SQLite for today's record
      try {
        final user = context.read<AuthProvider>().user;
        if (user?.employeeRecordId != null) {
          final localAttendance = await _offlineService.getTodayOfflineAttendance(user!.employeeRecordId!);
          if (localAttendance != null && mounted) {
            setState(() {
              _todayAttendance = localAttendance;
              if (localAttendance['attendance_type'] != null) {
                _attendanceType = localAttendance['attendance_type'];
              }
            });
          }
        }
      } catch (localErr) {
        debugPrint('Local fetch also failed: $localErr');
      }
    }
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _connectivity.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  Future<void> _checkPermissionsAndLocate() async {
    // 1. Check if GPS hardware is actually ON
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('GPS tidak aktif. Harap nyalakan Lokasi Anda.');
      }
      return;
    }

    // Request both permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.camera,
    ].request();

    final locationStatus = statuses[Permission.locationWhenInUse];
    final cameraStatus = statuses[Permission.camera];

    if (locationStatus == PermissionStatus.permanentlyDenied ||
        cameraStatus == PermissionStatus.permanentlyDenied) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showPermissionHelpDialog();
      }
      return;
    }

    if (locationStatus!.isGranted && cameraStatus!.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: Platform.isIOS
              ? AppleSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 10,
                  pauseLocationUpdatesAutomatically: true,
                )
              : const LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
        ).timeout(const Duration(seconds: 15));

        // Get Address
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 10));
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            _currentAddress =
                '${place.street}, ${place.subLocality}, ${place.locality}';
          }
        } catch (e) {
          debugPrint('Geocoding failed: $e');
          _currentAddress = 'Lokasi tidak diketahui';
        }

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoading = false;
            _checkDistance(position);
          });
        }

        // Move map to user location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          18.0,
        );
      } catch (e) {
        debugPrint('Location fetching failed: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('Gagal mendapatkan lokasi GPS. Mohon coba lagi.');
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Akses Lokasi & Kamera dibutuhkan untuk absensi.');
      }
    }
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

  void _checkDistance(Position userPos) {
    if (_locations.isEmpty) {
      if (mounted) {
        setState(() {
          _isWithinRange = false;
          _matchedLocationName = null;
        });
      }
      return;
    }

    bool found = false;
    String? matchedName;

    for (final loc in _locations) {
      final distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      final radius = (loc['radius_meters'] as num?)?.toDouble() ?? 100.0;
      if (distance <= radius + 10) {
        found = true;
        matchedName = loc['name'] as String?;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isWithinRange = found;
        _matchedLocationName = matchedName;
      });
    }
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
    // 1. Validation
    if (_currentPosition == null) {
      _showErrorSnackBar(
        'Lokasi tidak ditemukan. Pastikan GPS aktif dan sinyal stabil.',
      );
      return;
    }

    if (_attendanceType == 'office' && !_isWithinRange) {
      _showErrorSnackBar('Anda harus berada di salah satu area lokasi absensi!');
      return;
    }

    if (_attendanceType == 'field' &&
        _fieldNotesController.text.trim().isEmpty) {
      _showErrorSnackBar('Wajib mengisi keterangan untuk Absen Luar!');
      return;
    }

    // Navigate based on track type
    final user = context.read<AuthProvider>().user;
    if (user?.trackType == 'operational') {
      OfflineAttendanceHandler(context: context).startOfflineAttendance();
      return;
    }

    // Check for Shifting (late > 60m)
    bool isShifting = false;
    final now = DateTime.now();
    if (now.hour >= 9) {
      bool userConfirmedShift = false;
      await AwesomeDialog(
        context: context,
        dialogType: DialogType.question,
        animType: AnimType.scale,
        title: 'Konfirmasi Shifting',
        desc: 'Anda terlambat lebih dari 60 menit. Apakah Anda bekerja shift hari ini?',
        btnOkText: 'YA',
        btnCancelText: 'TIDAK',
        btnOkColor: Colors.green,
        btnCancelColor: Colors.red,
        btnOkOnPress: () {
          userConfirmedShift = true;
        },
        btnCancelOnPress: () {
          userConfirmedShift = false;
        },
      ).show();
      isShifting = userConfirmedShift;
    }

    // Default HO Selfie flow
    if (!mounted) return;
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(
          address: _currentAddress,
          shiftName: user?.shiftName ?? 'Regular Morning',
          isShifting: isShifting,
          status: _attendanceType == 'office' 
            ? (isShifting ? 'Work from Office (Shift)' : 'Work from Office') 
            : 'Work from Field',
        ),
      ),
    );

    if (photoPath != null) {
      _submitAttendance(photoPath, isShifting: isShifting);
    }
  }

  Future<void> _handleCheckOut() async {
    // 0. Null checks
    if (_currentPosition == null) {
      _showErrorSnackBar(
        'Lokasi tidak ditemukan. Pastikan GPS aktif dan sinyal stabil.',
      );
      return;
    }

    if (_todayAttendance == null) {
      _showErrorSnackBar('Data absensi hari ini tidak ditemukan.');
      return;
    }

    // Check if this is an operational track checkout — requires QR scan
    final bool isOperational = _todayAttendance!['track_type'] == 'operational';
    String? checkoutQrData;

    if (isOperational) {
      // Operational track: scan QR at checkout (must match check-in outlet)
      checkoutQrData = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AttendanceQrScannerScreen(onScanSuccess: (data) => data),
        ),
      );

      if (checkoutQrData == null || checkoutQrData.isEmpty) return; // User cancelled
    } else {
      // Flexible checkout: check based on CURRENTLY SELECTED type in UI
      if (_attendanceType == 'office' && !_isWithinRange) {
        _showErrorSnackBar('Anda harus berada di salah satu area lokasi absensi untuk Absen Kantor!');
        return;
      }
      
      if (_attendanceType == 'field' && _fieldNotesController.text.trim().isEmpty) {
        _showErrorSnackBar('Wajib mengisi keterangan untuk Absen Luar saat pulang!');
        return;
      }
    }

    // 1. Photo Confirmation (Selfie)
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(
          address: _currentAddress,
          shiftName: user?.shiftName ?? 'Regular Morning',
          isShifting: false,
          status: _attendanceType == 'office' 
            ? 'Work from Office' 
            : 'Work from Field',
        ),
      ),
    );

    if (photoPath == null) return; // User cancelled

    // 2. Submit Checkout
    _showLoading();

    try {
      await _attendanceService.checkOut(
        attendanceId: _todayAttendance!['id'],
        checkOutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        photo: File(photoPath),
        status: 'present',
        qrCodeData: checkoutQrData,
        attendanceType: _attendanceType,
        fieldNotes: _attendanceType == 'field' ? _fieldNotesController.text : null,
      );

      _fieldNotesController.clear();
      await _fetchTodayAttendance(); // Refresh status

      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      _showSuccessSnackBar('Check Out Berhasil!');
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


  Future<void> _submitAttendance(String photoPath, {String? qrCodeData, bool isShifting = false}) async {
    _showLoading();

    try {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user?.employeeRecordId == null) {
        throw 'Data Karyawan tidak valid. Silakan login ulang.';
      }

      await _attendanceService.checkIn(
        employeeId: user!.employeeRecordId!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: File(photoPath),
        status: 'present',
        address: _currentAddress,
        attendanceType: _attendanceType,
        fieldNotes: _attendanceType == 'field' ? _fieldNotesController.text : null,
        trackType: user.trackType,
        isShifting: isShifting,
        notes: qrCodeData, // Include QR data in notes for operational
      );

      await _fetchTodayAttendance(); // Refresh status

      if (!mounted) return;
      Navigator.pop(context); // Pop loading

      if (_attendanceType == 'field') {
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
      final result = await _offlineService.syncAllUnsyncedAttendances();
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success'] == true && result['synced'] > 0) {
        _showSuccessSnackBar('Berhasil menyinkronkan ${result['synced']} data!');
        _fetchTodayAttendance(); // Refresh status
      } else if (result['synced'] == 0 && result['failed'] == 0) {
        _showSuccessSnackBar('Semua data sudah tersinkronisasi.');
      } else if (result['failed'] > 0) {
        _showErrorSnackBar('Gagal menyinkronkan ${result['failed']} data. Cek koneksi Anda.');
      }
      
      // Force UI refresh for the unsynced count
      setState(() {}); 
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnackBar('Gagal sinkronisasi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep existing var declarations)
    // Logic for Buttons
    bool hasCheckedIn = _todayAttendance != null;
    bool hasCheckedOut = hasCheckedIn && _todayAttendance!['check_out'] != null;

    bool canCheckIn = !hasCheckedIn;
    bool canCheckOut = hasCheckedIn && !hasCheckedOut;

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
                                future: _offlineService.getUnsyncedCount(),
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
                                    onTap: () => setState(
                                      () => _attendanceType = 'office',
                                    ),
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
                                    onTap: () => setState(
                                      () => _attendanceType = 'field',
                                    ),
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

                        // Offline Attendance Button (when no internet)
                        if (!_isOnline && canCheckIn) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Start offline attendance flow
                                OfflineAttendanceHandler(
                                  context: context,
                                ).startOfflineAttendance();
                              },
                              icon: const Icon(Icons.offline_pin),
                              label: const Text('Absen Offline'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.colorCyan,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            '• QR Code untuk operasional / GPS untuk kantor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Action Buttons (Online mode)
                        if (_isOnline)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (canCheckIn &&
                                          !_isLoading &&
                                          (_attendanceType == 'field' ||
                                              _isWithinRange))
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
                                          (_attendanceType == 'field' || _isWithinRange) &&
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
