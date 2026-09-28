/// Pure pattern-detection engine for weekly audit analysis (Spec §5 T2.4 & Workbook Day 3 §3.6).
library;

/// Represents a single failure occurrence on a daily audit.
class DailyFailPoint {
  const DailyFailPoint({
    required this.checkpointId,
    required this.auditDate,
    this.findingText,
    this.croId,
  });

  final String checkpointId;
  final String auditDate; // YYYY-MM-DD
  final String? findingText;
  final String? croId;
}

/// Represents a cross-day failure pattern detected across the week's daily audits (T2.4).
class PatternFinding {
  const PatternFinding({
    required this.checkpointId,
    required this.failCount,
    required this.dates,
    required this.weekdaysEn,
    required this.weekdaysMr,
    this.findings = const [],
  });

  factory PatternFinding.fromJson(Map<String, Object?> map) => PatternFinding(
        checkpointId: map['checkpoint_id']! as String,
        failCount: map['fail_count']! as int,
        dates: (map['dates'] as List).cast<String>(),
        weekdaysEn: (map['weekdays_en'] as List).cast<String>(),
        weekdaysMr: (map['weekdays_mr'] as List).cast<String>(),
        findings: ((map['findings'] as List?) ?? const []).cast<String>(),
      );

  final String checkpointId;
  final int failCount;
  final List<String> dates; // Sorted YYYY-MM-DD
  final List<String> weekdaysEn; // ['Mon', 'Tue', 'Wed']
  final List<String> weekdaysMr; // ['सोम', 'मंगळ', 'बुध']
  final List<String> findings;

  /// Formatted description by language code ('en' or 'mr') matching Spec §5 T2.4.
  String formattedDescription(String lang) {
    if (lang == 'mr') {
      final days = weekdaysMr.join(', ');
      return 'तपासणी बिंदू $checkpointId $failCount दिवस अयशस्वी ($days) — पॅटर्न';
    }
    final days = weekdaysEn.join(', ');
    return 'Checkpoint $checkpointId failed on $failCount days ($days) — pattern';
  }

  /// English summary of the pattern per Spec §5 T2.4.
  String get summaryEn => formattedDescription('en');

  /// Marathi summary of the pattern per Rule #8 dual-language parity.
  String get summaryMr => formattedDescription('mr');

  /// Maps 1:1 to exactly ONE suggested Pattern CAP per T2.4 single-CAP rule.
  SuggestedPatternCap toSuggestedCap() {
    final daysEn = weekdaysEn.join(', ');
    final daysMr = weekdaysMr.join(', ');
    return SuggestedPatternCap(
      checkpointId: checkpointId,
      failCount: failCount,
      problemStatementEn:
          'Recurring pattern: Checkpoint $checkpointId failed on $failCount days ($daysEn)',
      problemStatementMr:
          'वारंवार आढळणारा पॅटर्न: तपासणी बिंदू $checkpointId $failCount दिवस अयशस्वी ($daysMr)',
      suggestedActionEn:
          'Conduct refresher briefing for store staff on Checkpoint $checkpointId and monitor daily compliance.',
      suggestedActionMr:
          'तपासणी बिंदू $checkpointId वर स्टोअर कर्मचाऱ्यांसाठी उजळणी मार्गदर्शन आयोजित करा आणि दैनंदिन पालनाचे निरीक्षण करा.',
    );
  }

  Map<String, Object?> toJson() => {
        'checkpoint_id': checkpointId,
        'fail_count': failCount,
        'dates': dates,
        'weekdays_en': weekdaysEn,
        'weekdays_mr': weekdaysMr,
        'findings': findings,
      };
}

/// A suggested CAP for a detected pattern (Spec §5 T2.4).
class SuggestedPatternCap {
  const SuggestedPatternCap({
    required this.checkpointId,
    required this.failCount,
    required this.problemStatementEn,
    required this.problemStatementMr,
    required this.suggestedActionEn,
    required this.suggestedActionMr,
  });

  factory SuggestedPatternCap.fromJson(Map<String, Object?> map) =>
      SuggestedPatternCap(
        checkpointId: map['checkpoint_id']! as String,
        failCount: map['fail_count']! as int,
        problemStatementEn: map['problem_statement_en']! as String,
        problemStatementMr: map['problem_statement_mr']! as String,
        suggestedActionEn: map['suggested_action_en']! as String,
        suggestedActionMr: map['suggested_action_mr']! as String,
      );

  final String checkpointId;
  final int failCount;
  final String problemStatementEn;
  final String problemStatementMr;
  final String suggestedActionEn;
  final String suggestedActionMr;

  Map<String, Object?> toJson() => {
        'checkpoint_id': checkpointId,
        'fail_count': failCount,
        'problem_statement_en': problemStatementEn,
        'problem_statement_mr': problemStatementMr,
        'suggested_action_en': suggestedActionEn,
        'suggested_action_mr': suggestedActionMr,
      };
}

/// Pure pattern-detection engine (Spec §5 T2.4 & Workbook Day 3 §3.6).
///
/// Examines all failure points from the week's daily audits.
/// Any checkpoint failing on >= 3 distinct audit dates triggers a [PatternFinding].
List<PatternFinding> detectWeeklyPatterns(List<DailyFailPoint> failPoints) {
  // 1. Group fail points by checkpointId
  final Map<String, List<DailyFailPoint>> byCheckpoint = {};
  for (final fp in failPoints) {
    byCheckpoint.putIfAbsent(fp.checkpointId, () => []).add(fp);
  }

  final List<PatternFinding> patterns = [];

  for (final entry in byCheckpoint.entries) {
    final cpId = entry.key;
    final points = entry.value;

    // Distinct dates on which this checkpoint failed
    final distinctDates = points.map((p) => p.auditDate).toSet().toList()..sort();

    // Spec T2.4 rule: failure on >= 3 distinct days triggers a pattern
    if (distinctDates.length >= 3) {
      final List<String> weekdaysEn = [];
      final List<String> weekdaysMr = [];
      final List<String> findings = [];

      for (final dateStr in distinctDates) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          weekdaysEn.add(_weekdayShortEn(parsed.weekday));
          weekdaysMr.add(_weekdayShortMr(parsed.weekday));
        }

        // Collect finding texts for this date
        final matchedPoints = points.where((p) => p.auditDate == dateStr);
        for (final mp in matchedPoints) {
          if (mp.findingText != null && mp.findingText!.isNotEmpty) {
            findings.add(mp.findingText!);
          }
        }
      }

      patterns.add(
        PatternFinding(
          checkpointId: cpId,
          failCount: distinctDates.length,
          dates: distinctDates,
          weekdaysEn: weekdaysEn,
          weekdaysMr: weekdaysMr,
          findings: findings,
        ),
      );
    }
  }

  // Sort by failCount DESC, then checkpointId ASC
  patterns.sort((a, b) {
    final c = b.failCount.compareTo(a.failCount);
    if (c != 0) return c;
    return a.checkpointId.compareTo(b.checkpointId);
  });

  return patterns;
}

String _weekdayShortEn(int weekday) {
  return switch (weekday) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    7 => 'Sun',
    _ => '',
  };
}

String _weekdayShortMr(int weekday) {
  return switch (weekday) {
    1 => 'सोम',
    2 => 'मंगळ',
    3 => 'बुध',
    4 => 'गुरू',
    5 => 'शुक्र',
    6 => 'शनि',
    7 => 'रवि',
    _ => '',
  };
}
