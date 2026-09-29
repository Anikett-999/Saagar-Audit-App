import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/audit_result.dart';
import 'package:saagar_audit_app/data/models/checkpoint.dart';
import 'package:saagar_audit_app/domain/escalation_engine.dart';

void main() {
  group('Sprint P3-2 — Escalation Engine (Spec §7 & Appendix A.5)', () {
    // Helper fixtures
    final now = DateTime.now().toUtc().toIso8601String();

    Audit makeDailyAudit({
      String id = 'audit-d1',
      String auditDate = '2026-09-29',
      double compliancePct = 78.5,
      String band = 'critical',
      int passCount = 50,
      int failCount = 18,
      int naCount = 0,
      double? cashVarianceRupees,
    }) {
      return Audit(
        id: id,
        auditType: 'daily',
        auditDate: auditDate,
        weekNumber: 39,
        monthNumber: 9,
        year: 2026,
        auditorId: 'user-sm-1',
        deviceId: 'device-1',
        status: 'submitted',
        draftStartedAt: now,
        submittedAt: now,
        rawScore: compliancePct,
        maxScore: 100.0,
        compliancePct: compliancePct,
        band: band,
        passCount: passCount,
        failCount: failCount,
        naCount: naCount,
        cashVarianceRupees: cashVarianceRupees,
      );
    }

    Audit makeWeeklyAudit({
      String id = 'audit-w1',
      String auditDate = '2026-09-27',
      int weekNumber = 39,
      double compliancePct = 86.0,
      String band = 'fair',
    }) {
      return Audit(
        id: id,
        auditType: 'weekly',
        auditDate: auditDate,
        weekNumber: weekNumber,
        monthNumber: 9,
        year: 2026,
        auditorId: 'user-gm-1',
        deviceId: 'device-1',
        status: 'submitted',
        draftStartedAt: now,
        submittedAt: now,
        rawScore: compliancePct,
        maxScore: 100.0,
        compliancePct: compliancePct,
        band: band,
        passCount: 30,
        failCount: 6,
        naCount: 0,
      );
    }

    Checkpoint makeCp({
      required String id,
      required String sopId,
      required String titleEn,
    }) {
      return Checkpoint(
        id: id,
        sopId: sopId,
        frequency: 'daily',
        sequence: 1,
        textEn: titleEn,
        textMr: titleEn,
        weight: 1,
        allowsNa: false,
        requiresPhotoOnFail: false,
        displayOrder: 1,
      );
    }

    AuditResult makeResult({
      required String auditId,
      required String checkpointId,
      required String result,
    }) {
      return AuditResult(
        id: '$auditId-$checkpointId',
        auditId: auditId,
        checkpointId: checkpointId,
        result: result,
        createdAt: now,
      );
    }

    // =========================================================================
    // Trigger 1 Tests
    // =========================================================================
    group('Trigger 1: Daily Critical band (< 80%)', () {
      test('Fires to GM (same_night, in_app) when cause is non-cash and non-inventory', () {
        final audit = makeDailyAudit(compliancePct: 78.0, band: 'critical');
        final cps = [
          makeCp(id: '1.1', sopId: 'SOP1', titleEn: 'Opening checklist'),
          makeCp(id: '2.1', sopId: 'SOP2', titleEn: 'Grooming'),
        ];
        final results = [
          makeResult(auditId: audit.id, checkpointId: '1.1', result: 'F'),
          makeResult(auditId: audit.id, checkpointId: '2.1', result: 'P'),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        expect(drafts.length, 1);
        final gmDraft = drafts.first;
        expect(gmDraft.triggerNumber, 1);
        expect(gmDraft.triggerLabel, 'Daily audit Critical band');
        expect(gmDraft.targetRole, 'GM');
        expect(gmDraft.urgency, 'same_night');
        expect(gmDraft.deliveryChannel, 'in_app');
        expect(gmDraft.whatHappened, contains('78.0% (Critical band)'));
      });

      test('Fires to BOTH GM and Owner (same_night, whatsapp) when cause is Cash Management (SOP6)', () {
        final audit = makeDailyAudit(compliancePct: 75.0, band: 'critical');
        final cps = [
          makeCp(id: '6.5', sopId: 'SOP6', titleEn: 'Cash drawer count'),
        ];
        final results = [
          makeResult(auditId: audit.id, checkpointId: '6.5', result: 'F'),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        expect(drafts.length, 2);
        final gmDraft = drafts.firstWhere((d) => d.targetRole == 'GM');
        expect(gmDraft.triggerNumber, 1);
        expect(gmDraft.urgency, 'same_night');
        expect(gmDraft.deliveryChannel, 'whatsapp');

        final ownerDraft = drafts.firstWhere((d) => d.targetRole == 'OWNER');
        expect(ownerDraft.triggerNumber, 1);
        expect(ownerDraft.urgency, 'same_night');
        expect(ownerDraft.deliveryChannel, 'whatsapp');
        expect(ownerDraft.whatHappened, contains('Cash Management'));
      });

      test('Fires to BOTH GM and Owner (same_night, whatsapp) when cause is Inventory (SOP7)', () {
        final audit = makeDailyAudit(compliancePct: 77.0, band: 'critical');
        final cps = [
          makeCp(id: '7.3', sopId: 'SOP7', titleEn: 'High value watch count'),
        ];
        final results = [
          makeResult(auditId: audit.id, checkpointId: '7.3', result: 'F'),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        expect(drafts.length, 2);
        expect(drafts.any((d) => d.targetRole == 'GM' && d.deliveryChannel == 'whatsapp'), isTrue);
        expect(drafts.any((d) => d.targetRole == 'OWNER' && d.deliveryChannel == 'whatsapp'), isTrue);
      });

      test('Does NOT fire Trigger 1 if score is in Poor, Fair, Good, or Excellent band (>= 80%)', () {
        final audit = makeDailyAudit(compliancePct: 80.0, band: 'poor');
        final cps = [makeCp(id: '6.5', sopId: 'SOP6', titleEn: 'Cash')];
        final results = [makeResult(auditId: audit.id, checkpointId: '6.5', result: 'F')];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        expect(drafts.where((d) => d.triggerNumber == 1).isEmpty, isTrue);
      });
    });

    // =========================================================================
    // Trigger 2 Tests
    // =========================================================================
    group('Trigger 2: Same checkpoint repeated Fail (≥5 of last 7 dailies)', () {
      test('Fires to GM (next_audit, in_app) when a checkpoint fails in 5 of last 7 daily audits', () {
        final weeklyAudit = makeWeeklyAudit();
        final dailyAudits = List.generate(
          7,
          (i) => makeDailyAudit(id: 'daily-$i', auditDate: '2026-09-2$i', compliancePct: 85.0, band: 'fair'),
        );
        final cp = makeCp(id: '1.2', sopId: 'SOP1', titleEn: 'Uniform inspection');

        // Checkpoint 1.2 fails in 5 out of 7 daily audits
        final dailyResults = <AuditResult>[];
        for (var i = 0; i < 7; i++) {
          dailyResults.add(
            makeResult(
              auditId: 'daily-$i',
              checkpointId: '1.2',
              result: i < 5 ? 'F' : 'P',
            ),
          );
        }

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: weeklyAudit,
          results: const [],
          checkpoints: [cp],
          recentDailyAudits: dailyAudits,
          recentDailyResults: dailyResults,
        );

        expect(drafts.length, 1);
        final d = drafts.first;
        expect(d.triggerNumber, 2);
        expect(d.triggerLabel, 'Same checkpoint repeated Fail');
        expect(d.targetRole, 'GM');
        expect(d.urgency, 'next_audit');
        expect(d.deliveryChannel, 'in_app');
        expect(d.whatHappened, contains('failed in 5 of the last 7 daily audits'));
      });

      test('Does NOT fire Trigger 2 if checkpoint failed fewer than 5 times (e.g. 4 times)', () {
        final weeklyAudit = makeWeeklyAudit();
        final dailyAudits = List.generate(
          7,
          (i) => makeDailyAudit(id: 'daily-$i', auditDate: '2026-09-2$i'),
        );
        final cp = makeCp(id: '1.2', sopId: 'SOP1', titleEn: 'Uniform');

        final dailyResults = <AuditResult>[
          for (var i = 0; i < 7; i++)
            makeResult(
              auditId: 'daily-$i',
              checkpointId: '1.2',
              result: i < 4 ? 'F' : 'P', // Only 4 fails
            ),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: weeklyAudit,
          results: const [],
          checkpoints: [cp],
          recentDailyAudits: dailyAudits,
          recentDailyResults: dailyResults,
        );

        expect(drafts.where((d) => d.triggerNumber == 2).isEmpty, isTrue);
      });
    });

    // =========================================================================
    // Trigger 3 Tests
    // =========================================================================
    group('Trigger 3: Single-day cash variance (> ₹500)', () {
      test('Fires to GM (same_day, whatsapp) on cash shortage > ₹500', () {
        final audit = makeDailyAudit(
          compliancePct: 90.0,
          band: 'good',
          cashVarianceRupees: -650.0, // ₹650 shortage
        );

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: const [],
          checkpoints: const [],
        );

        expect(drafts.length, 1);
        final d = drafts.first;
        expect(d.triggerNumber, 3);
        expect(d.triggerLabel, 'Single-day cash variance');
        expect(d.targetRole, 'GM');
        expect(d.urgency, 'same_day');
        expect(d.deliveryChannel, 'whatsapp');
        expect(d.whatHappened, contains('₹650 (shortage)'));
      });

      test('Fires to GM (same_day) AND Owner (immediate, whatsapp) if yesterday was also > ₹500', () {
        final yesterday = makeDailyAudit(
          id: 'audit-d0',
          auditDate: '2026-09-28',
          cashVarianceRupees: -700.0,
        );
        final today = makeDailyAudit(
          id: 'audit-d1',
          auditDate: '2026-09-29',
          compliancePct: 92.0,
          band: 'good',
          cashVarianceRupees: 550.0, // ₹550 excess
        );

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: today,
          results: const [],
          checkpoints: const [],
          previousDailyAudit: yesterday,
        );

        expect(drafts.length, 2);
        final gmDraft = drafts.firstWhere((d) => d.targetRole == 'GM');
        expect(gmDraft.triggerNumber, 3);
        expect(gmDraft.urgency, 'same_day');
        expect(gmDraft.deliveryChannel, 'whatsapp');

        final ownerDraft = drafts.firstWhere((d) => d.targetRole == 'OWNER');
        expect(ownerDraft.triggerNumber, 3);
        expect(ownerDraft.urgency, 'immediate');
        expect(ownerDraft.deliveryChannel, 'whatsapp');
        expect(ownerDraft.whatHappened, contains('Second consecutive day'));
      });

      test('Does NOT fire Trigger 3 if cash variance is <= ₹500 (e.g. ₹500, -₹250, 0, or null)', () {
        final audit = makeDailyAudit(cashVarianceRupees: -500.0);
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: const [],
          checkpoints: const [],
        );
        expect(drafts.where((d) => d.triggerNumber == 3).isEmpty, isTrue);

        final auditNull = makeDailyAudit(cashVarianceRupees: null);
        final draftsNull = EscalationEngine.evaluateAfterAudit(
          audit: auditNull,
          results: const [],
          checkpoints: const [],
        );
        expect(draftsNull.where((d) => d.triggerNumber == 3).isEmpty, isTrue);
      });
    });

    // =========================================================================
    // Trigger 7 Tests
    // =========================================================================
    group('Trigger 7: Declining trend across 3+ consecutive weeks', () {
      test('Fires to Owner (same_day, in_app) when 3 consecutive weeks strictly decline (e.g. 93% → 90% → 86%)', () {
        final w0 = makeWeeklyAudit(id: 'w-0', auditDate: '2026-09-10', weekNumber: 37, compliancePct: 93.0);
        final w1 = makeWeeklyAudit(id: 'w-1', auditDate: '2026-09-17', weekNumber: 38, compliancePct: 90.0);
        final wCurrent = makeWeeklyAudit(id: 'w-2', auditDate: '2026-09-24', weekNumber: 39, compliancePct: 86.0);

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: wCurrent,
          results: const [],
          checkpoints: const [],
          recentWeeklyAudits: [w0, w1],
        );

        expect(drafts.length, 1);
        final d = drafts.first;
        expect(d.triggerNumber, 7);
        expect(d.triggerLabel, 'Declining trend');
        expect(d.targetRole, 'OWNER');
        expect(d.urgency, 'same_day');
        expect(d.deliveryChannel, 'in_app');
        expect(d.whatHappened, contains('93.0% → 90.0% → 86.0%'));
      });

      test('Does NOT fire Trigger 7 if trend is not strictly declining (e.g. 90% → 92% → 85%)', () {
        final w0 = makeWeeklyAudit(id: 'w-0', auditDate: '2026-09-10', compliancePct: 90.0);
        final w1 = makeWeeklyAudit(id: 'w-1', auditDate: '2026-09-17', compliancePct: 92.0); // Increased!
        final wCurrent = makeWeeklyAudit(id: 'w-2', auditDate: '2026-09-24', compliancePct: 85.0);

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: wCurrent,
          results: const [],
          checkpoints: const [],
          recentWeeklyAudits: [w0, w1],
        );

        expect(drafts.where((d) => d.triggerNumber == 7).isEmpty, isTrue);
      });
    });

    // =========================================================================
    // Trigger 6 (Manual) & 4-Part Message Format Tests
    // =========================================================================
    group('Trigger 6 (Manual) & 4-Part Message Generator (Spec §7.2 / Appendix A.5)', () {
      test('createManualEscalation sets trigger 6, target Owner, same_day, whatsapp', () {
        final draft = EscalationEngine.createManualEscalation(
          raisedByUserId: 'user-sm-1',
          whatHappened: 'Customer complaint regarding damaged strap on purchase',
          evidence: 'Receipt #9482 and WhatsApp chat with customer',
          impact: 'Potential Titan customer escalation and store brand risk',
          requestedAction: 'Owner approval for customer replacement watch',
        );

        expect(draft.triggerNumber, 6);
        expect(draft.triggerLabel, 'Customer complaint');
        expect(draft.targetRole, 'OWNER');
        expect(draft.urgency, 'same_day');
        expect(draft.deliveryChannel, 'whatsapp');
      });

      test('buildEscalationMessage produces 4-part message in English with standard header and footer', () {
        const draft = EscalationDraft(
          triggerNumber: 1,
          triggerLabel: 'Daily audit Critical band',
          sourceType: 'audit',
          sourceAuditId: 'audit-d1',
          targetRole: 'GM',
          urgency: 'same_night',
          deliveryChannel: 'whatsapp',
          whatHappened: 'Daily audit score for 2026-09-29 dropped to 78.2% (Critical band).',
          evidence: 'Checkpoint 6.5 cash variance ₹420 and 6.11 missing signature.',
          impact: 'Closing cash risk at Titan World counter.',
          requestedAction: 'GM review audit tonight; approve emergency cash audit.',
        );

        final msg = EscalationEngine.buildEscalationMessage(
          draft,
          auditDate: '2026-09-29',
          auditType: 'daily',
        );

        expect(msg.summary, '[SAME_NIGHT] Trigger 1 — 2026-09-29');

        // Check the 4 mandatory parts from Spec §7.2
        expect(msg.full, contains('ESCALATION — Daily audit Critical band'));
        expect(msg.full, contains('1. What happened: Daily audit score for 2026-09-29 dropped to 78.2% (Critical band).'));
        expect(msg.full, contains('2. Evidence: Checkpoint 6.5 cash variance ₹420 and 6.11 missing signature.'));
        expect(msg.full, contains('3. Impact: Closing cash risk at Titan World counter.'));
        expect(msg.full, contains('4. Requested action: GM review audit tonight; approve emergency cash audit.'));

        // Check footer
        expect(msg.full, contains('Saagar Traders audit app — auto-generated'));
        expect(msg.full, contains('Date: 2026-09-29 • Tier: daily'));
      });
    });
  });
}
