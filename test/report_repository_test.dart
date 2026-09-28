import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/report_repository.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Sprint P2-4 — ReportRepository & 9-Section Payload Tests', () {
    late FakeDatabase fakeDb;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed SOPs (SOP1..SOP8 and SOP9)
      for (int i = 1; i <= 8; i++) {
        await fakeDb.insert('sops', {
          'id': 'SOP$i',
          'number': i,
          'name_en': 'SOP $i Title',
          'name_mr': 'एसओपी $i शीर्षक',
          'weight': 1,
          'is_critical': 0,
          'display_order': i,
        });
      }
      await fakeDb.insert('sops', {
        'id': 'SOP9',
        'number': 9,
        'name_en': 'Store Operations',
        'name_mr': 'स्टोअर ऑपरेशन्स',
        'weight': 1,
        'is_critical': 0,
        'display_order': 9,
      });

      // Seed checkpoints
      for (int i = 1; i <= 68; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'CP.$i',
          'sop_id': 'SOP${((i - 1) % 8) + 1}',
          'frequency': 'daily',
          'sequence': i,
          'text_en': 'Daily Checkpoint $i',
          'text_mr': 'दैनिक चेकपॉईंट $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': i,
        });
      }

      // Seed 36 weekly checkpoints (Ops 10x1=10, Cash 8x2=16, RS 6x1=6, Inv 12x2=24; 56 pts total)
      for (int i = 1; i <= 10; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'O.$i',
          'sop_id': 'SOP9',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Operations $i',
          'text_mr': 'ऑपरेशन्स $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': 68 + i,
        });
      }
      for (int i = 1; i <= 8; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'CW.$i',
          'sop_id': 'SOP6',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Cash Weekly $i',
          'text_mr': 'कॅश साप्ताहिक $i',
          'weight': 2,
          'allows_na': 1,
          'requires_photo_on_fail': 1,
          'display_order': 78 + i,
        });
      }
      for (int i = 1; i <= 6; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'RS.$i',
          'sop_id': 'SOP8',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Reporting Service $i',
          'text_mr': 'रिपोर्टिंग सर्व्हिस $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': 86 + i,
        });
      }
      for (int i = 1; i <= 12; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'IW.$i',
          'sop_id': 'SOP7',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Inventory Weekly $i',
          'text_mr': 'इन्व्हेंटरी साप्ताहिक $i',
          'weight': 2,
          'allows_na': 1,
          'requires_photo_on_fail': 1,
          'display_order': 92 + i,
        });
      }
    });

    test('1. Generates 9-section weekly report assembling true 124-point rollup and T2.4 patterns', () async {
      const weeklyAuditId = 'weekly-audit-w39';
      const gmUserId = 'usr-gm-01';

      // Insert weekly audit
      await fakeDb.insert('audits', {
        'id': weeklyAuditId,
        'audit_type': 'weekly',
        'audit_date': '2026-09-27',
        'week_number': 39,
        'year': 2026,
        'auditor_id': gmUserId,
        'device_id': 'dev-1',
        'status': 'submitted',
        'submitted_at': '2026-09-27T18:00:00Z',
      });

      // Seed 7 submitted daily audits for Week 39 (2026-09-21 to 2026-09-27)
      // Daily percentages matching T2.1 setup (avg = 84.1%)
      final dailyPcts = [90.0, 85.0, 80.0, 95.0, 75.0, 88.0, 75.7];
      for (int d = 1; d <= 7; d++) {
        final date = '2026-09-2$d';
        final auditId = 'd$d-audit';
        await fakeDb.insert('audits', {
          'id': auditId,
          'audit_type': 'daily',
          'audit_date': date,
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'sm-01',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': dailyPcts[d - 1],
          'submitted_at': '${date}T18:00:00Z',
        });

        // Seed failures: CP.4 fails on Days 1, 2, 3 (triggers T2.4 Pattern!)
        if (d <= 3) {
          await fakeDb.insert('audit_results', {
            'id': 'res-cp4-$d',
            'audit_id': auditId,
            'checkpoint_id': 'CP.4',
            'result': 'F',
            'findingText': 'Display glass stained on day $d',
            'created_at': '${date}T10:00:00Z',
          });
        }
      }

      // Weekly results: O.1..O.10, CW.1..CW.8, RS.1..RS.6, IW.1..IW.10 PASS; IW.11 & IW.12 FAIL
      final weeklyPassIds = [
        for (int i = 1; i <= 10; i++) 'O.$i',
        for (int i = 1; i <= 8; i++) 'CW.$i',
        for (int i = 1; i <= 6; i++) 'RS.$i',
        for (int i = 1; i <= 10; i++) 'IW.$i',
      ];
      for (int i = 0; i < weeklyPassIds.length; i++) {
        await fakeDb.insert('audit_results', {
          'id': 'wres-p-$i',
          'audit_id': weeklyAuditId,
          'checkpoint_id': weeklyPassIds[i],
          'result': 'P',
          'created_at': '2026-09-27T11:00:00Z',
        });
      }
      for (final failId in ['IW.11', 'IW.12']) {
        await fakeDb.insert('audit_results', {
          'id': 'wres-f-$failId',
          'audit_id': weeklyAuditId,
          'checkpoint_id': failId,
          'result': 'F',
          'finding_text': 'Missing fire extinguisher inspection tag',
          'created_at': '2026-09-27T11:00:00Z',
        });
      }

      // Generate the report
      final report = await ReportRepository.instance.generateWeeklyReport(
        weeklyAuditId: weeklyAuditId,
        authorUserId: gmUserId,
      );

      expect(report.id, isNotEmpty);
      expect(report.auditId, weeklyAuditId);
      expect(report.reportType, 'weekly');
      expect(report.authorUserId, gmUserId);
      expect(report.isReadByOwner, isFalse);

      // Section 1: Headline
      expect(report.headline, contains('Week 39 Ending 2026-09-27'));
      expect(report.headline, contains('2 Failures'));
      expect(report.headline, contains('1 Patterns'));

      // Section 2: Compliance Table
      final compTable = report.complianceTable;
      expect(compTable['avg_daily_pct'], closeTo(84.1, 0.1));
      expect(compTable['daily_contribution'], closeTo(57.2, 0.1));
      expect(compTable['total_max'], 124.0);
      expect(compTable['sop_rows'], isNotEmpty);

      // Section 3: Trend Block
      final trend = report.trendBlock;
      expect(trend['daily_pcts'], dailyPcts);
      expect(trend['daily_dates'].length, 7);

      // Section 4: Findings
      final findings = report.findings;
      expect(findings.length, 2);
      expect(findings.any((f) => f['checkpoint_id'] == 'IW.11'), isTrue);
      expect(findings.any((f) => f['checkpoint_id'] == 'IW.12'), isTrue);

      // Section 5: Patterns (T2.4 verified!)
      final patterns = report.patterns;
      expect(patterns.length, 1);
      expect(patterns.first.checkpointId, 'CP.4');
      expect(patterns.first.failCount, 3);
      expect(patterns.first.weekdaysEn, ['Mon', 'Tue', 'Wed']);

      // Section 6: CAPs Opened (Suggested Pattern CAP)
      final capsOpened = report.capsOpened;
      expect(capsOpened.length, 1);
      expect(capsOpened.first['is_pattern'], isTrue);
      expect(capsOpened.first['checkpoint_id'], 'CP.4');

      // Sections 7, 8, 9: Honest empty-states for future phases
      expect(report.capsClosed, isEmpty);
      expect(report.capsAged, isEmpty);
      expect(report.escalations, isEmpty);

      // Verify markReadByOwner
      await ReportRepository.instance.markReadByOwner(
        reportId: report.id,
        ownerUserId: 'usr-owner-01',
      );
      final readReport = (await ReportRepository.instance.getById(report.id))!;
      expect(readReport.isReadByOwner, isTrue);
      expect(readReport.readByOwnerAt, isNotNull);

      // Verify listReports
      final reportsList = await ReportRepository.instance.listReports();
      expect(reportsList.length, 1);
      expect(reportsList.first.id, report.id);
    });
  });
}
