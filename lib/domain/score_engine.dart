/// Score engine for daily audits (Spec §6.1 – §6.4).
///
/// Pure functions only — no IO, no database. Audit submission code wires
/// the engine's output back to the `audits` table.
///
/// Hard rule (Spec §14.1 Rule #4): canonical test cases MUST pass. The
/// Workbook §5.1 daily case must produce 81 / 90 = 90.0% Good exactly.
library;

/// A single audit result for scoring. `weight` is copied from the
/// checkpoint definition so this engine has no DB dependency.
class CheckpointMark {
  const CheckpointMark({
    required this.checkpointId,
    required this.result,
    required this.weight,
  });

  final String checkpointId;
  final Verdict result;
  final int weight; // 1 or 2

  /// `null` for NA (excluded from both numerator and denominator per §6.4).
  /// `0` for F, `weight` for P.
  double? get weightedPoints {
    switch (result) {
      case Verdict.pass:
        return weight.toDouble();
      case Verdict.fail:
        return 0.0;
      case Verdict.na:
        return null;
    }
  }
}

enum Verdict { pass, fail, na }

enum Band { excellent, good, fair, poor, critical }

/// Output of scoring a daily audit.
class ScoreResult {
  const ScoreResult({
    required this.rawScore,
    required this.maxScore,
    required this.compliancePct,
    required this.band,
    required this.passCount,
    required this.failCount,
    required this.naCount,
  });

  final double rawScore;
  final double maxScore;
  final double compliancePct; // 1 decimal, never round before band calc
  final Band band;
  final int passCount;
  final int failCount;
  final int naCount;

  @override
  String toString() =>
      'ScoreResult(raw=$rawScore, max=$maxScore, pct=$compliancePct%, band=$band, '
      'P=$passCount F=$failCount NA=$naCount)';
}

/// Computes a daily audit score per Spec §6.1.
ScoreResult scoreDaily(List<CheckpointMark> marks) {
  if (marks.isEmpty) {
    throw ArgumentError('scoreDaily: must have at least one mark');
  }

  var rawScore = 0.0;
  var maxScore = 0.0;
  var pass = 0;
  var fail = 0;
  var na = 0;

  for (final m in marks) {
    switch (m.result) {
      case Verdict.pass:
        rawScore += m.weight;
        maxScore += m.weight;
        pass++;
      case Verdict.fail:
        // raw += 0, but max still counts the weight
        maxScore += m.weight;
        fail++;
      case Verdict.na:
        // Excluded from both — touch nothing
        na++;
    }
  }

  if (maxScore == 0) {
    // Every mark was NA — undefined compliance. Per spec ambiguity, treat as
    // Excellent (no Fails) rather than divide-by-zero. Will need confirmation
    // from Sagar if this edge case ever surfaces in real data.
    return ScoreResult(
      rawScore: 0,
      maxScore: 0,
      compliancePct: 100.0,
      band: Band.excellent,
      passCount: pass,
      failCount: fail,
      naCount: na,
    );
  }

  // Round to 1 decimal — `band` then derived from the rounded value per §6.2.
  // Using `round` (banker's would change the math at boundaries).
  final pct = _round1((rawScore / maxScore) * 100.0);
  final band = bandFromCompliance(pct);

  return ScoreResult(
    rawScore: rawScore,
    maxScore: maxScore,
    compliancePct: pct,
    band: band,
    passCount: pass,
    failCount: fail,
    naCount: na,
  );
}

/// Strict band boundaries per Spec §6.2.
/// 89.9 → fair, 84.9 → poor, 79.9 → critical. Always use the rounded pct.
Band bandFromCompliance(double pct) {
  if (pct >= 95.0) return Band.excellent;
  if (pct >= 90.0) return Band.good;
  if (pct >= 85.0) return Band.fair;
  if (pct >= 80.0) return Band.poor;
  return Band.critical;
}

/// Output of scoring a weekly audit (Spec §6.5 – §6.7).
class WeeklyScoreResult {
  const WeeklyScoreResult({
    required this.dailyPcts,
    required this.avgDailyPct,
    required this.dailyContribution,
    required this.weeklyRaw,
    required this.weeklyMax,
    required this.totalRaw,
    required this.totalMax,
    required this.compliancePct,
    required this.band,
    required this.passCount,
    required this.failCount,
    required this.naCount,
  });

  final List<double> dailyPcts;
  final double avgDailyPct;
  final double dailyContribution; // out of 68
  final double weeklyRaw;
  final double weeklyMax;
  final double totalRaw;
  final double totalMax; // 68 + weeklyMax
  final double compliancePct; // 1 decimal
  final Band band;
  final int passCount;
  final int failCount;
  final int naCount;

