import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/db/schema.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/audit_result.dart';
import 'package:saagar_audit_app/data/models/checkpoint.dart';
import 'package:saagar_audit_app/data/repositories/audit_repository.dart';
import 'package:saagar_audit_app/data/repositories/escalation_repository.dart';
import 'package:saagar_audit_app/domain/escalation_engine.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Sprint P3-2b — Triggers T4 & T5 Escalation Suite', () {
    final now = DateTime.now().toUtc().toIso8601String();

    Audit makeAudit({
      String id = 'audit-1',
      String auditType = 'weekly',
      String auditDate = '2026-09-29',
      double compliancePct = 88.0,
      String band = 'fair',
      double? inventoryVariancePct,
      double? cashVarianceRupees,
    }) {
      return Audit(
        id: id,
        auditType: auditType,
        auditDate: auditDate,
        weekNumber: 39,
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
        cashVarianceRupees: cashVarianceRupees,
        inventoryVariancePct: inventoryVariancePct,
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
        frequency: 'weekly',
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
      bool flagSecurityConcern = false,
      String? findingText,
    }) {
      return AuditResult(
        id: '$auditId-$checkpointId',
        auditId: auditId,
        checkpointId: checkpointId,
        result: result,
        flagSecurityConcern: flagSecurityConcern,
        findingText: findingText,
        createdAt: now,
      );
    }

    // =========================================================================
    // 1. Schema & Migration v2 -> v3
    // =========================================================================
    group('1. Database Schema & Migration v2 -> v3', () {
      test('Schema.currentVersion is 3', () {
        expect(Schema.currentVersion, 3);
      });

      test('createStatements contains inventory_variance_pct column in audits table', () {
        expect(
          Schema.createStatements.any((s) => s.contains('inventory_variance_pct REAL')),
          isTrue,
        );
      });

      test('createStatements contains flag_security_concern column with CHECK constraint in audit_results', () {
        expect(
          Schema.createStatements.any((s) => s.contains('flag_security_concern INTEGER NOT NULL DEFAULT 0 CHECK (flag_security_concern IN (0,1))')),
          isTrue,
        );
      });

      test('Audit model serialization round-trip preserves inventoryVariancePct', () {
        final audit = makeAudit(inventoryVariancePct: 2.35);
        final map = audit.toMap();
        expect(map['inventory_variance_pct'], 2.35);

        final restored = Audit.fromMap(map);
        expect(restored.inventoryVariancePct, 2.35);

        final nullAudit = makeAudit(inventoryVariancePct: null);
        final nullMap = nullAudit.toMap();
        expect(nullMap['inventory_variance_pct'], isNull);
        final nullRestored = Audit.fromMap(nullMap);
        expect(nullRestored.inventoryVariancePct, isNull);
      });

      test('AuditResult model serialization round-trip preserves flagSecurityConcern', () {
        final resTrue = makeResult(
          auditId: 'a1',
          checkpointId: 'IW.1',
          result: 'F',
          flagSecurityConcern: true,
        );
        final mapTrue = resTrue.toMap();
        expect(mapTrue['flag_security_concern'], 1);
        final restoredTrue = AuditResult.fromMap(mapTrue);
        expect(restoredTrue.flagSecurityConcern, isTrue);

        final resFalse = makeResult(
          auditId: 'a1',
          checkpointId: 'IW.1',
          result: 'P',
          flagSecurityConcern: false,
        );
        final mapFalse = resFalse.toMap();
        expect(mapFalse['flag_security_concern'], 0);
        final restoredFalse = AuditResult.fromMap(mapFalse);
        expect(restoredFalse.flagSecurityConcern, isFalse);
      });
    });

    // =========================================================================
    // 2. Trigger T4 Truth Table: Inventory Variance > 2% (Weekly only)
    // =========================================================================
    group('2. Trigger T4: Inventory Variance > 2% (Weekly only)', () {
      final defaultCps = [
        makeCp(id: 'IW.1', sopId: 'SOP7', titleEn: 'Full storage area count'),
      ];
      final defaultResults = [
        makeResult(auditId: 'a1', checkpointId: 'IW.1', result: 'P'),
      ];

      test('Fires when weekly audit has inventoryVariancePct = 2.1% (> 2.0%)', () {
        final audit = makeAudit(
          auditType: 'weekly',
          inventoryVariancePct: 2.1,
        );
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: defaultResults,
          checkpoints: defaultCps,
        );

        final t4Drafts = drafts.where((d) => d.triggerNumber == 4).toList();
        expect(t4Drafts.length, 1);

        final t4 = t4Drafts.first;
        expect(t4.triggerLabel, 'Inventory variance > 2%');
        expect(t4.targetRole, 'OWNER');
        expect(t4.urgency, 'same_day');
        expect(t4.deliveryChannel, 'whatsapp');
        expect(t4.whatHappened, contains('Weekly physical inventory count variance exceeded 2.0% threshold (measured: 2.1%)'));

        final message = EscalationEngine.buildEscalationMessage(
          t4,
          auditDate: audit.auditDate,
          auditType: audit.auditType,
        );
        expect(message.full, contains('ESCALATION — Inventory variance > 2%'));
        expect(message.full, contains('1. What happened: Weekly physical inventory count variance exceeded 2.0% threshold (measured: 2.1%)'));
        expect(message.full, contains('2. Evidence: Weekly stock audit sheet for 2026-09-29 records inventory variance of 2.1% of total stock value.'));
        expect(message.full, contains('3. Impact: Significant stock discrepancy indicates potential shrinkage, unrecorded stock movements, or inventory miscounting.'));
        expect(message.full, contains('4. Requested action: Owner action needed: Review weekly count variance report and initiate stock reconciliation with Store Manager.'));
      });

      test('Does NOT fire when inventoryVariancePct = 2.0% (strict > boundary)', () {
        final audit = makeAudit(
          auditType: 'weekly',
          inventoryVariancePct: 2.0,
        );
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: defaultResults,
          checkpoints: defaultCps,
        );
        expect(drafts.any((d) => d.triggerNumber == 4), isFalse);
      });

      test('Does NOT fire when inventoryVariancePct = 1.99% (< 2.0%)', () {
        final audit = makeAudit(
          auditType: 'weekly',
          inventoryVariancePct: 1.99,
        );
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: defaultResults,
          checkpoints: defaultCps,
        );
        expect(drafts.any((d) => d.triggerNumber == 4), isFalse);
      });

      test('Does NOT fire when inventoryVariancePct is null', () {
        final audit = makeAudit(
          auditType: 'weekly',
          inventoryVariancePct: null,
        );
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: defaultResults,
          checkpoints: defaultCps,
        );
        expect(drafts.any((d) => d.triggerNumber == 4), isFalse);
      });

      test('Does NOT fire when auditType is daily even if variance > 2%', () {
        final audit = makeAudit(
          auditType: 'daily',
          inventoryVariancePct: 3.5,
        );
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: defaultResults,
          checkpoints: defaultCps,
        );
        expect(drafts.any((d) => d.triggerNumber == 4), isFalse);
      });

      test('Does NOT fire when auditType is monthly even if variance > 2%', () {
        final audit = makeAudit(
          auditType: 'monthly',
          inventoryVariancePct: 4.0,
        );
        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: defaultResults,
          checkpoints: defaultCps,
        );
        expect(drafts.any((d) => d.triggerNumber == 4), isFalse);
      });
    });

    // =========================================================================
    // 3. Trigger T5 Truth Table: Security Concern Flag
    // =========================================================================
    group('3. Trigger T5: Security Concern Flag', () {
      final cps = [
        makeCp(id: '6.1', sopId: 'SOP6', titleEn: 'Cash drawer lock'),
        makeCp(id: '7.2', sopId: 'SOP7', titleEn: 'Stock room CCTV angle'),
        makeCp(id: '1.1', sopId: 'SOP1', titleEn: 'Store opening on time'),
      ];

      test('Fires immediate WhatsApp alert to Owner for result with flagSecurityConcern: true', () {
        final audit = makeAudit(auditType: 'daily');
        final results = [
          makeResult(
            auditId: audit.id,
            checkpointId: '6.1',
            result: 'F',
            flagSecurityConcern: true,
            findingText: 'Cash drawer lock tampered with',
          ),
          makeResult(
            auditId: audit.id,
            checkpointId: '1.1',
            result: 'P',
            flagSecurityConcern: false,
          ),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        final t5Drafts = drafts.where((d) => d.triggerNumber == 5).toList();
        expect(t5Drafts.length, 1);

        final t5 = t5Drafts.first;
        expect(t5.triggerLabel, 'Security concern');
        expect(t5.targetRole, 'OWNER');
        expect(t5.urgency, 'immediate');
        expect(t5.deliveryChannel, 'whatsapp');
        expect(t5.whatHappened, contains('Security concern flagged on Checkpoint 6.1'));

        final message = EscalationEngine.buildEscalationMessage(
          t5,
          auditDate: audit.auditDate,
          auditType: audit.auditType,
        );
        expect(message.full, contains('ESCALATION — Security concern'));
        expect(message.full, contains('1. What happened: Security concern flagged on Checkpoint 6.1 during daily audit on 2026-09-29. Finding: "Cash drawer lock tampered with".'));
        expect(message.full, contains('2. Evidence: Auditor noted security risk on Checkpoint 6.1 (Cash drawer lock) with status F.'));
        expect(message.full, contains('3. Impact: Potential security vulnerability or breach threatening store safety, asset integrity, or staff security.'));
        expect(message.full, contains('4. Requested action: Immediate action required: Owner review security finding and inspect counter CCTV / premises immediately.'));
      });

      test('Fires distinct T5 drafts for each checkpoint flagged on the same audit', () {
        final audit = makeAudit(auditType: 'daily');
        final results = [
          makeResult(
            auditId: audit.id,
            checkpointId: '6.1',
            result: 'F',
            flagSecurityConcern: true,
            findingText: 'Broken cash drawer latch',
          ),
          makeResult(
            auditId: audit.id,
            checkpointId: '7.2',
            result: 'F',
            flagSecurityConcern: true,
            findingText: 'CCTV wire cut behind storage shelf',
          ),
          makeResult(
            auditId: audit.id,
            checkpointId: '1.1',
            result: 'P',
            flagSecurityConcern: false,
          ),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        final t5Drafts = drafts.where((d) => d.triggerNumber == 5).toList();
        expect(t5Drafts.length, 2);

        final cpIds = t5Drafts.map((d) => d.whatHappened).toList();
        expect(cpIds.any((s) => s.contains('Checkpoint 6.1')), isTrue);
        expect(cpIds.any((s) => s.contains('Checkpoint 7.2')), isTrue);
      });

      test('Does NOT fire T5 when flagSecurityConcern is false for all checkpoints', () {
        final audit = makeAudit(auditType: 'daily');
        final results = [
          makeResult(auditId: audit.id, checkpointId: '6.1', result: 'F', flagSecurityConcern: false),
          makeResult(auditId: audit.id, checkpointId: '1.1', result: 'P', flagSecurityConcern: false),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        expect(drafts.any((d) => d.triggerNumber == 5), isFalse);
      });

      test('T5 fires on PASS or NA if security concern was explicitly flagged', () {
        final audit = makeAudit(auditType: 'weekly');
        final results = [
          makeResult(
            auditId: audit.id,
            checkpointId: '6.1',
            result: 'P',
            flagSecurityConcern: true,
            findingText: 'Safe passed code test but suspicious scratches noticed on handle',
          ),
        ];

        final drafts = EscalationEngine.evaluateAfterAudit(
          audit: audit,
          results: results,
          checkpoints: cps,
        );

        final t5Drafts = drafts.where((d) => d.triggerNumber == 5).toList();
        expect(t5Drafts.length, 1);
        expect(t5Drafts.first.whatHappened, contains('Checkpoint 6.1'));
      });
    });

    // =========================================================================
    // 4. EscalationRepository Idempotency for T4 and T5
    // =========================================================================
    group('4. EscalationRepository Idempotency for T4 & T5', () {
      late FakeDatabase fakeDb;

      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        fakeDb = FakeDatabase();
        AppDatabase.instance.setDatabaseForTesting(fakeDb);

        // Seed active Owner
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

        // Seed active GM
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
      });

      test('T4: double-raise is deduplicated', () async {
        const draft = EscalationDraft(
          triggerNumber: 4,
          triggerLabel: 'Inventory variance > 2%',
          sourceType: 'audit',
          targetRole: 'OWNER',
          urgency: 'same_day',
          deliveryChannel: 'whatsapp',
          whatHappened: 'Weekly storage count inventory variance: 2.50%',
          evidence: 'Storage count record',
          impact: 'Stock shrinkage',
          requestedAction: 'Conduct physical recount',
          sourceAuditId: 'audit-weekly-t4',
        );

        final first = await EscalationRepository.instance.raise(draft);
        final second = await EscalationRepository.instance.raise(draft);

        expect(first.id, second.id);
        final rows = await fakeDb.query('escalations');
        expect(rows.length, 1);
      });

      test('T5: two distinct checkpoints on same audit raise two distinct escalations', () async {
        const draft1 = EscalationDraft(
          triggerNumber: 5,
          triggerLabel: 'Security concern flag',
          sourceType: 'audit',
          targetRole: 'OWNER',
          urgency: 'immediate',
          deliveryChannel: 'whatsapp',
          whatHappened: 'Security concern flagged at checkpoint 6.1 (Cash lock)',
          evidence: 'Tampered latch',
          impact: 'Immediate theft risk',
          requestedAction: 'Inspect cash drawer immediately',
          sourceAuditId: 'audit-t5-multi',
        );

        const draft2 = EscalationDraft(
          triggerNumber: 5,
          triggerLabel: 'Security concern flag',
          sourceType: 'audit',
          targetRole: 'OWNER',
          urgency: 'immediate',
          deliveryChannel: 'whatsapp',
          whatHappened: 'Security concern flagged at checkpoint 7.2 (Stock CCTV)',
          evidence: 'Cut cable',
          impact: 'Blind spot in storage',
          requestedAction: 'Inspect camera and recount stock',
          sourceAuditId: 'audit-t5-multi',
        );

        final esc1 = await EscalationRepository.instance.raise(draft1);
        final esc2 = await EscalationRepository.instance.raise(draft2);

        expect(esc1.id, isNot(equals(esc2.id)));
        final rows = await fakeDb.query('escalations');
        expect(rows.length, 2);

        // Re-raising draft1 should be deduplicated
        final esc1Re = await EscalationRepository.instance.raise(draft1);
        expect(esc1Re.id, esc1.id);
        final rowsAfter = await fakeDb.query('escalations');
        expect(rowsAfter.length, 2);
      });
    });

    // =========================================================================
    // 5. Bilingual ARB Parity Check
    // =========================================================================
    group('5. ARB Localization Parity for Sprint P3-2b Keys', () {
      test('All 6 new keys exist and are non-empty in app_en.arb and app_mr.arb', () {
        final enFile = File('assets/translations/app_en.arb');
        final mrFile = File('assets/translations/app_mr.arb');

        expect(enFile.existsSync(), isTrue);
        expect(mrFile.existsSync(), isTrue);

        final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
        final mrJson = jsonDecode(mrFile.readAsStringSync()) as Map<String, dynamic>;

        const expectedKeys = [
          's10InventoryVarianceTitle',
          's10InventoryVarianceSubtitle',
          's10InventoryVarianceLabel',
          's10InventoryVarianceHelper',
          's07SecurityConcernLabel',
          's07SecurityConcernSubtitle',
        ];

        for (final key in expectedKeys) {
          expect(enJson.containsKey(key), isTrue, reason: 'app_en.arb missing $key');
          expect(mrJson.containsKey(key), isTrue, reason: 'app_mr.arb missing $key');

          expect(
            (enJson[key] as String).trim().isNotEmpty,
            isTrue,
            reason: 'app_en.arb key $key is empty',
          );
          expect(
            (mrJson[key] as String).trim().isNotEmpty,
            isTrue,
            reason: 'app_mr.arb key $key is empty',
          );
        }
      });
    });

    // =========================================================================
    // 6. AuditRepository Data Layer Persistence
    // =========================================================================
    group('6. AuditRepository Data Layer Persistence', () {
      late FakeDatabase fakeDb;

      setUp(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        fakeDb = FakeDatabase();
        AppDatabase.instance.setDatabaseForTesting(fakeDb);
      });

      test('saveResult writes flag_security_concern to database', () async {
        final res = await AuditRepository.instance.saveResult(
          auditId: 'audit-test-1',
          checkpointId: 'IW.1',
          result: 'F',
          weight: 1,
          findingText: 'Security hazard observed',
          flagSecurityConcern: true,
        );

        expect(res.flagSecurityConcern, isTrue);

        final found = await AuditRepository.instance.findResult(
          auditId: 'audit-test-1',
          checkpointId: 'IW.1',
        );
        expect(found, isNotNull);
        expect(found!.flagSecurityConcern, isTrue);
      });

      test('submitAudit persists inventory_variance_pct to audits table', () async {
        // Create draft audit in fakeDb
        await fakeDb.insert('audits', {
          'id': 'audit-weekly-sub',
          'audit_type': 'weekly',
          'audit_date': '2026-09-29',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-gm-1',
          'device_id': 'dev-1',
          'status': 'draft',
          'draft_started_at': now,
        });

        await AuditRepository.instance.submitAudit(
          auditId: 'audit-weekly-sub',
          rawScore: 85.0,
          maxScore: 100.0,
          compliancePct: 85.0,
          band: 'fair',
          passCount: 30,
          failCount: 6,
          naCount: 0,
          inventoryVariancePct: 2.75,
        );

        final audit = await AuditRepository.instance.findById('audit-weekly-sub');
        expect(audit, isNotNull);
        expect(audit!.status, 'submitted');
        expect(audit.inventoryVariancePct, 2.75);
      });
    });
  });
}
