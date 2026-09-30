import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/db/database.dart';
import 'cap_aging_service.dart';

const String capAutoAgingTask = 'capAutoAgingTask';
const String capAutoAgingUniqueName = 'cap-auto-aging-daily';
const String lastCapAgingDateKey = 'last_cap_aging_date';

/// Top-level background isolate entry point for WorkManager.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == capAutoAgingTask || taskName == capAutoAgingUniqueName) {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        // 1. Check "already ran today" marker so multiple daily wake-ups no-op
        final prefs = await SharedPreferences.getInstance();
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final lastRunDate = prefs.getString(lastCapAgingDateKey);

        if (lastRunDate == todayStr) {
          debugPrint('WorkManager: CapAutoAging already ran today ($todayStr). Skipping.');
          return Future.value(true);
        }

        // 2. Open SQLite database in background isolate
        await AppDatabase.instance.open();

        // 3. Execute daily aging evaluation & escalation dispatch
        final summary = await CapAgingService.instance.runDailyAging();
        debugPrint(
          'WorkManager: CapAutoAging completed: ${summary.agedCount} aged, '
          '${summary.verifyPendingCount} verify-pending, '
          '${summary.escalationsRaised.length} escalations raised.',
        );

        // 4. Record successful run date
        await prefs.setString(lastCapAgingDateKey, todayStr);
        return Future.value(true);
      } catch (e, st) {
        debugPrint('WorkManager: error in CapAutoAging task: $e\n$st');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

class WorkmanagerService {
  WorkmanagerService._();
  static final WorkmanagerService instance = WorkmanagerService._();

  /// Initializes WorkManager and registers the daily periodic CAP aging task.
  ///
  /// Spec §9.1 states aging runs daily at 00:05 local time. Because Android WorkManager
  /// cannot guarantee exact minute firing times, it runs periodically (daily cadence)
  /// with a persistent "already ran today" marker preventing multiple evaluations per day.
  Future<void> initialize() async {
    // Only initialize on supported mobile platforms
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      await Workmanager().registerPeriodicTask(
        capAutoAgingUniqueName,
        capAutoAgingTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('WorkmanagerService: initialization skipped or failed: $e');
    }
  }

  /// App-launch catch-up runner: if the device was powered off or WorkManager was delayed,
  /// runs aging on app launch if it hasn't run yet today.
  Future<void> runCatchUpIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastRunDate = prefs.getString(lastCapAgingDateKey);

      if (lastRunDate != todayStr) {
        final summary = await CapAgingService.instance.runDailyAging();
        await prefs.setString(lastCapAgingDateKey, todayStr);
        debugPrint('WorkmanagerService: catch-up aging ran for $todayStr (${summary.agedCount} aged).');
      }
    } catch (e) {
      debugPrint('WorkmanagerService: catch-up aging check error: $e');
    }
  }
}
