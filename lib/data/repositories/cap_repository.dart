import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../domain/iso_week.dart';
import '../../providers/auth_provider.dart';
import '../db/database.dart';
import '../device_service.dart';
import '../models/cap.dart';
import '../models/cap_action.dart';
import '../models/cap_log_entry.dart';

/// Repository managing Corrective Action Plans (CAPs), action steps, and audit logs.
///
/// Follows Spec §5 (Screens S14–S17) and Spec §4.9–§4.11 database definitions.
class CapRepository {
  CapRepository._();
  static final CapRepository instance = CapRepository._();

  /// Generates the next sequential CAP ID for the given [originDate] (Spec §5 S15).
  ///
  /// Format: `CAP-YYYY-Wxx-nn` where `nn` is zero-padded sequential 01, 02...
  Future<String> generateNextCapId(DateTime originDate) async {
    final year = originDate.year;
    final week = isoWeek(originDate);
    final prefix = 'CAP-$year-W${week.toString().padLeft(2, '0')}-';

    final rows = await AppDatabase.instance.db.query(
      'caps',
      columns: ['id'],
      where: 'id LIKE ?',
      whereArgs: ['$prefix%'],
    );

    var maxSeq = 0;
    for (final r in rows) {
      final id = r['id'] as String;
      final parts = id.split('-');
      if (parts.length == 4) {
        final seq = int.tryParse(parts[3]) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    return formatCapId(year: year, week: week, sequence: maxSeq + 1);
  }

  /// Atomically creates a new CAP with 3–5 action steps and an initial `created` log entry.
  ///
  /// Validations:
  /// - Non-empty: problemStatement, why1, rootCause, responsibleUserId, deadline, verificationMethod.
  /// - Action steps count must be between 3 and 5 (inclusive).
  /// - Responsible user must have role SM, GM, or OWNER (CROs cannot be responsible).
  Future<Cap> createCap({
    String? id,
    required String originAuditId,
    String? originResultId,
    required String originCheckpointId,
    bool isPattern = false,
    required String problemStatement,
    required String why1,
    String? why2,
    String? why3,
    String? why4,
    String? why5,
    required String rootCause,
    required String responsibleUserId,
    required String deadline, // YYYY-MM-DD
    required String verificationMethod,
    required List<String> actionSteps,
    String? creatorUserId,
    DateTime? originDate,
  }) async {
    if (problemStatement.trim().isEmpty) {
      throw ArgumentError('Problem statement cannot be empty');
    }
    if (why1.trim().isEmpty) {
      throw ArgumentError('Why 1 cannot be empty');
    }
    if (rootCause.trim().isEmpty) {
      throw ArgumentError('Root cause cannot be empty');
    }
    if (responsibleUserId.trim().isEmpty) {
      throw ArgumentError('Responsible user must be specified');
    }
    if (deadline.trim().isEmpty) {
      throw ArgumentError('Deadline cannot be empty');
    }
    if (verificationMethod.trim().isEmpty) {
      throw ArgumentError('Verification method cannot be empty');
    }
    if (actionSteps.length < 3 || actionSteps.length > 5) {
      throw ArgumentError(
        'Action steps must contain between 3 and 5 steps (got ${actionSteps.length})',
      );
    }
    for (var i = 0; i < actionSteps.length; i++) {
      if (actionSteps[i].trim().isEmpty) {
        throw ArgumentError('Action step ${i + 1} text cannot be empty');
      }
    }

    // Role check: responsible user must be SM, GM, or OWNER
    final userRows = await AppDatabase.instance.db.query(
      'users',
      columns: ['role'],
      where: 'id = ?',
      whereArgs: [responsibleUserId],
    );
    if (userRows.isEmpty) {
      throw ArgumentError('Responsible user $responsibleUserId not found');
    }
    final role = userRows.first['role'] as String;
    if (role != 'SM' && role != 'GM' && role != 'OWNER') {
      throw ArgumentError(
        'Responsible user must be SM, GM, or OWNER (found role: $role)',
      );
    }

    final capId = id ?? await generateNextCapId(originDate ?? DateTime.now());
    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();

    final capMap = {
      'id': capId,
      'origin_audit_id': originAuditId,
      'origin_result_id': originResultId,
      'origin_checkpoint_id': originCheckpointId,
      'is_pattern': isPattern ? 1 : 0,
      'problem_statement': problemStatement.trim(),
      'why_1': why1.trim(),
      'why_2': why2?.trim(),
      'why_3': why3?.trim(),
      'why_4': why4?.trim(),
      'why_5': why5?.trim(),
      'root_cause': rootCause.trim(),
      'responsible_user_id': responsibleUserId,
      'deadline': deadline.trim(),
      'verification_method': verificationMethod.trim(),
      'status': 'open',
      'opened_at': now,
      'done_at': null,
      'verified_at': null,
      'closed_at': null,
      'verified_by': null,
      'closed_by': null,
      'aged_count': 0,
      'extension_count': 0,
      'latest_extension_reason': null,
    };

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.insert('caps', capMap);

      for (var i = 0; i < actionSteps.length; i++) {
        await txn.insert('cap_actions', {
          'id': const Uuid().v4(),
          'cap_id': capId,
          'sequence': i + 1,
          'action_text': actionSteps[i].trim(),
          'is_done': 0,
          'done_at': null,
          'done_by': null,
          'done_notes': null,
        });
      }

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'created',
        'from_status': null,
        'to_status': 'open',
        'actor_user_id': creatorUserId ?? responsibleUserId,
        'device_id': deviceId,
        'timestamp': now,
        'note': 'CAP created with ${actionSteps.length} action steps',
      });
    });

    // TODO(phase4): Push notification to responsible user / GM on CAP creation
    return Cap.fromMap(capMap);
  }

  /// Lists CAPs with role-scoping and status filtering.
  ///
  /// - SM: sees CAPs where `responsible_user_id = viewer.id` OR origin audit was authored by them.
  /// - GM / OWNER: sees all CAPs.
  /// - Sorted by deadline ascending, aged/overdue first.
  Future<List<Cap>> listCaps({
    required AuthUser viewer,
    CapFilter filter = CapFilter.all,
    String? search,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    // Role-scoping
    if (viewer.isSm) {
      whereClauses.add(
        '(responsible_user_id = ? OR origin_audit_id IN (SELECT id FROM audits WHERE auditor_id = ?))',
      );
      whereArgs.add(viewer.id);
      whereArgs.add(viewer.id);
    }

    // Status filter
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    switch (filter) {
      case CapFilter.all:
        break;
      case CapFilter.open:
        whereClauses.add("status IN ('open', 'reopened')");
        break;
      case CapFilter.done:
        whereClauses.add("status = 'done'");
        break;
      case CapFilter.aged:
        whereClauses.add(
          "(status = 'aged' OR (status IN ('open', 'reopened') AND deadline < ?))",
        );
        whereArgs.add(todayStr);
        break;
      case CapFilter.closed:
        whereClauses.add("status IN ('closed', 'verified')");
        break;
    }

    // Text search
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      whereClauses.add('(problem_statement LIKE ? OR id LIKE ?)');
      whereArgs.add('%$s%');
      whereArgs.add('%$s%');
    }

    final whereString =
        whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final rows = await AppDatabase.instance.db.query(
      'caps',
      where: whereString,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'deadline ASC, opened_at DESC',
    );

    return rows.map(Cap.fromMap).toList();
  }

  /// Lookup a single CAP by ID.
  Future<Cap?> getById(String capId) async {
    final rows = await AppDatabase.instance.db.query(
      'caps',
      where: 'id = ?',
      whereArgs: [capId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Cap.fromMap(rows.first);
  }

  /// Retrieves all action steps for a CAP, ordered by sequence.
  Future<List<CapAction>> actionsFor(String capId) async {
    final rows = await AppDatabase.instance.db.query(
      'cap_actions',
      where: 'cap_id = ?',
      whereArgs: [capId],
      orderBy: 'sequence ASC',
    );
    return rows.map(CapAction.fromMap).toList();
  }

  /// Retrieves the immutable event log timeline for a CAP, ordered by timestamp.
  Future<List<CapLogEntry>> logFor(String capId) async {
    final rows = await AppDatabase.instance.db.query(
      'cap_log',
      where: 'cap_id = ?',
      whereArgs: [capId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(CapLogEntry.fromMap).toList();
  }

  /// Toggles an action step's completion state and logs the change.
  Future<void> toggleAction({
    required String actionId,
    required bool done,
    required String userId,
    String? notes,
  }) async {
    final actionRows = await AppDatabase.instance.db.query(
      'cap_actions',
      where: 'id = ?',
      whereArgs: [actionId],
      limit: 1,
    );
    if (actionRows.isEmpty) {
      throw StateError('Action step $actionId not found');
    }

    final action = actionRows.first;
    final capId = action['cap_id'] as String;
    final seq = action['sequence'] as int;
    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.update(
        'cap_actions',
        {
          'is_done': done ? 1 : 0,
          'done_at': done ? now : null,
          'done_by': done ? userId : null,
          'done_notes': notes,
        },
        where: 'id = ?',
        whereArgs: [actionId],
      );

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'action_done',
        'from_status': null,
        'to_status': null,
        'actor_user_id': userId,
        'device_id': deviceId,
        'timestamp': now,
        'note': done
            ? 'Action step #$seq marked done${notes != null && notes.isNotEmpty ? ': $notes' : ''}'
            : 'Action step #$seq marked incomplete',
      });
    });
  }

  /// Transitions a CAP from `open`/`reopened` to `done` once all action steps are complete.
  ///
  /// Enforces:
  /// - Current status must be `open` or `reopened`.
  /// - Every action step in `cap_actions` must have `is_done = 1`.
  /// - Optionally saves a completion photo with `context = 'cap_progress'`.
  Future<void> markDone({
    required String capId,
    required String userId,
    String? doneNotes,
    String? photoPath,
  }) async {
    final cap = await getById(capId);
    if (cap == null) {
      throw StateError('CAP $capId not found');
    }
    if (cap.status != 'open' && cap.status != 'reopened') {
      throw StateError(
        'Cannot mark done: CAP $capId has status ${cap.status} (expected open or reopened)',
      );
    }

    final actions = await actionsFor(capId);
    if (actions.isEmpty || actions.any((a) => !a.isDone)) {
      throw StateError(
        'Cannot mark done: all ${actions.length} action steps must be completed first',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.update(
        'caps',
        {
          'status': 'done',
          'done_at': now,
        },
        where: 'id = ?',
        whereArgs: [capId],
      );

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'marked_done',
        'from_status': cap.status,
        'to_status': 'done',
        'actor_user_id': userId,
        'device_id': deviceId,
        'timestamp': now,
        'note': doneNotes,
      });

      if (photoPath != null && photoPath.trim().isNotEmpty) {
        int? bytes;
        try {
          final f = File(photoPath);
          if (f.existsSync()) {
            bytes = f.lengthSync();
          }
        } catch (_) {
          bytes = null;
        }

        await txn.insert('photos', {
          'id': const Uuid().v4(),
          'audit_result_id': null,
          'cap_id': capId,
          'context': 'cap_progress',
          'local_path': photoPath,
          'cloud_url': null,
          'thumb_local_path': null,
          'upload_status': 'pending',
          'captured_at': now,
          'captured_lat': null,
          'captured_lng': null,
          'uploaded_by': userId,
          'file_size_bytes': bytes,
        });
      }
    });

    // TODO(phase4): Push notification to GM alerting CAP marked done
  }

  /// Returns all photos attached to a given CAP (context: cap_progress, cap_verification).
  Future<List<Map<String, Object?>>> photosForCap(String capId) async {
    return await AppDatabase.instance.db.query(
      'photos',
      where: 'cap_id = ?',
      whereArgs: [capId],
      orderBy: 'captured_at ASC',
    );
  }

  /// Returns all CAPs linked to a given audit (for S13 Audit Detail).
  Future<List<Cap>> capsForAudit(String auditId) async {
    final rows = await AppDatabase.instance.db.query(
      'caps',
      where: 'origin_audit_id = ?',
      whereArgs: [auditId],
      orderBy: 'opened_at ASC',
    );
    return rows.map(Cap.fromMap).toList();
  }

  /// Returns the CAP linked to a specific audit result / fail (for S13 linked CAP chip).
  Future<Cap?> capForResult(String resultId) async {
    final rows = await AppDatabase.instance.db.query(
      'caps',
      where: 'origin_result_id = ?',
      whereArgs: [resultId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Cap.fromMap(rows.first);
  }

  /// Transitions a CAP from `done` to `verified` (Spec §5 S18).
  ///
  /// Enforces:
  /// - Current status must be `done` (throws StateError).
  /// - If the origin checkpoint has `requires_photo_on_fail == 1`, `photoPath` is mandatory (throws ArgumentError).
  /// - Atomically updates `caps` (status = 'verified', verified_at = now, verified_by = verifierId).
  /// - Inserts `cap_log` entry with event 'verified' (from_status = 'done', to_status = 'verified').
  /// - If `photoPath` is provided, inserts photo row with `context = 'cap_verification'`.
  Future<void> verifyCap({
    required String capId,
    required String verifierId,
    String? photoPath,
  }) async {
    final cap = await getById(capId);
    if (cap == null) {
      throw StateError('CAP $capId not found');
    }
    if (cap.status != 'done') {
      throw StateError(
        'Cannot verify: CAP $capId has status ${cap.status} (expected done)',
      );
    }

    // Check if origin checkpoint requires photo on fail
    final cpRows = await AppDatabase.instance.db.query(
      'checkpoints',
      columns: ['requires_photo_on_fail'],
      where: 'id = ?',
      whereArgs: [cap.originCheckpointId],
      limit: 1,
    );
    final requiresPhoto = cpRows.isNotEmpty &&
        (cpRows.first['requires_photo_on_fail'] as int? ?? 0) == 1;

    if (requiresPhoto && (photoPath == null || photoPath.trim().isEmpty)) {
      throw ArgumentError(
        'Verification photo is mandatory for checkpoint ${cap.originCheckpointId}',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.update(
        'caps',
        {
          'status': 'verified',
          'verified_at': now,
          'verified_by': verifierId,
        },
        where: 'id = ?',
        whereArgs: [capId],
      );

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'verified',
        'from_status': 'done',
        'to_status': 'verified',
        'actor_user_id': verifierId,
        'device_id': deviceId,
        'timestamp': now,
        'note': 'CAP verified by GM/Owner',
      });

      if (photoPath != null && photoPath.trim().isNotEmpty) {
        int? bytes;
        try {
          final f = File(photoPath);
          if (f.existsSync()) {
            bytes = f.lengthSync();
          }
        } catch (_) {
          bytes = null;
        }

        await txn.insert('photos', {
          'id': const Uuid().v4(),
          'audit_result_id': null,
          'cap_id': capId,
          'context': 'cap_verification',
          'local_path': photoPath,
          'cloud_url': null,
          'thumb_local_path': null,
          'upload_status': 'pending',
          'captured_at': now,
          'captured_lat': null,
          'captured_lng': null,
          'uploaded_by': verifierId,
          'file_size_bytes': bytes,
        });
      }
    });
  }

  /// Transitions a CAP from `verified` to `closed` (Spec §5 S19).
  ///
  /// Enforces:
  /// - Current status must be `verified` (throws StateError).
  /// - Atomically updates `caps` (status = 'closed', closed_at = now, closed_by = closerId).
  /// - Inserts `cap_log` entry with event 'closed' (from_status = 'verified', to_status = 'closed').
  Future<void> closeCap({
    required String capId,
    required String closerId,
  }) async {
    final cap = await getById(capId);
    if (cap == null) {
      throw StateError('CAP $capId not found');
    }
    if (cap.status != 'verified') {
      throw StateError(
        'Cannot close: CAP $capId has status ${cap.status} (expected verified)',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.update(
        'caps',
        {
          'status': 'closed',
          'closed_at': now,
          'closed_by': closerId,
        },
        where: 'id = ?',
        whereArgs: [capId],
      );

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'closed',
        'from_status': 'verified',
        'to_status': 'closed',
        'actor_user_id': closerId,
        'device_id': deviceId,
        'timestamp': now,
        'note': 'CAP permanently closed',
      });
    });
  }

  /// Extends a CAP's deadline (Workbook Day 4 §4.3).
  ///
  /// Enforces:
  /// - Current status must be `open`, `done`, or `reopened` (throws StateError).
  /// - Reason must not be blank (throws ArgumentError).
  /// - New deadline must not be blank (throws ArgumentError).
  /// - Bumps `extension_count = extension_count + 1`, stores `latest_extension_reason`.
  /// - Keeps the current status (e.g. verify-fail -> extend leaves it `done`; open stays `open`).
  /// - Inserts `cap_log` entry with event 'extended'.
  Future<void> extendCap({
    required String capId,
    required String actorId,
    required String newDeadline,
    required String reason,
  }) async {
    final cap = await getById(capId);
    if (cap == null) {
      throw StateError('CAP $capId not found');
    }
    if (cap.status != 'open' && cap.status != 'done' && cap.status != 'reopened') {
      throw StateError(
        'Cannot extend: CAP $capId has status ${cap.status} (expected open, done, or reopened)',
      );
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('Extension reason must not be blank');
    }
    if (newDeadline.trim().isEmpty) {
      throw ArgumentError('New deadline must not be blank');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();
    final trimmedReason = reason.trim();
    final trimmedDeadline = newDeadline.trim();

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.update(
        'caps',
        {
          'deadline': trimmedDeadline,
          'extension_count': cap.extensionCount + 1,
          'latest_extension_reason': trimmedReason,
        },
        where: 'id = ?',
        whereArgs: [capId],
      );

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'extended',
        'from_status': cap.status,
        'to_status': cap.status,
        'actor_user_id': actorId,
        'device_id': deviceId,
        'timestamp': now,
        'note': 'Deadline extended to $trimmedDeadline: $trimmedReason',
      });
    });
  }

  /// Reopens a CAP at Plan phase (Workbook Day 4 §4.3 & S16).
  ///
  /// Enforces:
  /// - Current status must be `done` (verify-fail) or `closed` (Owner reopen) (throws StateError).
  /// - Reason must not be blank (throws ArgumentError).
  /// - Updates status to `reopened`.
  /// - Inserts `cap_log` entry with event 'reopened'.
  Future<void> reopenCap({
    required String capId,
    required String actorId,
    required String reason,
  }) async {
    final cap = await getById(capId);
    if (cap == null) {
      throw StateError('CAP $capId not found');
    }
    if (cap.status != 'done' && cap.status != 'closed') {
      throw StateError(
        'Cannot reopen: CAP $capId has status ${cap.status} (expected done or closed)',
      );
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('Reopen reason must not be blank');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final deviceId = await DeviceService.instance.getId();
    final trimmedReason = reason.trim();

    await AppDatabase.instance.db.transaction((txn) async {
      await txn.update(
        'caps',
        {
          'status': 'reopened',
        },
        where: 'id = ?',
        whereArgs: [capId],
      );

      await txn.insert('cap_log', {
        'id': const Uuid().v4(),
        'cap_id': capId,
        'event': 'reopened',
        'from_status': cap.status,
        'to_status': 'reopened',
        'actor_user_id': actorId,
        'device_id': deviceId,
        'timestamp': now,
        'note': 'CAP reopened: $trimmedReason',
      });
    });
  }

  /// Computes summary counts of CAPs by status and overdue count for GM Dashboard.
  Future<CapDashboardCounts> getCapCounts({AuthUser? viewer}) async {
    final caps = await listCaps(
      viewer: viewer ??
          const AuthUser(id: 'gm', name: 'GM', role: 'GM', languagePref: 'en'),
    );
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    var openCount = 0;
    var awaitingCount = 0;
    var verifiedCount = 0;
    var closedCount = 0;
    var overdueCount = 0;

    for (final c in caps) {
      if (c.status == 'open' || c.status == 'reopened') {
        openCount++;
      } else if (c.status == 'done') {
        awaitingCount++;
      } else if (c.status == 'verified') {
        verifiedCount++;
      } else if (c.status == 'closed') {
        closedCount++;
      }

      // Overdue: not closed, not verified, deadline strictly before today
      if (c.status != 'closed' &&
          c.status != 'verified' &&
          c.deadline.compareTo(todayStr) < 0) {
        overdueCount++;
      }
    }

    return CapDashboardCounts(
      open: openCount,
      awaitingVerification: awaitingCount,
      verified: verifiedCount,
      closed: closedCount,
      overdue: overdueCount,
    );
  }

  /// Daily batch job evaluating overdue CAPs (Spec §9.1 / Workbook Day 4 §4.4).
  ///
  /// Evaluates all CAPs with status in ('open', 'done'):
  ///   1. If status == 'open' and deadline < asOfDate:
  ///      Atomically updates status -> 'aged', increments aged_count, and logs cap_log event 'aged'.
  ///      Returns updated CAP in [CapAgingResult.agedCaps].
  ///   2. If status == 'done' and deadline < asOfDate and done > 3 days ago:
  ///      Collects CAP in [CapAgingResult.verifyPendingCaps] without status mutation.
  Future<CapAgingResult> ageOverdueCaps({DateTime? asOf}) async {
    final effectiveAsOf = asOf ?? DateTime.now();
    final todayStr = effectiveAsOf.toIso8601String().substring(0, 10);
    final asOfDateOnly = DateTime(effectiveAsOf.year, effectiveAsOf.month, effectiveAsOf.day);

    final db = AppDatabase.instance.db;

    // 1. Select all candidate caps with status IN ('open', 'done')
    final rows = await db.query(
      'caps',
      where: "status IN ('open', 'done')",
    );

    final agedList = <Cap>[];
    final verifyPendingList = <Cap>[];

    for (final row in rows) {
      final cap = Cap.fromMap(row);

      if (cap.status == 'open' && cap.deadline.compareTo(todayStr) < 0) {
        // Overdue open CAP -> transition to aged in transaction
        final nowIso = DateTime.now().toUtc().toIso8601String();
        final newAgedCount = cap.agedCount + 1;

        await db.transaction((txn) async {
          await txn.update(
            'caps',
            {
              'status': 'aged',
              'aged_count': newAgedCount,
            },
            where: 'id = ?',
            whereArgs: [cap.id],
          );

          await txn.insert('cap_log', {
            'id': const Uuid().v4(),
            'cap_id': cap.id,
            'event': 'aged',
            'from_status': 'open',
            'to_status': 'aged',
            'actor_user_id': null,
            'device_id': null,
            'timestamp': nowIso,
            'note': 'Auto-aged: deadline ${cap.deadline} passed',
          });
        });

        // Add updated Cap to returned aged list
        agedList.add(
          Cap.fromMap({
            ...row,
            'status': 'aged',
            'aged_count': newAgedCount,
          }),
        );
      } else if (cap.status == 'done' && cap.deadline.compareTo(todayStr) < 0) {
        if (cap.doneAt != null) {
          final doneDateTime = DateTime.tryParse(cap.doneAt!);
          if (doneDateTime != null) {
            final doneDateOnly = DateTime(doneDateTime.year, doneDateTime.month, doneDateTime.day);
            final daysSinceDone = asOfDateOnly.difference(doneDateOnly).inDays;
            if (daysSinceDone > 3) {
              verifyPendingList.add(cap);
            }
          }
        }
      }
    }

    return CapAgingResult(
      agedCaps: agedList,
      verifyPendingCaps: verifyPendingList,
    );
  }
}

/// Summary counts for GM CAP oversight dashboard.
class CapDashboardCounts {
  const CapDashboardCounts({
    required this.open,
    required this.awaitingVerification,
    required this.verified,
    required this.closed,
    required this.overdue,
  });

  final int open;
  final int awaitingVerification;
  final int verified;
  final int closed;
  final int overdue;
}

/// Result structure returned by [CapRepository.ageOverdueCaps].
class CapAgingResult {
  const CapAgingResult({
    required this.agedCaps,
    required this.verifyPendingCaps,
  });

  final List<Cap> agedCaps;
  final List<Cap> verifyPendingCaps;
}

