import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/escalation_repository.dart';
import 'package:saagar_audit_app/domain/escalation_engine.dart';
import 'package:saagar_audit_app/services/escalation_service.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Sprint P3-2 — Escalation Repository & Integration Flow (Spec §7 & Appendix A.5)', () {
    late FakeDatabase fakeDb;
    final now = DateTime.now().toUtc().toIso8601String();

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed Users: Owner and GM
      await fakeDb.insert('users', {
        'id': 'user-owner',
        'name': 'Rajesh Saagar',
        'role': 'OWNER',
        'pin_hash': 'hash1',
        'language_pref': 'en',
        'phone': '919822012345',
        'is_active': 1,
        'created_at': now,
      });

      await fakeDb.insert('users', {
        'id': 'user-gm',
        'name': 'Amit Shinde',
        'role': 'GM',
        'pin_hash': 'hash2',
        'language_pref': 'en',
        'phone': '919822054321',
        'is_active': 1,
        'created_at': now,
      });

      await fakeDb.insert('users', {
        'id': 'user-sm',
        'name': 'Pooja Kadam',
        'role': 'SM',
        'pin_hash': 'hash3',
        'language_pref': 'mr',
        'phone': '919822099999',
        'is_active': 1,
        'created_at': now,
      });

      // Seed SOPs
      await fakeDb.insert('sops', {
        'id': 'SOP6',
        'number': 6,
        'name_en': 'Cash Management',
        'name_mr': 'रोख व्यवस्थापन',
        'weight': 2,
        'is_critical': 1,
        'display_order': 5,
      });

      await fakeDb.insert('sops', {
        'id': 'SOP7',
        'number': 7,
        'name_en': 'Inventory Management',
        'name_mr': 'साठा व्यवस्थापन',
        'weight': 2,
        'is_critical': 1,
        'display_order': 6,
      });

      // Seed Checkpoints
      await fakeDb.insert('checkpoints', {
        'id': '6.5',
        'sop_id': 'SOP6',
        'frequency': 'daily',
        'sequence': 5,
        'text_en': 'Physical cash count vs POS till',
        'text_mr': 'प्रत्यक्ष रोख मोजणी वि. POS गल्ला',
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 40,
      });

      await fakeDb.insert('checkpoints', {
        'id': '1.1',
        'sop_id': 'SOP1',
        'frequency': 'daily',
        'sequence': 1,
        'text_en': 'Store shutter opening on time',
        'text_mr': 'स्टोअरचे शटर वेळेवर उघडणे',
        'weight': 1,
        'allows_na': 0,
        'requires_photo_on_fail': 0,
        'display_order': 1,
      });
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    // =========================================================================
    // 1. EscalationRepository CRUD & Idempotency
    // =========================================================================
    test('1. EscalationRepository — raise, acknowledge, resolve, and idempotency', () async {
      final repo = EscalationRepository.instance;

      const draft = EscalationDraft(
        triggerNumber: 1,
        triggerLabel: 'Daily audit Critical band',
        sourceType: 'audit',
        sourceAuditId: 'audit-d1',
        targetRole: 'GM',
        urgency: 'same_night',
        deliveryChannel: 'whatsapp',
        whatHappened: 'Daily audit dropped to 76.5% Critical band.',
        evidence: 'Checkpoint 6.5 cash fail.',
        impact: 'Closing cash float unreconciled.',
        requestedAction: 'GM conduct emergency cash audit.',
      );

      // Raise escalation
      final created = await repo.raise(draft);
      expect(created.id, isNotEmpty);
      expect(created.status, 'open');
      expect(created.triggerNumber, 1);
      expect(created.raisedToUserId, 'user-gm'); // GM resolved
      expect(created.whatsappSent, isFalse);

      // Idempotency: repeated raise of same trigger & audit returns existing row
      final duplicate = await repo.raise(draft);
      expect(duplicate.id, equals(created.id));

      final allOpen = await repo.listOpen();
      expect(allOpen.length, 1);
      expect(await repo.countOpen(), 1);

      // Acknowledge
      await repo.acknowledge(created.id);
      final acknowledged = await repo.getById(created.id);
      expect(acknowledged?.status, 'acknowledged');
      expect(acknowledged?.acknowledgedAt, isNotNull);
      expect(await repo.countOpen(), 0);

      // Mark WhatsApp sent
      await repo.markWhatsAppSent(created.id);
      final waSent = await repo.getById(created.id);
      expect(waSent?.whatsappSent, isTrue);

      // Resolve requires notes
      expect(
        () => repo.resolve(created.id, resolutionNotes: '  '),
        throwsArgumentError,
      );

      await repo.resolve(
        created.id,
        resolutionNotes: 'Count reconciled by GM; ₹120 change discrepancy rectified.',
      );
      final resolved = await repo.getById(created.id);
      expect(resolved?.status, 'resolved');
      expect(resolved?.resolvedAt, isNotNull);
      expect(resolved?.resolutionNotes, contains('reconciled by GM'));
    });

    // =========================================================================
    // 2. EscalationService — Trigger 1 (Daily Critical + Cash Cause)
    // =========================================================================
    test('2. EscalationService — Trigger 1 raises for both GM and Owner on Cash cause', () async {
      // Insert submitted daily audit with Critical score and cash fail
      await fakeDb.insert('audits', {
        'id': 'audit-critical-1',
        'audit_type': 'daily',
        'audit_date': '2026-09-29',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': 'user-sm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 74.0,
        'band': 'critical',
        'pass_count': 45,
        'fail_count': 15,
        'na_count': 0,
        'submitted_at': now,
      });

      // Insert fail result on cash checkpoint 6.5
      await fakeDb.insert('audit_results', {
        'id': 'res-1',
        'audit_id': 'audit-critical-1',
        'checkpoint_id': '6.5',
        'result': 'F',
        'created_at': now,
      });

      final escalations = await EscalationService.instance.evaluateAndDispatch(
        auditId: 'audit-critical-1',
      );

      // Must raise 2 escalations: 1 to GM and 1 to Owner (both whatsapp delivery)
      expect(escalations.length, 2);
      expect(escalations.any((e) => e.raisedToUserId == 'user-gm' && e.triggerNumber == 1), isTrue);
      expect(escalations.any((e) => e.raisedToUserId == 'user-owner' && e.triggerNumber == 1), isTrue);
      expect(escalations.every((e) => e.urgency == 'same_night'), isTrue);
    });

    // =========================================================================
    // 3. EscalationService — Trigger 3 (Cash Variance > ₹500 & Consecutive)
    // =========================================================================
    test('3. EscalationService — Trigger 3 raises on cash variance > ₹500 and escalates to Owner if consecutive', () async {
      // Day 1 (yesterday): cash variance = -₹700
      await fakeDb.insert('audits', {
        'id': 'audit-cash-yest',
        'audit_type': 'daily',
        'audit_date': '2026-09-28',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': 'user-sm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 92.0,
        'band': 'good',
        'cash_variance_rupees': -700.0,
        'submitted_at': now,
      });

      // Day 2 (today): cash variance = +₹600
      await fakeDb.insert('audits', {
        'id': 'audit-cash-today',
        'audit_type': 'daily',
        'audit_date': '2026-09-29',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': 'user-sm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 91.0,
        'band': 'good',
        'cash_variance_rupees': 600.0,
        'submitted_at': now,
      });

      final escalations = await EscalationService.instance.evaluateAndDispatch(
        auditId: 'audit-cash-today',
      );

      // Expect 2 escalations for Trigger 3: GM (same_day) and Owner (immediate)
      expect(escalations.length, 2);
      final gmEsc = escalations.firstWhere((e) => e.raisedToUserId == 'user-gm');
      expect(gmEsc.triggerNumber, 3);
      expect(gmEsc.urgency, 'same_day');
      expect(gmEsc.whatHappened, contains('₹600 (excess)'));

      final ownerEsc = escalations.firstWhere((e) => e.raisedToUserId == 'user-owner');
      expect(ownerEsc.triggerNumber, 3);
      expect(ownerEsc.urgency, 'immediate');
      expect(ownerEsc.whatHappened, contains('Second consecutive day'));
    });

    // =========================================================================
    // 4. EscalationService — Trigger 2 (Repeated Checkpoint Fails in Daily Audits)
    // =========================================================================
    test('4. EscalationService — Trigger 2 raises on weekly audit when checkpoint failed in ≥5 daily audits', () async {
      // Create 7 daily audits
      for (var i = 1; i <= 7; i++) {
        final date = '2026-09-0$i';
        await fakeDb.insert('audits', {
          'id': 'audit-d-$i',
          'audit_type': 'daily',
          'audit_date': date,
          'week_number': 36,
          'year': 2026,
          'auditor_id': 'user-sm',
          'device_id': 'device-1',
          'status': 'submitted',
          'compliance_pct': 88.0,
          'band': 'fair',
          'submitted_at': now,
        });

        // Checkpoint 1.1 fails in 5 of the 7 days (days 1, 2, 3, 4, 5)
        await fakeDb.insert('audit_results', {
          'id': 'res-d-$i',
          'audit_id': 'audit-d-$i',
          'checkpoint_id': '1.1',
          'result': i <= 5 ? 'F' : 'P',
          'created_at': now,
        });
      }

      // Submit weekly audit
      await fakeDb.insert('audits', {
        'id': 'audit-w-1',
        'audit_type': 'weekly',
        'audit_date': '2026-09-07',
        'week_number': 36,
        'year': 2026,
        'auditor_id': 'user-gm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 90.0,
        'band': 'good',
        'submitted_at': now,
      });

      final escalations = await EscalationService.instance.evaluateAndDispatch(
        auditId: 'audit-w-1',
      );

      expect(escalations.any((e) => e.triggerNumber == 2), isTrue);
      final t2 = escalations.firstWhere((e) => e.triggerNumber == 2);
      expect(t2.raisedToUserId, 'user-gm');
      expect(t2.urgency, 'next_audit');
      expect(t2.whatHappened, contains('1.1'));
      expect(t2.whatHappened, contains('failed in 5 of the last 7 daily audits'));
    });

    // =========================================================================
    // 5. EscalationService — Trigger 7 (3 Consecutive Declining Weekly Audits)
    // =========================================================================
    test('5. EscalationService — Trigger 7 raises to Owner on 3 consecutive weeks of decline', () async {
      // Week 36: 93.0%
      await fakeDb.insert('audits', {
        'id': 'audit-w-w36',
        'audit_type': 'weekly',
        'audit_date': '2026-09-07',
        'week_number': 36,
        'year': 2026,
        'auditor_id': 'user-gm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 93.0,
        'band': 'good',
        'submitted_at': now,
      });

      // Week 37: 89.0%
      await fakeDb.insert('audits', {
        'id': 'audit-w-w37',
        'audit_type': 'weekly',
        'audit_date': '2026-09-14',
        'week_number': 37,
        'year': 2026,
        'auditor_id': 'user-gm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 89.0,
        'band': 'fair',
        'submitted_at': now,
      });

      // Week 38: 84.0% (Current submitted)
      await fakeDb.insert('audits', {
        'id': 'audit-w-w38',
        'audit_type': 'weekly',
        'audit_date': '2026-09-21',
        'week_number': 38,
        'year': 2026,
        'auditor_id': 'user-gm',
        'device_id': 'device-1',
        'status': 'submitted',
        'compliance_pct': 84.0,
        'band': 'poor',
        'submitted_at': now,
      });

      final escalations = await EscalationService.instance.evaluateAndDispatch(
        auditId: 'audit-w-w38',
      );

      expect(escalations.any((e) => e.triggerNumber == 7), isTrue);
      final t7 = escalations.firstWhere((e) => e.triggerNumber == 7);
      expect(t7.raisedToUserId, 'user-owner');
      expect(t7.urgency, 'same_day');
      expect(t7.whatHappened, contains('declined for 3 consecutive weeks'));
      expect(t7.whatHappened, contains('93.0% → 89.0% → 84.0%'));
    });

    // =========================================================================
    // 6. Dual-Language & English Message Body Invariant (Rule 8 & R-Escalation)
    // =========================================================================
    test('6. Dual-Language Parity & English Body Invariant', () {
      final enFile = File('assets/translations/app_en.arb');
      final mrFile = File('assets/translations/app_mr.arb');

      final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final mrJson = jsonDecode(mrFile.readAsStringSync()) as Map<String, dynamic>;

      final expectedKeys = [
        's10ClosingCashVarianceTitle',
        's10CashVarianceTitle',
        's10CashVarianceSubtitle',
        's10CashVarianceLabel',
        's10CashVarianceHelper',
        's33EscalationsTitle',
        's33EscalationsSubtitle',
        's33FilterAll',
        's33FilterOpen',
        's33FilterAcknowledged',
        's33FilterResolved',
        's33EmptyOpen',
        's33EmptyOpenDesc',
        's33TriggerLabel',
        's33AcknowledgeAction',
        's33ResolveAction',
        's33CopyAction',
        's33CopiedSuccess',
        's33WhatsAppAction',
        's33ResolutionNotesTitle',
        's33ResolutionNotesHint',
        's33ResolutionNotesRequired',
        's33AcknowledgeSuccess',
        's33ResolveSuccess',
        's33RaiseManualTitle',
        's33WhatHappenedLabel',
        's33EvidenceLabel',
        's33ImpactLabel',
        's33ActionLabel',
        's33SaveManualButton',
        's33UrgencyImmediate',
        's33UrgencySameDay',
        's33UrgencySameNight',
        's33UrgencyNextAudit',
        's33TargetOwner',
        's33TargetGm',
        's33WhatsAppSentBadge',
        'fieldRequired',
      ];

      for (final key in expectedKeys) {
        expect(enJson.containsKey(key), isTrue, reason: 'app_en.arb missing $key');
        expect(mrJson.containsKey(key), isTrue, reason: 'app_mr.arb missing $key');
        expect(enJson[key].toString().trim(), isNotEmpty);
        expect(mrJson[key].toString().trim(), isNotEmpty);
      }

      // Guard test: CW.7 cumulative variance and closing cash variance must remain distinct
      expect(
        enJson['s10CashVarianceTitle'],
        isNot(equals(enJson['s10ClosingCashVarianceTitle'])),
        reason: 's10CashVarianceTitle and s10ClosingCashVarianceTitle must be distinct in EN',
      );
      expect(
        mrJson['s10CashVarianceTitle'],
        isNot(equals(mrJson['s10ClosingCashVarianceTitle'])),
        reason: 's10CashVarianceTitle and s10ClosingCashVarianceTitle must be distinct in MR',
      );

      // Assert English-only body invariant for generated WhatsApp/Forward message
      const testDraft = EscalationDraft(
        triggerNumber: 3,
        triggerLabel: 'Single-day cash variance',
        sourceType: 'audit',
        targetRole: 'GM',
        urgency: 'same_day',
        deliveryChannel: 'whatsapp',
        whatHappened: 'Closing cash variance of ₹850 short observed during today count.',
        evidence: 'Checkpoint 6.5 fail, physical count sheet vs POS.',
        impact: 'Direct shortage in daily till exceeding tolerance.',
        requestedAction: 'GM investigate cashier log with SM.',
      );

      final msg = EscalationEngine.buildEscalationMessage(
        testDraft,
        auditDate: '2026-09-29',
        auditType: 'daily',
      );

      // Verify the 4 mandatory parts from Workbook Appendix A.5
      expect(msg.full, contains('1. What happened:'));
      expect(msg.full, contains('2. Evidence:'));
      expect(msg.full, contains('3. Impact:'));
      expect(msg.full, contains('4. Requested action:'));
      expect(msg.full, contains('Saagar Traders audit app — auto-generated'));
      expect(msg.summary, contains('[SAME_DAY] Trigger 3 — 2026-09-29'));
    });
  });
}
