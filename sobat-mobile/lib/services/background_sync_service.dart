import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import '../services/offline_attendance_service.dart';
import '../services/connectivity_service.dart';

/// Background sync task for offline attendance
/// This runs periodically to sync unsynced attendance records to the server

// Task name constants
const String offlineSyncTaskName = 'offline-attendance-sync';
const String offlineSyncTaskTag = 'offline-sync';

/// Initialize WorkManager for background sync
void initializeBackgroundSync() {
  Workmanager().initialize(
    callbackDispatcher,
  );

  // Register periodic sync task
  // Minimum interval is 15 minutes on Android
  Workmanager().registerPeriodicTask(
    offlineSyncTaskTag,
    offlineSyncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  debugPrint('Background sync initialized');
}

/// Cancel background sync (if needed)
void cancelBackgroundSync() {
  Workmanager().cancelByTag(offlineSyncTaskTag);
  debugPrint('Background sync cancelled');
}

/// Callback dispatcher for WorkManager
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background sync task started: $task');

    try {
      // Initialize services
      final connectivityService = ConnectivityService();
      final offlineService = OfflineAttendanceService();

      // Check connectivity first
      final isOnline = await connectivityService.checkConnectivity();
      
      if (!isOnline) {
        debugPrint('No internet, skipping sync');
        return Future.value(false);
      }

      // Get unsynced count
      final unsyncedCount = await offlineService.getUnsyncedCount();
      debugPrint('Unsynced records: $unsyncedCount');

      if (unsyncedCount == 0) {
        debugPrint('No unsynced records');
        return Future.value(true);
      }

      // Perform sync
      final result = await offlineService.syncAllUnsyncedAttendances();
      
      debugPrint('Sync completed: $result');

      // Cleanup old records after successful sync
      if (result['success'] == true) {
        await offlineService.cleanupOldRecords(daysToKeep: 7);
      }

      return Future.value(result['success'] == true);
    } catch (e) {
      debugPrint('Background sync error: $e');
      return Future.value(false);
    }
  });
}

/// Trigger immediate sync (one-time)
Future<void> triggerImmediateSync() async {
  try {
    // Register one-off task
    await Workmanager().registerOneOffTask(
      'immediate-sync',
      offlineSyncTaskName,
      initialDelay: Duration.zero,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('Immediate sync triggered');
  } catch (e) {
    debugPrint('Failed to trigger immediate sync: $e');
  }
}
