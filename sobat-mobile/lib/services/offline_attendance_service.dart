import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/offline_attendance.dart';
import '../services/database_helper.dart';
import '../services/connectivity_service.dart';
import '../services/storage_service.dart';

/// Service to handle offline attendance operations
class OfflineAttendanceService {
  static final OfflineAttendanceService _instance = OfflineAttendanceService._internal();
  factory OfflineAttendanceService() => _instance;
  OfflineAttendanceService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final ConnectivityService _connectivity = ConnectivityService();
  
  /// Store offline attendance locally
  Future<int> storeOfflineAttendance({
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
    String? attendanceType,
    String? fieldNotes,
  }) async {
    try {
      final now = DateTime.now();
      final deviceInfo = await _getDeviceInfo();
      final deviceUptime = await _getDeviceUptime();

      final attendance = OfflineAttendance(
        userId: userId,
        employeeId: employeeId,
        trackType: trackType,
        validationMethod: validationMethod,
        qrCodeData: qrCodeData,
        gpsLatitude: gpsLatitude,
        gpsLongitude: gpsLongitude,
        timestamp: now.toIso8601String(),
        deviceTimestamp: now.toIso8601String(),
        photoPath: photoPath,
        photoBase64: photoBase64,
        locationAddress: locationAddress,
        attendanceType: attendanceType,
        fieldNotes: fieldNotes,
        deviceId: deviceInfo,
        deviceUptimeSeconds: deviceUptime,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      final id = await _db.insertOfflineAttendance(attendance.toMap());
      
      debugPrint('Offline attendance stored with ID: $id');
      debugPrint('Track type: $trackType, Validation: $validationMethod');
      debugPrint('Unsynced count: ${await _db.getUnsyncedCount()}');

      return id;
    } catch (e) {
      debugPrint('Error storing offline attendance: $e');
      rethrow;
    }
  }

  /// Get all unsynced attendance records
  Future<List<OfflineAttendance>> getUnsyncedAttendances() async {
    try {
      final records = await _db.getUnsyncedAttendances();
      return records.map((r) => OfflineAttendance.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getting unsynced attendances: $e');
      return [];
    }
  }

  /// Sync all unsynced attendance records to server
  Future<Map<String, dynamic>> syncAllUnsyncedAttendances() async {
    final unsynced = await getUnsyncedAttendances();
    
    if (unsynced.isEmpty) {
      return {
        'success': true,
        'message': 'No unsynced records',
        'synced': 0,
        'failed': 0,
      };
    }

    debugPrint('Starting sync of ${unsynced.length} offline attendance records');

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final attendance in unsynced) {
      try {
        await _syncSingleAttendance(attendance);
        await _db.markAsSynced(attendance.id!);
        synced++;
        debugPrint('Successfully synced attendance ID: ${attendance.id}');
      } catch (e) {
        failed++;
        await _db.incrementSyncAttempts(attendance.id!);
        errors.add('ID ${attendance.id}: $e');
        debugPrint('Failed to sync attendance ID ${attendance.id}: $e');
      }
    }

    return {
      'success': failed == 0,
      'message': 'Synced $synced, failed $failed',
      'synced': synced,
      'failed': failed,
      'errors': errors,
    };
  }

  /// Sync single attendance record to server
  Future<void> _syncSingleAttendance(OfflineAttendance attendance) async {
    // Check internet first
    final isOnline = await _connectivity.checkConnectivity();
    if (!isOnline) {
      throw Exception('No internet connection');
    }

    // Prepare payload
    final payload = {
      'employee_id': attendance.employeeId,
      'track_type': attendance.trackType,
      'validation_method': attendance.validationMethod,
      'photo_base64': attendance.photoBase64,
      'device_timestamp': attendance.deviceTimestamp,
      'device_id': attendance.deviceId ?? 'unknown',
      'device_uptime_seconds': attendance.deviceUptimeSeconds,
    };

    // Add validation-specific data
    if (attendance.validationMethod == 'qr_code') {
      payload['qr_code_data'] = attendance.qrCodeData;
    } else if (attendance.validationMethod == 'gps') {
      payload['gps_coordinates'] = {
        'latitude': attendance.gpsLatitude,
        'longitude': attendance.gpsLongitude,
      };
    }

    // Add optional fields
    if (attendance.attendanceType != null) {
      payload['attendance_type'] = attendance.attendanceType;
    }
    if (attendance.fieldNotes != null) {
      payload['field_notes'] = attendance.fieldNotes;
    }

    // Get auth token
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No auth token found');
    }

    // Send to server
    final url = Uri.parse('${ApiConfig.baseUrl}attendance/offline-sync');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw Exception('Request timeout');
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Server error: ${response.statusCode}');
    }
  }

  /// Get device unique ID
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      }
      
      return 'unknown_device';
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return 'unknown_device';
    }
  }

  /// Get device uptime in seconds (approximate)
  Future<int?> _getDeviceUptime() async {
    try {
      // Note: Getting actual device uptime requires native code
      // For now, we'll use a workaround with process start time
      // This is an approximation and may not be accurate across app restarts
      
      // In production, you'd use a platform channel to get actual uptime
      // For now, return null (server will still validate timestamp)
      return null;
    } catch (e) {
      debugPrint('Error getting device uptime: $e');
      return null;
    }
  }

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    return await _db.getUnsyncedCount();
  }

  /// Get total count of records
  Future<int> getTotalCount() async {
    return await _db.getTotalCount();
  }

  /// Cleanup old synced records (older than 7 days)
  Future<void> cleanupOldRecords({int daysToKeep = 7}) async {
    try {
      // Note: SQLite doesn't have direct date arithmetic in all versions
      // This is a simplified cleanup - in production, you'd want to query by date
      
      final allRecords = await _db.getAllAttendances();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      for (final record in allRecords) {
        if ((record['is_synced'] as int) == 1) {
          final createdAt = DateTime.parse(record['created_at'] as String);
          if (createdAt.isBefore(cutoffDate)) {
            await _db.deleteSyncedAttendance(record['id'] as int);
          }
        }
      }
      
      debugPrint('Cleanup completed');
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
