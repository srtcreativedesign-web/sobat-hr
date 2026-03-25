import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline_attendance_service.dart';
import 'attendance_qr_scanner_screen.dart';
import 'offline_selfie_screen.dart';
import '../../services/connectivity_service.dart';
import '../../services/attendance_service.dart';

/// Handler for offline attendance operations
/// This is called from the main AttendanceScreen when internet is not available
class OfflineAttendanceHandler {
  final BuildContext context;
  final OfflineAttendanceService _offlineService = OfflineAttendanceService();
  final AttendanceService _attendanceService = AttendanceService();
  final ConnectivityService _connectivity = ConnectivityService();

  OfflineAttendanceHandler({required this.context});

  /// Start offline attendance flow
  Future<void> startOfflineAttendance() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || user.employeeRecordId == null) {
      _showError('Data karyawan tidak valid. Silakan login ulang.');
      return;
    }

    // Determine track type
    final trackType = user.trackType;

    debugPrint('Starting offline attendance for track: $trackType');

    // Show track-specific instructions
    _showTrackInstructions(trackType, user.track == 'operational');

    // Wait a bit for user to read instructions
    await Future.delayed(const Duration(seconds: 2));

    // Start validation based on track
    if (trackType == 'operational') {
      _navigateToQrScanner();
    } else {
      _captureGpsAndSelfie();
    }
  }

  /// Show instructions based on track type
  void _showTrackInstructions(String trackType, [bool isDirect = false]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<bool>(
        future: _connectivity.checkConnectivity(),
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? _connectivity.isOnline;
          final String modePrefix = isOnline ? '' : 'Mode Offline - ';
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  trackType == 'operational'
                      ? Icons.qr_code_scanner
                      : Icons.gps_fixed,
                  color: AppTheme.colorCyan,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trackType == 'operational'
                        ? '${modePrefix}Outlet'
                        : '${modePrefix}Kantor',
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trackType == 'operational'
                      ? (isOnline 
                          ? 'Silakan scan QR Code (kamera belakang), lalu ambil foto verifikasi (kamera depan wide angle).'
                          : 'Karena tidak ada koneksi internet, silakan scan QR Code (kamera belakang), lalu ambil foto verifikasi (kamera depan wide angle).')
                      : (isOnline
                          ? 'Sistem akan merekam lokasi GPS Anda dan foto selfie sebagai bukti kehadiran.'
                          : 'Karena tidak ada koneksi internet, sistem akan merekam lokasi GPS Anda dan foto selfie sebagai bukti kehadiran.'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.colorCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.wifi : Icons.wifi_off,
                            size: 14,
                            color: isOnline ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline
                                ? 'Terhubung (Lansung ke Server)'
                                : 'Offline (Simpan di Perangkat)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOnline
                            ? '• Data akan langsung terkirim ke server'
                            : '• Data akan disimpan di perangkat dan otomatis terkirim saat ada internet',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (trackType == 'operational') {
                    _navigateToQrScanner();
                  } else {
                    _captureGpsAndSelfie();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorCyan,
                ),
                child: const Text(
                  'Mulai Absen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Navigate to QR scanner for operational track
  void _navigateToQrScanner() async {
    try {
      final qrCodeData = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AttendanceQrScannerScreen(onScanSuccess: (data) => data),
        ),
      );

      if (qrCodeData != null && qrCodeData.isNotEmpty) {
        // Validate QR format before proceeding (catches invalid/expired QR codes immediately)
        if (!_isValidQrFormat(qrCodeData)) {
          _showError('QR Code tidak valid. Format yang diharapkan: OUTLET-{ID}-LT{LANTAI}-{TIMESTAMP}-{KODE}');
          return;
        }

        // Try to get GPS coordinates as metadata (even for QR)
        double? lat;
        double? lng;
        
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: Platform.isIOS
                ? AppleSettings(
                    accuracy: LocationAccuracy.medium,
                    timeLimit: const Duration(seconds: 5),
                  )
                : const LocationSettings(
                    accuracy: LocationAccuracy.medium,
                    timeLimit: Duration(seconds: 5),
                  ),
          );
          lat = position.latitude;
          lng = position.longitude;
        } catch (e) {
          debugPrint('Optional GPS capture failed for QR track: $e');
          // Proceed with null GPS, which is now allowed by DB schema
        }

        // Show confirmation popup with outlet data
        _showOutletConfirmation(
          qrCodeData: qrCodeData,
          gpsLatitude: lat,
          gpsLongitude: lng,
        );
      }
    } catch (e) {
      debugPrint('QR Scanner error: $e');
      _showError('Gagal scan QR Code: $e');
    }
  }

  /// Capture GPS and proceed to selfie for HO track
  void _captureGpsAndSelfie() async {
    try {
      // Show loading while getting GPS
      _showLoading('Mengambil lokasi GPS...');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isIOS
            ? AppleSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 30),
                distanceFilter: 10,
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 30),
              ),
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Proceed to selfie with GPS coordinates
      await _proceedToSelfie(
        qrCodeData: null,
        gpsLatitude: position.latitude,
        gpsLongitude: position.longitude,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      debugPrint('GPS error: $e');
      _showError('Gagal mendapatkan lokasi GPS. Pastikan GPS aktif.');
    }
  }

  /// Proceed to selfie screen after validation
  Future<void> _proceedToSelfie({
    String? qrCodeData,
    double? gpsLatitude,
    double? gpsLongitude,
  }) async {
    final user = context.read<AuthProvider>().user;
    final trackType = user?.trackType ?? 'head_office';

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => OfflineSelfieScreen(
            trackType: trackType,
            qrCodeData: qrCodeData,
            gpsLatitude: gpsLatitude,
            gpsLongitude: gpsLongitude,
          ),
        ),
      );

      if (result != null && result['photoBase64'] != null) {
        // Process attendance (Smart logic: online first, then offline)
        await _processAttendance(
          userId: user!.id,
          employeeId: user.employeeRecordId!,
          trackType: trackType,
          validationMethod: trackType == 'operational' ? 'qr_code' : 'gps',
          qrCodeData: qrCodeData,
          gpsLatitude: gpsLatitude,
          gpsLongitude: gpsLongitude,
          photoPath: result['photoPath'],
          photoBase64: result['photoBase64'],
          locationAddress: result['address'],
        );
      }
    } catch (e) {
      debugPrint('Selfie error: $e');
      _showError('Gagal mengambil foto: $e');
    }
  }

  /// Process attendance with Smart Logic: Online first, then Local DB if failed
  Future<void> _processAttendance({
    required int userId,
    required int employeeId,
    required String trackType,
    required String validationMethod,
    String? qrCodeData,
    double? gpsLatitude,
    double? gpsLongitude,
    required String photoPath,
    required String photoBase64,
    String? locationAddress,
  }) async {
    try {
      _showLoading('Memproses absensi...');

      // 1. Check if server is actually reachable (not just WiFi connected)
      bool isOnline = false;
      try {
        isOnline = await _connectivity.hasInternetAccess().timeout(
          const Duration(seconds: 6),
        );
        debugPrint('Server reachability check: ${isOnline ? "REACHABLE" : "UNREACHABLE"}');
      } catch (e) {
        debugPrint('Server reachability check failed, assuming offline: $e');
        isOnline = false;
      }
      
      if (isOnline) {
        try {
          debugPrint('Server reachable, trying direct submission with 30s timeout...');
          await _attendanceService.checkIn(
            employeeId: employeeId,
            latitude: gpsLatitude ?? 0,
            longitude: gpsLongitude ?? 0,
            photo: File(photoPath),
            status: 'present',
            address: locationAddress,
            notes: qrCodeData,
            attendanceType: 'office',
            trackType: trackType,
          ).timeout(const Duration(seconds: 30));

          if (!context.mounted) return;
          Navigator.pop(context); // Close loading

          _showSuccess('✅ Absensi Berhasil terkirim ke server!');
          return;
        } on DioException catch (e) {
          // DioException propagated from AttendanceService — check type
          final isNetwork = _isNetworkError(e);
          debugPrint('checkIn DioException: type=${e.type}, statusCode=${e.response?.statusCode}, isNetwork=$isNetwork');
          debugPrint('Response body: ${e.response?.data}');

          if (isNetwork) {
            debugPrint('→ Network error, falling back to offline save');
            // Fall through to offline save below
          } else {
            // Server responded (4xx/5xx) — show actual error, do NOT save offline
            debugPrint('→ Server error, showing to user');
            if (!context.mounted) return;
            Navigator.pop(context); // Close loading
            _showError('Gagal absensi: ${_extractErrorMessage(e)}');
            return;
          }
        } catch (e) {
          // Non-Dio error (e.g. TimeoutException from .timeout())
          if (_isNetworkError(e)) {
            debugPrint('Non-Dio network error (${e.runtimeType}), falling back to offline: $e');
            // Fall through to offline save below
          } else {
            debugPrint('Non-Dio non-network error (${e.runtimeType}): $e');
            if (!context.mounted) return;
            Navigator.pop(context); // Close loading
            _showError('Gagal absensi: ${_extractErrorMessage(e)}');
            return;
          }
        }
      }

      // 2. Offline / Fallback Path
      debugPrint('Saving to local database...');
      await _offlineService.storeOfflineAttendance(
        userId: userId,
        employeeId: employeeId,
        trackType: trackType,
        validationMethod: validationMethod,
        qrCodeData: qrCodeData,
        gpsLatitude: gpsLatitude,
        gpsLongitude: gpsLongitude,
        photoPath: photoPath,
        photoBase64: photoBase64,
        locationAddress: locationAddress,
        attendanceType: 'office',
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      _showSuccess(
        '✅ Tersimpan secara Lokal (Mode Offline)\nData akan otomatis terkirim saat ada internet.',
      );

      // Trigger sync in background if online but first try failed
      _triggerBackgroundSync();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      debugPrint('Process error: $e');
      _showError('Gagal memproses absensi: $e');
    }
  }

  /// Trigger background sync service
  void _triggerBackgroundSync() async {
    try {
      final result = await _offlineService.syncAllUnsyncedAttendances();
      debugPrint('Sync result: $result');
    } catch (e) {
      debugPrint('Background sync error: $e');
      // Silent fail - sync will retry later
    }
  }

  /// Show confirmation dialog for operational track
  void _showOutletConfirmation({
    required String qrCodeData,
    double? gpsLatitude,
    double? gpsLongitude,
  }) {
    String outletName = 'Outlet Tidak Diketahui';
    String outletCode = '-';

    try {
      // Simple parsing logic (supports JSON or simple string)
      if (qrCodeData.startsWith('{')) {
        final data = jsonDecode(qrCodeData);
        outletName = data['name'] ?? data['outlet_name'] ?? qrCodeData;
        outletCode = data['code'] ?? data['outlet_code'] ?? '-';
      } else if (qrCodeData.contains('|')) {
        final parts = qrCodeData.split('|');
        for (var p in parts) {
          if (p.toLowerCase().contains('name:')) {
            outletName = p.split(':')[1].trim();
          }
          if (p.toLowerCase().contains('code:')) {
            outletCode = p.split(':')[1].trim();
          }
        }
      } else {
        outletName = qrCodeData;
      }
    } catch (e) {
      outletName = qrCodeData;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.store, color: AppTheme.colorCyan),
            SizedBox(width: 12),
            Text('Konfirmasi Outlet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code berhasil dipindai:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              outletName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Kode: $outletCode',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              'Silakan verifikasi kehadiran dengan mengambil foto area outlet (kamera depan wide angle).',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _proceedToSelfie(
                qrCodeData: qrCodeData,
                gpsLatitude: gpsLatitude,
                gpsLongitude: gpsLongitude,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Verifikasi Foto',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if an error is a network/connectivity issue (should fall back to offline)
  /// vs a server-side rejection (should show error to user)
  bool _isNetworkError(Object e) {
    // TimeoutException from .timeout()
    if (e is TimeoutException) return true;

    // SocketException (connection refused, no route to host, etc.)
    if (e is SocketException) return true;

    // DioException — check the type directly (AttendanceService now rethrows these)
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          // Server responded with 4xx/5xx — NOT a network error
          return false;
        default:
          // Unknown Dio error with no response — likely network
          return e.response == null;
      }
    }

    // Everything else (including wrapped Exception) — NOT a network error
    return false;
  }

  /// Extract a user-friendly error message from an exception
  String _extractErrorMessage(Object e) {
    // DioException with server response — extract the message from response body
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        // Server returns { "message": "..." }
        return data['message']?.toString() ?? 'Terjadi kesalahan pada server';
      }
    }

    // DioException without response body
    if (e is DioException) {
      return e.message ?? 'Terjadi kesalahan jaringan';
    }

    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }

  /// Validate QR code format.
  /// Accepts:
  ///   - Named format: KINGTECH-T3F-CGK-LT1-A3B2  ({CODE}-LT{FLOOR}-{RANDOM})
  ///   - Legacy format: OUTLET-123-LT1-1234567890-ABC123
  ///   - JSON format: {"code": "...", "name": "..."}
  ///   - Pipe-delimited: code:XXX|name:YYY
  bool _isValidQrFormat(String qrData) {
    // Named format: {CODE}-LT{FLOOR}-{RANDOM} (e.g. KINGTECH-T3F-CGK-LT1-A3B2)
    // Must contain -LT followed by a digit
    final namedPattern = RegExp(r'^[A-Za-z0-9\-]+-LT\d+-[A-Za-z0-9]+$');
    if (namedPattern.hasMatch(qrData)) return true;

    // Legacy format: OUTLET-123-LT1-1234567890-ABC123
    final legacyPattern = RegExp(r'^OUTLET-\d+-LT\d+-\d+-[A-Za-z0-9]+$');
    if (legacyPattern.hasMatch(qrData)) return true;

    // JSON format
    if (qrData.startsWith('{') && qrData.endsWith('}')) {
      try {
        jsonDecode(qrData);
        return true;
      } catch (_) {
        return false;
      }
    }

    // Pipe-delimited format
    if (qrData.contains('|') && qrData.contains('code:')) return true;

    return false;
  }

  // Helper methods
  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
