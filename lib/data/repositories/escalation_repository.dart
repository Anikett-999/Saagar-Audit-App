import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/escalation.dart';
import '../../domain/escalation_engine.dart';
import 'user_repository.dart';

/// Repository for the `escalations` table (Spec §7, §4.13 & Appendix A.5).
class EscalationRepository {
  EscalationRepository._();
  static final EscalationRepository instance = EscalationRepository._();

  /// Inserts a new escalation row with idempotency protection.
  ///
  /// Prevents double-raising the same (trigger_number, source_audit_id, raised_to_user_id).
  Future<Escalation> raise(EscalationDraft draft) async {
    // 1. Resolve recipient user ID based on target role
    String? recipientId;
    if (draft.targetRole == 'GM') {
      final gm = await UserRepository.instance.getFirstGm();
      recipientId = gm?.id;
    } else {
      final owner = await UserRepository.instance.getOwner();
      recipientId = owner?.id;
    }

    if (recipientId == null) {
      // Fallback: any active user in the database
      final active = await UserRepository.instance.listActive();
      if (active.isNotEmpty) {
        recipientId = active.first.id;
      } else {
        throw StateError('Cannot raise escalation: no active recipient user found in database.');
      }
    }

    final String resolvedRecipientId = recipientId;
    final db = AppDatabase.instance.db;

    return await db.transaction((txn) async {
      // 2. Idempotency check: don't double-raise on same audit + trigger + recipient
      // For Trigger 2 (recurring checkpoint fails) and Trigger 5 (security concern flag),
      // discriminate by what_happened so multiple checkpoints each raise their own escalation record.
      if (draft.sourceAuditId != null) {
        final isDiscriminated = draft.triggerNumber == 2 || draft.triggerNumber == 5;
        final existing = await txn.query(
          'escalations',
          where: isDiscriminated
              ? 'trigger_number = ? AND source_audit_id = ? AND raised_to_user_id = ? AND what_happened = ?'
              : 'trigger_number = ? AND source_audit_id = ? AND raised_to_user_id = ?',
          whereArgs: isDiscriminated
              ? [draft.triggerNumber, draft.sourceAuditId, resolvedRecipientId, draft.whatHappened]
              : [draft.triggerNumber, draft.sourceAuditId, resolvedRecipientId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          return Escalation.fromMap(existing.first);
        }
      } else if (draft.sourceCapId != null) {
        // Spec §3.1 / §4.3: Guard against double-raising CAP escalations.
        // For verify-pending specifically, do not re-raise while one is already active ('open' or 'acknowledged').
        final isVerifyPending = draft.triggerLabel == 'CAP verify pending';
        final existing = await txn.query(
          'escalations',
          where: isVerifyPending
              ? "trigger_number = ? AND source_cap_id = ? AND raised_to_user_id = ? AND status IN ('open', 'acknowledged')"
              : 'trigger_number = ? AND source_cap_id = ? AND raised_to_user_id = ?',
          whereArgs: [draft.triggerNumber, draft.sourceCapId, resolvedRecipientId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          return Escalation.fromMap(existing.first);
        }
      }

      // 3. Insert fresh escalation record atomically
      final escalation = Escalation(
        id: const Uuid().v4(),
        triggerNumber: draft.triggerNumber,
        triggerLabel: draft.triggerLabel,
        sourceType: draft.sourceType,
        sourceAuditId: draft.sourceAuditId,
        sourceCapId: draft.sourceCapId,
        raisedByUserId: draft.raisedByUserId,
        raisedToUserId: resolvedRecipientId,
        urgency: draft.urgency,
        whatHappened: draft.whatHappened,
        evidence: draft.evidence,
        impact: draft.impact,
        requestedAction: draft.requestedAction,
        status: 'open',
        raisedAt: DateTime.now().toUtc().toIso8601String(),
        whatsappSent: false,
      );

      await txn.insert('escalations', escalation.toMap());
      return escalation;
    });
  }

  /// Lists escalations with optional status and recipient filters.
  Future<List<Escalation>> listAll({
    String? status,
    String? raisedToUserId,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    if (raisedToUserId != null) {
      whereClauses.add('raised_to_user_id = ?');
      whereArgs.add(raisedToUserId);
    }

    final rows = await AppDatabase.instance.db.query(
      'escalations',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'raised_at DESC',
    );

    return rows.map(Escalation.fromMap).toList();
  }

  /// Lists all currently open escalations.
  Future<List<Escalation>> listOpen({String? raisedToUserId}) async {
    return listAll(status: 'open', raisedToUserId: raisedToUserId);
  }

  /// Returns total count of open escalations.
  Future<int> countOpen({String? raisedToUserId}) async {
    final openList = await listOpen(raisedToUserId: raisedToUserId);
    return openList.length;
  }

  /// Retrieves a single escalation by ID.
  Future<Escalation?> getById(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'escalations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Escalation.fromMap(rows.first);
  }

  /// Acknowledges an open escalation (Spec §7).
  Future<void> acknowledge(String id) async {
    await AppDatabase.instance.db.update(
      'escalations',
      {
        'status': 'acknowledged',
        'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Resolves an escalation with mandatory resolution notes (Spec §7).
  Future<void> resolve(String id, {required String resolutionNotes}) async {
    final notes = resolutionNotes.trim();
    if (notes.isEmpty) {
      throw ArgumentError('Resolution notes cannot be empty when resolving an escalation.');
    }

    await AppDatabase.instance.db.update(
      'escalations',
      {
        'status': 'resolved',
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'resolution_notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks WhatsApp message as launched/sent.
  Future<void> markWhatsAppSent(String id) async {
    await AppDatabase.instance.db.update(
      'escalations',
      {'whatsapp_sent': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
