import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/cap.dart';
import 'package:saagar_audit_app/data/repositories/cap_repository.dart';
import 'package:saagar_audit_app/data/repositories/escalation_repository.dart';
import 'package:saagar_audit_app/domain/escalation_engine.dart';
import 'package:saagar_audit_app/services/cap_aging_service.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Sprint P3-3 — EscalationEngine CAP Aging Draft Builders (§9.1 / §9.2)', () {
    final now = DateTime(2026, 9, 30, 10, 0);

    const sampleCap = Cap(
      id: 'cap-101',
      originAuditId: 'audit-daily-1',
      originCheckpointId: '1.2',
      problemStatement: 'Fire exit partially blocked by merchandise cartons.',
      why1: 'Stock delivered late yesterday.',
      rootCause: 'No designated overflow staging area.',
      responsibleUserId: 'user-sm',
      deadline: '2026-09-25',
      verificationMethod: 'Floor inspection and clearance photo.',
      status: 'open',
      openedAt: '2026-09-20T10:00:00Z',
      agedCount: 0,
    );

    test('1. createCapAgedEscalation enforces tier-up truth table (SM -> GM -> Owner)', () {
      // SM -> GM
      final smDraft = EscalationEngine.createCapAgedEscalation(
        cap: sampleCap,
        responsibleRole: 'SM',
        asOf: now,
      );
      expect(smDraft.targetRole, 'GM');
      expect(smDraft.triggerNumber, 0);
      expect(smDraft.triggerLabel, 'CAP aged');
      expect(smDraft.sourceType, 'cap');
      expect(smDraft.sourceCapId, 'cap-101');
      expect(smDraft.sourceAuditId, isNull);
      expect(smDraft.urgency, 'same_day');
      expect(smDraft.deliveryChannel, 'in_app');

      // GM -> OWNER
      final gmDraft = EscalationEngine.createCapAgedEscalation(
        cap: sampleCap,
        responsibleRole: 'GM',
        asOf: now,
      );
      expect(gmDraft.targetRole, 'OWNER');

      // OWNER -> OWNER (capped at highest role)
      final ownerDraft = EscalationEngine.createCapAgedEscalation(
        cap: sampleCap,
        responsibleRole: 'OWNER',
        asOf: now,
      );
      expect(ownerDraft.targetRole, 'OWNER');
    });

    test('2. createCapAgedEscalation generates valid 4-part message container in English', () {
      final draft = EscalationEngine.createCapAgedEscalation(
        cap: sampleCap,
        responsibleRole: 'SM',
        asOf: now,
      );

      expect(draft.whatHappened, contains('cap-101'));
      expect(draft.whatHappened, contains('2026-09-25'));
      expect(draft.whatHappened, contains('age count: 1'));
      expect(draft.evidence, contains('1.2'));
      expect(draft.evidence, contains('Fire exit partially blocked'));
      expect(draft.impact, contains('Corrective action overdue'));
      expect(draft.requestedAction, contains('GM intervention required'));

      final msg = EscalationEngine.buildEscalationMessage(
        draft,
        auditDate: '2026-09-30',
        auditType: 'cap_aging',
      );

      expect(msg.full, contains('ESCALATION — CAP aged'));
      expect(msg.full, contains('1. What happened:'));
      expect(msg.full, contains('2. Evidence:'));
      expect(msg.full, contains('3. Impact:'));
      expect(msg.full, contains('4. Requested action:'));
      expect(msg.full, contains('Saagar Traders audit app — auto-generated'));
    });

    test('3. createVerifyPendingEscalation targets GM with same_day urgency', () {
      const doneCap = Cap(
        id: 'cap-done-202',
        originAuditId: 'audit-daily-2',
        originCheckpointId: '6.5',
        problemStatement: 'Cash drawer discrepancy exceeding tolerance.',
        why1: 'Cashier shift handover not verified.',
        rootCause: 'Lack of handover supervisor sign-off.',
        responsibleUserId: 'user-sm',
        deadline: '2026-09-24',
        verificationMethod: 'Cash till physical count sheet review.',
        status: 'done',
        openedAt: '2026-09-20T10:00:00Z',
        doneAt: '2026-09-24T18:00:00Z',
        agedCount: 0,
      );

      final draft = EscalationEngine.createVerifyPendingEscalation(
        cap: doneCap,
        asOf: now,
      );

      expect(draft.triggerNumber, 0);
      expect(draft.triggerLabel, 'CAP verify pending');
      expect(draft.sourceType, 'cap');
      expect(draft.sourceCapId, 'cap-done-202');
      expect(draft.sourceAuditId, isNull);
      expect(draft.targetRole, 'GM');
      expect(draft.urgency, 'same_day');
      expect(draft.deliveryChannel, 'in_app');

      expect(draft.whatHappened, contains('cap-done-202'));
      expect(draft.whatHappened, contains('remains unverified > 3 days past deadline'));
      expect(draft.evidence, contains('6.5'));
      expect(draft.impact, contains('Corrective actions cannot be formally closed'));
      expect(draft.requestedAction, contains('GM verification required'));
    });
  });

  group('Sprint P3-3 — CapRepository.ageOverdueCaps & EscalationRepository Idempotency', () {
    late FakeDatabase fakeDb;
    final asOfDate = DateTime(2026, 9, 30, 0, 5); // 2026-09-30

    setUp(() async {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed standard active users
      await fakeDb.insert('users', {
        'id': 'user-sm',
        'name': 'Store Manager',
        'role': 'SM',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      });
      await fakeDb.insert('users', {
        'id': 'user-gm',
        'name': 'General Manager',
        'role': 'GM',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      });
      await fakeDb.insert('users', {
        'id': 'user-owner',
        'name': 'Store Owner',
        'role': 'OWNER',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      });
    });

    test('4. ageOverdueCaps transitions overdue open CAP to aged and increments aged_count', () async {
      // 1. Overdue open CAP (deadline 2026-09-25 < 2026-09-30)
      await fakeDb.insert('caps', {
        'id': 'cap-overdue-1',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.2',
        'problem_statement': 'Fire exit blocked',
        'why_1': 'Late shipment',
        'root_cause': 'Staging overflow',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-25',
        'verification_method': 'Floor check',
        'status': 'open',
        'opened_at': '2026-09-20T10:00:00Z',
        'aged_count': 0,
      });

      // 2. Future open CAP (deadline 2026-10-05 > 2026-09-30)
      await fakeDb.insert('caps', {
        'id': 'cap-future-2',
        'origin_audit_id': 'audit-2',
        'origin_checkpoint_id': '2.1',
        'problem_statement': 'Price tags missing',
        'why_1': 'New batch',
        'root_cause': 'Printer jam',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-10-05',
        'verification_method': 'Audit scan',
        'status': 'open',
        'opened_at': '2026-09-28T10:00:00Z',
        'aged_count': 0,
      });

      // 3. Overdue done CAP, completed 5 days ago (2026-09-24, > 3 days past done)
      await fakeDb.insert('caps', {
        'id': 'cap-done-overdue-3',
        'origin_audit_id': 'audit-3',
        'origin_checkpoint_id': '6.5',
        'problem_statement': 'Till variance',
        'why_1': 'Shift handover',
        'root_cause': 'No supervisor sign-off',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-24',
        'verification_method': 'Till check',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
        'done_at': '2026-09-24T18:00:00Z',
        'aged_count': 0,
      });

      // 4. Done CAP, completed only 1 day ago (2026-09-29, <= 3 days)
      await fakeDb.insert('caps', {
        'id': 'cap-done-recent-4',
        'origin_audit_id': 'audit-4',
        'origin_checkpoint_id': '3.1',
        'problem_statement': 'Uniform missing',
        'why_1': 'Laundry delayed',
        'root_cause': 'Low buffer stock',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-28',
        'verification_method': 'Photo check',
        'status': 'done',
        'opened_at': '2026-09-25T10:00:00Z',
        'done_at': '2026-09-29T10:00:00Z',
        'aged_count': 0,
      });

      final result = await CapRepository.instance.ageOverdueCaps(asOf: asOfDate);

      // Verify agedCaps contains cap-overdue-1 only
      expect(result.agedCaps.length, 1);
      expect(result.agedCaps.first.id, 'cap-overdue-1');
      expect(result.agedCaps.first.status, 'aged');
      expect(result.agedCaps.first.agedCount, 1);

      // Verify DB row was updated
      final updatedRow = (await fakeDb.query('caps', where: 'id = ?', whereArgs: ['cap-overdue-1'])).first;
      expect(updatedRow['status'], 'aged');
      expect(updatedRow['aged_count'], 1);

      // Verify cap_log was inserted
      final logs = await fakeDb.query('cap_log', where: 'cap_id = ?', whereArgs: ['cap-overdue-1']);
      expect(logs.length, 1);
      expect(logs.first['event'], 'aged');
      expect(logs.first['from_status'], 'open');
      expect(logs.first['to_status'], 'aged');
      expect(logs.first['note'], contains('2026-09-25'));

      // Verify verifyPendingCaps contains cap-done-overdue-3 only (no status mutation)
      expect(result.verifyPendingCaps.length, 1);
      expect(result.verifyPendingCaps.first.id, 'cap-done-overdue-3');
      final doneRow = (await fakeDb.query('caps', where: 'id = ?', whereArgs: ['cap-done-overdue-3'])).first;
      expect(doneRow['status'], 'done'); // Status unchanged
    });

    test('5. ageOverdueCaps is idempotent — second run produces 0 newly aged caps', () async {
      await fakeDb.insert('caps', {
        'id': 'cap-overdue-1',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.2',
        'problem_statement': 'Fire exit blocked',
        'why_1': 'Late shipment',
        'root_cause': 'Staging overflow',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-25',
        'verification_method': 'Floor check',
        'status': 'open',
        'opened_at': '2026-09-20T10:00:00Z',
        'aged_count': 0,
      });

      // Run 1
      final run1 = await CapRepository.instance.ageOverdueCaps(asOf: asOfDate);
      expect(run1.agedCaps.length, 1);

      // Run 2 (same asOf date)
      final run2 = await CapRepository.instance.ageOverdueCaps(asOf: asOfDate);
      expect(run2.agedCaps.length, 0); // Already aged, not re-aged!
    });

    test('6. EscalationRepository.raise idempotency protects verify-pending CAP escalations', () async {
      const verifyCap = Cap(
        id: 'cap-verify-1',
        originAuditId: 'audit-1',
        originCheckpointId: '6.5',
        problemStatement: 'Cash discrepancy',
        why1: 'Till check',
        rootCause: 'Handover error',
        responsibleUserId: 'user-sm',
        deadline: '2026-09-24',
        verificationMethod: 'Review till counts',
        status: 'done',
        openedAt: '2026-09-20T10:00:00Z',
        doneAt: '2026-09-24T18:00:00Z',
        agedCount: 0,
      );

      final draft = EscalationEngine.createVerifyPendingEscalation(
        cap: verifyCap,
        asOf: asOfDate,
      );

      // Raise 1: creates escalation
      final esc1 = await EscalationRepository.instance.raise(draft);
      expect(esc1.id, isNotEmpty);
      expect(esc1.sourceCapId, 'cap-verify-1');
      expect(esc1.status, 'open');

      // Raise 2: while still open, returns existing escalation
      final esc2 = await EscalationRepository.instance.raise(draft);
      expect(esc2.id, esc1.id);

      final allEsc = await EscalationRepository.instance.listAll();
      expect(allEsc.where((e) => e.sourceCapId == 'cap-verify-1').length, 1);

      // Once resolved, a new verify pending can be raised
      await EscalationRepository.instance.resolve(
        esc1.id,
        resolutionNotes: 'GM verified on floor',
      );

      final esc3 = await EscalationRepository.instance.raise(draft);
      expect(esc3.id, isNot(equals(esc1.id)));
      expect(esc3.status, 'open');
    });

    test('7. CapAgingService.runDailyAging end-to-end integration (tier-up & verify-pending)', () async {
      // 1. SM-owned overdue open CAP -> should tier up to GM
      await fakeDb.insert('caps', {
        'id': 'cap-sm-overdue',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.2',
        'problem_statement': 'Fire exit blocked',
        'why_1': 'Late shipment',
        'root_cause': 'Staging overflow',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-25',
        'verification_method': 'Floor check',
        'status': 'open',
        'opened_at': '2026-09-20T10:00:00Z',
        'aged_count': 0,
      });

      // 2. GM-owned overdue open CAP -> should tier up to OWNER
      await fakeDb.insert('caps', {
        'id': 'cap-gm-overdue',
        'origin_audit_id': 'audit-2',
        'origin_checkpoint_id': '2.1',
        'problem_statement': 'Display glass scratch',
        'why_1': 'Cleaning chemical error',
        'root_cause': 'Vendor chemical issue',
        'responsible_user_id': 'user-gm',
        'deadline': '2026-09-26',
        'verification_method': 'Vendor replacement inspection',
        'status': 'open',
        'opened_at': '2026-09-21T10:00:00Z',
        'aged_count': 0,
      });

      // 3. Overdue done CAP > 3 days -> verify-pending escalation to GM
      await fakeDb.insert('caps', {
        'id': 'cap-done-pending',
        'origin_audit_id': 'audit-3',
        'origin_checkpoint_id': '6.5',
        'problem_statement': 'Cash difference',
        'why_1': 'Shift handover',
        'root_cause': 'Cashier log missing',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-24',
        'verification_method': 'Cash count sheet',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
        'done_at': '2026-09-24T18:00:00Z',
        'aged_count': 0,
      });

      // Execute daily aging run
      final summary = await CapAgingService.instance.runDailyAging(asOf: asOfDate);

      expect(summary.agedCount, 2);
      expect(summary.verifyPendingCount, 1);
      expect(summary.escalationsRaised.length, 3);

      // Verify Escalation 1: SM-owned CAP tiered up to GM
      final smCapEsc = summary.escalationsRaised.firstWhere((e) => e.sourceCapId == 'cap-sm-overdue');
      expect(smCapEsc.raisedToUserId, 'user-gm');
      expect(smCapEsc.triggerNumber, 0);
      expect(smCapEsc.triggerLabel, 'CAP aged');
      expect(smCapEsc.urgency, 'same_day');

      // Verify Escalation 2: GM-owned CAP tiered up to Owner
      final gmCapEsc = summary.escalationsRaised.firstWhere((e) => e.sourceCapId == 'cap-gm-overdue');
      expect(gmCapEsc.raisedToUserId, 'user-owner');
      expect(gmCapEsc.triggerNumber, 0);
      expect(gmCapEsc.triggerLabel, 'CAP aged');

      // Verify Escalation 3: Verify-pending CAP routed to GM
      final verifyEsc = summary.escalationsRaised.firstWhere((e) => e.sourceCapId == 'cap-done-pending');
      expect(verifyEsc.raisedToUserId, 'user-gm');
      expect(verifyEsc.triggerLabel, 'CAP verify pending');

      // Re-run aging on same date: 0 new aged caps, verify-pending skipped due to active escalation
      final rerunSummary = await CapAgingService.instance.runDailyAging(asOf: asOfDate);
      expect(rerunSummary.agedCount, 0);
      expect(rerunSummary.escalationsRaised.length, 1); // Only verifyPending re-returned existing record from idempotency
      final totalEscalations = await fakeDb.query('escalations');
      expect(totalEscalations.length, 3); // No new rows created in DB!
    });

    test('8. Dual-Language Parity (Rule #8) for CAP Aging UI chrome', () {
      final enFile = File('assets/translations/app_en.arb');
      final mrFile = File('assets/translations/app_mr.arb');

      final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final mrJson = jsonDecode(mrFile.readAsStringSync()) as Map<String, dynamic>;

      final expectedKeys = [
        's14StatusAged',
        's14FilterAged',
        's16StatusAged',
        's27RunAgingTitle',
        's27RunAgingSubtitle',
        's27RunAgingSuccess',
      ];

      for (final key in expectedKeys) {
        expect(enJson.containsKey(key), isTrue, reason: 'app_en.arb missing $key');
        expect(mrJson.containsKey(key), isTrue, reason: 'app_mr.arb missing $key');
        expect(enJson[key].toString().trim(), isNotEmpty);
        expect(mrJson[key].toString().trim(), isNotEmpty);
      }
    });
  });
}
