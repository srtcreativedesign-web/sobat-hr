import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database helper for offline attendance queue
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intTypeNullable = 'INTEGER';
    const realType = 'REAL NOT NULL';

    // Offline attendance queue table
    await db.execute('''
      CREATE TABLE offline_attendances (
        id $idType,
        user_id $intType,
        employee_id $intType,
        track_type $textType,
        validation_method $textType,
        qr_code_data $textTypeNullable,
        gps_latitude $realType,
        gps_longitude $realType,
        timestamp $textType,
        device_timestamp $textType,
        photo_path $textType,
        photo_base64 $textType,
        location_address $textTypeNullable,
        attendance_type $textTypeNullable,
        field_notes $textTypeNullable,
        is_synced $intType DEFAULT 0,
        sync_attempts $intType DEFAULT 0,
        last_sync_attempt_at $textTypeNullable,
        device_id $textTypeNullable,
        device_uptime_seconds $intTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_sync_status 
      ON offline_attendances(is_synced, created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_employee 
      ON offline_attendances(employee_id)
    ''');
  }

  /// Insert new offline attendance record
  Future<int> insertOfflineAttendance(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('offline_attendances', row);
  }

  /// Get all unsynced attendance records
  Future<List<Map<String, dynamic>>> getUnsyncedAttendances() async {
    final db = await database;
    return await db.query(
      'offline_attendances',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  /// Get all attendance records (for debugging)
  Future<List<Map<String, dynamic>>> getAllAttendances() async {
    final db = await database;
    return await db.query(
      'offline_attendances',
      orderBy: 'created_at DESC',
    );
  }

  /// Mark attendance as synced
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'offline_attendances',
      {
        'is_synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increment sync attempts
  Future<int> incrementSyncAttempts(int id) async {
    final db = await database;
    return await db.rawUpdate('''
      UPDATE offline_attendances 
      SET sync_attempts = sync_attempts + 1, 
          last_sync_attempt_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  /// Update sync failure (keep is_synced = 0, but update attempts)
  Future<int> updateSyncFailure(int id, String errorMessage) async {
    final db = await database;
    return await db.update(
      'offline_attendances',
      {
        'sync_attempts': await _getSyncAttempts(id) + 1,
        'last_sync_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> _getSyncAttempts(int id) async {
    final db = await database;
    final result = await db.query(
      'offline_attendances',
      columns: ['sync_attempts'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return 0;
    return result.first['sync_attempts'] as int? ?? 0;
  }

  /// Delete synced records (cleanup old data)
  Future<int> deleteSyncedAttendance(int id) async {
    final db = await database;
    return await db.delete(
      'offline_attendances',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all synced records (bulk cleanup)
  Future<int> deleteAllSyncedAttendances() async {
    final db = await database;
    return await db.delete(
      'offline_attendances',
      where: 'is_synced = ?',
      whereArgs: [1],
    );
  }

  /// Get count of unsynced records
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_attendances WHERE is_synced = 0'
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Get count of all records
  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_attendances'
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
