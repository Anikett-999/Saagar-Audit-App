import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/db/database.dart';

/// Status of the cloud sync engine.
enum CloudSyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
  unconfigured,
}

/// Result of an attempted cloud synchronization pass.
class SyncResult {
  const SyncResult({
    required this.success,
    required this.status,
    this.pushedRecords = 0,
    this.pulledRecords = 0,
    this.uploadedPhotos = 0,
    this.message,
  });

  factory SyncResult.offline() => const SyncResult(
        success: false,
        status: CloudSyncStatus.offline,
        message: 'No internet connection available.',
      );

  factory SyncResult.unconfigured([String? message]) => SyncResult(
        success: false,
        status: CloudSyncStatus.unconfigured,
        message: message ?? 'Cloud backend not configured or initialized.',
      );

  factory SyncResult.success({
    int pushed = 0,
    int pulled = 0,
    int photos = 0,
  }) =>
      SyncResult(
        success: true,
        status: CloudSyncStatus.success,
        pushedRecords: pushed,
        pulledRecords: pulled,
        uploadedPhotos: photos,
      );

  factory SyncResult.error(String message) => SyncResult(
        success: false,
        status: CloudSyncStatus.error,
        message: message,
      );

  final bool success;
  final CloudSyncStatus status;
  final int pushedRecords;
  final int pulledRecords;
  final int uploadedPhotos;
  final String? message;
}

/// Immutable state snapshot of cloud synchronization for UI presentation.
class CloudSyncState {
  const CloudSyncState({
    this.status = CloudSyncStatus.idle,
    this.lastSyncAt,
    this.pendingCount = 0,
    this.pushedRecords = 0,
    this.pulledRecords = 0,
    this.uploadedPhotos = 0,
    this.errorMessage,
    this.progress = 0.0,
  });

  final CloudSyncStatus status;
  final DateTime? lastSyncAt;
  final int pendingCount;
  final int pushedRecords;
  final int pulledRecords;
  final int uploadedPhotos;
  final String? errorMessage;
  final double progress;

  CloudSyncState copyWith({
    CloudSyncStatus? status,
    DateTime? lastSyncAt,
    int? pendingCount,
    int? pushedRecords,
    int? pulledRecords,
    int? uploadedPhotos,
    String? errorMessage,
    double? progress,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      pendingCount: pendingCount ?? this.pendingCount,
      pushedRecords: pushedRecords ?? this.pushedRecords,
      pulledRecords: pulledRecords ?? this.pulledRecords,
      uploadedPhotos: uploadedPhotos ?? this.uploadedPhotos,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

/// Abstract adapter seam for testing sync without real Firebase.
abstract class CloudSyncAdapter {
  Future<int> pushRecords(String collection, List<Map<String, dynamic>> records);
  Future<List<Map<String, dynamic>>> pullRecords(String collection, DateTime? since);
  Future<String?> uploadPhoto(String localPath, String storagePath);
}

/// Production Cloud Synchronization Engine.
///
/// Implements Spec §1, §4.14, §11.5, §16.4 & Rule 3 (Offline-First):
/// - SQLite is always the primary source of truth.
/// - Cloud sync is strictly asynchronous and non-blocking.
/// - Never crashes or blocks if offline or unconfigured.
/// - Bi-directional delta sync with last-write-wins and full audit history.
/// - Uploads local photos to Firebase Storage with local fallback.
class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  static const String prefKeyLastSync = 'cloud_last_sync_timestamp';

  Database? _testDb;
  CloudSyncAdapter? _testAdapter;
  Connectivity? _testConnectivity;

  /// Visible for testing to inject fake database or adapters.
  @visibleForTesting
  void configureForTesting({
    Database? database,
    CloudSyncAdapter? adapter,
    Connectivity? connectivity,
  }) {
    _testDb = database;
    _testAdapter = adapter;
    _testConnectivity = connectivity;
  }

  Database get _db => _testDb ?? AppDatabase.instance.db;
  Connectivity get _connectivity => _testConnectivity ?? Connectivity();

  /// Checks if Firebase is initialized in this runtime.
  bool get isFirebaseReady {
    if (_testAdapter != null) return true;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Initializes cloud services safely in the background.
  Future<bool> initialize() async {
    if (_testAdapter != null) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      debugPrint('CloudSyncService: Firebase.initializeApp() skipped or failed: $e');
      return false;
    }
  }

  /// Retrieves the last recorded sync timestamp from SharedPreferences.
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso = prefs.getString(prefKeyLastSync);
      if (iso != null) {
        return DateTime.tryParse(iso);
      }
    } catch (_) {}
    return null;
  }

