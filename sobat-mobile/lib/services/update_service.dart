import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check for update and trigger appropriate UI
  Future<void> checkForUpdate() async {
    if (kIsWeb || !defaultTargetPlatform.toString().contains('android')) {
      // In-app updates are only available for Android
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // If update is available, decide which one to use.
        // For now, let's use Flexible update so user can still use the app.
        // If the update is critical, we could use performImmediateUpdate().

        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          // After downloading, user needs to complete the update
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
    }
  }
}
