import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/cro.dart';
import 'package:saagar_audit_app/domain/cash_thresholds.dart';
import 'package:saagar_audit_app/providers/draft_audit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 13: Cash Variance Enforcement & Thresholds Suite', () {
    late FakeDatabase fakeDb;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed checkpoints table in fakeDb
      fakeDb.tables['checkpoints'] = [
        {
          'id': '6.5',
          'sop_id': 'SOP6',
          'frequency': 'daily',
          'sequence': 5,
          'text_en': 'Cash variance ≤ ₹50 (or fully explained)',
          'text_mr': 'रोख तफावत ≤ ₹५०',
          'weight': 2,
          'allows_na': 0,
          'requires_photo_on_fail': 1,
          'display_order': 36,
        },
        {
          'id': '6.1',
          'sop_id': 'SOP6',
          'frequency': 'daily',
          'sequence': 1,
          'text_en': 'Opening float verified',
          'text_mr': 'प्रारंभिक फ्लोट पडताळला',
          'weight': 1,
          'allows_na': 0,
          'requires_photo_on_fail': 0,
          'display_order': 32,
        },
      ];
    });

    test('CashThresholds constants strictly adhere to Spec §6.5, §6.7, §7.0', () {
      expect(CashThresholds.dailyPassTolerance, equals(50.0));
      expect(CashThresholds.weeklyCumulativeTolerance, equals(200.0));
      expect(CashThresholds.escalationTolerance, equals(500.0));
    });

    test('Daily audit: Closing cash variance of -₹600 auto-FAILS Checkpoint 6.5 (resolves Item 13)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(draftAuditProvider.notifier);

      // Start a daily audit
      await notifier.startAudit(
        date: '2026-10-29',
        auditType: 'daily',
        auditorId: 'u_sm_001',
        cros: [
          Cro(
            id: 'cro_1',
            name: 'Staff 1',
            counter: 'Titan',
            shift: 'morning',
            isActive: true,
            joinedAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      // Manually mark all checkpoints as PASS on S07
      final state = container.read(draftAuditProvider);
      for (final _ in state.checkpoints) {
        await notifier.mark(Verdict.pass);
      }

      // Checkpoint 6.5 is initially PASS
      expect(container.read(draftAuditProvider).results['6.5'], equals(Verdict.pass));

      // Auditor on S10 submits with -₹600 closing cash shortage
      final scoreResult = await notifier.submitAudit(
        notes: null,
        cashVarianceRupees: -600.0,
      );

      // Checkpoint 6.5 MUST be forced to FAIL
      final resultsAfter = container.read(draftAuditProvider).results;
      expect(
        resultsAfter['6.5'],
        equals(Verdict.fail),
        reason: 'Variance of -₹600 exceeds ₹500 tolerance and must auto-FAIL Checkpoint 6.5',
      );

      // SQLite result must record the failure with finding note
      final savedResults = fakeDb.tables['audit_results']!;
      final r65 = savedResults.firstWhere((r) => r['checkpoint_id'] == '6.5');
      expect(r65['result'], equals('F'));
      expect(r65['weighted_points'], equals(0.0));
      expect(r65['finding_text'].toString(), contains('exceeds ₹500 tolerance'));

      // Score deduction reflected
      expect(scoreResult.failCount, greaterThanOrEqualTo(1));
    });

    test('Daily audit: Variance between ₹50 and ₹500 without note auto-FAILS Checkpoint 6.5', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(draftAuditProvider.notifier);
      await notifier.startAudit(
        date: '2026-10-29',
        auditType: 'daily',
        auditorId: 'u_sm_001',
        cros: const [],
      );

      for (final _ in container.read(draftAuditProvider).checkpoints) {
        await notifier.mark(Verdict.pass);
      }

      // Submit with -₹150 variance and NO note
      await notifier.submitAudit(
        notes: null,
        cashVarianceRupees: -150.0,
      );

      expect(
        container.read(draftAuditProvider).results['6.5'],
        equals(Verdict.fail),
        reason: 'Unexplained variance > ₹50 must auto-FAIL',
      );
    });

    test('Daily audit: Variance between ₹50 and ₹500 WITH explanation note PASSES Checkpoint 6.5', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(draftAuditProvider.notifier);
      await notifier.startAudit(
        date: '2026-10-29',
        auditType: 'daily',
        auditorId: 'u_sm_001',
        cros: const [],
      );

      for (final _ in container.read(draftAuditProvider).checkpoints) {
        await notifier.mark(Verdict.pass);
      }

      // Submit with -₹150 variance WITH explanation note (Pass with note rule)
      await notifier.submitAudit(
        notes: '₹150 coin exchange pending with ICICI bank counter, cashier countersigned.',
        cashVarianceRupees: -150.0,
      );

      expect(
        container.read(draftAuditProvider).results['6.5'],
        equals(Verdict.pass),
        reason: 'Variance between ₹50 and ₹500 with detailed explanation is permitted as Pass with Note',
      );
    });

    test('Daily audit: Variance ≤ ₹50 PASSES Checkpoint 6.5 without note', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(draftAuditProvider.notifier);
      await notifier.startAudit(
        date: '2026-10-29',
        auditType: 'daily',
        auditorId: 'u_sm_001',
        cros: const [],
      );

      for (final _ in container.read(draftAuditProvider).checkpoints) {
        await notifier.mark(Verdict.pass);
      }

      // Submit with -₹30 variance (within ±₹50 daily till limit)
      await notifier.submitAudit(
        notes: null,
        cashVarianceRupees: -30.0,
      );

      expect(
        container.read(draftAuditProvider).results['6.5'],
        equals(Verdict.pass),
        reason: 'Variance of ₹30 is within normal daily tolerance and must pass',
      );
    });

    test('Weekly audit: Cumulative weekly cash variance breaching ±₹200 auto-FAILS Checkpoint CW.7', () async {
      // Seed CW.7 checkpoint
      fakeDb.tables['checkpoints']!.add({
        'id': 'CW.7',
        'sop_id': 'SOP6',
        'frequency': 'weekly',
        'sequence': 7,
        'text_en': 'Cumulative weekly variance within ±₹200',
        'text_mr': 'संचयी साप्ताहिक तफावत ±₹२०० च्या आत',
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 85,
      });

      // Seed 7 submitted daily audits with cumulative shortage of -₹600
      fakeDb.tables['audits']!.add({
        'id': 'daily_audit_1',
        'audit_type': 'daily',
        'audit_date': '2026-10-27',
        'week_number': 44,
        'year': 2026,
        'auditor_id': 'u_sm_001',
        'device_id': 'dev_1',
        'status': 'submitted',
        'cash_variance_rupees': -600.0,
        'compliance_pct': 90.0,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(draftAuditProvider.notifier);
      await notifier.startAudit(
        date: '2026-10-29',
        auditType: 'weekly',
        auditorId: 'u_gm_001',
        cros: const [],
      );

      for (final _ in container.read(draftAuditProvider).checkpoints) {
        await notifier.mark(Verdict.pass);
      }

      // CW.7 was initially marked PASS on S07
      expect(container.read(draftAuditProvider).results['CW.7'], equals(Verdict.pass));

      // Submit weekly audit
      await notifier.submitAudit();

      // CW.7 MUST be forced to FAIL
      expect(
        container.read(draftAuditProvider).results['CW.7'],
        equals(Verdict.fail),
        reason: 'Cumulative variance of -₹600 breaches ±₹200 threshold; CW.7 must auto-FAIL',
      );

      final savedResults = fakeDb.tables['audit_results']!;
      final rCW7 = savedResults.firstWhere((r) => r['checkpoint_id'] == 'CW.7');
      expect(rCW7['result'], equals('F'));
      expect(rCW7['weighted_points'], equals(0.0));
      expect(rCW7['finding_text'].toString(), contains('breaches permitted ±₹200'));
    });
  });
}
