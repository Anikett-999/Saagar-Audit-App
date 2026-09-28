import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/domain/score_engine.dart';

void main() {
  group('Weekly Score Engine — Spec §6.5 & §6.7', () {
    test(
      'T2.1 (canonical, EXACT): Workbook §5.2 simulated weekly audit reproduces 104.8 / 124 = 84.5% Poor',
      () {
        // Daily audit percentages for Week 24: Mon-Sun
        final dailyPcts = [92.2, 91.1, 90.0, 88.8, 93.3, 89.7, 91.4];

        // Weekly-only checkpoints per Workbook §5.2:
        // Operations: 7 Pass (1x), 3 Fail (1x) -> 7 / 10
        // Cash: 5 Pass (2x), 3 Fail (2x) -> 10 / 16
        // Reporting & Service: 4 Pass (1x), 2 Fail (1x) -> 4 / 6
        // Inventory: 11 Pass (2x), 1 Fail (2x) -> 22 / 24
        final weeklyMarks = <CheckpointMark>[
          // Operations (10 raw, wt 1)
          for (var i = 1; i <= 7; i++)
            CheckpointMark(checkpointId: 'O.$i', result: Verdict.pass, weight: 1),
          for (var i = 8; i <= 10; i++)
            CheckpointMark(checkpointId: 'O.$i', result: Verdict.fail, weight: 1),

          // Cash ★ (8 raw, wt 2)
          for (var i = 1; i <= 5; i++)
            CheckpointMark(checkpointId: 'CW.$i', result: Verdict.pass, weight: 2),
          for (var i = 6; i <= 8; i++)
            CheckpointMark(checkpointId: 'CW.$i', result: Verdict.fail, weight: 2),

          // Reporting & Service (6 raw, wt 1)
          for (var i = 1; i <= 4; i++)
            CheckpointMark(checkpointId: 'RS.$i', result: Verdict.pass, weight: 1),
          for (var i = 5; i <= 6; i++)
            CheckpointMark(checkpointId: 'RS.$i', result: Verdict.fail, weight: 1),

          // Inventory ★ (12 raw, wt 2)
          for (var i = 1; i <= 11; i++)
            CheckpointMark(checkpointId: 'IW.$i', result: Verdict.pass, weight: 2),
          const CheckpointMark(checkpointId: 'IW.12', result: Verdict.fail, weight: 2),
        ];

        final result = computeWeeklyScore(
          dailyPcts: dailyPcts,
          weeklyMarks: weeklyMarks,
        );

        // Assert step-by-step math per Workbook §5.2 Answer Key
        // Sum = 636.5 / 7 = 90.9%
        expect(result.avgDailyPct, 90.9, reason: 'avg daily pct rounded to 1 decimal');
        // Contribution = 90.9 * 0.68 = 61.8
        expect(result.dailyContribution, 61.8, reason: 'daily contribution rounded to 1 decimal');

        // Weekly components:
        // Ops 7 + Cash 10 + RS 4 + Inv 22 = 43 raw
        expect(result.weeklyRaw, 43.0, reason: 'weekly raw points');
        // Ops 10 + Cash 16 + RS 6 + Inv 24 = 56 max
        expect(result.weeklyMax, 56.0, reason: 'weekly max points');

        // Combined: 61.8 + 43.0 = 104.8
        expect(result.totalRaw, 104.8, reason: 'total raw score');
        // Total max: 68 + 56 = 124
        expect(result.totalMax, 124.0, reason: 'total max score');

        // Compliance: 104.8 / 124 = 84.5% EXACT
        expect(result.compliancePct, 84.5, reason: 'compliance percentage must match 84.5% exactly');
        expect(result.band, Band.poor, reason: '84.5 is strictly in the POOR band (80.0–84.9)');
        expect(result.passCount, 27);
        expect(result.failCount, 9);
        expect(result.naCount, 0);
      },
    );

    test('T2.2 (missing day = 0%): 6 days @ 90%, 1 day absent yields avg=77.1% and contribution=52.4', () {
      // 6 days at 90.0%, 1 day missing (passed as 0.0 or omitted in 6-day list)
      final dailyPcts = [90.0, 90.0, 0.0, 90.0, 90.0, 90.0, 90.0];

      final result = computeWeeklyScore(
        dailyPcts: dailyPcts,
        weeklyMarks: const [],
      );

      // (90 * 6 + 0) / 7 = 540 / 7 = 77.1428... -> 77.1
      expect(result.avgDailyPct, 77.1);
      // 77.1 * 0.68 = 52.428 -> 52.4
      expect(result.dailyContribution, 52.4);
      expect(result.totalRaw, 52.4);
      expect(result.totalMax, 68.0);
      // 52.4 / 68.0 * 100 = 77.058... -> 77.1
      expect(result.compliancePct, 77.1);
      expect(result.band, Band.critical);
    });

    test('Pads daily percentages with 0.0 if fewer than 7 days provided', () {
      // Caller passes 6 days only
      final dailyPcts = [90.0, 90.0, 90.0, 90.0, 90.0, 90.0];

      final result = computeWeeklyScore(
        dailyPcts: dailyPcts,
        weeklyMarks: const [],
      );

      expect(result.dailyPcts.length, 7);
      expect(result.dailyPcts[6], 0.0);
      expect(result.avgDailyPct, 77.1);
      expect(result.dailyContribution, 52.4);
    });

    test('Throws ArgumentError if more than 7 daily percentages provided', () {
      expect(
        () => computeWeeklyScore(
          dailyPcts: [90.0, 90.0, 90.0, 90.0, 90.0, 90.0, 90.0, 90.0],
          weeklyMarks: const [],
        ),
        throwsArgumentError,
      );
    });

    test('NA weekly checkpoints are excluded from both weeklyRaw and weeklyMax', () {
      final dailyPcts = [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0];
      // 1 Pass (wt 2), 1 Fail (wt 2), 2 NA (wt 2)
      final weeklyMarks = [
        const CheckpointMark(checkpointId: 'W1', result: Verdict.pass, weight: 2),
        const CheckpointMark(checkpointId: 'W2', result: Verdict.fail, weight: 2),
        const CheckpointMark(checkpointId: 'W3', result: Verdict.na, weight: 2),
        const CheckpointMark(checkpointId: 'W4', result: Verdict.na, weight: 2),
      ];

      final result = computeWeeklyScore(
        dailyPcts: dailyPcts,
        weeklyMarks: weeklyMarks,
      );

      expect(result.dailyContribution, 68.0);
      expect(result.weeklyRaw, 2.0);
      expect(result.weeklyMax, 4.0, reason: 'NA excluded from max');
      expect(result.totalRaw, 70.0);
      expect(result.totalMax, 72.0, reason: '68 + 4 = 72');
      expect(result.compliancePct, round1(70.0 / 72.0 * 100.0));
      expect(result.naCount, 2);
    });

    test('Strict band cutoff boundaries apply to weekly compliance percentage', () {
      expect(bandFromCompliance(95.0), Band.excellent);
      expect(bandFromCompliance(94.9), Band.good);
      expect(bandFromCompliance(90.0), Band.good);
      expect(bandFromCompliance(89.9), Band.fair);
      expect(bandFromCompliance(85.0), Band.fair);
      expect(bandFromCompliance(84.9), Band.poor);
      expect(bandFromCompliance(80.0), Band.poor);
      expect(bandFromCompliance(79.9), Band.critical);
    });

    group('CW.7 Cumulative Weekly Cash Variance — Spec §6.7', () {
      test('Workbook §5.2 scenario: +45, +60, -30 net variance = +75 (no breach)', () {
        final variances = [0.0, 45.0, 60.0, 0.0, 0.0, 0.0, -30.0];
        final result = computeCumulativeWeeklyVariance(variances);

        expect(result.netVarianceRupees, 75.0);
        expect(result.isBreached, isFalse);
      });

      test('Breach detected when net cash variance exceeds +200 rupees', () {
        final variances = [50.0, 60.0, 70.0, 30.0, 0.0, 0.0, 0.0]; // +210
        final result = computeCumulativeWeeklyVariance(variances);

        expect(result.netVarianceRupees, 210.0);
        expect(result.isBreached, isTrue);
      });

      test('Breach detected when negative net variance exceeds -200 rupees', () {
        final variances = [-100.0, -80.0, -30.0, 0.0, 0.0, 0.0, 0.0]; // -210
        final result = computeCumulativeWeeklyVariance(variances);

        expect(result.netVarianceRupees, -210.0);
        expect(result.isBreached, isTrue);
      });

      test('Boundary ±200 rupees is NOT breached (within threshold)', () {
        expect(computeCumulativeWeeklyVariance([200.0]).isBreached, isFalse);
        expect(computeCumulativeWeeklyVariance([-200.0]).isBreached, isFalse);
        expect(computeCumulativeWeeklyVariance([200.1]).isBreached, isTrue);
        expect(computeCumulativeWeeklyVariance([-200.1]).isBreached, isTrue);
      });
    });
  });
}
