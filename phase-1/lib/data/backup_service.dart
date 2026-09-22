import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db/database.dart';

/// Result summary of an exported SQLite database backup.
class BackupResult {
  const BackupResult({
    required this.filePath,
    required this.fileName,
    required this.tableCount,
    required this.totalRecords,
    required this.fileSizeBytes,
    required this.exportedAt,
  });

  final String filePath;
  final String fileName;
  final int tableCount;
  final int totalRecords;
  final int fileSizeBytes;
  final DateTime exportedAt;
}

/// Service for exporting the entire SQLite database to a structured JSON file.
///
/// Implements Spec §S32:
/// - Exports all 14 SQLite tables into a timestamped JSON file.
/// - Saves to device Downloads directory (with graceful fallback to documents).
/// - Contains sensitive audit history and bcrypt password hashes.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// All 14 relational tables in the Saagar Audit SQLite schema per Spec §4.
  static const List<String> kDatabaseTables = [
    'users',
    'devices',
    'sops',
    'checkpoints',
    'cros',
    'audits',
    'audit_results',
    'photos',
    'caps',
    'cap_actions',
    'cap_log',
    'reports',
    'escalations',
    'audit_log',
  ];

  Directory? _testDirectory;

  /// Injects a test directory for file export tests.
  void setDirectoryForTesting(Directory? dir) {
    _testDirectory = dir;
  }

  /// Exports all 14 tables as a map structure.
  Future<Map<String, Object?>> exportDatabaseToJson({Database? database}) async {
    final db = database ?? AppDatabase.instance.db;
    final tablesData = <String, List<Map<String, Object?>>>{};
    var totalRecords = 0;

    for (final table in kDatabaseTables) {
      try {
        final rows = await db.query(table);
        tablesData[table] = rows;
        totalRecords += rows.length;
      } catch (_) {
        // Table may be unseeded or empty
        tablesData[table] = [];
      }
    }

    final exportedAt = DateTime.now().toUtc();

    return {
      'app_name': 'Saagar Audit App',
      'app_version': '0.1.0+1',
      'schema_version': 1,
      'exported_at': exportedAt.toIso8601String(),
      'tables_count': kDatabaseTables.length,
      'total_records': totalRecords,
      'tables': tablesData,
    };
  }

  /// Locates the appropriate directory for saving backups.
  /// Prefers Downloads, falls back gracefully to ApplicationDocuments.
  Future<Directory> getBackupDirectory() async {
    if (_testDirectory != null) {
      return _testDirectory!;
    }

    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      // getDownloadsDirectory unsupported on some platforms/environments
    }

    dir ??= await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Generates the timestamped JSON backup and writes it to disk.
  Future<BackupResult> exportAndSaveToFile({
    Database? database,
    Directory? targetDir,
  }) async {
    final data = await exportDatabaseToJson(database: database);
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'saagar_audit_backup_$timestamp.json';

    final directory = targetDir ?? await getBackupDirectory();
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString, flush: true);

    final fileSizeBytes = await file.length();

    return BackupResult(
      filePath: filePath,
      fileName: fileName,
      tableCount: kDatabaseTables.length,
      totalRecords: data['total_records'] as int? ?? 0,
      fileSizeBytes: fileSizeBytes,
      exportedAt: now,
    );
  }
}
