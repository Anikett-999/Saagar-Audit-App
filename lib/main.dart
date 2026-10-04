import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/database.dart';
import 'services/cloud_sync_service.dart';
import 'services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open SQLite, run migrations, load seed JSON on first launch.
  await AppDatabase.instance.open();

  // Register daily background WorkManager task and run catch-up if needed (Spec §9.1).
  await WorkmanagerService.instance.initialize();
  await WorkmanagerService.instance.runCatchUpIfNeeded();

  // Safe, non-blocking Firebase initialization in background (Spec §1, §16.4)
  unawaited(CloudSyncService.instance.initialize());

  runApp(const ProviderScope(child: SaagarAuditApp()));
}

