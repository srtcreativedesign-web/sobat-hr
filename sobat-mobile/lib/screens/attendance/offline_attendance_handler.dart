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

    // Show track-specific instructions (has its own "Mulai Absen" button)
    _showTrackInstructions(trackType, user.track == 'operational');
  }


  /// Show instructions based on track type
  void _showTrackInstructions(String trackType, [bool isDirect = false]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => FutureBuilder<bool>(
        future: _connectivity.checkConnectivity(),
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? _connectivity.isOnline;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Icon badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: trackType == 'operational'
                          ? [AppTheme.colorCyan, const Color(0xFF0D47A1)]
                          : [AppTheme.colorEggplant, const Color(0xFF6A1B9A)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    trackType == 'operational'
                        ? Icons.qr_code_scanner_rounded
                        : Icons.gps_fixed_rounded,
                    color: Colors.white, size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  trackType == 'operational'
                      ? 'Absen Outlet'
                      : 'Absen Kantor',
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Connection badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOnline ? Colors.green : Colors.orange,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        size: 14,
                        color: isOnline ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online — Langsung ke Server' : 'Offline — Simpan di Perangkat',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isOnline ? Colors.green[700] : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Steps
                ..._buildSteps(trackType),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (trackType == 'operational') {
                            _navigateToQrScanner();
                          } else {
                            _captureGpsAndSelfie();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trackType == 'operational'
                              ? AppTheme.colorCyan : AppTheme.colorEggplant,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Mulai Absen',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build step indicators for instructions
  List<Widget> _buildSteps(String trackType) {
    final steps = trackType == 'operational'
        ? [
            {'icon': Icons.qr_code_scanner_rounded, 'title': 'Scan QR Code', 'desc': 'Arahkan kamera belakang ke QR yang ditempel di outlet'},
            {'icon': Icons.camera_front_rounded, 'title': 'Foto Selfie', 'desc': 'Ambil foto verifikasi dengan kamera depan (wide angle)'},
            {'icon': Icons.cloud_upload_rounded, 'title': 'Kirim Data', 'desc': 'Data akan dikirim ke server atau disimpan lokal'},
          ]
        : [
            {'icon': Icons.gps_fixed_rounded, 'title': 'Rekam GPS', 'desc': 'Sistem akan merekam lokasi GPS Anda secara otomatis'},
            {'icon': Icons.camera_front_rounded, 'title': 'Foto Selfie', 'desc': 'Ambil foto wajah sebagai bukti kehadiran'},
            {'icon': Icons.cloud_upload_rounded, 'title': 'Kirim Data', 'desc': 'Data akan dikirim ke server atau disimpan lokal'},
          ];

    return steps.asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.colorCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(step['icon'] as IconData, color: AppTheme.colorCyan, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah ${i + 1}: ${step['title']}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    step['desc'] as String,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Success icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),

            const Text(
              'QR Code Berhasil Dipindai!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 20),

            // Outlet card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.colorCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_rounded, color: AppTheme.colorCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outletName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (outletCode != '-')
                              Text(
                                'Kode: $outletCode',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Instruction text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Selanjutnya, ambil foto selfie untuk verifikasi kehadiran.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_front_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Ambil Foto',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 60),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mohon tunggu sebentar...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
