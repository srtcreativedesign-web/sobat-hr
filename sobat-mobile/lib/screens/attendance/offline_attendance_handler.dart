import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/offline_attendance_service.dart';
import 'offline_qr_scanner_screen.dart';
import 'offline_selfie_screen.dart';
import '../../services/connectivity_service.dart';

/// Handler for offline attendance operations
/// This is called from the main AttendanceScreen when internet is not available
class OfflineAttendanceHandler {
  final BuildContext context;
  final OfflineAttendanceService _offlineService = OfflineAttendanceService();

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
    final connectivity = ConnectivityService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<bool>(
        future: connectivity.checkConnectivity(),
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? true;
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
                        '📝 Catatan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOnline
                            ? '• Data akan langsung terkirim ke server'
                            : '• Data akan disimpan di perangkat dan otomatis terkirim saat ada internet',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (!isOnline) ...[
                        const SizedBox(height: 4),
                        const Text(
                          '• Waktu absen dicatat saat tombol ditekan, bukan saat terkirim',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
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
              OfflineQrScannerScreen(onScanSuccess: (data) => data),
        ),
      );

      if (qrCodeData != null && qrCodeData.isNotEmpty) {
        // QR scan successful, proceed to selfie
        await _proceedToSelfie(
          qrCodeData: qrCodeData,
          gpsLatitude: null,
          gpsLongitude: null,
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
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
        // Save offline attendance
        await _saveOfflineAttendance(
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

  /// Save offline attendance to local database
  Future<void> _saveOfflineAttendance({
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
      _showLoading('Menyimpan absensi...');

      final attendanceType = 'office'; // Default for offline

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
        attendanceType: attendanceType,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Show success
      _showSuccess(
        '✅ Absensi berhasil disimpan!\nData akan otomatis terkirim saat ada internet.',
      );

      // Trigger sync check
      _triggerBackgroundSync();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      debugPrint('Save error: $e');
      _showError('Gagal menyimpan absensi: $e');
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