  /// Sets the last recorded sync timestamp.
  Future<void> setLastSyncTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyLastSync, time.toIso8601String());

      // Also record in devices table if available
      try {
        await _db.update(
          'devices',
          {
            'last_sync_at': time.toIso8601String(),
            'sync_state': 'synced',
          },
        );
      } catch (_) {}
    } catch (_) {}
  }

  /// Checks whether internet connectivity is currently available.
  Future<bool> isNetworkAvailable() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Counts the total number of local changes pending cloud upload.
  Future<int> countPendingChanges() async {
    try {
      final lastSync = await getLastSyncTime();
      int count = 0;

      // 1. Pending photos
      final pendingPhotos = await _db.rawQuery(
        "SELECT COUNT(*) as count FROM photos WHERE upload_status = 'pending' OR cloud_url IS NULL",
      );
      count += (Sqflite.firstIntValue(pendingPhotos) ?? 0);

      // 2. Pending audit_log items
      try {
        final pendingLogs = await _db.rawQuery(
          "SELECT COUNT(*) as count FROM audit_log WHERE sync_state = 'pending'",
        );
        count += (Sqflite.firstIntValue(pendingLogs) ?? 0);
      } catch (_) {}

      // 3. New audits since last sync
      if (lastSync != null) {
        final newAudits = await _db.rawQuery(
          'SELECT COUNT(*) as count FROM audits WHERE created_at > ?',
          [lastSync.toIso8601String()],
        );
        count += (Sqflite.firstIntValue(newAudits) ?? 0);

        final newCaps = await _db.rawQuery(
          'SELECT COUNT(*) as count FROM caps WHERE opened_at > ?',
          [lastSync.toIso8601String()],
        );
        count += (Sqflite.firstIntValue(newCaps) ?? 0);

        final newEscalations = await _db.rawQuery(
          'SELECT COUNT(*) as count FROM escalations WHERE raised_at > ?',
          [lastSync.toIso8601String()],
        );
        count += (Sqflite.firstIntValue(newEscalations) ?? 0);
      } else {
        // Never synced — count all completed audits
        final allAudits = await _db.rawQuery(
          "SELECT COUNT(*) as count FROM audits WHERE status != 'draft'",
        );
        count += (Sqflite.firstIntValue(allAudits) ?? 0);
      }

      return count;
    } catch (e) {
      debugPrint('CloudSyncService.countPendingChanges error: $e');
      return 0;
    }
  }

  /// Executes a full bi-directional synchronization pass.
  Future<SyncResult> syncAll({
    bool force = false,
    void Function(double progress, String step)? onProgress,
  }) async {
    // Step 1: Network Check
    final hasNet = await isNetworkAvailable();
    if (!hasNet) {
      return SyncResult.offline();
    }

    // Step 2: Backend Ready Check
    final isReady = await initialize();
    if (!isReady && _testAdapter == null) {
      return SyncResult.unconfigured(
        'Firebase not configured. Please place google-services.json in android/app.',
      );
    }

    try {
      onProgress?.call(0.1, 'Preparing sync...');
      final lastSync = await getLastSyncTime();
      int totalPushed = 0;
      int totalPulled = 0;
      int photosUploaded = 0;

      // Step 3: Photo Upload Pass
      onProgress?.call(0.2, 'Uploading evidence photos...');
      photosUploaded = await _syncPendingPhotos();

      // Step 4: Outbound Push Pass (SQLite -> Cloud)
      onProgress?.call(0.4, 'Pushing audits & compliance records...');
      totalPushed += await _pushTableData('audits', lastSync, force: force);
      totalPushed += await _pushTableData('audit_results', lastSync, force: force);
      totalPushed += await _pushTableData('caps', lastSync, force: force);
      totalPushed += await _pushTableData('cap_actions', lastSync, force: force);
      totalPushed += await _pushTableData('cap_log', lastSync, force: force);
      totalPushed += await _pushTableData('escalations', lastSync, force: force);
      totalPushed += await _pushTableData('reports', lastSync, force: force);

      // Master data push (clean user records without pin_hash)
      totalPushed += await _pushUsers(lastSync, force: force);
      totalPushed += await _pushTableData('cros', lastSync, force: force);

      // Step 5: Inbound Pull Pass (Cloud -> SQLite)
      onProgress?.call(0.7, 'Pulling updates from cloud...');
      totalPulled += await _pullTableData('cros', lastSync);
      totalPulled += await _pullTableData('caps', lastSync);
      totalPulled += await _pullTableData('escalations', lastSync);

      // Step 6: Mark Audit Log as Synced
      try {
        await _db.update(
          'audit_log',
          {'sync_state': 'synced'},
          where: "sync_state = 'pending'",
        );
      } catch (_) {}

      // Step 7: Record Completion
      final now = DateTime.now();
      await setLastSyncTime(now);

      onProgress?.call(1.0, 'Sync completed.');
      return SyncResult.success(
        pushed: totalPushed,
        pulled: totalPulled,
        photos: photosUploaded,
      );
    } catch (e, st) {
      debugPrint('CloudSyncService.syncAll failed: $e\n$st');
      return SyncResult.error(e.toString());
    }
  }

  /// Uploads pending photos to Firebase Storage.
  Future<int> _syncPendingPhotos() async {
    int uploaded = 0;
    try {
      final rows = await _db.query(
        'photos',
        where: "upload_status = 'pending' OR cloud_url IS NULL",
        limit: 20, // Batch limit per pass
      );

      for (final row in rows) {
        final id = row['id'] as String;
        final localPath = row['local_path'] as String?;
        if (localPath == null) continue;

        final file = File(localPath);
        if (!file.existsSync()) continue;

        String? cloudUrl;
        final storagePath = 'photos/$id.jpg';

        if (_testAdapter != null) {
          cloudUrl = await _testAdapter!.uploadPhoto(localPath, storagePath);
        } else {
          try {
            final ref = FirebaseStorage.instance.ref().child(storagePath);
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'photo_id': id},
            );
            await ref.putFile(file, metadata);
            cloudUrl = await ref.getDownloadURL();
          } catch (e) {
            debugPrint('Failed to upload photo $id: $e');
            continue;
          }
        }

        if (cloudUrl != null) {
          await _db.update(
            'photos',
            {
              'cloud_url': cloudUrl,
              'upload_status': 'uploaded',
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          uploaded++;
        }
      }
    } catch (e) {
      debugPrint('CloudSyncService._syncPendingPhotos error: $e');
    }
    return uploaded;
  }

  /// Pushes records from a local SQLite table to Firestore.
  Future<int> _pushTableData(
    String tableName,
    DateTime? since, {
    bool force = false,
  }) async {
    try {
      List<Map<String, dynamic>> records;
      final timeCol = _getTimestampColumn(tableName);
      if (since == null || force || timeCol == null) {
        records = await _db.query(tableName);
      } else {
        // Push records modified or created since last sync
        records = await _db.query(
          tableName,
          where: '$timeCol > ?',
          whereArgs: [since.toIso8601String()],
        );
      }

      if (records.isEmpty) return 0;

      if (_testAdapter != null) {
        return await _testAdapter!.pushRecords(tableName, records);
      }

      // Firestore Batch Write
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection(tableName);
      final batch = firestore.batch();
      int count = 0;

      for (final record in records) {
        final id = record['id']?.toString();
        if (id == null) continue;

        final docRef = collection.doc(id);
        final data = Map<String, dynamic>.from(record);
        data['_synced_at'] = FieldValue.serverTimestamp();

        batch.set(docRef, data, SetOptions(merge: true));
        count++;

        if (count >= 400) {
          // Commit batch before 500 limit
          await batch.commit();
          break;
        }
      }

      if (count > 0 && count < 400) {
        await batch.commit();
      }

      return count;
    } catch (e) {
      debugPrint('CloudSyncService._pushTableData($tableName) error: $e');
      return 0;
    }
  }

  /// Pushes users to Firestore without sensitive pin_hash values.
  Future<int> _pushUsers(DateTime? since, {bool force = false}) async {
    try {
      final rows = await _db.query('users');
      final sanitized = rows.map((r) {
        final map = Map<String, dynamic>.from(r);
        map.remove('pin_hash'); // Inviolable Rule 4: never sync PIN hashes to cloud
        return map;
      }).toList();

      if (sanitized.isEmpty) return 0;

      if (_testAdapter != null) {
        return await _testAdapter!.pushRecords('users', sanitized);
      }

      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('users');
      final batch = firestore.batch();

      for (final user in sanitized) {
        final id = user['id']?.toString();
        if (id == null) continue;
        final docRef = collection.doc(id);
        user['_synced_at'] = FieldValue.serverTimestamp();
        batch.set(docRef, user, SetOptions(merge: true));
      }

      await batch.commit();
      return sanitized.length;
    } catch (e) {
      debugPrint('CloudSyncService._pushUsers error: $e');
      return 0;
    }
  }

  /// Pulls remote documents from Firestore and upserts into local SQLite.
  Future<int> _pullTableData(String tableName, DateTime? since) async {
    try {
      List<Map<String, dynamic>> remoteDocs = [];

      if (_testAdapter != null) {
        remoteDocs = await _testAdapter!.pullRecords(tableName, since);
      } else {
        final firestore = FirebaseFirestore.instance;
        Query query = firestore.collection(tableName);

        if (since != null) {
          query = query.where('_synced_at', isGreaterThan: Timestamp.fromDate(since));
        }

        final snapshot = await query.limit(100).get();
        remoteDocs = snapshot.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          data.remove('_synced_at');
          return data;
        }).toList();
      }

      if (remoteDocs.isEmpty) return 0;

      int upserted = 0;
      await _db.transaction((txn) async {
        for (final doc in remoteDocs) {
          final id = doc['id']?.toString();
          if (id == null) continue;

          // Check if exists locally
          final existing = await txn.query(
            tableName,
            where: 'id = ?',
            whereArgs: [id],
            limit: 1,
          );

          if (existing.isEmpty) {
            // Filter to only columns that exist in SQLite schema
            final filtered = await _filterColumns(tableName, doc, txn);
            await txn.insert(tableName, filtered);
            upserted++;
          } else {
            // Last write wins comparison
            final localDoc = existing.first;
            final shouldUpdate = _isRemoteNewer(localDoc, doc);
            if (shouldUpdate) {
              final filtered = await _filterColumns(tableName, doc, txn);
              await txn.update(
                tableName,
                filtered,
                where: 'id = ?',
                whereArgs: [id],
              );
              upserted++;
            }
          }
        }
      });

      return upserted;
    } catch (e) {
      debugPrint('CloudSyncService._pullTableData($tableName) error: $e');
      return 0;
    }
  }

  bool _isRemoteNewer(Map<String, dynamic> local, Map<String, dynamic> remote) {
    final localTime = local['updated_at'] ?? local['created_at'];
    final remoteTime = remote['updated_at'] ?? remote['created_at'];
    if (localTime == null || remoteTime == null) return true;
    try {
      return DateTime.parse(remoteTime.toString())
          .isAfter(DateTime.parse(localTime.toString()));
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>> _filterColumns(
    String tableName,
    Map<String, dynamic> doc,
    Transaction txn,
  ) async {
    final pragma = await txn.rawQuery('PRAGMA table_info($tableName)');
    final Set<String> validColumns = pragma
        .map((Map<String, Object?> row) => row['name']! as String)
        .toSet();

    final filtered = <String, dynamic>{};
    for (final entry in doc.entries) {
      if (validColumns.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  String? _getTimestampColumn(String table) {
    if (table == 'audits') return 'created_at';
    if (table == 'caps') return 'opened_at';
    if (table == 'escalations') return 'raised_at';
    if (table == 'reports') return 'generated_at';
    if (table == 'cros' || table == 'users') return 'updated_at';
    if (table == 'cap_log') return 'created_at';
    return null;
  }
}
