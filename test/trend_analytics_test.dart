import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/report.dart';
import 'package:saagar_audit_app/domain/trend_analytics.dart';

void main() {
  group('Sprint P3-4 — Trend Analytics Unit Tests (Spec §4.1, §4.5)', () {
    Report makeWeeklyReport({
      required String id,
      required int weekNumber,
      required int year,
      required String weekEnding,
      required double overallPct,
      required Map<String, double> perSopPct,
      Map<String, int> perSopFailCount = const {},
      String reportType = 'weekly',
    }) {
      final sopRows = perSopPct.entries.map((e) {
        final fails = perSopFailCount[e.key] ?? (e.value < 100 ? 1 : 0);
        return {
          'sop_id': e.key,
          'sop_number': e.key,
          'name_en': 'SOP ${e.key}',
          'name_mr': 'एसओपी ${e.key}',
          'raw_score': 10.0 - fails,
          'max_score': 10.0,
          'compliance_pct': e.value,
        };
      }).toList();

      final complianceTable = {
        'compliance_pct': overallPct,
        'sop_rows': sopRows,
      };

      final trendBlock = {
        'weekly_pct': overallPct,
        'daily_dates': [
          '${weekEnding.substring(0, 8)}01',
          '${weekEnding.substring(0, 8)}02',
          '${weekEnding.substring(0, 8)}03',
          '${weekEnding.substring(0, 8)}04',
          '${weekEnding.substring(0, 8)}05',
          '${weekEnding.substring(0, 8)}06',
          weekEnding,
        ],
      };

      return Report(
        id: id,
        auditId: 'audit-$id',
        reportType: reportType,
        headline: 'Week $weekNumber Ending $weekEnding · ${overallPct.toStringAsFixed(1)}% GOOD',
        complianceTableJson: jsonEncode(complianceTable),
        trendBlockJson: jsonEncode(trendBlock),
        submittedAt: '${weekEnding}T18:00:00Z',
      );
    }

    // =========================================================================
    // 1. Weekly Series Extraction
    // =========================================================================
    group('1. Weekly Series Extraction', () {
      test('buildWeeklySeries sorts chronologically and ignores non-weekly reports', () {
        final reports = [
          makeWeeklyReport(
            id: 'r2',
            weekNumber: 38,
            year: 2026,
            weekEnding: '2026-09-20',
            overallPct: 92.0,
            perSopPct: {'1': 95.0, '2': 89.0},
          ),
          makeWeeklyReport(
            id: 'r1',
            weekNumber: 37,
            year: 2026,
            weekEnding: '2026-09-13',
            overallPct: 90.0,
            perSopPct: {'1': 90.0, '2': 90.0},
          ),
          makeWeeklyReport(
            id: 'monthly-1',
            weekNumber: 39,
            year: 2026,
            weekEnding: '2026-09-27',
            overallPct: 100.0,
            perSopPct: {},
            reportType: 'monthly',
          ),
        ];

        final series = TrendAnalytics.buildWeeklySeries(reports);
        expect(series.length, 2);
        expect(series[0].weekNumber, 37);
        expect(series[0].overallPct, 90.0);
        expect(series[1].weekNumber, 38);
        expect(series[1].overallPct, 92.0);
        expect(series[1].perSopPct['2'], 89.0);
      });

      test('Empty reports returns empty series', () {
        final series = TrendAnalytics.buildWeeklySeries([]);
        expect(series, isEmpty);
      });
    });

    // =========================================================================
    // 2. 4-Week Moving Average Calculation (§4.1)
    // =========================================================================
    group('2. 4-Week Moving Average (§4.1)', () {
      test('Produces null for weeks 1..3 and accurate 4-week average from week 4 onwards', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 90.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 94.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 96.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 40, year: 2026, weekEnding: '2026-10-04', overallPct: 90.0, perSopPct: {}),
        ];

        final ma = TrendAnalytics.computeFourWeekMovingAverages(data);
        expect(ma.length, 5);
        expect(ma[0].value, isNull);
        expect(ma[1].value, isNull);
        expect(ma[2].value, isNull);

        // Week 39 MA = (90 + 92 + 94 + 96) / 4 = 372 / 4 = 93.0
        expect(ma[3].value, 93.0);

        // Week 40 MA = (92 + 94 + 96 + 90) / 4 = 372 / 4 = 93.0
        expect(ma[4].value, 93.0);
      });

      test('Graceful degradation when series has fewer than 4 weeks', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 90.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 92.0, perSopPct: {}),
        ];

        final ma = TrendAnalytics.computeFourWeekMovingAverages(data);
        expect(ma.length, 2);
        expect(ma[0].value, isNull);
        expect(ma[1].value, isNull);
      });
    });

    // =========================================================================
    // 3. Pattern 1: Slow Slide (§4.5)
    // =========================================================================
    group('3. Pattern 1: Slow Slide (§4.5)', () {
      test('Detects slow slide when 3 consecutive weeks decline (even if above target)', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 96.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 94.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 90.0, perSopPct: {}),
        ];

        final pattern = TrendAnalytics.detectSlowSlide(data);
        expect(pattern, isNotNull);
        expect(pattern!.type, TrendPatternType.slowSlide);
        expect(pattern.severity, 'warning');
        expect(pattern.metadata['consecutive_weeks'], 3);
        expect(pattern.metadata['start_pct'], 96.0);
        expect(pattern.metadata['end_pct'], 90.0);
        expect(pattern.metadata['drop_points'], 6.0);
        expect(pattern.nameEn, contains('Slow Slide'));
        expect(pattern.nameMr, contains('मंद घसरण'));
      });

      test('Does NOT detect slow slide if declines are fewer than 3 consecutive weeks', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 94.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 93.0, perSopPct: {}), // rebound
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 91.0, perSopPct: {}),
        ];

        expect(TrendAnalytics.detectSlowSlide(data), isNull);
      });

      test('Gracefully returns null when series has fewer than 4 weeks', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 94.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 92.0, perSopPct: {}),
        ];

        expect(TrendAnalytics.detectSlowSlide(data), isNull);
      });
    });

    // =========================================================================
    // 4. Pattern 2: Single-SOP Decay (§4.5)
    // =========================================================================
    group('4. Pattern 2: Single-SOP Decay (§4.5)', () {
      test('Detects single-SOP decay when SOP fails in 4 consecutive weeks while aggregate stays healthy', () {
        final data = [
          const WeeklyDataPoint(
            weekNumber: 36,
            year: 2026,
            weekEnding: '2026-09-06',
            overallPct: 92.0,
            perSopPct: {'1': 95.0, '2': 80.0},
            perSopFailCount: {'1': 0, '2': 2},
          ),
          const WeeklyDataPoint(
            weekNumber: 37,
            year: 2026,
            weekEnding: '2026-09-13',
            overallPct: 91.0,
            perSopPct: {'1': 94.0, '2': 82.0},
            perSopFailCount: {'1': 0, '2': 1},
          ),
          const WeeklyDataPoint(
            weekNumber: 38,
            year: 2026,
            weekEnding: '2026-09-20',
            overallPct: 93.0,
            perSopPct: {'1': 96.0, '2': 78.0},
            perSopFailCount: {'1': 0, '2': 2},
          ),
          const WeeklyDataPoint(
            weekNumber: 39,
            year: 2026,
            weekEnding: '2026-09-27',
            overallPct: 90.0,
            perSopPct: {'1': 95.0, '2': 85.0},
            perSopFailCount: {'1': 0, '2': 1},
          ),
        ];

        final patterns = TrendAnalytics.detectSingleSopDecay(data);
        expect(patterns.length, 1);
        final p = patterns.first;
        expect(p.type, TrendPatternType.singleSopDecay);
        expect(p.metadata['sop_id'], '2');
        expect(p.descriptionEn, contains('SOP 2 recorded failures in 4 consecutive weeks'));
        expect(p.descriptionEn, contains('rolling 4-week SOP graph'));
      });

      test('Does NOT flag single-SOP decay if aggregate score is unhealthy (< 85%)', () {
        final data = [
          const WeeklyDataPoint(
            weekNumber: 36,
            year: 2026,
            weekEnding: '2026-09-06',
            overallPct: 80.0,
            perSopPct: {'2': 70.0},
            perSopFailCount: {'2': 2},
          ),
          const WeeklyDataPoint(
            weekNumber: 37,
            year: 2026,
            weekEnding: '2026-09-13',
            overallPct: 82.0,
            perSopPct: {'2': 72.0},
            perSopFailCount: {'2': 2},
          ),
          const WeeklyDataPoint(
            weekNumber: 38,
            year: 2026,
            weekEnding: '2026-09-20',
            overallPct: 79.0,
            perSopPct: {'2': 68.0},
            perSopFailCount: {'2': 3},
          ),
          const WeeklyDataPoint(
            weekNumber: 39,
            year: 2026,
            weekEnding: '2026-09-27',
            overallPct: 81.0,
            perSopPct: {'2': 75.0},
            perSopFailCount: {'2': 2},
          ),
        ];

        // Overall average is ~80.5% < 85% -> general store crisis, not isolated single-SOP decay
        final patterns = TrendAnalytics.detectSingleSopDecay(data);
        expect(patterns, isEmpty);
      });

      test('Does NOT flag single-SOP decay if SOP had 100% in one of the 4 weeks', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 92.0, perSopPct: {'2': 80.0}, perSopFailCount: {'2': 1}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 92.0, perSopPct: {'2': 100.0}, perSopFailCount: {'2': 0}), // clean
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 92.0, perSopPct: {'2': 80.0}, perSopFailCount: {'2': 1}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 92.0, perSopPct: {'2': 85.0}, perSopFailCount: {'2': 1}),
        ];

        expect(TrendAnalytics.detectSingleSopDecay(data), isEmpty);
      });
    });

    // =========================================================================
    // 5. Pattern 3: Day-of-Week Clustering (§4.5)
    // =========================================================================
    group('5. Pattern 3: Day-of-Week Clustering (§4.5)', () {
      test('Detects clustering when Fri/Sat average is ≥ 3.0 pts below Mon-Thu', () {
        // Mon=2026-09-07, Tue=2026-09-08, Wed=2026-09-09, Thu=2026-09-10
        // Fri=2026-09-11, Sat=2026-09-12
        final dailyAudits = <Audit>[
          const Audit(id: 'd1', auditType: 'daily', auditDate: '2026-09-07', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 93.0),
          const Audit(id: 'd2', auditType: 'daily', auditDate: '2026-09-08', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 92.0),
          const Audit(id: 'd3', auditType: 'daily', auditDate: '2026-09-09', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 94.0),
          const Audit(id: 'd4', auditType: 'daily', auditDate: '2026-09-10', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 93.0), // weekday avg = 93.0%
          const Audit(id: 'd5', auditType: 'daily', auditDate: '2026-09-11', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 88.0), // Fri
          const Audit(id: 'd6', auditType: 'daily', auditDate: '2026-09-12', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 86.0), // Sat, weekend avg = 87.0% (delta = 6.0)
        ];

        final pattern = TrendAnalytics.detectDayOfWeekClustering(dailyAudits);
        expect(pattern, isNotNull);
        expect(pattern!.type, TrendPatternType.dayOfWeekClustering);
        expect(pattern.metadata['avg_weekday'], 93.0);
        expect(pattern.metadata['avg_weekend'], 87.0);
        expect(pattern.metadata['delta'], 6.0);
        expect(pattern.nameEn, contains('Day-of-Week Clustering'));
        expect(pattern.nameMr, contains('ठरावीक दिवसांची घसरण'));
      });

      test('Does NOT flag clustering when weekend difference is < 3.0 pts', () {
        final dailyAudits = <Audit>[
          const Audit(id: 'd1', auditType: 'daily', auditDate: '2026-09-07', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 92.0),
          const Audit(id: 'd2', auditType: 'daily', auditDate: '2026-09-08', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 92.0),
          const Audit(id: 'd3', auditType: 'daily', auditDate: '2026-09-09', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 92.0),
          const Audit(id: 'd4', auditType: 'daily', auditDate: '2026-09-10', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 92.0),
          const Audit(id: 'd5', auditType: 'daily', auditDate: '2026-09-11', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 91.0),
          const Audit(id: 'd6', auditType: 'daily', auditDate: '2026-09-12', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 90.0), // delta = 1.5 < 3.0
        ];

        expect(TrendAnalytics.detectDayOfWeekClustering(dailyAudits), isNull);
      });

      test('Returns null if insufficient weekday or weekend audits exist', () {
        final dailyAudits = <Audit>[
          const Audit(id: 'd1', auditType: 'daily', auditDate: '2026-09-07', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 90.0),
          const Audit(id: 'd5', auditType: 'daily', auditDate: '2026-09-11', weekNumber: 37, year: 2026, auditorId: 'u1', deviceId: 'dev1', status: 'submitted', compliancePct: 80.0),
        ];

        expect(TrendAnalytics.detectDayOfWeekClustering(dailyAudits), isNull);
      });
    });

    // =========================================================================
    // 6. Volatility Finding (§4.1: "92/88/94/89 → volatility is the finding")
    // =========================================================================
    group('6. Volatility Finding (§4.1)', () {
      test('Detects canonical Spec §4.1 volatility case: 92% -> 88% -> 94% -> 89%', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 88.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 94.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 89.0, perSopPct: {}),
        ];

        final pattern = TrendAnalytics.detectVolatility(data);
        expect(pattern, isNotNull);
        expect(pattern!.type, TrendPatternType.volatility);
        expect(pattern.nameEn, contains('Volatility'));
      });

      test('Stable series does not flag volatility', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 91.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 91.5, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 91.2, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 91.8, perSopPct: {}),
        ];

        expect(TrendAnalytics.detectVolatility(data), isNull);
      });
    });

    // =========================================================================
    // 7. Month-over-Month Delta (§3.3 derivation)
    // =========================================================================
    group('7. MoM Delta (§3.3 derivation)', () {
      test('Calculates MoM delta correctly across 8-week series', () {
        final data = [
          // Month 1: avg = 88.0%
          const WeeklyDataPoint(weekNumber: 32, year: 2026, weekEnding: '2026-08-09', overallPct: 88.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 33, year: 2026, weekEnding: '2026-08-16', overallPct: 88.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 34, year: 2026, weekEnding: '2026-08-23', overallPct: 88.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 35, year: 2026, weekEnding: '2026-08-30', overallPct: 88.0, perSopPct: {}),
          // Month 2: avg = 92.0%
          const WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 92.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 92.0, perSopPct: {}),
        ];

        final delta = TrendAnalytics.calculateMomDelta(data);
        expect(delta, 4.0); // +4.0%
      });

      test('Returns null if fewer than 4 weeks exist', () {
        final data = [
          const WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 90.0, perSopPct: {}),
          const WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 92.0, perSopPct: {}),
        ];
        expect(TrendAnalytics.calculateMomDelta(data), isNull);
      });
    });

    // =========================================================================
    // 8. End-to-End TrendAnalysisResult & Serialization
    // =========================================================================
    group('8. TrendAnalysisResult & Serialization', () {
      test('End-to-end analyze generates full result and JSON round-trip preserves fields', () {
        final reports = [
          makeWeeklyReport(id: 'w1', weekNumber: 36, year: 2026, weekEnding: '2026-09-06', overallPct: 94.0, perSopPct: {'1': 95.0, '2': 80.0}),
          makeWeeklyReport(id: 'w2', weekNumber: 37, year: 2026, weekEnding: '2026-09-13', overallPct: 93.0, perSopPct: {'1': 95.0, '2': 80.0}),
          makeWeeklyReport(id: 'w3', weekNumber: 38, year: 2026, weekEnding: '2026-09-20', overallPct: 91.0, perSopPct: {'1': 95.0, '2': 80.0}),
          makeWeeklyReport(id: 'w4', weekNumber: 39, year: 2026, weekEnding: '2026-09-27', overallPct: 89.0, perSopPct: {'1': 95.0, '2': 80.0}),
        ];

        final result = TrendAnalytics.analyze(weeklyReports: reports);
        expect(result.hasSufficientData, isTrue);
        expect(result.weeklySeries.length, 4);
        expect(result.movingAverages.length, 4);
        expect(result.movingAverages.last.value, isNotNull);
        expect(result.detectedPatterns.any((p) => p.type == TrendPatternType.slowSlide), isTrue);

        final json = result.toJson();
        final decoded = TrendAnalysisResult.fromJson(json);

        expect(decoded.hasSufficientData, isTrue);
        expect(decoded.weeklySeries.length, 4);
        expect(decoded.weeklySeries[0].overallPct, 94.0);
        expect(decoded.movingAverages.last.value, result.movingAverages.last.value);
        expect(decoded.detectedPatterns.length, result.detectedPatterns.length);
      });
    });
  });
}
