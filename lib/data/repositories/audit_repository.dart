import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/iso_week.dart';
import '../../providers/auth_provider.dart';
import '../db/database.dart';
import '../device_service.dart';
import '../models/audit.dart';
import '../models/audit_result.dart';
import '../models/photo.dart';

/// Filter for audit history listing (Spec §5 S12).
enum AuditHistoryFilter {
  all,
  daily,
  unverified,
}

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
      'week_number': isoWeek(parsed),
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

  /// Lists submitted and verified audits (never draft or hidden) for S12 history.
  /// Role-scoped: SM only sees audits they authored; GM and OWNER see all.
  /// Ordered by submitted_at DESC.
  Future<List<Audit>> listAudits({
    required AuthUser viewer,
    AuditHistoryFilter filter = AuditHistoryFilter.all,
    int limit = 30,
    int offset = 0,
  }) async {
    final whereClauses = <String>["status IN ('submitted', 'verified')"];
    final whereArgs = <Object?>[];

    if (viewer.isSm) {
      whereClauses.add('auditor_id = ?');
      whereArgs.add(viewer.id);
    }

    switch (filter) {
      case AuditHistoryFilter.daily:
        whereClauses.add("audit_type = 'daily'");
        break;
      case AuditHistoryFilter.unverified:
        whereClauses.add("status = 'submitted'");
        break;
      case AuditHistoryFilter.all:
        break;
    }

    final rows = await AppDatabase.instance.db.query(
      'audits',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'submitted_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(Audit.fromMap).toList();
  }

  /// Lookup an audit by ID.
  Future<Audit?> getById(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Audit.fromMap(rows.first);
  }
}
