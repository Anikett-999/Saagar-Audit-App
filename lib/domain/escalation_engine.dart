import '../data/models/audit.dart';
import '../data/models/audit_result.dart';
import '../data/models/cap.dart';
import '../data/models/checkpoint.dart';

/// Draft escalation object before database persistence (Spec §7 & Appendix A.5).
class EscalationDraft {
  const EscalationDraft({
    required this.triggerNumber,
    required this.triggerLabel,
    required this.sourceType,
    this.sourceAuditId,
    this.sourceCapId,
    this.raisedByUserId,
    required this.targetRole,
    required this.urgency,
    required this.deliveryChannel,
    required this.whatHappened,
    required this.evidence,
    required this.impact,
    required this.requestedAction,
  });

  final int triggerNumber; // 0..7
  final String triggerLabel;
  final String sourceType; // 'audit' | 'cap' | 'trend' | 'manual'
  final String? sourceAuditId;
  final String? sourceCapId;
  final String? raisedByUserId;
  final String targetRole; // 'GM' | 'OWNER'
  final String urgency; // 'immediate' | 'same_day' | 'same_night' | 'next_audit'
  final String deliveryChannel; // 'in_app' | 'whatsapp'
  final String whatHappened;
  final String evidence;
  final String impact;
  final String requestedAction;
}

/// Generated 4-part message container (Spec §7.2 / Appendix A.5).
class EscalationMessage {
  const EscalationMessage({
    required this.summary,
    required this.full,
  });

  final String summary;
  final String full;
}

/// Pure deterministic escalation engine (Spec Section 7 & Appendix A.5).
///
/// Evaluates threshold breaches over audit and CAP results without DB side-effects.
class EscalationEngine {
  EscalationEngine._();