  @override
  String toString() =>
      'WeeklyScoreResult(dailyContrib=$dailyContribution/68 (avg=$avgDailyPct%), '
      'weeklyRaw=$weeklyRaw/$weeklyMax, total=$totalRaw/$totalMax, '
      'pct=$compliancePct%, band=$band, P=$passCount F=$failCount NA=$naCount)';
}

/// Output of computing cumulative weekly cash variance (CW.7, Spec §6.7).
class CumulativeVarianceResult {
  const CumulativeVarianceResult({
    required this.dailyVariances,
    required this.netVarianceRupees,
    required this.isBreached,
    this.thresholdRupees = 200.0,
  });

  final List<double> dailyVariances;
  final double netVarianceRupees;
  final bool isBreached;
  final double thresholdRupees;

  @override
  String toString() =>
      'CumulativeVarianceResult(net=₹$netVarianceRupees, breached=$isBreached, '
      'threshold=±₹$thresholdRupees)';
}

/// Computes a weekly audit score per Spec §6.5.
///
/// 1. Daily-average contribution (out of 68):
///    - Takes 7 daily compliance percentages (missing day = 0.0).
///    - avgDailyPct = round1(sum(dailyPcts) / 7.0)
///    - dailyContribution = round1(avgDailyPct / 100.0 * 68.0)
/// 2. Weekly-only checkpoints (max 56 if no NAs):
///    - weeklyRaw = sum(weighted_points for PASS)
///    - weeklyMax = sum(weight for PASS/FAIL, NA excluded)
/// 3. Combine:
///    - totalRaw = dailyContribution + weeklyRaw
///    - totalMax = 68.0 + weeklyMax
///    - compliancePct = round1(totalRaw / totalMax * 100.0)
///    - band = bandFromCompliance(compliancePct)
WeeklyScoreResult computeWeeklyScore({
  required List<double> dailyPcts,
  required List<CheckpointMark> weeklyMarks,
}) {
  if (dailyPcts.length > 7) {
    throw ArgumentError('dailyPcts cannot contain more than 7 days');
  }

  // Pad to 7 days if fewer provided (missing days = 0.0)
  final pcts = List<double>.filled(7, 0.0);
  for (var i = 0; i < dailyPcts.length; i++) {
    pcts[i] = dailyPcts[i];
  }

  final dailySum = pcts.fold(0.0, (acc, p) => acc + p);
  final avgDailyPct = round1(dailySum / 7.0);
  final dailyContribution = round1(avgDailyPct / 100.0 * 68.0);

  var weeklyRaw = 0.0;
  var weeklyMax = 0.0;
  var pass = 0;
  var fail = 0;
  var na = 0;

  for (final m in weeklyMarks) {
    switch (m.result) {
      case Verdict.pass:
        weeklyRaw += m.weight;
        weeklyMax += m.weight;
        pass++;
      case Verdict.fail:
        weeklyMax += m.weight;
        fail++;
      case Verdict.na:
        na++;
    }
  }

  final totalRaw = round1(dailyContribution + weeklyRaw);
  final totalMax = round1(68.0 + weeklyMax);
  final compliancePct =
      totalMax > 0 ? round1((totalRaw / totalMax) * 100.0) : 100.0;
  final band = bandFromCompliance(compliancePct);

  return WeeklyScoreResult(
    dailyPcts: List.unmodifiable(pcts),
    avgDailyPct: avgDailyPct,
    dailyContribution: dailyContribution,
    weeklyRaw: weeklyRaw,
    weeklyMax: weeklyMax,
    totalRaw: totalRaw,
    totalMax: totalMax,
    compliancePct: compliancePct,
    band: band,
    passCount: pass,
    failCount: fail,
    naCount: na,
  );
}

/// Computes cumulative weekly cash variance per CW.7 / Spec §6.7.
///
/// Signed sum of daily cash variances across the 7 dates (+ over, - short).
/// Flags a breach when the absolute net variance exceeds [thresholdRupees] (default ±₹200).
CumulativeVarianceResult computeCumulativeWeeklyVariance(
  List<double> dailyVariances, {
  double thresholdRupees = 200.0,
}) {
  final net = dailyVariances.fold(0.0, (acc, v) => acc + v);
  final roundedNet = round1(net);
  final isBreached = roundedNet.abs() > thresholdRupees;

  return CumulativeVarianceResult(
    dailyVariances: List.unmodifiable(dailyVariances),
    netVarianceRupees: roundedNet,
    isBreached: isBreached,
    thresholdRupees: thresholdRupees,
  );
}

double round1(double v) => (v * 10).round() / 10.0;
double _round1(double v) => round1(v);

