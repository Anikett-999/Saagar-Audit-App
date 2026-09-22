import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../device_service.dart';
import '../models/audit.dart';
import '../models/audit_result.dart';
import '../models/photo.dart';

/// CRUD for audits, audit_results, photos. No business logic — the score
/// engine lives in `domain/score_engine.dart`.
class AuditRepository {
  AuditRepository._();
  static final AuditRepository instance = AuditRepository._();

  Future<Audit?> findByDate({
    required String date, // YYYY-MM-DD
    required String auditType, // 'daily' | 'weekly' | 'monthly'
  }) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where:
          "audit_date = ? AND audit_type = ? AND status NOT IN ('hidden')",
      whereArgs: [date, auditType],
      orderBy: 'submitted_at DESC, draft_started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Audit.fromMap(rows.first);
  }

  /// Creates a new draft audit row. Caller can pass [supersedesAuditId] when
  /// re-doing an audit (Spec §3 — mistakes are corrected via supersession, not
  /// edits).
  Future<Audit> createDraft({
    required String date,
    required String auditType,
    required String auditorId,
    String? supersedesAuditId,
  }) async {
    final deviceId = await DeviceService.instance.getId();
    final parsed = DateTime.parse(date);
    final id = const Uuid().v4();

    final row = {
      'id': id,
      'audit_type': auditType,
      'audit_date': date,
      'week_number': _isoWeek(parsed),
      'month_number': parsed.month,
      'year': parsed.year,
      'auditor_id': auditorId,
      'device_id': deviceId,
      'status': 'draft',
      'fail_count': 0,
      'pass_count': 0,
      'na_count': 0,
      'draft_started_at': DateTime.now().toUtc().toIso8601String(),
      'supersedes_audit_id': supersedesAuditId,
    };
    await AppDatabase.instance.db.insert('audits', row);
    return Audit.fromMap(row);
  }

  /// Upsert one P/F/NA result. Unique constraint on (audit_id, checkpoint_id)
  /// means a re-mark overwrites the previous result rather than inserting.
  /// Hard Rule (Spec §14.1 Rule #6): Rejects modification if audit is submitted.
  Future<AuditResult> saveResult({
    required String auditId,
    required String checkpointId,
    required String result,
    required int weight,
    String? findingText,
    String? croId,
  }) async {
    final auditRows = await AppDatabase.instance.db.query(
      'audits',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [auditId],
    );
    if (auditRows.isNotEmpty && auditRows.first['status'] != 'draft') {
      throw StateError(
        'Cannot modify audit $auditId: status is ${auditRows.first['status']}',
      );
    }

    final id = const Uuid().v4();
    final row = {
      'id': id,
      'audit_id': auditId,
      'checkpoint_id': checkpointId,
      'result': result,
      'weighted_points': switch (result) {
        'P' => weight.toDouble(),
        'F' => 0.0,
        _ => null, // NA
      },
      'finding_text': findingText,
      'cro_id': croId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    await AppDatabase.instance.db.insert(
      'audit_results',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return AuditResult.fromMap(row);
  }

  /// Submits an audit row, locking it to 'submitted' status with calculated scores.
  Future<void> submitAudit({
    required String auditId,
    required double rawScore,
    required double maxScore,
    required double compliancePct,
    required String band,
    required int passCount,
    required int failCount,
    required int naCount,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final count = await AppDatabase.instance.db.update(
      'audits',
      {
        'status': 'submitted',
        'submitted_at': now,
        'raw_score': rawScore,
        'max_score': maxScore,
        'compliance_pct': compliancePct,
        'band': band,
        'pass_count': passCount,
        'fail_count': failCount,
        'na_count': naCount,
        'notes': notes,
      },
      where: "id = ? AND status = 'draft'",
      whereArgs: [auditId],
    );
    if (count == 0) {
      throw StateError(
        'Cannot submit audit $auditId: not found or not in draft status',
      );
    }
  }

  Future<AuditResult?> findResult({
    required String auditId,
    required String checkpointId,
  }) async {
    final rows = await AppDatabase.instance.db.query(
      'audit_results',
      where: 'audit_id = ? AND checkpoint_id = ?',
      whereArgs: [auditId, checkpointId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuditResult.fromMap(rows.first);
  }

  Future<List<AuditResult>> resultsForAudit(String auditId) async {
    final rows = await AppDatabase.instance.db.query(
      'audit_results',
      where: 'audit_id = ?',
      whereArgs: [auditId],
    );
    return rows.map(AuditResult.fromMap).toList();
  }

  Future<List<Photo>> photosForResult(String auditResultId) async {
    final rows = await AppDatabase.instance.db.query(
      'photos',
      where: 'audit_result_id = ?',
      whereArgs: [auditResultId],
      orderBy: 'captured_at',
    );
    return rows.map(Photo.fromMap).toList();
  }

  Future<Photo> attachPhoto({
    required String auditResultId,
    required String localPath,
    int? fileSizeBytes,
  }) async {
    final id = const Uuid().v4();
    final row = {
      'id': id,
      'audit_result_id': auditResultId,
      'context': 'fail_evidence',
      'local_path': localPath,
      'upload_status': 'pending',
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'file_size_bytes': fileSizeBytes,
    };
    await AppDatabase.instance.db.insert('photos', row);
    return Photo.fromMap(row);
  }

  /// ISO 8601 week number — matches Spec §15.5 commit message format and
  /// CAP IDs (`CAP-YYYY-Wxx-NN`).
  int _isoWeek(DateTime date) {
    // Algorithm: Thursday in the same week is in the year that owns the week.
    final dayOfYear = int.parse(_dayOfYearStr(date));
    final dow = date.weekday; // 1=Mon..7=Sun
    final week = ((dayOfYear - dow + 10) ~/ 7);
    if (week < 1) {
      return _isoWeek(DateTime(date.year - 1, 12, 31));
    }
    if (week > 52) {
      final jan4 = DateTime(date.year + 1, 1, 4);
      final daysToJan4 = jan4.difference(date).inDays;
      if (daysToJan4 <= 3) return 1;
    }
    return week;
  }

  String _dayOfYearStr(DateTime d) {
    final firstDay = DateTime(d.year, 1, 1);
    return (d.difference(firstDay).inDays + 1).toString();
  }
}