  /// Evaluates triggers after an audit submission (Spec §7).
  ///
  /// Implemented in P3-2:
  /// - Trigger 1: Daily Critical band (< 80%) → GM (same_night), Owner if Cash/Inv cause.
  /// - Trigger 2: Same checkpoint failed in ≥5 of last 7 daily audits → GM (next_audit).
  /// - Trigger 3: Single-day cash variance > ₹500 → GM (same_day, whatsapp); consecutive → Owner (immediate, whatsapp).
  /// - Trigger 7: Declining trend across 3+ consecutive weekly audits → Owner (same_day, in_app).
  ///
  /// Note: Triggers 4 (inventory variance >2%) and 5 (security concern flag)
  /// are deferred to P3-2b per Owner ruling.
  static List<EscalationDraft> evaluateAfterAudit({
    required Audit audit,
    required List<AuditResult> results,
    required List<Checkpoint> checkpoints,
    Audit? previousDailyAudit,
    List<Audit> recentDailyAudits = const [],
    List<AuditResult> recentDailyResults = const [],
    List<Audit> recentWeeklyAudits = const [],
    String? raisedByUserId,
  }) {
    final drafts = <EscalationDraft>[];

    // -------------------------------------------------------------
    // Trigger 1: Daily Critical band (< 80%) (Spec §7.0)
    // -------------------------------------------------------------
    final band = audit.band?.toLowerCase();
    final compliance = audit.compliancePct;
    if (audit.auditType == 'daily' &&
        (band == 'critical' || (compliance != null && compliance < 80.0))) {
      final cpMap = {for (final cp in checkpoints) cp.id: cp};
      final failedResults = results.where((r) => r.result == 'F').toList();

      bool hasCashCause = false;
      bool hasInvCause = false;
      final failedCpLabels = <String>[];

      for (final r in failedResults) {
        final cp = cpMap[r.checkpointId];
        final sopId = cp?.sopId ?? '';
        final cpId = r.checkpointId;

        final isCash = sopId == 'SOP6' || cpId.startsWith('6.') || cpId.startsWith('CW.');
        final isInv = sopId == 'SOP7' || cpId.startsWith('7.') || cpId.startsWith('IW.');

        if (isCash) hasCashCause = true;
        if (isInv) hasInvCause = true;

        failedCpLabels.add(cp != null ? '${cp.id} (${cp.sopId})' : cpId);
      }

      final isCashOrInv = hasCashCause || hasInvCause;
      final failedSummary = failedCpLabels.isEmpty ? 'None' : failedCpLabels.take(4).join(', ');

      // 1A. To GM (same_night; via whatsapp if cash/inv else in_app)
      drafts.add(
        EscalationDraft(
          triggerNumber: 1,
          triggerLabel: 'Daily audit Critical band',
          sourceType: 'audit',
          sourceAuditId: audit.id,
          raisedByUserId: raisedByUserId,
          targetRole: 'GM',
          urgency: 'same_night',
          deliveryChannel: isCashOrInv ? 'whatsapp' : 'in_app',
          whatHappened:
              'Daily audit score for ${audit.auditDate} dropped to ${(compliance ?? 0.0).toStringAsFixed(1)}% (Critical band)${isCashOrInv ? ' with failures on critical cash/inventory controls.' : '.'}',
          evidence:
              'Daily audit score sheet (${(compliance ?? 0.0).toStringAsFixed(1)}% Critical band, ${audit.failCount} fails). Failed checkpoints: $failedSummary.',
          impact: isCashOrInv
              ? 'Immediate closing risk at store counter; store closed without reconciled cash or inventory controls.'
              : 'Store compliance fell below 80% critical threshold, indicating broad operational breakdowns.',
          requestedAction:
              'Decision needed: GM review audit tonight; approve emergency corrective actions before tomorrow 10:00 AM opening.',
        ),
      );

      // 1B. If Cash or Inventory cause, ALSO to Owner via whatsapp (same_night)
      if (isCashOrInv) {
        drafts.add(
          EscalationDraft(
            triggerNumber: 1,
            triggerLabel: 'Daily audit Critical band',
            sourceType: 'audit',
            sourceAuditId: audit.id,
            raisedByUserId: raisedByUserId,
            targetRole: 'OWNER',
            urgency: 'same_night',
            deliveryChannel: 'whatsapp',
            whatHappened:
                'Critical band breach (< 80%) on ${audit.auditDate} caused by critical ${hasCashCause && hasInvCause ? 'Cash and Inventory' : hasCashCause ? 'Cash Management' : 'Inventory Management'} failures.',
            evidence:
                'Audit #${audit.id.substring(0, audit.id.length.clamp(0, 8))} scored ${(compliance ?? 0.0).toStringAsFixed(1)}%. Critical fails: $failedSummary.',
            impact:
                'High financial and operational exposure in cash till / inventory shrinkage at store premises.',
            requestedAction:
                'Immediate review needed: Owner review critical failure and verify GM night reconciliation response.',
          ),
        );
      }
    }

    // -------------------------------------------------------------
    // Trigger 2: Same checkpoint repeated Fail (≥5 of last 7 dailies) (Spec §7.0)
    // Evaluated only when weekly audit is submitted.
    // -------------------------------------------------------------
    if (audit.auditType == 'weekly' && recentDailyAudits.isNotEmpty) {
      // Map checkpointId -> count of daily audits it failed in
      final auditIds = recentDailyAudits.map((a) => a.id).toSet();
      final failCounts = <String, int>{};

      for (final r in recentDailyResults) {
        if (r.result == 'F' && auditIds.contains(r.auditId)) {
          failCounts[r.checkpointId] = (failCounts[r.checkpointId] ?? 0) + 1;
        }
      }

      final cpMap = {for (final cp in checkpoints) cp.id: cp};

      for (final entry in failCounts.entries) {
        if (entry.value >= 5) {
          final cp = cpMap[entry.key];
          final cpName = cp?.textEn ?? entry.key;

          drafts.add(
            EscalationDraft(
              triggerNumber: 2,
              triggerLabel: 'Same checkpoint repeated Fail',
              sourceType: 'audit',
              sourceAuditId: audit.id,
              raisedByUserId: raisedByUserId,
              targetRole: 'GM',
              urgency: 'next_audit',
              deliveryChannel: 'in_app',
              whatHappened:
                  'Checkpoint ${entry.key} ($cpName) failed in ${entry.value} of the last ${recentDailyAudits.length} daily audits.',
              evidence:
                  'Daily audit results over the past week demonstrate chronic recurrence (${entry.value}/7 days failed).',
              impact:
                  'Systemic non-compliance indicates persistent operational breakdown rather than isolated human error.',
              requestedAction:
                  'GM action needed: Issue Pattern CAP at weekly audit, investigate root cause with Store Manager, and set mandatory follow-up.',
            ),
          );
        }
      }
    }

    // -------------------------------------------------------------
    // Trigger 3: Single-day cash variance > ₹500 (Spec §7.0)
    // -------------------------------------------------------------
    if (audit.auditType == 'daily') {
      final variance = audit.cashVarianceRupees;
      if (variance != null && variance.abs() > 500.0) {
        final varianceAbs = variance.abs().toStringAsFixed(0);
        final direction = variance < 0 ? 'shortage' : 'excess';

        // 3A. To GM (same_day, whatsapp)
        drafts.add(
          EscalationDraft(
            triggerNumber: 3,
            triggerLabel: 'Single-day cash variance',
            sourceType: 'audit',
            sourceAuditId: audit.id,
            raisedByUserId: raisedByUserId,
            targetRole: 'GM',
            urgency: 'same_day',
            deliveryChannel: 'whatsapp',
            whatHappened:
                'Closing cash variance of ₹$varianceAbs ($direction) observed during daily audit on ${audit.auditDate}.',
            evidence:
                'Daily cash count sheet shows actual variance of ₹${variance.toStringAsFixed(0)} (exceeds ₹500 tolerance).',
            impact:
                'Direct financial discrepancy in daily cash till; unaccounted variance exceeds permitted tolerance.',
            requestedAction:
                'Decision needed: GM to investigate cashier log and verify CCTV of cash drawer with SM today.',
          ),
        );

        // 3B. Check yesterday — if also > ₹500, escalate to Owner (immediate, whatsapp)
        final yestVar = previousDailyAudit?.cashVarianceRupees;
        if (yestVar != null && yestVar.abs() > 500.0) {
          final yestAbs = yestVar.abs().toStringAsFixed(0);
          drafts.add(
            EscalationDraft(
              triggerNumber: 3,
              triggerLabel: 'Single-day cash variance',
              sourceType: 'audit',
              sourceAuditId: audit.id,
              raisedByUserId: raisedByUserId,
              targetRole: 'OWNER',
              urgency: 'immediate',
              deliveryChannel: 'whatsapp',
              whatHappened:
                  'Second consecutive day with closing cash variance exceeding ₹500 (today: ₹$varianceAbs $direction; yesterday: ₹$yestAbs).',
              evidence:
                  'Consecutive daily cash discrepancies recorded on ${previousDailyAudit?.auditDate} (₹$yestAbs) and ${audit.auditDate} (₹$varianceAbs).',
              impact:
                  'Repeated cash leakage indicates potential systemic till mismanagement or security breach.',
              requestedAction:
                  'Immediate action needed: Owner notified for immediate cash drawer audit and management review.',
            ),
          );
        }
      }
    }

    // -------------------------------------------------------------
    // Trigger 7: Declining trend across 3+ consecutive weeks (Spec §7.0)
    // -------------------------------------------------------------
    if (audit.auditType == 'weekly') {
      // Gather chronological weekly audits including current audit
      final allWeeklies = <Audit>[...recentWeeklyAudits];
      if (!allWeeklies.any((w) => w.id == audit.id)) {
        allWeeklies.add(audit);
      }
      allWeeklies.sort((a, b) => a.auditDate.compareTo(b.auditDate));

      if (allWeeklies.length >= 3) {
        final last3 = allWeeklies.sublist(allWeeklies.length - 3);
        final w0 = last3[0];
        final w1 = last3[1];
        final w2 = last3[2]; // current or most recent

        final p0 = w0.compliancePct;
        final p1 = w1.compliancePct;
        final p2 = w2.compliancePct;

        // Strictly declining: w0 > w1 > w2
        if (p0 != null && p1 != null && p2 != null && p0 > p1 && p1 > p2) {
          drafts.add(
            EscalationDraft(
              triggerNumber: 7,
              triggerLabel: 'Declining trend',
              sourceType: 'trend',
              sourceAuditId: audit.id,
              raisedByUserId: raisedByUserId,
              targetRole: 'OWNER',
              urgency: 'same_day',
              deliveryChannel: 'in_app',
              whatHappened:
                  'Weekly audit compliance percentage has declined for 3 consecutive weeks (${p0.toStringAsFixed(1)}% → ${p1.toStringAsFixed(1)}% → ${p2.toStringAsFixed(1)}%).',
              evidence:
                  'Weekly audit scores for Week ${w0.weekNumber} (${p0.toStringAsFixed(1)}%), Week ${w1.weekNumber} (${p1.toStringAsFixed(1)}%), and Week ${w2.weekNumber} (${p2.toStringAsFixed(1)}%) demonstrate continuous downward trajectory.',
              impact:
                  'Store operational performance is degrading across multiple weeks without effective corrective turnaround.',
              requestedAction:
                  'Owner action needed: Review 3-week trend report and schedule store operational review with GM.',
            ),
          );
        }
      }
    }

    return drafts;
  }

