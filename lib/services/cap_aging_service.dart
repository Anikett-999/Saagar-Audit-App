import 'package:flutter/foundation.dart';

import '../data/models/escalation.dart';
import '../data/repositories/cap_repository.dart';
import '../data/repositories/escalation_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/escalation_engine.dart';
import 'notification_service.dart';

/// Summary report of a daily CAP aging job run.
class CapAgingRunSummary {
  const CapAgingRunSummary({
    required this.agedCount,
    required this.verifyPendingCount,
    required this.escalationsRaised,
  });

  final int agedCount;
  final int verifyPendingCount;
  final List<Escalation> escalationsRaised;
}

/// Orchestrator service running the daily time-based CAP aging and escalation checks
/// (Spec §9.1 / Workbook Day 4 §4.4).
class CapAgingService {
  CapAgingService._();
  static final CapAgingService instance = CapAgingService._();

  /// Executes daily CAP aging evaluation and escalation dispatch.
  ///
  /// Safe execution: each escalation dispatch is isolated in its own try/catch so
  /// delivery or notification errors never fail the batch or roll back database records.
  Future<CapAgingRunSummary> runDailyAging({DateTime? asOf}) async {
    final effectiveAsOf = asOf ?? DateTime.now();
    final dateStr = effectiveAsOf.toIso8601String().substring(0, 10);

    // 1. Transactionally age overdue open CAPs and collect verify-pending candidates
    final result = await CapRepository.instance.ageOverdueCaps(asOf: effectiveAsOf);

    final raisedEscalations = <Escalation>[];

    // 2. Process aged CAPs -> Escalate one tier up (SM -> GM, GM -> OWNER, OWNER -> OWNER)
    for (final cap in result.agedCaps) {
      try {
        final user = await UserRepository.instance.getById(cap.responsibleUserId);
        final responsibleRole = user?.role ?? 'SM';

        final draft = EscalationEngine.createCapAgedEscalation(
          cap: cap,
          responsibleRole: responsibleRole,
          asOf: effectiveAsOf,
        );

        final escalation = await EscalationRepository.instance.raise(draft);
        raisedEscalations.add(escalation);

        final msg = EscalationEngine.buildEscalationMessage(
          draft,
          auditDate: dateStr,
          auditType: 'cap',
        );

        await NotificationService.instance.showNotification(
          id: escalation.hashCode.abs() % 100000,
          title: msg.summary,
          body: draft.whatHappened,
          payload: escalation.id,
        );
      } catch (e, st) {
        debugPrint('CapAgingService: Error processing aged CAP ${cap.id}: $e\n$st');
      }
    }

    // 3. Process verify-pending CAPs -> Escalate to GM
    for (final cap in result.verifyPendingCaps) {
      try {
        final draft = EscalationEngine.createVerifyPendingEscalation(
          cap: cap,
          asOf: effectiveAsOf,
        );

        final escalation = await EscalationRepository.instance.raise(draft);
        raisedEscalations.add(escalation);

        final msg = EscalationEngine.buildEscalationMessage(
          draft,
          auditDate: dateStr,
          auditType: 'cap',
        );

        await NotificationService.instance.showNotification(
          id: escalation.hashCode.abs() % 100000,
          title: msg.summary,
          body: draft.whatHappened,
          payload: escalation.id,
        );
      } catch (e, st) {
        debugPrint('CapAgingService: Error processing verify-pending CAP ${cap.id}: $e\n$st');
      }
    }

    return CapAgingRunSummary(
      agedCount: result.agedCaps.length,
      verifyPendingCount: result.verifyPendingCaps.length,
      escalationsRaised: raisedEscalations,
    );
  }
}
