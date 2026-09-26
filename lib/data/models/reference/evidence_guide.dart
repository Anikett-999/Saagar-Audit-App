/// A strong vs weak evidence comparison pair matching Workbook Appendix A.6.
class EvidencePair {
  const EvidencePair({
    required this.id,
    required this.strongEn,
    required this.strongMr,
    required this.weakEn,
    required this.weakMr,
  });

  factory EvidencePair.fromJson(Map<String, dynamic> json) {
    return EvidencePair(
      id: json['id'] as int,
      strongEn: json['strong_en'] as String,
      strongMr: json['strong_mr'] as String,
      weakEn: json['weak_en'] as String,
      weakMr: json['weak_mr'] as String,
    );
  }

  final int id;
  final String strongEn;
  final String strongMr;
  final String weakEn;
  final String weakMr;

  String strong(String locale) => locale == 'mr' ? strongMr : strongEn;
  String weak(String locale) => locale == 'mr' ? weakMr : weakEn;
}

/// Warning banner at the bottom of the evidence table.
class EvidenceWarningBanner {
  const EvidenceWarningBanner({
    required this.textEn,
    required this.textMr,
  });

  factory EvidenceWarningBanner.fromJson(Map<String, dynamic> json) {
    return EvidenceWarningBanner(
      textEn: json['text_en'] as String,
      textMr: json['text_mr'] as String,
    );
  }

  final String textEn;
  final String textMr;

  String text(String locale) => locale == 'mr' ? textMr : textEn;
}

/// Complete Evidence Guide model matching `evidence.json`.
class EvidenceGuide {
  const EvidenceGuide({
    required this.titleEn,
    required this.titleMr,
    required this.subtitleEn,
    required this.subtitleMr,
    required this.pairs,
    required this.warningBanner,
  });

  factory EvidenceGuide.fromJson(Map<String, dynamic> json) {
    return EvidenceGuide(
      titleEn: json['title_en'] as String,
      titleMr: json['title_mr'] as String,
      subtitleEn: json['subtitle_en'] as String,
      subtitleMr: json['subtitle_mr'] as String,
      pairs: (json['pairs'] as List<dynamic>)
          .map((p) => EvidencePair.fromJson(p as Map<String, dynamic>))
          .toList(),
      warningBanner: EvidenceWarningBanner.fromJson(
        json['warning_banner'] as Map<String, dynamic>,
      ),
    );
  }

  final String titleEn;
  final String titleMr;
  final String subtitleEn;
  final String subtitleMr;
  final List<EvidencePair> pairs;
  final EvidenceWarningBanner warningBanner;

  String title(String locale) => locale == 'mr' ? titleMr : titleEn;
  String subtitle(String locale) => locale == 'mr' ? subtitleMr : subtitleEn;
}
