import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/checkpoint.dart';
import 'package:saagar_audit_app/data/repositories/audit_repository.dart';
import 'package:saagar_audit_app/data/repositories/checkpoint_repository.dart';
import 'package:saagar_audit_app/domain/score_engine.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/draft_audit_provider.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Sprint P3-1 — Monthly Strategic Audit Foundation Suite', () {
    late FakeDatabase fakeDb;

    final mockMonthlyCheckpoints = const [
      Checkpoint(
        id: 'MC.1',
        sopId: 'SOP2',
        frequency: 'monthly',
        sequence: 1,
        textEn: 'Recount safe cash',
        textMr: 'सेफ रोख रकमेची पुन्हा मोजणी',
        weight: 2,
        allowsNa: false,
        requiresPhotoOnFail: true,
        displayOrder: 105,
      ),
      Checkpoint(
        id: 'MC.2',
        sopId: 'SOP7',
        frequency: 'monthly',
        sequence: 2,
        textEn: 'Recount one display tray',
        textMr: 'एका डिस्प्ले ट्रेची पुन्हा मोजणी',
        weight: 2,
        allowsNa: false,
        requiresPhotoOnFail: true,
        displayOrder: 106,
      ),
      Checkpoint(
        id: 'MC.3',
        sopId: 'SOP4',
        frequency: 'monthly',
        sequence: 3,
        textEn: 'Audit 15 customer-DB entries',
        textMr: 'ग्राहक डेटाबेसमधील १५ नोंदींची पडताळणी',
        weight: 1,
        allowsNa: false,
        requiresPhotoOnFail: false,
        displayOrder: 107,
      ),
    ];

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      for (final cp in mockMonthlyCheckpoints) {
        await fakeDb.insert('checkpoints', {
          'id': cp.id,
          'sop_id': cp.sopId,
          'frequency': cp.frequency,
          'sequence': cp.sequence,
          'text_en': cp.textEn,
          'text_mr': cp.textMr,
          'weight': cp.weight,
          'allows_na': cp.allowsNa ? 1 : 0,
          'requires_photo_on_fail': cp.requiresPhotoOnFail ? 1 : 0,
          'display_order': cp.displayOrder,
        });
      }

      final sops = [
        {'id': 'SOP2', 'number': 2, 'name_en': 'Cash Counter Operations', 'name_mr': 'कॅश काउंटर कामकाज', 'weight': 2, 'is_critical': 1, 'display_order': 2},
        {'id': 'SOP4', 'number': 4, 'name_en': 'Customer Handling & Billing', 'name_mr': 'ग्राहक व्यवस्थापन व बिलिंग', 'weight': 1, 'is_critical': 0, 'display_order': 4},
        {'id': 'SOP7', 'number': 7, 'name_en': 'Inventory Management', 'name_mr': 'स्टॉक व्यवस्थापन', 'weight': 2, 'is_critical': 1, 'display_order': 6},
      ];
      for (final s in sops) {
        await fakeDb.insert('sops', s);
      }
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('1. Seed Integrity — Monthly checkpoints in checkpoints.json match Workbook Tier 3 spec', () {
      final cpFile = File('assets/seed/checkpoints.json');
      final rawCp = jsonDecode(cpFile.readAsStringSync()) as List<dynamic>;
      final monthly = rawCp
          .whereType<Map<String, dynamic>>()
          .where((m) => m['frequency'] == 'monthly')
          .toList();

      expect(monthly.length, equals(3));

      final mc1 = monthly.firstWhere((m) => m['id'] == 'MC.1');
      expect(mc1['sop_id'], equals('SOP2'));
      expect(mc1['weight'], equals(2));
      expect(mc1['requires_photo_on_fail'], equals(1));
      expect(mc1['text_en'], equals('Recount safe cash'));
      expect(mc1['text_mr'], equals('सेफ रोख रकमेची पुन्हा मोजणी'));

      final mc2 = monthly.firstWhere((m) => m['id'] == 'MC.2');
      expect(mc2['sop_id'], equals('SOP7'));
      expect(mc2['weight'], equals(2));
      expect(mc2['requires_photo_on_fail'], equals(1));
      expect(mc2['text_en'], equals('Recount one display tray'));
      expect(mc2['text_mr'], equals('एका डिस्प्ले ट्रेची पुन्हा मोजणी'));

      final mc3 = monthly.firstWhere((m) => m['id'] == 'MC.3');
      expect(mc3['sop_id'], equals('SOP4'));
      expect(mc3['weight'], equals(1));
      expect(mc3['requires_photo_on_fail'], equals(0));
      expect(mc3['text_en'], equals('Audit 15 customer-DB entries'));
      expect(mc3['text_mr'], equals('ग्राहक डेटाबेसमधील १५ नोंदींची पडताळणी'));

      // Total weight is 5 (Cash 2 + Tray 2 + DB 1)
      final totalWeight = monthly.fold<int>(0, (sum, m) => sum + (m['weight'] as int));
      expect(totalWeight, equals(5));
    });

    test('2. Scoring Logic — 95%+ target, single fail triggers band drop', () {
      // All PASS: 5/5 = 100% -> Band.excellent (Meets Tier 3 target: 95%+)
      final allPassMarks = [
        const CheckpointMark(checkpointId: 'MC.1', result: Verdict.pass, weight: 2),
        const CheckpointMark(checkpointId: 'MC.2', result: Verdict.pass, weight: 2),
        const CheckpointMark(checkpointId: 'MC.3', result: Verdict.pass, weight: 1),
      ];
      final resAllPass = scoreDaily(allPassMarks);
      expect(resAllPass.rawScore, equals(5.0));
      expect(resAllPass.maxScore, equals(5.0));
      expect(resAllPass.compliancePct, equals(100.0));
      expect(resAllPass.band, equals(Band.excellent));

      // Customer DB FAIL (wt 1): 4/5 = 80.0% -> Band.poor (< 85%, fails 95%+ target)
      final dbFailMarks = [
        const CheckpointMark(checkpointId: 'MC.1', result: Verdict.pass, weight: 2),
        const CheckpointMark(checkpointId: 'MC.2', result: Verdict.pass, weight: 2),
        const CheckpointMark(checkpointId: 'MC.3', result: Verdict.fail, weight: 1),
      ];
      final resDbFail = scoreDaily(dbFailMarks);
      expect(resDbFail.rawScore, equals(4.0));
      expect(resDbFail.maxScore, equals(5.0));
      expect(resDbFail.compliancePct, equals(80.0));
      expect(resDbFail.band, equals(Band.poor));

      // Safe Cash FAIL (wt 2): 3/5 = 60.0% -> Band.critical (< 80%)
      final cashFailMarks = [
        const CheckpointMark(checkpointId: 'MC.1', result: Verdict.fail, weight: 2),
        const CheckpointMark(checkpointId: 'MC.2', result: Verdict.pass, weight: 2),
        const CheckpointMark(checkpointId: 'MC.3', result: Verdict.pass, weight: 1),
      ];
      final resCashFail = scoreDaily(cashFailMarks);
      expect(resCashFail.rawScore, equals(3.0));
      expect(resCashFail.maxScore, equals(5.0));
      expect(resCashFail.compliancePct, equals(60.0));
      expect(resCashFail.band, equals(Band.critical));
    });

    test('3. Conduct Flow & Photo Enforcement — startMonthly, mandatory photo on MC.1/MC.2 fail', () async {
      final notifier = DraftAuditNotifier();
      await notifier.startMonthly(
        date: '2026-09-01',
        auditorId: 'owner-user-1',
        cros: const [],
      );

      expect(notifier.state.audit, isNotNull);
      expect(notifier.state.audit!.auditType, equals('monthly'));
      expect(notifier.state.audit!.monthNumber, equals(9));
      expect(notifier.state.audit!.year, equals(2026));
      expect(notifier.state.checkpoints.length, equals(3));

      // 1. Current checkpoint is MC.1 (Safe Cash, wt 2, requires photo on fail)
      expect(notifier.state.currentCheckpoint!.id, equals('MC.1'));
      expect(notifier.state.currentCheckpoint!.requiresPhotoOnFail, isTrue);

      // Recording fail without photo throws ArgumentError
      expect(
        () => notifier.recordFailAndAdvance(
          findingText: 'Safe cash discrepancy ₹5,000 short against safe ledger',
          photoPaths: [],
        ),
        throwsArgumentError,
      );

      // Recording fail with photo succeeds and advances to MC.2
      await notifier.recordFailAndAdvance(
        findingText: 'Safe cash discrepancy ₹5,000 short against safe ledger',
        photoPaths: ['/local/photos/safe_cash_recount.jpg'],
      );
      expect(notifier.state.currentCheckpoint!.id, equals('MC.2'));

      // 2. MC.2 (Display tray recount, wt 2, requires photo on fail)
      expect(notifier.state.currentCheckpoint!.requiresPhotoOnFail, isTrue);
      await notifier.mark(Verdict.pass);
      expect(notifier.state.currentCheckpoint!.id, equals('MC.3'));

      // 3. MC.3 (Customer DB audit, wt 1, requires_photo_on_fail = 0)
      expect(notifier.state.currentCheckpoint!.requiresPhotoOnFail, isFalse);
      await notifier.recordFailAndAdvance(
        findingText: '2 out of 15 customer phone numbers were invalid dummy entries',
        photoPaths: [],
      );

      // All 3 checkpoints marked
      expect(notifier.state.isComplete, isTrue);
      expect(notifier.state.failCount, equals(2));
      expect(notifier.state.passCount, equals(1));

      // Submit audit
      await notifier.submitAudit(notes: 'Monthly strategic audit completed by Owner.');

      // Verify DB record
      final submitted = await AuditRepository.instance.getById(notifier.state.audit!.id);
      expect(submitted, isNotNull);
      expect(submitted!.status, equals('submitted'));
      expect(submitted.rawScore, equals(2.0));
      expect(submitted.maxScore, equals(5.0));
      expect(submitted.compliancePct, equals(40.0));
      expect(submitted.band, equals('critical'));

      // Rule #6: modifying submitted audit throws StateError
      expect(
        () => AuditRepository.instance.saveResult(
          auditId: submitted.id,
          checkpointId: 'MC.1',
          result: 'P',
          weight: 2,
        ),
        throwsStateError,
      );
    });

    test('4. Role Gating — Owner only can start monthly audit, SM and GM are restricted', () {
      const owner = AuthUser(id: '1', name: 'Owner User', role: 'OWNER', languagePref: 'en');
      const gm = AuthUser(id: '2', name: 'GM User', role: 'GM', languagePref: 'en');
      const sm = AuthUser(id: '3', name: 'SM User', role: 'SM', languagePref: 'en');

      bool canStartMonthly(AuthUser u) => u.role == 'OWNER';
      bool canStartWeekly(AuthUser u) => u.role == 'GM' || u.role == 'OWNER';
      bool canStartDaily(AuthUser u) => u.role == 'SM' || u.role == 'OWNER';

      expect(canStartMonthly(owner), isTrue);
      expect(canStartMonthly(gm), isFalse);
      expect(canStartMonthly(sm), isFalse);

      expect(canStartWeekly(owner), isTrue);
      expect(canStartWeekly(gm), isTrue);
      expect(canStartWeekly(sm), isFalse);

      expect(canStartDaily(owner), isTrue);
      expect(canStartDaily(sm), isTrue);
    });

    test('5. S12 History & S13 Detail — Monthly filter and checkpoint loading', () async {
      const viewer = AuthUser(id: 'owner-1', name: 'Owner', role: 'OWNER', languagePref: 'en');

      const monthlyAudit = Audit(
        id: 'audit-monthly-1',
        auditType: 'monthly',
        auditDate: '2026-09-01',
        weekNumber: 36,
        monthNumber: 9,
        year: 2026,
        auditorId: 'owner-1',
        deviceId: 'device-1',
        status: 'submitted',
        compliancePct: 100.0,
        band: 'excellent',
        submittedAt: '2026-09-01T10:00:00Z',
      );
      const weeklyAudit = Audit(
        id: 'audit-weekly-1',
        auditType: 'weekly',
        auditDate: '2026-09-07',
        weekNumber: 37,
        monthNumber: 9,
        year: 2026,
        auditorId: 'gm-1',
        deviceId: 'device-1',
        status: 'submitted',
        compliancePct: 88.0,
        band: 'fair',
        submittedAt: '2026-09-07T18:00:00Z',
      );
      await fakeDb.insert('audits', monthlyAudit.toMap());
      await fakeDb.insert('audits', weeklyAudit.toMap());

      // Filter: monthly returns only the monthly audit
      final monthlyAudits = await AuditRepository.instance.listAudits(
        viewer: viewer,
        filter: AuditHistoryFilter.monthly,
      );
      expect(monthlyAudits.length, equals(1));
      expect(monthlyAudits.first.id, equals('audit-monthly-1'));
      expect(monthlyAudits.first.auditType, equals('monthly'));

      // S13 Detail: loadCheckpointsByFrequency('monthly') loads all 3 monthly checkpoints
      final s13Checkpoints = await CheckpointRepository.instance.loadCheckpointsByFrequency('monthly');
      expect(s13Checkpoints.length, equals(3));
      expect(s13Checkpoints.map((c) => c.id).toList(), equals(['MC.1', 'MC.2', 'MC.3']));
    });

    test('6. Dual-Language Parity (Rule #8) — authentic Marathi strings exist for monthly flow', () {
      final enFile = File('assets/translations/app_en.arb');
      final mrFile = File('assets/translations/app_mr.arb');

      final en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final mr = jsonDecode(mrFile.readAsStringSync()) as Map<String, dynamic>;

      const requiredKeys = [
        's05ThisMonthMonthlyAudit',
        's05MonthlyNotStartedYet',
        's05StartMonthlyAudit',
        's05ResumeMonthlyDraft',
        's05MonthlyDraftInProgress',
        's05MonthlyAuditsRunByOwner',
        's05MonthYearLabel',
        's05MonthlySubtitle',
        's06MonthlyTitle',
        's06SubmittedAuditExistsMonthly',
        's06DraftAuditExistsMonthly',
        's10MonthlyScoreTitle',
        's11MonthlyTitle',
        's12FilterMonthly',
      ];

      for (final key in requiredKeys) {
        expect(en.containsKey(key), isTrue, reason: 'EN missing key $key');
        expect(mr.containsKey(key), isTrue, reason: 'MR missing key $key');
        expect(en[key], isNotNull, reason: 'EN value null for $key');
        expect(mr[key], isNotNull, reason: 'MR value null for $key');
        expect(en[key].toString().isNotEmpty, isTrue, reason: 'EN empty for $key');
        expect(mr[key].toString().isNotEmpty, isTrue, reason: 'MR empty for $key');
      }

      // Check authentic Marathi translations
      expect(mr['s05ThisMonthMonthlyAudit'], equals('या महिन्याचे धोरणात्मक ऑडिट'));
      expect(mr['s05StartMonthlyAudit'], equals('मासिक ऑडिट सुरू करा'));
      expect(mr['s06MonthlyTitle'], equals('मासिक धोरणात्मक ऑडिट सुरू करा'));
      expect(mr['s11MonthlyTitle'], equals('मासिक ऑडिट सादर झाले'));
      expect(mr['s12FilterMonthly'], equals('मासिक'));
    });
  });
}
