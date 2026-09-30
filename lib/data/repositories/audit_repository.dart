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
  weekly,
  monthly,
  unverified,
}

/// CRUD for audits, audit_results, photos. No business logic — the score
/// engine lives in `domain/score_engine.dart`.
class AuditRepository {
  AuditRepository._();
  static final AuditRepository instance = AuditRepository._();

  /// Finds an audit by its primary key ID.
  Future<Audit?> findById(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Audit.fromMap(rows.first);
  }

  /// Finds the latest submitted daily audit before a given date (used for T3 consecutive variance).
  Future<Audit?> findPreviousDailyAudit(String beforeDate) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where: "audit_type = 'daily' AND audit_date < ? AND status IN ('submitted', 'verified')",
      whereArgs: [beforeDate],
      orderBy: 'audit_date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Audit.fromMap(rows.first);
  }

  /// Returns recent submitted daily audits (used for T2 repeated fail detection).
  Future<List<Audit>> findRecentDailyAudits({int limit = 7, String? beforeDate}) async {
    final whereClauses = <String>["audit_type = 'daily'", "status IN ('submitted', 'verified')"];
    final whereArgs = <Object?>[];
    if (beforeDate != null) {
      whereClauses.add("audit_date <= ?");
      whereArgs.add(beforeDate);
    }
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'audit_date DESC',
      limit: limit,
    );
    return rows.map(Audit.fromMap).toList();
  }

  /// Returns recent submitted weekly audits (used for T7 declining trend detection).
  Future<List<Audit>> findRecentWeeklyAudits({int limit = 4, String? beforeDate}) async {
    final whereClauses = <String>["audit_type = 'weekly'", "status IN ('submitted', 'verified')"];
    final whereArgs = <Object?>[];
    if (beforeDate != null) {
      whereClauses.add("audit_date <= ?");
      whereArgs.add(beforeDate);
    }
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'audit_date DESC',
      limit: limit,
    );
    return rows.map(Audit.fromMap).toList();
  }

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

  /// Finds an audit for a specific week and year (used for weekly audits).
  Future<Audit?> findByWeek({
    required int weekNumber,
    required int year,
    required String auditType,
  }) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where:
          "week_number = ? AND year = ? AND audit_type = ? AND status NOT IN ('hidden')",
      whereArgs: [weekNumber, year, auditType],
      orderBy: 'submitted_at DESC, draft_started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Audit.fromMap(rows.first);
  }

  /// Finds an audit for a specific month and year (used for monthly audits).
  Future<Audit?> findByMonth({
    required int monthNumber,
    required int year,
    required String auditType,
  }) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where:
          "month_number = ? AND year = ? AND audit_type = ? AND status NOT IN ('hidden')",
      whereArgs: [monthNumber, year, auditType],
      orderBy: 'submitted_at DESC, draft_started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Audit.fromMap(rows.first);
  }

  /// Returns submitted or verified daily audits for a given ISO week and year,
  /// ordered by audit_date ASC. Deduplicates per audit_date so that superseded
  /// daily audits (e.g. re-done audits) do not cause double-counting or exceed
  /// 7 days in the weekly score engine rollup.
  Future<List<Audit>> findSubmittedDailyAuditsForWeek({
    required int weekNumber,
    required int year,
  }) async {
    final rows = await AppDatabase.instance.db.query(
      'audits',
      where:
          "week_number = ? AND year = ? AND audit_type = 'daily' AND status IN ('submitted', 'verified')",
      whereArgs: [weekNumber, year],
      orderBy: 'audit_date ASC',
    );
    final allAudits = rows.map(Audit.fromMap).toList();

    // 1. Identify all audit IDs that were explicitly superseded by another audit
    final supersededIds = allAudits
        .map((a) => a.supersedesAuditId)
        .whereType<String>()
        .toSet();

    // 2. Group by audit_date, keeping only non-superseded audits and picking
    // the latest by submitted_at (or draftStartedAt)
    final Map<String, Audit> latestByDate = {};
    for (final audit in allAudits) {
      if (supersededIds.contains(audit.id)) {
        continue;
      }
      final existing = latestByDate[audit.auditDate];
      if (existing == null) {
        latestByDate[audit.auditDate] = audit;
      } else {
        final existingTime = existing.submittedAt ?? existing.draftStartedAt ?? '';
        final auditTime = audit.submittedAt ?? audit.draftStartedAt ?? '';
        if (auditTime.compareTo(existingTime) >= 0) {
          latestByDate[audit.auditDate] = audit;
        }
      }
    }

    final result = latestByDate.values.toList()
      ..sort((a, b) => a.auditDate.compareTo(b.auditDate));
    return result;
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
    bool flagSecurityConcern = false,
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
      'flag_security_concern': flagSecurityConcern ? 1 : 0,
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
    double? cashVarianceRupees,
    double? inventoryVariancePct,
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
        'cash_variance_rupees': cashVarianceRupees,
        'inventory_variance_pct': inventoryVariancePct,
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
      case AuditHistoryFilter.weekly:
        whereClauses.add("audit_type = 'weekly'");
        break;
      case AuditHistoryFilter.monthly:
        whereClauses.add("audit_type = 'monthly'");
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

  /// Marks a submitted daily audit as GM-verified per Spec §5 T2.3 / §4.3.
  /// Enforces R5 immutability: transitions status 'submitted' -> 'verified'
  /// and records verifierId and verifiedAt.
  /// Throws StateError if audit does not exist or status is not 'submitted'.
  Future<void> verifyDailyAudit({
    required String auditId,
    required String verifierId,
    String? notes,
  }) async {
    final existing = await getById(auditId);
    if (existing == null) {
      throw StateError('Audit $auditId not found.');
    }
    if (existing.status != 'submitted') {
      throw StateError(
        'Cannot verify audit $auditId: status is "${existing.status}", expected "submitted".',
      );
    }
    if (existing.auditType != 'daily') {
      throw StateError('Only daily audits can be verified through spot-check.');
    }

    final verifiedAt = DateTime.now().toUtc().toIso8601String();
    final values = <String, Object?>{
      'status': 'verified',
      'verifier_id': verifierId,
      'verified_at': verifiedAt,
    };
    if (notes != null && notes.isNotEmpty) {
      values['notes'] = existing.notes != null
          ? '${existing.notes}\n[GM Verification]: $notes'
          : '[GM Verification]: $notes';
    }

    final count = await AppDatabase.instance.db.update(
      'audits',
      values,
      where: "id = ? AND status = 'submitted'",
      whereArgs: [auditId],
    );
    if (count == 0) {
      throw StateError('Failed to verify audit $auditId: status changed or update rejected.');
    }
  }

  /// Flags a discrepancy on a submitted daily audit during spot-check.
  /// Withholds verification: status remains 'submitted', and records
  /// discrepancy note per Spec §4.2.
  Future<void> flagDailyAuditDiscrepancy({
    required String auditId,
    required String verifierId,
    required String discrepancyNote,
  }) async {
    final existing = await getById(auditId);
    if (existing == null) {
      throw StateError('Audit $auditId not found.');
    }
    if (existing.status != 'submitted') {
      throw StateError(
        'Cannot flag discrepancy on audit $auditId: status is "${existing.status}", expected "submitted".',
      );
    }

    final updatedNotes = existing.notes != null && existing.notes!.isNotEmpty
        ? '${existing.notes}\n[Spot Check Discrepancy by $verifierId]: $discrepancyNote'
        : '[Spot Check Discrepancy by $verifierId]: $discrepancyNote';

    await AppDatabase.instance.db.update(
      'audits',
      {'notes': updatedNotes},
      where: 'id = ?',
      whereArgs: [auditId],
    );
  }
}

