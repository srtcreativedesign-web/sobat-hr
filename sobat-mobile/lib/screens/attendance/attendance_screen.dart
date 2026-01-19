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
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
  String _statusMessage = 'Mencari lokasi...';
  String? _currentAddress;
  bool _isWithinRange = false;
  Map<String, dynamic>? _todayAttendance;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Office Location (Dummy for now - Monas)
  // TODO: Fetch from User -> Employee -> Organization -> Lat/Lng
  static const LatLng _officeLocation = LatLng(-6.13778, 106.62295);
  static const double _attendanceRadius = 100; // meters

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
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

        setState(() {
          _currentPosition = position;
          _isLoading = false;
          _checkDistance(position);
        });

        // Move map to user location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          18.0,
        );
      } catch (e) {
        setState(() {
          _statusMessage = 'Gagal mendapatkan lokasi: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _statusMessage = 'Izin lokasi ditolak. Mohon aktifkan di pengaturan.';
        _isLoading = false;
      });
    }
  }

  void _checkDistance(Position userPos) {
    double distance = Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );

    setState(() {
      _isWithinRange = distance <= _attendanceRadius;
      if (_currentAddress != null) {
        _statusMessage = 'Jarak ke kantor: ${distance.toStringAsFixed(0)}m';
      } else {
        _statusMessage = _isWithinRange
            ? 'Anda berada di dalam area kantor (${distance.toStringAsFixed(0)}m)'
            : 'Anda berada di luar area kantor (${distance.toStringAsFixed(0)}m)';
      }
    });
  }

  Future<void> _handleCheckIn() async {
    if (!_isWithinRange) {
      _showErrorSnackBar('Anda harus berada di area kantor untuk absen!');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );

    if (photo != null) {
      _showLoading();

      try {
        final user = context.read<AuthProvider>().user;
        if (user?.employeeRecordId == null) {
          throw 'Data Karyawan tidak valid. Silakan login ulang.';
        }

        await _attendanceService.checkIn(
          employeeId: user!.employeeRecordId!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          photo: File(photo.path),
          status: 'present',
          address: _currentAddress,
        );

        await _fetchTodayAttendance(); // Refresh status

        if (!mounted) return;
        Navigator.pop(context); // Pop loading
        _showSuccessSnackBar('Check In Berhasil!');
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Pop loading
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> _handleCheckOut() async {
    if (!_isWithinRange) {
      _showErrorSnackBar('Anda harus berada di area kantor untuk absen!');
      return;
    }

    // 1. Photo Confirmation (Selfie)
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );

    if (photo == null) return; // User cancelled

    // 2. Submit Checkout
    _showLoading();

    try {
      if (_todayAttendance == null) {
        throw 'Data absensi hari ini tidak ditemukan.';
      }

      await _attendanceService.checkOut(
        attendanceId: _todayAttendance!['id'],
        checkOutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        photo: File(photo.path),
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
    // Logic for Buttons
    bool hasCheckedIn = _todayAttendance != null;
    bool hasCheckedOut = hasCheckedIn && _todayAttendance!['check_out'] != null;

    bool canCheckIn = !hasCheckedIn;
    bool canCheckOut = hasCheckedIn && !hasCheckedOut;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. FULL SCREEN MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _officeLocation,
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sobat_hr',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _officeLocation,
                    color: AppTheme.colorCyan.withOpacity(0.15),
                    borderColor: AppTheme.colorCyan,
                    borderStrokeWidth: 1,
                    useRadiusInMeter: true,
                    radius: _attendanceRadius,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _officeLocation,
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
                              BoxShadow(color: Colors.black26, blurRadius: 10),
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
                                  color: AppTheme.colorCyan.withOpacity(
                                    0.4 - (_pulseController.value * 0.4),
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
                              ? Colors.green.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
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
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Location Info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.colorCyan.withOpacity(0.1),
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
                                  (canCheckIn && _isWithinRange && !_isLoading)
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
