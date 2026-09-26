/// Compliance band model matching Workbook Appendix A.4 and score engine cutoffs.
class ComplianceBand {
  const ComplianceBand({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.rangeEn,
    required this.rangeMr,
    required this.minPercentage,
    required this.maxPercentage,
    required this.color,
    required this.actionEn,
    required this.actionMr,
    required this.whoActsEn,
    required this.whoActsMr,
  });

  factory ComplianceBand.fromJson(Map<String, dynamic> json) {
    return ComplianceBand(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameMr: json['name_mr'] as String,
      rangeEn: json['range_en'] as String,
      rangeMr: json['range_mr'] as String,
      minPercentage: (json['min_percentage'] as num).toDouble(),
      maxPercentage: (json['max_percentage'] as num).toDouble(),
      color: json['color'] as String,
      actionEn: json['action_en'] as String,
      actionMr: json['action_mr'] as String,
      whoActsEn: json['who_acts_en'] as String,
      whoActsMr: json['who_acts_mr'] as String,
    );
  }

  final String id;
  final String nameEn;
  final String nameMr;
  final String rangeEn;
  final String rangeMr;
  final double minPercentage;
  final double maxPercentage;
  final String color;
  final String actionEn;
  final String actionMr;
  final String whoActsEn;
  final String whoActsMr;

  String name(String locale) => locale == 'mr' ? nameMr : nameEn;
  String range(String locale) => locale == 'mr' ? rangeMr : rangeEn;
  String action(String locale) => locale == 'mr' ? actionMr : actionEn;
  String whoActs(String locale) => locale == 'mr' ? whoActsMr : whoActsEn;
}

/// Tier-specific audit target matching Workbook Appendix A.4.
class TierTarget {
  const TierTarget({
    required this.tierEn,
    required this.tierMr,
    required this.auditorEn,
    required this.auditorMr,
    required this.targetPctEn,
    required this.targetPctMr,
    required this.totalPointsEn,
    required this.totalPointsMr,
    required this.passPointsEn,
    required this.passPointsMr,
  });

  factory TierTarget.fromJson(Map<String, dynamic> json) {
    return TierTarget(
      tierEn: json['tier_en'] as String,
      tierMr: json['tier_mr'] as String,
      auditorEn: json['auditor_en'] as String,
      auditorMr: json['auditor_mr'] as String,
      targetPctEn: json['target_pct_en'] as String,
      targetPctMr: json['target_pct_mr'] as String,
      totalPointsEn: json['total_points_en'] as String,
      totalPointsMr: json['total_points_mr'] as String,
      passPointsEn: json['pass_points_en'] as String,
      passPointsMr: json['pass_points_mr'] as String,
    );
  }

  final String tierEn;
  final String tierMr;
  final String auditorEn;
  final String auditorMr;
  final String targetPctEn;
  final String targetPctMr;
  final String totalPointsEn;
  final String totalPointsMr;
  final String passPointsEn;
  final String passPointsMr;

  String tier(String locale) => locale == 'mr' ? tierMr : tierEn;
  String auditor(String locale) => locale == 'mr' ? auditorMr : auditorEn;
  String targetPct(String locale) => locale == 'mr' ? targetPctMr : targetPctEn;
  String totalPoints(String locale) =>
      locale == 'mr' ? totalPointsMr : totalPointsEn;
  String passPoints(String locale) =>
      locale == 'mr' ? passPointsMr : passPointsEn;
}

/// Critical scoring reminder notice.
class ReminderNotice {
  const ReminderNotice({
    required this.titleEn,
    required this.titleMr,
    required this.textEn,
    required this.textMr,
  });

  factory ReminderNotice.fromJson(Map<String, dynamic> json) {
    return ReminderNotice(
      titleEn: json['title_en'] as String,
      titleMr: json['title_mr'] as String,
      textEn: json['text_en'] as String,
      textMr: json['text_mr'] as String,
    );
  }

  final String titleEn;
  final String titleMr;
  final String textEn;
  final String textMr;

  String title(String locale) => locale == 'mr' ? titleMr : titleEn;
  String text(String locale) => locale == 'mr' ? textMr : textEn;
}

/// Complete Rating Scale model matching `rating_scale.json`.
class RatingScale {
  const RatingScale({
    required this.bands,
    required this.tierTargets,
    required this.reminder,
  });

  factory RatingScale.fromJson(Map<String, dynamic> json) {
    return RatingScale(
      bands: (json['bands'] as List<dynamic>)
          .map((b) => ComplianceBand.fromJson(b as Map<String, dynamic>))
          .toList(),
      tierTargets: (json['tier_targets'] as List<dynamic>)
          .map((t) => TierTarget.fromJson(t as Map<String, dynamic>))
          .toList(),
      reminder:
          ReminderNotice.fromJson(json['reminder'] as Map<String, dynamic>),
    );
  }

  final List<ComplianceBand> bands;
  final List<TierTarget> tierTargets;
  final ReminderNotice reminder;
}
