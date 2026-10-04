import 'dart:math' as math;

import '../data/models/audit.dart';
import '../data/models/report.dart';
import 'iso_week.dart';

/// A single week's compliance data point in a multi-week trend series.
class WeeklyDataPoint {
  const WeeklyDataPoint({
    required this.weekNumber,
    required this.year,
    required this.weekEnding,
    required this.overallPct,
    required this.perSopPct,
    this.perSopFailCount = const {},
  });

  factory WeeklyDataPoint.fromJson(Map<String, dynamic> json) => WeeklyDataPoint(
        weekNumber: (json['week_number'] as num).toInt(),
        year: (json['year'] as num).toInt(),
        weekEnding: json['week_ending'] as String? ?? '',
        overallPct: (json['overall_pct'] as num).toDouble(),
        perSopPct: (json['per_sop_pct'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const {},
        perSopFailCount: (json['per_sop_fail_count'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            const {},
      );

  final int weekNumber;
  final int year;
  final String weekEnding;
  final double overallPct;
  final Map<String, double> perSopPct;
  final Map<String, int> perSopFailCount;

  Map<String, dynamic> toJson() => {
        'week_number': weekNumber,
        'year': year,
        'week_ending': weekEnding,
        'overall_pct': overallPct,
        'per_sop_pct': perSopPct,
        'per_sop_fail_count': perSopFailCount,
      };
}

/// A 4-week moving average point corresponding to a week in the series (Spec §4.1).
class MovingAveragePoint {
  const MovingAveragePoint({
    required this.weekNumber,
    required this.year,
    required this.weekEnding,
    required this.value, // null if < 4 historical weeks available
  });

  factory MovingAveragePoint.fromJson(Map<String, dynamic> json) => MovingAveragePoint(
        weekNumber: (json['week_number'] as num).toInt(),
        year: (json['year'] as num).toInt(),
        weekEnding: json['week_ending'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble(),
      );

  final int weekNumber;
  final int year;
  final String weekEnding;
  final double? value;

  Map<String, dynamic> toJson() => {
        'week_number': weekNumber,
        'year': year,
        'week_ending': weekEnding,
        'value': value,
      };
}

/// The multi-week trend patterns named in Spec §4.1 & §4.5.
enum TrendPatternType {
  slowSlide,
  singleSopDecay,
  dayOfWeekClustering,
  volatility,
}

/// A detected multi-week trend pattern.
class TrendPattern {
  const TrendPattern({
    required this.type,
    required this.nameEn,
    required this.nameMr,
    required this.descriptionEn,
    required this.descriptionMr,
    required this.severity, // 'warning' | 'critical' | 'info'
    this.metadata = const {},
  });

  factory TrendPattern.fromJson(Map<String, dynamic> json) => TrendPattern(
        type: TrendPatternType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TrendPatternType.slowSlide,
        ),
        nameEn: json['name_en'] as String? ?? '',
        nameMr: json['name_mr'] as String? ?? '',
        descriptionEn: json['description_en'] as String? ?? '',
        descriptionMr: json['description_mr'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );

  final TrendPatternType type;
  final String nameEn;
  final String nameMr;
  final String descriptionEn;
  final String descriptionMr;
  final String severity;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name_en': nameEn,
        'name_mr': nameMr,
        'description_en': descriptionEn,
        'description_mr': descriptionMr,
        'severity': severity,
        'metadata': metadata,
      };
}

/// Complete result of multi-week trend analytics.
class TrendAnalysisResult {
  const TrendAnalysisResult({
    required this.weeklySeries,
    required this.movingAverages,
    required this.detectedPatterns,
    this.momDelta,
    required this.hasSufficientData,
    this.volatilityScore,
  });

  factory TrendAnalysisResult.fromJson(Map<String, dynamic> json) => TrendAnalysisResult(
        weeklySeries: ((json['weekly_series'] as List?) ?? [])
            .map((item) => WeeklyDataPoint.fromJson(item as Map<String, dynamic>))
            .toList(),
        movingAverages: ((json['moving_averages'] as List?) ?? [])
            .map((item) => MovingAveragePoint.fromJson(item as Map<String, dynamic>))
            .toList(),
        detectedPatterns: ((json['detected_patterns'] as List?) ?? [])
            .map((item) => TrendPattern.fromJson(item as Map<String, dynamic>))
            .toList(),
        momDelta: (json['mom_delta'] as num?)?.toDouble(),
        hasSufficientData: json['has_sufficient_data'] as bool? ?? false,
        volatilityScore: (json['volatility_score'] as num?)?.toDouble(),
      );

  final List<WeeklyDataPoint> weeklySeries;
  final List<MovingAveragePoint> movingAverages;
  final List<TrendPattern> detectedPatterns;
  final double? momDelta;
  final bool hasSufficientData;
  final double? volatilityScore;

  Map<String, dynamic> toJson() => {
        'weekly_series': weeklySeries.map((w) => w.toJson()).toList(),
        'moving_averages': movingAverages.map((m) => m.toJson()).toList(),
        'detected_patterns': detectedPatterns.map((p) => p.toJson()).toList(),
        'mom_delta': momDelta,
        'has_sufficient_data': hasSufficientData,
        'volatility_score': volatilityScore,
      };
}

/// Pure domain trend analytics engine for multi-week analysis (Spec §4.1, §4.5).
class TrendAnalytics {
  const TrendAnalytics._();

  /// Builds a sorted, chronological series of [WeeklyDataPoint] from weekly reports.
  static List<WeeklyDataPoint> buildWeeklySeries(List<Report> weeklyReports) {
    final valid = weeklyReports.where((r) => r.reportType == 'weekly').toList();
    final points = <WeeklyDataPoint>[];

    for (final report in valid) {
      final compTable = report.complianceTable;
      final trend = report.trendBlock;

      final overallPct = (compTable['compliance_pct'] as num?)?.toDouble() ??
          (trend['weekly_pct'] as num?)?.toDouble() ??
          0.0;

      // Extract per-SOP compliance % and fail counts
      final sopRows = (compTable['sop_rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final perSopPct = <String, double>{};
      final perSopFailCount = <String, int>{};

      for (final row in sopRows) {
        final sopId = (row['sop_id'] ?? row['sop_number'] ?? '').toString();
        if (sopId.isEmpty) continue;
        final pct = (row['compliance_pct'] as num?)?.toDouble() ?? 100.0;
        final raw = (row['raw_score'] as num?)?.toDouble() ?? 0.0;
        final max = (row['max_score'] as num?)?.toDouble() ?? 0.0;
        perSopPct[sopId] = pct;
        if (max > raw) {
          perSopFailCount[sopId] = (max - raw).round();
        } else {
          perSopFailCount[sopId] = 0;
        }
      }

      // Determine week number, year, and week ending date
      int weekNumber = 1;
      int year = DateTime.now().year;
      String weekEnding = '';

      final dailyDates = (trend['daily_dates'] as List?)?.cast<String>() ?? [];
      if (dailyDates.isNotEmpty) {
        weekEnding = dailyDates.last;
        final dt = DateTime.tryParse(weekEnding);
        if (dt != null) {
          year = dt.year;
          weekNumber = isoWeek(dt);
        }
      } else if (report.submittedAt != null) {
        final dt = DateTime.tryParse(report.submittedAt!);
        if (dt != null) {
          year = dt.year;
          weekNumber = isoWeek(dt);
          weekEnding = report.submittedAt!.split('T').first;
        }
      }

      // Try headline regex fallback: e.g. "Week 38 Ending 2026-09-20"
      if (report.headline != null) {
        final match = RegExp(r'Week\s+(\d+)\s+Ending\s+([0-9-]+)', caseSensitive: false)
            .firstMatch(report.headline!);
        if (match != null) {
          weekNumber = int.tryParse(match.group(1) ?? '') ?? weekNumber;
          weekEnding = match.group(2) ?? weekEnding;
        }
      }

      points.add(
        WeeklyDataPoint(
          weekNumber: weekNumber,
          year: year,
          weekEnding: weekEnding,
          overallPct: overallPct,
          perSopPct: perSopPct,
          perSopFailCount: perSopFailCount,
        ),
      );
    }

    // Sort chronologically by year then weekNumber
    points.sort((a, b) {
      if (a.year != b.year) return a.year.compareTo(b.year);
      return a.weekNumber.compareTo(b.weekNumber);
    });

    return points;
  }

  /// Computes the 4-week moving average series for a weekly series (Spec §4.1).
  /// For any week where fewer than 4 historical data points are available, value is null.
  static List<MovingAveragePoint> computeFourWeekMovingAverages(List<WeeklyDataPoint> series) {
    final result = <MovingAveragePoint>[];

    for (var i = 0; i < series.length; i++) {
      final cur = series[i];
      if (i < 3) {
        // Fewer than 4 weeks available up to index i
        result.add(
          MovingAveragePoint(
            weekNumber: cur.weekNumber,
            year: cur.year,
            weekEnding: cur.weekEnding,
            value: null,
          ),
        );
      } else {
        // Average of past four weeks (i-3, i-2, i-1, i)
        final sum = series[i - 3].overallPct +
            series[i - 2].overallPct +
            series[i - 1].overallPct +
            series[i].overallPct;
        final ma = double.parse((sum / 4.0).toStringAsFixed(1));
        result.add(
          MovingAveragePoint(
            weekNumber: cur.weekNumber,
            year: cur.year,
            weekEnding: cur.weekEnding,
            value: ma,
          ),
        );
      }
    }

    return result;
  }

  /// Detects Slow Slide pattern (Spec §4.5):
  /// "3+ consecutive weeks of negative movement even if above target"
  /// A run of at least 3 consecutive week-to-week declines (i.e. 4 weeks: w0 > w1 > w2 > w3).
  static TrendPattern? detectSlowSlide(List<WeeklyDataPoint> series) {
    if (series.length < 4) return null;

    // Scan backwards from most recent weeks to find the longest recent declining streak
    int consecutiveDeclines = 0;
    int endIndex = -1;

    for (var i = series.length - 1; i >= 1; i--) {
      if (series[i].overallPct < series[i - 1].overallPct) {
        consecutiveDeclines++;
        if (endIndex == -1) endIndex = i;
      } else {
        if (consecutiveDeclines >= 3) break;
        consecutiveDeclines = 0;
        endIndex = -1;
      }
    }

    if (consecutiveDeclines >= 3 && endIndex != -1) {
      final startIndex = endIndex - consecutiveDeclines;
      final startPct = series[startIndex].overallPct;
      final endPct = series[endIndex].overallPct;
      final dropTotal = double.parse((startPct - endPct).toStringAsFixed(1));

      return TrendPattern(
        type: TrendPatternType.slowSlide,
        nameEn: 'Slow Slide Detected',
        nameMr: 'मंद घसरण आढळली',
        descriptionEn:
            '$consecutiveDeclines consecutive weeks of declining compliance (${startPct.toStringAsFixed(1)}% → ${endPct.toStringAsFixed(1)}%, -$dropTotal pts), even if above target.',
        descriptionMr:
            'लक्ष्यापेक्षा जास्त असले तरी सलग $consecutiveDeclines आठवडे गुण घसरले (${startPct.toStringAsFixed(1)}% → ${endPct.toStringAsFixed(1)}%, -$dropTotal गुण).',
        severity: 'warning',
        metadata: {
          'consecutive_weeks': consecutiveDeclines,
          'start_pct': startPct,
          'end_pct': endPct,
          'drop_points': dropTotal,
          'start_week': series[startIndex].weekNumber,
          'end_week': series[endIndex].weekNumber,
        },
      );
    }

    return null;
  }

  /// Detects Single-SOP Decay pattern (Spec §4.5):
  /// "one SOP failing ≥1 checkpoint every week for 4 consecutive weeks while the aggregate stays healthy"
  /// Requires at least 4 consecutive weeks of data.
  static List<TrendPattern> detectSingleSopDecay(
    List<WeeklyDataPoint> series, {
    double aggregateHealthyThreshold = 85.0,
  }) {
    if (series.length < 4) return const [];

    // Consider the most recent 4 weeks
    final window = series.sublist(series.length - 4);

    // Verify aggregate stays healthy across the window
    final avgAggregate = window.map((w) => w.overallPct).reduce((a, b) => a + b) / 4.0;
    if (avgAggregate < aggregateHealthyThreshold) {
      return const [];
    }

    // Collect all unique SOP IDs present in the window
    final allSopIds = <String>{};
    for (final w in window) {
      allSopIds.addAll(w.perSopPct.keys);
    }

    final patterns = <TrendPattern>[];

    for (final sopId in allSopIds) {
      // Check if this SOP failed >=1 checkpoint (or compliance < 100%) in all 4 consecutive weeks
      bool failedEveryWeek = true;
      final weeklyPcts = <double>[];

      for (final w in window) {
        final pct = w.perSopPct[sopId] ?? 100.0;
        // Use perSopFailCount as authoritative when key exists;
        // only fall back to pct-based heuristic when key is absent.
        final int fails;
        if (w.perSopFailCount.containsKey(sopId)) {
          fails = w.perSopFailCount[sopId]!;
        } else {
          fails = pct < 100.0 ? 1 : 0;
        }
        weeklyPcts.add(pct);

        if (fails <= 0) {
          failedEveryWeek = false;
          break;
        }
      }

      if (failedEveryWeek) {
        final avgSopPct = (weeklyPcts.reduce((a, b) => a + b) / 4.0).toStringAsFixed(1);
        patterns.add(
          TrendPattern(
            type: TrendPatternType.singleSopDecay,
            nameEn: 'Single-SOP Decay: SOP $sopId',
            nameMr: 'एकाच SOP चा घसरता कल: SOP $sopId',
            descriptionEn:
                'SOP $sopId recorded failures in 4 consecutive weeks (avg: $avgSopPct%) while aggregate store compliance remained healthy (${avgAggregate.toStringAsFixed(1)}%). Review rolling 4-week SOP graph.',
            descriptionMr:
                'एकूण स्टोअर पालन निरोगी (${avgAggregate.toStringAsFixed(1)}%) असताना SOP $sopId मध्ये सलग ४ आठवडे त्रुटी आढळल्या (सरासरी: $avgSopPct%). रोलिंग ४-आठवडे आलेखाचे पुनरावलोकन करा.',
            severity: 'warning',
            metadata: {
              'sop_id': sopId,
              'window_weeks': window.map((w) => w.weekNumber).toList(),
              'sop_pcts': weeklyPcts,
              'avg_sop_pct': double.parse(avgSopPct),
              'avg_aggregate': double.parse(avgAggregate.toStringAsFixed(1)),
            },
          ),
        );
      }
    }

    return patterns;
  }

  /// Detects Day-of-Week Clustering pattern (Spec §4.5):
  /// "Fri/Sat consistently 3–5 pts below Mon–Thu"
  /// Analyzes submitted daily audits from the monthly period.
  static TrendPattern? detectDayOfWeekClustering(
    List<Audit> dailyAudits, {
    double minDeltaThreshold = 3.0,
  }) {
    if (dailyAudits.isEmpty) return null;

    final weekdayPcts = <double>[]; // Mon (1) to Thu (4)
    final weekendPcts = <double>[]; // Fri (5) to Sat (6)

    for (final audit in dailyAudits) {
      if (audit.auditType != 'daily' || audit.compliancePct == null) continue;
      final dt = DateTime.tryParse(audit.auditDate);
      if (dt == null) continue;

      if (dt.weekday >= DateTime.monday && dt.weekday <= DateTime.thursday) {
        weekdayPcts.add(audit.compliancePct!);
      } else if (dt.weekday == DateTime.friday || dt.weekday == DateTime.saturday) {
        weekendPcts.add(audit.compliancePct!);
      }
    }

    // Require sufficient representation (at least 4 weekdays and 2 weekend days)
    if (weekdayPcts.length < 4 || weekendPcts.length < 2) {
      return null;
    }

    final avgWeekday = weekdayPcts.reduce((a, b) => a + b) / weekdayPcts.length;
    final avgWeekend = weekendPcts.reduce((a, b) => a + b) / weekendPcts.length;
    final delta = avgWeekday - avgWeekend;

    if (delta >= minDeltaThreshold) {
      final deltaFixed = delta.toStringAsFixed(1);
      final weekdayFixed = avgWeekday.toStringAsFixed(1);
      final weekendFixed = avgWeekend.toStringAsFixed(1);

      return TrendPattern(
        type: TrendPatternType.dayOfWeekClustering,
        nameEn: 'Day-of-Week Clustering (Fri/Sat Drop)',
        nameMr: 'आठवड्याच्या ठरावीक दिवसांची घसरण (शुक्र/शनि)',
        descriptionEn:
            'Weekend compliance (Fri/Sat avg: $weekendFixed%) is $deltaFixed points lower than weekday compliance (Mon–Thu avg: $weekdayFixed%). Indicates staffing, rush, or closing fatigue.',
        descriptionMr:
            'आठवड्याच्या अखेरचे पालन (शुक्र/शनि सरासरी: $weekendFixed%) सोमवार–गुरुवारच्या सरासरीपेक्षा ($weekdayFixed%) $deltaFixed गुणांनी कमी आहे. कर्मचारी संख्या किंवा गर्दीचा ताण दर्शवते.',
        severity: 'warning',
        metadata: {
          'avg_weekday': double.parse(weekdayFixed),
          'avg_weekend': double.parse(weekendFixed),
          'delta': double.parse(deltaFixed),
          'weekday_count': weekdayPcts.length,
          'weekend_count': weekendPcts.length,
        },
      );
    }

    return null;
  }

  /// Detects Volatility pattern (Spec §4.1: "92/88/94/89 → volatility is the finding").
  /// Measures week-to-week volatility when swings are large (> 5% swing or high standard deviation).
  static TrendPattern? detectVolatility(
    List<WeeklyDataPoint> series, {
    double minStdDev = 3.0,
    double minSwing = 5.0,
  }) {
    if (series.length < 4) return null;

    final pcts = series.map((s) => s.overallPct).toList();
    final mean = pcts.reduce((a, b) => a + b) / pcts.length;

    double varianceSum = 0.0;
    for (final p in pcts) {
      varianceSum += math.pow(p - mean, 2);
    }
    final stdDev = math.sqrt(varianceSum / pcts.length);

    // Also count week-to-week absolute swings
    int bigSwings = 0;
    for (var i = 1; i < pcts.length; i++) {
      if ((pcts[i] - pcts[i - 1]).abs() >= minSwing) {
        bigSwings++;
      }
    }

    if (stdDev >= minStdDev || bigSwings >= 2) {
      final stdDevFixed = stdDev.toStringAsFixed(1);
      final meanFixed = mean.toStringAsFixed(1);

      return TrendPattern(
        type: TrendPatternType.volatility,
        nameEn: 'High Volatility Finding',
        nameMr: 'उच्च अस्थिरता आढळली',
        descriptionEn:
            'Weekly compliance shows high volatility (σ = $stdDevFixed%, mean = $meanFixed%). Swings > $minSwing% between consecutive weeks indicate process inconsistency.',
        descriptionMr:
            'साप्ताहिक पालनात उच्च अस्थिरता दिसून येते (σ = $stdDevFixed%, सरासरी = $meanFixed%). लागोपाठच्या आठवड्यांमधील $minSwing% पेक्षा जास्त चढ-उतार प्रक्रियेतील विसंगती दर्शवतात.',
        severity: 'info',
        metadata: {
          'std_dev': double.parse(stdDevFixed),
          'mean': double.parse(meanFixed),
          'big_swings': bigSwings,
        },
      );
    }

    return null;
  }

  /// Calculates Month-over-Month (MoM) delta between current 4-week MA and prior window (Spec derivation §3.3).
  static double? calculateMomDelta(List<WeeklyDataPoint> series) {
    if (series.length < 8) {
      // If we don't have 8 weeks, compare second half vs first half if at least 4 weeks
      if (series.length >= 4) {
        final mid = series.length ~/ 2;
        final firstHalf = series.sublist(0, mid);
        final secondHalf = series.sublist(mid);
        if (firstHalf.isEmpty || secondHalf.isEmpty) return null;
        final avg1 = firstHalf.map((s) => s.overallPct).reduce((a, b) => a + b) / firstHalf.length;
        final avg2 = secondHalf.map((s) => s.overallPct).reduce((a, b) => a + b) / secondHalf.length;
        return double.parse((avg2 - avg1).toStringAsFixed(1));
      }
      return null;
    }

    // With 8+ weeks, compare last 4 weeks average vs prior 4 weeks average
    final currentMonth = series.sublist(series.length - 4);
    final priorMonth = series.sublist(series.length - 8, series.length - 4);

    final avgCur = currentMonth.map((s) => s.overallPct).reduce((a, b) => a + b) / 4.0;
    final avgPrior = priorMonth.map((s) => s.overallPct).reduce((a, b) => a + b) / 4.0;

    return double.parse((avgCur - avgPrior).toStringAsFixed(1));
  }

  /// Executes full multi-week trend analytics over weekly reports and daily audits.
  static TrendAnalysisResult analyze({
    required List<Report> weeklyReports,
    List<Audit> dailyAudits = const [],
  }) {
    final series = buildWeeklySeries(weeklyReports);
    final movingAverages = computeFourWeekMovingAverages(series);
    final hasSufficientData = series.length >= 4;

    final detectedPatterns = <TrendPattern>[];

    final slowSlide = detectSlowSlide(series);
    if (slowSlide != null) detectedPatterns.add(slowSlide);

    final singleSopPatterns = detectSingleSopDecay(series);
    detectedPatterns.addAll(singleSopPatterns);

    final dayClustering = detectDayOfWeekClustering(dailyAudits);
    if (dayClustering != null) detectedPatterns.add(dayClustering);

    final volatility = detectVolatility(series);
    if (volatility != null) detectedPatterns.add(volatility);

    final momDelta = calculateMomDelta(series);

    // Compute volatility score (stdDev)
    double? volatilityScore;
    if (series.length >= 2) {
      final pcts = series.map((s) => s.overallPct).toList();
      final mean = pcts.reduce((a, b) => a + b) / pcts.length;
      double vSum = 0.0;
      for (final p in pcts) {
        vSum += math.pow(p - mean, 2);
      }
      volatilityScore = double.parse(math.sqrt(vSum / pcts.length).toStringAsFixed(1));
    }

    return TrendAnalysisResult(
      weeklySeries: series,
      movingAverages: movingAverages,
      detectedPatterns: detectedPatterns,
      momDelta: momDelta,
      hasSufficientData: hasSufficientData,
      volatilityScore: volatilityScore,
    );
  }
}