  /// Creates a manual Trigger 6 escalation (auditor or user initiated per Spec §7.0).
  static EscalationDraft createManualEscalation({
    required String raisedByUserId,
    required String whatHappened,
    required String evidence,
    required String impact,
    required String requestedAction,
    String? sourceCapId,
    String? sourceAuditId,
    String targetRole = 'OWNER',
    String urgency = 'same_day',
    String deliveryChannel = 'whatsapp',
  }) {
    return EscalationDraft(
      triggerNumber: 6,
      triggerLabel: 'Customer complaint',
      sourceType: sourceCapId != null ? 'cap' : 'manual',
      sourceAuditId: sourceAuditId,
      sourceCapId: sourceCapId,
      raisedByUserId: raisedByUserId,
      targetRole: targetRole,
      urgency: urgency,
      deliveryChannel: deliveryChannel,
      whatHappened: whatHappened,
      evidence: evidence,
      impact: impact,
      requestedAction: requestedAction,
    );
  }

  /// Creates an escalation for an overdue CAP transitioning to 'aged' (Spec §9.1 / Workbook Day 4 §4.4).
  ///
  /// Target role is escalated one tier up:
  ///   * SM -> GM
  ///   * GM -> OWNER
  ///   * OWNER -> OWNER (capped at highest role)
  static EscalationDraft createCapAgedEscalation({
    required Cap cap,
    required String responsibleRole,
    DateTime? asOf,
  }) {
    final cleanRole = responsibleRole.toUpperCase().trim();
    final String targetRole;
    if (cleanRole == 'SM') {
      targetRole = 'GM';
    } else {
      targetRole = 'OWNER';
    }

    return EscalationDraft(
      triggerNumber: 0,
      triggerLabel: 'CAP aged',
      sourceType: 'cap',
      sourceAuditId: null,
      sourceCapId: cap.id,
      raisedByUserId: null,
      targetRole: targetRole,
      urgency: 'same_day',
      deliveryChannel: 'in_app',
      whatHappened:
          'CAP ${cap.id} missed its deadline (${cap.deadline}) without completion and has auto-aged (age count: ${cap.agedCount + 1}).',
      evidence:
          'Origin Checkpoint: ${cap.originCheckpointId}, Problem: "${cap.problemStatement}", Root cause: "${cap.rootCause}".',
      impact:
          'Corrective action overdue. Operational non-compliance remains unmitigated past commitment date.',
      requestedAction:
          '$targetRole intervention required: Review root cause with responsible staff and expedite corrective action closure.',
    );
  }

