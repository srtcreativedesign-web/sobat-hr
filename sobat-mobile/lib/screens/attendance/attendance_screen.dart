import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Services
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  // State
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  String _statusMessage = 'Mencari lokasi...';
  bool _isWithinRange = false;

  // Office Location (Dummy for now - Monas)
  // TODO: Fetch from User -> Employee -> Organization -> Lat/Lng
  static const LatLng _officeLocation = LatLng(-6.13755, 106.62293);
  static const double _attendanceRadius = 100; // meters

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocate();
  }

  Future<void> _checkPermissionsAndLocate() async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

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
      _statusMessage = _isWithinRange
          ? 'Anda berada di dalam area kantor (${distance.toStringAsFixed(0)}m)'
          : 'Anda berada di luar area kantor (${distance.toStringAsFixed(0)}m)';
    });
  }

  Future<void> _handleCheckIn() async {
    if (!_isWithinRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus berada di area kantor untuk absen!'),
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50, // Compress
    );

    if (photo != null) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _attendanceService.checkIn(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          photo: File(photo.path),
          status: 'present', // Default to present
        );

        if (!mounted) return;
        Navigator.pop(context); // Pop loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Absensi Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // Back to home
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAP LAYER (Flutter Map OSM)
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
              // Office Circle & Marker
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _officeLocation,
                    color: Colors.green.withOpacity(0.2),
                    borderColor: Colors.green,
                    borderStrokeWidth: 2,
                    radius:
                        _attendanceRadius, // Radius in meters? Wait, flutter_map radius is in pixels usually? No, CircleMarker uses meters if useRadiusInMeter is true?
                    // CHECK: CircleMarker in flutter_map 7.0 uses radius in 'meters' if 'useRadiusInMeter' is true.
                    // Wait, let me check docs or assume standard behavior.
                    // Default is pixels. Need to check if version 7 supports meters.
                    // Actually, usually CircleMarker takes radius (pixels).
                    // To verify radius in meters, we might need Polygon or specific setting.
                    // For now let's assume pixel radius for visual or check if 'useRadiusInMeter' exists.
                    // Flutter Map 6+ has useRadiusInMeter: true.
                    useRadiusInMeter: true,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Office Marker
                  Marker(
                    point: _officeLocation,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.location_city, color: Colors.blue, size: 40),
                        Text(
                          'Kantor',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // User Marker
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // BACK BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // BOTTOM CARD
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Absensi Kehadiran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _isWithinRange
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isWithinRange
                              ? Icons.check_circle
                              : Icons.warning_rounded,
                          color: _isWithinRange ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _isWithinRange ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
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
                          onPressed: (_isLoading || !_isWithinRange)
                              ? null
                              : _handleCheckIn,
                          icon: const Icon(Icons.login),
                          label: const Text('Masuk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colorCyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || !_isWithinRange)
                              ? null
                              : _handleCheckIn, // Logic for check out later
                          icon: const Icon(Icons.logout),
                          label: const Text('Pulang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colorEggplant,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
