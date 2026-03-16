/// Model for offline attendance record
class OfflineAttendance {
  final int? id;
  final int userId;
  final int employeeId;
  final String trackType; // 'head_office' or 'operational'
  final String validationMethod; // 'qr_code' or 'gps'
  final String? qrCodeData;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String timestamp;
  final String deviceTimestamp;
  final String photoPath;
  final String photoBase64;
  final String? locationAddress;
  final String? attendanceType;
  final String? fieldNotes;
  final bool isSynced;
  final int syncAttempts;
  final String? lastSyncAttemptAt;
  final String? deviceId;
  final int? deviceUptimeSeconds;
  final String createdAt;
  final String updatedAt;

  OfflineAttendance({
    this.id,
    required this.userId,
    required this.employeeId,
    required this.trackType,
    required this.validationMethod,
    this.qrCodeData,
    this.gpsLatitude,
    this.gpsLongitude,
    required this.timestamp,
    required this.deviceTimestamp,
    required this.photoPath,
    required this.photoBase64,
    this.locationAddress,
    this.attendanceType,
    this.fieldNotes,
    this.isSynced = false,
    this.syncAttempts = 0,
    this.lastSyncAttemptAt,
    this.deviceId,
    this.deviceUptimeSeconds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Map (database row)
  factory OfflineAttendance.fromMap(Map<String, dynamic> map) {
    return OfflineAttendance(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      employeeId: map['employee_id'] as int,
      trackType: map['track_type'] as String,
      validationMethod: map['validation_method'] as String,
      qrCodeData: map['qr_code_data'] as String?,
      gpsLatitude: map['gps_latitude'] as double?,
      gpsLongitude: map['gps_longitude'] as double?,
      timestamp: map['timestamp'] as String,
      deviceTimestamp: map['device_timestamp'] as String,
      photoPath: map['photo_path'] as String,
      photoBase64: map['photo_base64'] as String,
      locationAddress: map['location_address'] as String?,
      attendanceType: map['attendance_type'] as String?,
      fieldNotes: map['field_notes'] as String?,
      isSynced: (map['is_synced'] as int) == 1,
      syncAttempts: map['sync_attempts'] as int? ?? 0,
      lastSyncAttemptAt: map['last_sync_attempt_at'] as String?,
      deviceId: map['device_id'] as String?,
      deviceUptimeSeconds: map['device_uptime_seconds'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  /// Convert to Map (for database insert/update)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'employee_id': employeeId,
      'track_type': trackType,
      'validation_method': validationMethod,
      'qr_code_data': qrCodeData,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'timestamp': timestamp,
      'device_timestamp': deviceTimestamp,
      'photo_path': photoPath,
      'photo_base64': photoBase64,
      'location_address': locationAddress,
      'attendance_type': attendanceType,
      'field_notes': fieldNotes,
      'is_synced': isSynced ? 1 : 0,
      'sync_attempts': syncAttempts,
      'last_sync_attempt_at': lastSyncAttemptAt,
      'device_id': deviceId,
      'device_uptime_seconds': deviceUptimeSeconds,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create a copy with updated fields
  OfflineAttendance copyWith({
    int? id,
    int? userId,
    int? employeeId,
    String? trackType,
    String? validationMethod,
    String? qrCodeData,
    double? gpsLatitude,
    double? gpsLongitude,
    String? timestamp,
    String? deviceTimestamp,
    String? photoPath,
    String? photoBase64,
    String? locationAddress,
    String? attendanceType,
    String? fieldNotes,
    bool? isSynced,
    int? syncAttempts,
    String? lastSyncAttemptAt,
    String? deviceId,
    int? deviceUptimeSeconds,
    String? createdAt,
    String? updatedAt,
  }) {
    return OfflineAttendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      trackType: trackType ?? this.trackType,
      validationMethod: validationMethod ?? this.validationMethod,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      timestamp: timestamp ?? this.timestamp,
      deviceTimestamp: deviceTimestamp ?? this.deviceTimestamp,
      photoPath: photoPath ?? this.photoPath,
      photoBase64: photoBase64 ?? this.photoBase64,
      locationAddress: locationAddress ?? this.locationAddress,
      attendanceType: attendanceType ?? this.attendanceType,
      fieldNotes: fieldNotes ?? this.fieldNotes,
      isSynced: isSynced ?? this.isSynced,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      deviceId: deviceId ?? this.deviceId,
      deviceUptimeSeconds: deviceUptimeSeconds ?? this.deviceUptimeSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'OfflineAttendance(id: $id, employeeId: $employeeId, trackType: $trackType, validationMethod: $validationMethod, isSynced: $isSynced)';
  }
}
