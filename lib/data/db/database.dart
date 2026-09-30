import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';
import 'seed_loader.dart';

/// Singleton wrapper around the SQLite database for the audit app.
///
/// Spec §2 mandates `sqflite` and offline-first behaviour — the app must
/// boot and be usable without network. Firestore sync is an upload-side
/// concern handled elsewhere; this class only owns the local store.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  /// True after [open] has completed; reopening is a no-op.
  bool get isOpen => _db != null;

  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('AppDatabase.open() must complete before db access.');
    }
    return d;
  }

  @visibleForTesting
  void setDatabaseForTesting(Database? testDb) {
    _db = testDb;
  }

  Future<void> open() async {
    if (_db != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'saagar_audit.db');

    _db = await openDatabase(
      dbPath,
      version: Schema.currentVersion,
      onConfigure: (db) async {
        // FK enforcement is enabled in onOpen after migrations/seeds complete,
        // so table schema restructures can run safely.
      },
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final stmt in Schema.createStatements) {
          batch.execute(stmt);
        }
        await batch.commit(noResult: true);
        await SeedLoader.loadAll(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration v1 -> v2:
          // In v1, sops table was created with CHECK (number BETWEEN 1 AND 8).
          // Recreate sops table to allow number >= 1 for SOP9 (Operations).
          await db.execute('''
            CREATE TABLE sops_v2 (
              id            TEXT PRIMARY KEY,
              number        INTEGER NOT NULL UNIQUE CHECK (number >= 1),
              name_en       TEXT NOT NULL,
              name_mr       TEXT NOT NULL,
              weight        INTEGER NOT NULL CHECK (weight IN (1,2)),
              is_critical   INTEGER NOT NULL DEFAULT 0 CHECK (is_critical IN (0,1)),
              display_order INTEGER NOT NULL
            );
          ''');
          await db.execute('INSERT OR IGNORE INTO sops_v2 SELECT * FROM sops');
          await db.execute('DROP TABLE sops');
          await db.execute('ALTER TABLE sops_v2 RENAME TO sops');

          await db.execute('''
            INSERT OR IGNORE INTO sops (id, number, name_en, name_mr, weight, is_critical, display_order)
            VALUES ('SOP9', 9, 'Operations', 'कार्यात्मक कामकाज', 1, 0, 9);
          ''');
          await SeedLoader.loadCheckpoints(db);
        }

        if (oldVersion < 3) {
          // Migration v2 -> v3 (Sprint P3-2b, Owner-authorised 2026-09-30):
          // 1. audits.inventory_variance_pct REAL (Spec §7 T4)
          // 2. audit_results.flag_security_concern INTEGER NOT NULL DEFAULT 0 (Spec §7 T5)
          try {
            final auditCols = await db.rawQuery('PRAGMA table_info(audits)');
            final hasInv = auditCols.any((c) => c['name'] == 'inventory_variance_pct');
            if (!hasInv) {
              await db.execute('ALTER TABLE audits ADD COLUMN inventory_variance_pct REAL;');
            }
          } catch (_) {}

          try {
            final resultCols = await db.rawQuery('PRAGMA table_info(audit_results)');
            final hasSec = resultCols.any((c) => c['name'] == 'flag_security_concern');
            if (!hasSec) {
              await db.execute(
                'ALTER TABLE audit_results ADD COLUMN flag_security_concern INTEGER NOT NULL DEFAULT 0 CHECK (flag_security_concern IN (0,1));',
              );
            }
          } catch (_) {}
        }
      },
      onOpen: (db) async {
        // Defensive check: ensure SOP9 exists in sops table in case a device
        // encountered a failed partial migration or legacy constraint.
        final sops = await db.rawQuery("SELECT id FROM sops WHERE id = 'SOP9'");
        if (sops.isEmpty) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sops_v2 (
              id            TEXT PRIMARY KEY,
              number        INTEGER NOT NULL UNIQUE CHECK (number >= 1),
              name_en       TEXT NOT NULL,
              name_mr       TEXT NOT NULL,
              weight        INTEGER NOT NULL CHECK (weight IN (1,2)),
              is_critical   INTEGER NOT NULL DEFAULT 0 CHECK (is_critical IN (0,1)),
              display_order INTEGER NOT NULL
            );
          ''');
          await db.execute('INSERT OR IGNORE INTO sops_v2 SELECT * FROM sops');
          await db.execute('DROP TABLE sops');
          await db.execute('ALTER TABLE sops_v2 RENAME TO sops');

          await db.execute('''
            INSERT OR IGNORE INTO sops (id, number, name_en, name_mr, weight, is_critical, display_order)
            VALUES ('SOP9', 9, 'Operations', 'कार्यात्मक कामकाज', 1, 0, 9);
          ''');
          await SeedLoader.loadCheckpoints(db);
        }

        // Defensive check: ensure monthly checkpoints exist in checkpoints table
        // in case an existing device installation upgraded from Phase 1 or 2.
        final monthlyCps = await db.rawQuery("SELECT id FROM checkpoints WHERE frequency = 'monthly'");
        if (monthlyCps.isEmpty) {
          await SeedLoader.loadCheckpoints(db);
        }

        // Defensive check: ensure v3 columns exist on audits and audit_results
        try {
          final auditCols = await db.rawQuery('PRAGMA table_info(audits)');
          final hasInv = auditCols.any((c) => c['name'] == 'inventory_variance_pct');
          if (!hasInv) {
            await db.execute('ALTER TABLE audits ADD COLUMN inventory_variance_pct REAL;');
          }
        } catch (_) {}

        try {
          final resultCols = await db.rawQuery('PRAGMA table_info(audit_results)');
          final hasSec = resultCols.any((c) => c['name'] == 'flag_security_concern');
          if (!hasSec) {
            await db.execute(
              'ALTER TABLE audit_results ADD COLUMN flag_security_concern INTEGER NOT NULL DEFAULT 0 CHECK (flag_security_concern IN (0,1));',
            );
          }
        } catch (_) {}

        // Clean up any empty drafts created before checkpoints were seeded
        await db.execute('''
          DELETE FROM audits 
          WHERE status = 'draft' 
            AND id NOT IN (SELECT DISTINCT audit_id FROM audit_results)
        ''');

        // Enable foreign key enforcement for all app queries per Spec §4
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// True if the `users` table is empty — used by S1 splash to decide
  /// whether to route to S3 First-Time Setup or straight to S4 Login.
  Future<bool> isFirstLaunch() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM users');
    final n = rows.first['n'] as int? ?? 0;
    return n == 0;
  }
}
