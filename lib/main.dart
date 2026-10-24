import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/db/database.dart';
import 'services/cloud_sync_service.dart';
import 'services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for all locales to avoid LocaleDataException
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('hi', null);
  await initializeDateFormatting('mr', null);

  // Set global ErrorWidget.builder to prevent silent blank white screens in release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF121214),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFD4AF37), size: 48),
              const SizedBox(height: 16),
              const Text(
                'Render Notice',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Open SQLite, run migrations, load seed JSON on first launch.
  await AppDatabase.instance.open();

  // Register daily background WorkManager task and run catch-up if needed (Spec §9.1).
  await WorkmanagerService.instance.initialize();
  await WorkmanagerService.instance.runCatchUpIfNeeded();

  // Safe, non-blocking Firebase initialization in background (Spec §1, §16.4)
  unawaited(CloudSyncService.instance.initialize());

  runApp(const ProviderScope(child: SaagarAuditApp()));
}


