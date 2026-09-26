/// A single bilingual glossary entry matching Workbook Appendix A.7 and Spec §11.4.
class GlossaryEntry {
  const GlossaryEntry({
    required this.en,
    required this.mr,
    required this.meaningEn,
    required this.meaningMr,
  });

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) {
    return GlossaryEntry(
      en: json['en'] as String,
      mr: json['mr'] as String,
      meaningEn: json['meaning_en'] as String,
      meaningMr: json['meaning_mr'] as String,
    );
  }

  final String en;
  final String mr;
  final String meaningEn;
  final String meaningMr;

  Map<String, dynamic> toJson() => {
        'en': en,
        'mr': mr,
        'meaning_en': meaningEn,
        'meaning_mr': meaningMr,
      };

  /// Returns the localized term.
  String term(String locale) => locale == 'mr' ? mr : en;

  /// Returns the localized meaning.
  String meaning(String locale) => locale == 'mr' ? meaningMr : meaningEn;

  /// Evaluates whether this entry matches the [query].
  ///
  /// Matches case-insensitively across [en], [mr], [meaningEn], and [meaningMr].
  /// An empty or whitespace-only query returns true.
  /// Seamlessly handles both Latin and Devanagari text.
  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    return en.toLowerCase().contains(clean) ||
        mr.toLowerCase().contains(clean) ||
        meaningEn.toLowerCase().contains(clean) ||
        meaningMr.toLowerCase().contains(clean);
  }
}