  /// Creates an escalation for a done CAP pending verification > 3 days past deadline (Spec §9.1).
  static EscalationDraft createVerifyPendingEscalation({
    required Cap cap,
    DateTime? asOf,
  }) {
    final doneDateStr = cap.doneAt != null
        ? (cap.doneAt!.length >= 10 ? cap.doneAt!.substring(0, 10) : cap.doneAt!)
        : 'unknown date';

    return EscalationDraft(
      triggerNumber: 0,
      triggerLabel: 'CAP verify pending',
      sourceType: 'cap',
      sourceAuditId: null,
      sourceCapId: cap.id,
      raisedByUserId: null,
      targetRole: 'GM',
      urgency: 'same_day',
      deliveryChannel: 'in_app',
      whatHappened:
          'CAP ${cap.id} was marked done on $doneDateStr but remains unverified > 3 days past deadline (${cap.deadline}).',
      evidence:
          'Origin Checkpoint: ${cap.originCheckpointId}, Verification method: "${cap.verificationMethod}".',
      impact:
          'Corrective actions cannot be formally closed without GM verification. Risk of recurring non-compliance.',
      requestedAction:
          'GM verification required: Conduct physical spot-check verification on store floor and verify or extend CAP in app.',
    );
  }

  /// Builds structured 4-part message container (Spec §7.2 / Appendix A.5).
  ///
  /// CRITICAL (R-Escalation): Message body is ALWAYS in English regardless of
  /// the recipient's UI language so it can be forwarded to banks, police, or
  /// Titan corporate if needed.
  static EscalationMessage buildEscalationMessage(
    EscalationDraft draft, {
    required String auditDate,
    required String auditType,
  }) {
    final urgencyTag = draft.urgency.toUpperCase();
    final summary = '[$urgencyTag] Trigger ${draft.triggerNumber} — $auditDate';
    final full = '''
ESCALATION — ${draft.triggerLabel}

1. What happened: ${draft.whatHappened}

2. Evidence: ${draft.evidence}

3. Impact: ${draft.impact}

4. Requested action: ${draft.requestedAction}

—
Saagar Traders audit app — auto-generated
Date: $auditDate • Tier: $auditType''';

    return EscalationMessage(summary: summary, full: full);
  }
}
