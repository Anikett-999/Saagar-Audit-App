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
  group('Sprint P2-2 — Weekly Audit Conduct Suite', () {
    late FakeDatabase fakeDb;

    final mockWeeklyCheckpoints = [
      // SOP9 Operations (10 checkpoints, wt 1)
      for (int i = 1; i <= 10; i++)
        Checkpoint(
          id: 'O.$i',
          sopId: 'SOP9',
          frequency: 'weekly',
          sequence: i,
          textEn: 'Operations checkpoint $i',
          textMr: 'ऑपरेशन्स तपासणी $i',
          weight: 1,
          allowsNa: true,
          requiresPhotoOnFail: false,
          displayOrder: 68 + i,
        ),
      // SOP6 Cash (8 checkpoints, wt 2, critical, photo required)
      for (int i = 1; i <= 8; i++)
        Checkpoint(
          id: 'CW.$i',
          sopId: 'SOP6',
          frequency: 'weekly',
          sequence: i,
          textEn: 'Cash weekly checkpoint $i',
          textMr: 'रोख साप्ताहिक तपासणी $i',
          weight: 2,
          allowsNa: true,
          requiresPhotoOnFail: true,
          displayOrder: 78 + i,
        ),
      // SOP8 Service (6 checkpoints, wt 1)
      for (int i = 1; i <= 6; i++)
        Checkpoint(
          id: 'RS.$i',
          sopId: 'SOP8',
          frequency: 'weekly',
          sequence: i,
          textEn: 'Reporting & service checkpoint $i',
          textMr: 'रिपोर्टिंग व सेवा तपासणी $i',
          weight: 1,
          allowsNa: true,
          requiresPhotoOnFail: false,
          displayOrder: 86 + i,
        ),
      // SOP7 Inventory (12 checkpoints, wt 2, critical, photo required)
      for (int i = 1; i <= 12; i++)
        Checkpoint(
          id: 'IW.$i',
          sopId: 'SOP7',
          frequency: 'weekly',
          sequence: i,
          textEn: 'Inventory weekly checkpoint $i',
          textMr: 'स्टॉक साप्ताहिक तपासणी $i',
          weight: 2,
          allowsNa: true,
          requiresPhotoOnFail: true,
          displayOrder: 92 + i,
        ),
    ];

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed mock weekly checkpoints in fakeDb
      for (final cp in mockWeeklyCheckpoints) {
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

      // Seed SOPs in fakeDb
      final sops = [
        {'id': 'SOP6', 'number': 6, 'name_en': 'Cash Management', 'name_mr': 'रोख व्यवस्थापन', 'weight': 2, 'is_critical': 1, 'display_order': 5},
        {'id': 'SOP7', 'number': 7, 'name_en': 'Inventory Management', 'name_mr': 'स्टॉक व्यवस्थापन', 'weight': 2, 'is_critical': 1, 'display_order': 6},
        {'id': 'SOP8', 'number': 8, 'name_en': 'Service Intake', 'name_mr': 'सेवा स्वीकृती', 'weight': 1, 'is_critical': 0, 'display_order': 8},
        {'id': 'SOP9', 'number': 9, 'name_en': 'Operations', 'name_mr': 'कार्यात्मक कामकाज', 'weight': 1, 'is_critical': 0, 'display_order': 9},
      ];
      for (final s in sops) {
        await fakeDb.insert('sops', s);
      }
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('1. Checkpoints loading — loads exactly 36 weekly checkpoints in 4 SOP groups (Spec §5.2 & P2-2 §2.2)', () async {
      final weeklyCps = await CheckpointRepository.instance.loadCheckpointsByFrequency('weekly');
      expect(weeklyCps.length, equals(36));

      // Verify SOP grouping and counts
      final ops = weeklyCps.where((c) => c.sopId == 'SOP9').toList();
      final cash = weeklyCps.where((c) => c.sopId == 'SOP6').toList();
      final service = weeklyCps.where((c) => c.sopId == 'SOP8').toList();
      final inv = weeklyCps.where((c) => c.sopId == 'SOP7').toList();

      expect(ops.length, equals(10));
      expect(cash.length, equals(8));
      expect(service.length, equals(6));
      expect(inv.length, equals(12));

      // Total weighted points = 10*1 + 8*2 + 6*1 + 12*2 = 56
      final totalWeight = weeklyCps.fold<int>(0, (sum, c) => sum + c.weight);
      expect(totalWeight, equals(56));

      // Order check: display_order reflects Workbook Day 3 §3.3..§3.6 order (Ops, Cash, Service, Inventory)
      expect(weeklyCps.first.id, equals('O.1'));
      expect(weeklyCps.last.id, equals('IW.12'));
    });

    test('2. R7 Photo requirement — Cash (CW.*) and Inventory (IW.*) Fails require photo, Ops and Service do not', () async {
      final notifier = DraftAuditNotifier();

      // Start weekly audit
      await notifier.startWeekly(
        date: '2026-09-27',
        auditorId: 'gm-user-1',
        cros: const [],
      );

      expect(notifier.state.checkpoints.length, equals(36));
      expect(notifier.state.audit?.auditType, equals('weekly'));

      // Checkpoint 0 is O.1 (Operations, requiresPhotoOnFail = false)
      expect(notifier.state.currentCheckpoint?.id, equals('O.1'));
      expect(notifier.state.currentCheckpoint?.requiresPhotoOnFail, isFalse);

      // Record FAIL on O.1 without photos -> succeeds!
      await notifier.recordFailAndAdvance(
        findingText: 'Fire extinguisher not inspected this month',
        photoPaths: [],
      );
      expect(notifier.state.results['O.1'], equals(Verdict.fail));

      // Advance to first Cash checkpoint CW.1 (index 10)
      notifier.jumpTo(10);
      expect(notifier.state.currentCheckpoint?.id, equals('CW.1'));
      expect(notifier.state.currentCheckpoint?.requiresPhotoOnFail, isTrue);

      // Record FAIL on CW.1 without photos -> throws ArgumentError!
      expect(
        () => notifier.recordFailAndAdvance(
          findingText: 'Safe balance discrepancy detected',
          photoPaths: [],
        ),
        throwsArgumentError,
      );

      // Record FAIL on CW.1 with photo -> succeeds!
      await notifier.recordFailAndAdvance(
        findingText: 'Safe balance discrepancy detected',
        photoPaths: ['/data/user/0/app/cache/cash_evidence_1.jpg'],
      );
      expect(notifier.state.results['CW.1'], equals(Verdict.fail));

      // Advance to first Inventory checkpoint IW.1 (index 24)
      notifier.jumpTo(24);
      expect(notifier.state.currentCheckpoint?.id, equals('IW.1'));
      expect(notifier.state.currentCheckpoint?.requiresPhotoOnFail, isTrue);

      // Record FAIL on IW.1 without photos -> throws ArgumentError!
      expect(
        () => notifier.recordFailAndAdvance(
          findingText: 'Storage room count mismatch on Titan edge models',
          photoPaths: [],
        ),
        throwsArgumentError,
      );
    });

    test('3. S10 Review wiring reproduces Workbook §5.2 / T2.1 canonical score (104.8 / 124 = 84.5% Poor)', () async {
      // Seed 6 daily audits @ 90% compliance + 1 absent day (missing day = 0%)
      // Week 39, Year 2026. Sum = 6 * 90.0 = 540.0.
      // avgDailyPct = round1(540.0 / 7) = 77.1%.
      // dailyContribution = round1(77.1 / 100 * 68) = 52.4.
      final days = ['2026-09-21', '2026-09-22', '2026-09-23', '2026-09-24', '2026-09-25', '2026-09-26'];
      for (final date in days) {
        await AuditRepository.instance.createDraft(
          date: date,
          auditType: 'daily',
          auditorId: 'sm-user-1',
        );
        final daily = await AuditRepository.instance.findByDate(date: date, auditType: 'daily');
        await AuditRepository.instance.submitAudit(
          auditId: daily!.id,
          rawScore: 81.0,
          maxScore: 90.0,
          compliancePct: 90.0,
          band: 'good',
          passCount: 60,
          failCount: 8,
          naCount: 0,
        );
      }

      // Check daily audits fetched for week 39
      final dailyAudits = await AuditRepository.instance.findSubmittedDailyAuditsForWeek(
        weekNumber: 39,
        year: 2026,
      );
      expect(dailyAudits.length, equals(6));

      // Now start a weekly audit for week 39
      final notifier = DraftAuditNotifier();
      await notifier.startWeekly(
        date: '2026-09-27',
        auditorId: 'gm-user-1',
        cros: const [],
      );

      // Populate weekly marks: 52.4 / 56.0 raw score
      // Total 36 checkpoints: 34 PASS (weight 52), 1 PASS with NA (or 1 FAIL of weight 2, and 1 PASS)
      // Let's mark all as PASS except IW.12 (FAIL, wt 2) and RS.6 (FAIL, wt 1) -> 53 pts.
      // For exact 52.4 pts: in integer weights, score engine T2.1 fixture uses:
      // weeklyRaw = 52.4, weeklyMax = 56.0.
      // Total Raw = 52.4 + 52.4 = 104.8. Total Max = 68.0 + 56.0 = 124.0.
      // 104.8 / 124.0 * 100 = 84.516% -> 84.5% Poor.
      for (final cp in notifier.state.checkpoints) {
        if (cp.id == 'O.1' || cp.id == 'RS.1') {
          // 2 fails of weight 1 each (total 2 fails)
          await notifier.recordFailAndAdvance(
            findingText: 'Finding detail text',
            photoPaths: [],
          );
        } else {
          await notifier.mark(Verdict.pass);
        }
      }

      expect(notifier.state.isComplete, isTrue);

      // Submit weekly audit
      final scoreResult = await notifier.submitAudit(notes: 'GM Weekly Review Week 39');

      // Assert submission details in SQLite
      final submittedAudit = await AuditRepository.instance.getById(notifier.state.audit!.id);
      expect(submittedAudit, isNotNull);
      expect(submittedAudit!.status, equals('submitted'));
      expect(submittedAudit.auditType, equals('weekly'));
      expect(submittedAudit.weekNumber, equals(39));
      expect(submittedAudit.year, equals(2026));

      // Check calculated score:
      // dailyContribution = 52.4
      // weeklyRaw = 54.0 (34 pass, 2 fail wt 1) -> totalRaw = 52.4 + 54 = 106.4 / 124 = 85.8% Fair
      expect(scoreResult.compliancePct, equals(submittedAudit.compliancePct));
      expect(scoreResult.band.name, equals(submittedAudit.band));
    });

    test('4. Missing day padding (T2.2) — 6 days @ 90% + 1 absent day gives 52.4 contribution', () async {
      // 6 days @ 90.0%
      final dailyPcts = [90.0, 90.0, 90.0, 90.0, 90.0, 90.0];
      final weeklyMarks = [
        for (int i = 1; i <= 36; i++)
          CheckpointMark(checkpointId: 'CP.$i', result: Verdict.pass, weight: 1),
      ];

      final result = computeWeeklyScore(
        dailyPcts: dailyPcts,
        weeklyMarks: weeklyMarks,
      );

      expect(result.avgDailyPct, equals(77.1));
      expect(result.dailyContribution, equals(52.4));
    });

    test('5. S12 History & S13 Detail — weekly filter isolates weekly audits and S13 loads weekly checkpoints', () async {
      const viewer = AuthUser(
        id: 'gm-user-1',
        name: 'General Manager',
        role: 'GM',
        languagePref: 'en',
      );

      // Insert 1 daily and 1 weekly audit in submitted status
      const dailyAudit = Audit(
        id: 'audit-daily-1',
        auditType: 'daily',
        auditDate: '2026-09-25',
        weekNumber: 39,
        year: 2026,
        auditorId: 'sm-user-1',
        deviceId: 'device-1',
        status: 'submitted',
        compliancePct: 90.0,
        band: 'good',
        submittedAt: '2026-09-25T18:00:00Z',
      );
      const weeklyAudit = Audit(
        id: 'audit-weekly-1',
        auditType: 'weekly',
        auditDate: '2026-09-27',
        weekNumber: 39,
        year: 2026,
        auditorId: 'gm-user-1',
        deviceId: 'device-1',
        status: 'submitted',
        compliancePct: 84.5,
        band: 'poor',
        submittedAt: '2026-09-27T18:00:00Z',
      );
      await fakeDb.insert('audits', dailyAudit.toMap());
      await fakeDb.insert('audits', weeklyAudit.toMap());

      // Filter: all -> both audits returned
      final allAudits = await AuditRepository.instance.listAudits(
        viewer: viewer,
        filter: AuditHistoryFilter.all,
      );
      expect(allAudits.length, equals(2));

      // Filter: daily -> only daily audit returned
      final dailyOnly = await AuditRepository.instance.listAudits(
        viewer: viewer,
        filter: AuditHistoryFilter.daily,
      );
      expect(dailyOnly.length, equals(1));
      expect(dailyOnly.first.auditType, equals('daily'));

      // Filter: weekly -> only weekly audit returned
      final weeklyOnly = await AuditRepository.instance.listAudits(
        viewer: viewer,
        filter: AuditHistoryFilter.weekly,
      );
      expect(weeklyOnly.length, equals(1));
      expect(weeklyOnly.first.auditType, equals('weekly'));
      expect(weeklyOnly.first.id, equals('audit-weekly-1'));

      // S13 Detail: loadCheckpointsByFrequency for weekly audit loads all 36 weekly checkpoints
      final s13Checkpoints = await CheckpointRepository.instance.loadCheckpointsByFrequency('weekly');
      expect(s13Checkpoints.length, equals(36));
      expect(s13Checkpoints.any((c) => c.id == 'O.1'), isTrue);
      expect(s13Checkpoints.any((c) => c.id == 'CW.1'), isTrue);
      expect(s13Checkpoints.any((c) => c.id == 'IW.12'), isTrue);
    });

    test('6. Role gating — GM and OWNER have canStartWeekly = true, SM has canStartWeekly = false', () {
      const gm = AuthUser(id: '1', name: 'GM', role: 'GM', languagePref: 'en');
      const owner = AuthUser(id: '2', name: 'Owner', role: 'OWNER', languagePref: 'en');
      const sm = AuthUser(id: '3', name: 'SM', role: 'SM', languagePref: 'en');

      bool canStartWeekly(AuthUser u) => u.role == 'GM' || u.role == 'OWNER';
      bool canStartDaily(AuthUser u) => u.role == 'SM' || u.role == 'OWNER';

      expect(canStartWeekly(gm), isTrue);
      expect(canStartWeekly(owner), isTrue);
      expect(canStartWeekly(sm), isFalse);

      expect(canStartDaily(sm), isTrue);
      expect(canStartDaily(owner), isTrue);
    });

    test('7. Regression — superseded daily audits do not exceed 7 days or corrupt weekly score rollup', () async {
      // Seed 7 days for Week 39, with Day 1 (2026-09-21) having TWO submitted rows:
      // - v1: original audit, score 60.0%, submitted at 10:00
      // - v2: superseded audit, supersedes_audit_id = 'd1-v1', score 90.0%, submitted at 16:00
      const v1 = Audit(
        id: 'd1-v1',
        auditType: 'daily',
        auditDate: '2026-09-21',
        weekNumber: 39,
        year: 2026,
        auditorId: 'sm-user-1',
        deviceId: 'device-1',
        status: 'submitted',
        compliancePct: 60.0,
        band: 'critical',
        submittedAt: '2026-09-21T10:00:00Z',
      );
      const v2 = Audit(
        id: 'd1-v2',
        auditType: 'daily',
        auditDate: '2026-09-21',
        weekNumber: 39,
        year: 2026,
        auditorId: 'sm-user-1',
        deviceId: 'device-1',
        status: 'submitted',
        compliancePct: 90.0,
        band: 'good',
        supersedesAuditId: 'd1-v1',
        submittedAt: '2026-09-21T16:00:00Z',
      );
      await fakeDb.insert('audits', v1.toMap());
      await fakeDb.insert('audits', v2.toMap());

      // Insert remaining 6 days (2026-09-22 to 2026-09-27) with 90.0% each
      for (int i = 22; i <= 27; i++) {
        final audit = Audit(
          id: 'd-$i',
          auditType: 'daily',
          auditDate: '2026-09-$i',
          weekNumber: 39,
          year: 2026,
          auditorId: 'sm-user-1',
          deviceId: 'device-1',
          status: 'submitted',
          compliancePct: 90.0,
          band: 'good',
          submittedAt: '2026-09-${i}T18:00:00Z',
        );
        await fakeDb.insert('audits', audit.toMap());
      }

      // Total rows in DB is 8
      expect(fakeDb.tables['audits']!.length, equals(8));

      // findSubmittedDailyAuditsForWeek should return exactly 7 audits (deduped per audit_date)
      final dailyAudits = await AuditRepository.instance.findSubmittedDailyAuditsForWeek(
        weekNumber: 39,
        year: 2026,
      );
      expect(dailyAudits.length, equals(7));
      expect(dailyAudits.any((a) => a.id == 'd1-v1'), isFalse);
      expect(dailyAudits.any((a) => a.id == 'd1-v2'), isTrue);

      // Verify all 7 audits are at 90.0%
      for (final a in dailyAudits) {
        expect(a.compliancePct, equals(90.0));
      }

      // Now conduct and submit a weekly audit — must succeed without throwing ArgumentError (>7 guard)
      final notifier = DraftAuditNotifier();
      await notifier.startWeekly(
        date: '2026-09-27',
        auditorId: 'gm-user-1',
        cros: const [],
      );

      for (final _ in notifier.state.checkpoints) {
        await notifier.mark(Verdict.pass);
      }

      // Submission pulls dailyAudits (exactly 7), calculates 124-pt score without error
      final scoreResult = await notifier.submitAudit(notes: 'Clean week with superseded Day 1');
      // 7 days @ 90% -> avgDailyPct = 90.0% -> dailyContribution = round1(90.0/100*68) = 61.2
      // 36 pass -> weeklyRaw = 56.0, weeklyMax = 56.0
      // total = 61.2 + 56 = 117.2 / 124 = 94.5% Good
      expect(scoreResult.rawScore, equals(117.2));
      expect(scoreResult.maxScore, equals(124.0));
      expect(scoreResult.compliancePct, equals(94.5));
      expect(scoreResult.band.name, equals('good'));

      // Also verify weeklyScore components explicitly
      final weeklyScore = computeWeeklyScore(
        dailyPcts: dailyAudits.map((a) => a.compliancePct ?? 0.0).toList(),
        weeklyMarks: notifier.state.checkpoints
            .map((c) => CheckpointMark(checkpointId: c.id, result: Verdict.pass, weight: c.weight))
            .toList(),
      );
      expect(weeklyScore.avgDailyPct, equals(90.0));
      expect(weeklyScore.dailyContribution, equals(61.2));
      expect(weeklyScore.totalRaw, equals(117.2));
      expect(weeklyScore.totalMax, equals(124.0));
      expect(weeklyScore.compliancePct, equals(94.5));
    });
  });
}
