import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:ui';
import '../../config/theme.dart';
import '../../services/attendance_service.dart';

import 'dart:io';
import 'package:intl/intl.dart';
import 'selfie_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final AttendanceService _attendanceService = AttendanceService();

  // State
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;

  String? _currentAddress;
  bool _isWithinRange = false;
  Map<String, dynamic>? _todayAttendance;

  // Field Attendance
  String _attendanceType = 'office'; // 'office' or 'field'
  final TextEditingController _fieldNotesController = TextEditingController();

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Office Location
  LatLng? _officeLocation;
  double _attendanceRadius = 100; // Default

  @override
  void initState() {
    super.initState();
    _initOfficeLocation();
    _checkPermissionsAndLocate();
    _fetchTodayAttendance();

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

  void _initOfficeLocation() {
    final user = context.read<AuthProvider>().user;
    if (user != null &&
        user.officeLatitude != null &&
        user.officeLongitude != null) {
      _officeLocation = LatLng(user.officeLatitude!, user.officeLongitude!);
      if (user.officeRadius != null) {
        _attendanceRadius = user.officeRadius!.toDouble();
      }
    } else {
      // Fallback or Handle Error? For now keep dummy as worst case fallback or null
      // _officeLocation = const LatLng(-6.13778, 106.62295);
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
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    }
  }

  Future<void> _checkPermissionsAndLocate() async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Get Address
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            _currentAddress =
                '${place.street}, ${place.subLocality}, ${place.locality}';
          }
        } catch (e) {
          debugPrint('Error getting address: $e');
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkDistance(Position userPos) {
    if (_officeLocation == null) {
      if (mounted) {
        setState(() {
          _isWithinRange = false;
        });
      }
      return;
    }

    double distance = Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      _officeLocation!.latitude,
      _officeLocation!.longitude,
    );

    setState(() {
      _isWithinRange = distance <= _attendanceRadius;
    });
  }

  // ... (Keep existing methods until build)

  Future<void> _handleCheckIn() async {
    // 1. Validation
    if (_attendanceType == 'office' && !_isWithinRange) {
      _showErrorSnackBar('Anda harus berada di area kantor untuk absen!');
      return;
    }

    if (_attendanceType == 'field' &&
        _fieldNotesController.text.trim().isEmpty) {
      _showErrorSnackBar('Wajib mengisi keterangan untuk Absen Luar!');
      return;
    }

    // Navigate to SelfieScreen
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(address: _currentAddress),
      ),
    );

    if (photoPath != null) {
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
          fieldNotes: _attendanceType == 'field'
              ? _fieldNotesController.text
              : null,
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
  }

  Future<void> _handleCheckOut() async {
    // Check if original check-in was field type
    bool isFieldAttendance = _todayAttendance?['attendance_type'] == 'field';

    // Skip range check if field attendance
    if (!isFieldAttendance && !_isWithinRange) {
      _showErrorSnackBar('Anda harus berada di area kantor untuk absen!');
      return;
    }

    // 1. Photo Confirmation (Selfie)
    final String? photoPath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelfieScreen(address: _currentAddress),
      ),
    );

    if (photoPath == null) return; // User cancelled

    // 2. Submit Checkout
    _showLoading();

    try {
      if (_todayAttendance == null) {
        throw 'Data absensi hari ini tidak ditemukan.';
      }

      await _attendanceService.checkOut(
        attendanceId: _todayAttendance!['id'],
        checkOutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        photo: File(photoPath),
        status: 'present',
      );

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep existing var declarations)
    // Logic for Buttons
    bool hasCheckedIn = _todayAttendance != null;
    bool hasCheckedOut = hasCheckedIn && _todayAttendance!['check_out'] != null;

    bool canCheckIn = !hasCheckedIn;
    bool canCheckOut = hasCheckedIn && !hasCheckedOut;

    if (_officeLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presensi')),
        body: const Center(
          child: Text('Lokasi kantor belum diatur untuk Anda.'),
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
              initialCenter: _officeLocation!,
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sobat_hr',
              ),
              CircleLayer(
                circles: [
                  if (_officeLocation != null)
                    CircleMarker(
                      point: _officeLocation!,
                      color: AppTheme.colorCyan.withValues(alpha: 0.15),
                      borderColor: AppTheme.colorCyan,
                      borderStrokeWidth: 1,
                      useRadiusInMeter: true,
                      radius: _attendanceRadius,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_officeLocation != null)
                    Marker(
                      point: _officeLocation!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.business,
                              color: AppTheme.colorEggplant,
                              size: 24,
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
              child: Padding(
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
                            BoxShadow(color: Colors.black12, blurRadius: 10),
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
                                  ? 'Di dalam Area Kantor'
                                  : 'Di Luar Area Kantor',
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
            ),
          ),

          // 3. BOTTOM FLOATING CARD
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Toggle Attendance Type (Only if not checked in)
                      if (canCheckIn) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _attendanceType = 'office',
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _attendanceType == 'office'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: _attendanceType == 'office'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Absen Kantor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _attendanceType == 'office'
                                            ? AppTheme.colorEggplant
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _attendanceType = 'field'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _attendanceType == 'field'
                                          ? AppTheme.colorCyan
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: _attendanceType == 'field'
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.colorCyan
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Absen Luar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _attendanceType == 'field'
                                            ? Colors.white
                                            : Colors.grey,
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
                            decoration: InputDecoration(
                              labelText: 'Keterangan (Wajib)',
                              hintText: 'Contoh: Meeting dengan Client A',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],

                      // Show Active Type if Checked In
                      if (!canCheckIn) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color:
                                (_todayAttendance?['attendance_type'] ==
                                    'field')
                                ? AppTheme.colorCyan.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  (_todayAttendance?['attendance_type'] ==
                                      'field')
                                  ? AppTheme.colorCyan
                                  : Colors.grey.shade300,
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
                                color:
                                    (_todayAttendance?['attendance_type'] ==
                                        'field')
                                    ? AppTheme.colorCyan
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (_todayAttendance?['attendance_type'] ==
                                        'field')
                                    ? 'Mode: Absen Luar (Dinas)'
                                    : 'Mode: Absen Kantor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (_todayAttendance?['attendance_type'] ==
                                          'field')
                                      ? AppTheme.colorCyan
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Location Info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.colorCyan.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: AppTheme.colorCyan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lokasi Anda',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentAddress ?? 'Mencari lokasi...',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(height: 1, color: Colors.grey.shade200),
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
                                          _isWithinRange))
                                  ? _handleCheckIn
                                  : null,
                              icon: const Icon(Icons.login),
                              label: const Text('Masuk'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.colorCyan,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (canCheckOut && _isWithinRange && !_isLoading)
                                  ? _handleCheckOut
                                  : null,
                              icon: const Icon(Icons.logout),
                              label: const Text('Pulang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.colorEggplant,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
