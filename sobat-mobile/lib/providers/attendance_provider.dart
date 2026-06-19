import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/attendance_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  // Services
  final AttendanceService _attendanceService = AttendanceService();
  final ConnectivityService _connectivity = ConnectivityService();
  final OfflineAttendanceService _offlineService = OfflineAttendanceService();

  // State
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isOnline = true;
  String? _currentAddress;
  bool _isWithinRange = false;
  Map<String, dynamic>? _todayAttendance;
  String _attendanceType = 'office'; // 'office' or 'field'
  List<Map<String, dynamic>> _locations = [];
  String? _matchedLocationName;
  StreamSubscription<bool>? _connectivitySubscription;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get currentAddress => _currentAddress;
  bool get isWithinRange => _isWithinRange;
  Map<String, dynamic>? get todayAttendance => _todayAttendance;
  String get attendanceType => _attendanceType;
  List<Map<String, dynamic>> get locations => _locations;
  String? get matchedLocationName => _matchedLocationName;

  // Constructor
  AttendanceProvider() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = _connectivity.onlineStatusStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Hardcoded fallback locations
  static const List<Map<String, dynamic>> _fallbackLocations = [
    {'id': 'office', 'name': 'Office', 'latitude': -6.13778, 'longitude': 106.62295, 'radius_meters': 10},
    {'id': 'gudang_b3', 'name': 'Gudang B3', 'latitude': -6.134087, 'longitude': 106.623301, 'radius_meters': 10},
    {'id': 'training_centre', 'name': 'Training Centre', 'latitude': -6.133417, 'longitude': 106.629707, 'radius_meters': 10},
  ];

  Future<void> initLocations() async {
    try {
      final apiLocations = await _attendanceService.getAttendanceLocations();
      _locations = apiLocations.isNotEmpty
          ? apiLocations
          : _fallbackLocations.map((l) => Map<String, dynamic>.from(l)).toList();

      if (_currentPosition != null) {
        checkDistance(_currentPosition!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing locations in Provider: $e');
      _locations = _fallbackLocations.map((l) => Map<String, dynamic>.from(l)).toList();
      notifyListeners();
    }
  }

  Future<void> fetchTodayAttendance(int employeeRecordId) async {
    try {
      final attendance = await _attendanceService.getTodayAttendance();
      _todayAttendance = attendance;
      if (attendance != null && attendance['attendance_type'] != null) {
        _attendanceType = attendance['attendance_type'];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Server fetch failed, checking local database: $e');
      try {
        final localAttendance = await _offlineService.getTodayOfflineAttendance(employeeRecordId);
        if (localAttendance != null) {
          _todayAttendance = localAttendance;
          if (localAttendance['attendance_type'] != null) {
            _attendanceType = localAttendance['attendance_type'];
          }
        }
      } catch (localErr) {
        debugPrint('Local fetch also failed: $localErr');
      }
      notifyListeners();
    }
  }

  Future<void> checkConnectivity() async {
    _isOnline = await _connectivity.checkConnectivity();
    notifyListeners();
  }

  void setAttendanceType(String type) {
    _attendanceType = type;
    notifyListeners();
  }

  void checkDistance(Position userPos) {
    if (_locations.isEmpty) {
      _isWithinRange = false;
      _matchedLocationName = null;
      notifyListeners();
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

    _isWithinRange = found;
    _matchedLocationName = matchedName;
    notifyListeners();
  }

  Future<void> checkPermissionsAndLocate(MapController mapController) async {
    _isLoading = true;
    notifyListeners();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLoading = false;
      notifyListeners();
      throw 'GPS tidak aktif. Harap nyalakan Lokasi Anda.';
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.camera,
    ].request();

    final locationStatus = statuses[Permission.locationWhenInUse];
    final cameraStatus = statuses[Permission.camera];

    if (locationStatus == PermissionStatus.permanentlyDenied ||
        cameraStatus == PermissionStatus.permanentlyDenied) {
      _isLoading = false;
      notifyListeners();
      throw 'permission_blocked';
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
              : AndroidSettings(
                  accuracy: LocationAccuracy.high,
                  forceLocationManager: true,
                  timeLimit: const Duration(seconds: 10),
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
            _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}';
          }
        } catch (e) {
          debugPrint('Geocoding failed: $e');
          _currentAddress = 'Lokasi tidak diketahui';
        }

        _currentPosition = position;
        _isLoading = false;
        checkDistance(position);

        // Move map to user location
        mapController.move(
          LatLng(position.latitude, position.longitude),
          18.0,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Location fetching failed: $e');
        _isLoading = false;
        notifyListeners();
        throw 'Gagal mendapatkan lokasi GPS. Mohon coba lagi.';
      }
    } else {
      _isLoading = false;
      notifyListeners();
      throw 'Akses Lokasi & Kamera dibutuhkan untuk absensi.';
    }
  }

  Future<void> submitCheckIn({
    required int employeeId,
    required String photoPath,
    required String trackType,
    required bool isShifting,
    String? fieldNotes,
  }) async {
    if (_currentPosition == null) {
      throw 'Lokasi tidak ditemukan. Pastikan GPS aktif dan sinyal stabil.';
    }

    await _attendanceService.checkIn(
      employeeId: employeeId,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      photo: File(photoPath),
      status: 'present',
      address: _currentAddress,
      attendanceType: _attendanceType,
      fieldNotes: fieldNotes,
      trackType: trackType,
      isShifting: isShifting,
    );

    await fetchTodayAttendance(employeeId);
  }

  Future<void> submitCheckOut({
    required int attendanceId,
    required String checkOutTime,
    required String photoPath,
    required int employeeId,
    String? fieldNotes,
    required bool wasPreviousDay,
  }) async {
    await _attendanceService.checkOut(
      attendanceId: attendanceId,
      checkOutTime: checkOutTime,
      photo: File(photoPath),
      status: 'present',
      attendanceType: _attendanceType,
      fieldNotes: fieldNotes,
    );

    if (wasPreviousDay) {
      _todayAttendance = null;
    }
    
    await fetchTodayAttendance(employeeId);
  }

  Future<Map<String, dynamic>> manualSync(int employeeId) async {
    final result = await _offlineService.syncAllUnsyncedAttendances();
    if (result['success'] == true && result['synced'] > 0) {
      await fetchTodayAttendance(employeeId);
    }
    notifyListeners();
    return result;
  }
}
