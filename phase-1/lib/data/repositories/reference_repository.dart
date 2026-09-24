import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reference/reference_models.dart';

/// Provider for accessing the [ReferenceRepository].
final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository.instance;
});

/// Repository for reading and caching bilingual reference assets (Screens S22–S26).
///
/// Follows Spec §5 (Screens S22–S26), Spec §11 (Reference Content), and
/// `brain/SPRINT_S22_S26_REFERENCE.md`.
///
/// Content is strictly read-only and loaded from bundled JSON assets under
/// `assets/reference/`.
class ReferenceRepository {
  ReferenceRepository({AssetBundle? bundle}) : _bundle = bundle;

  /// Singleton instance using default [rootBundle].
  static final ReferenceRepository instance = ReferenceRepository();

  final AssetBundle? _bundle;
  AssetBundle get bundle => _bundle ?? rootBundle;

  static const String ratingScalePath = 'assets/reference/rating_scale.json';
  static const String escalationTriggersPath =
      'assets/reference/escalation_triggers.json';
  static const String evidencePath = 'assets/reference/evidence.json';
  static const String glossaryPath = 'assets/reference/glossary.json';

  RatingScale? _cachedRatingScale;
  EscalationTriggers? _cachedEscalationTriggers;
  EvidenceGuide? _cachedEvidenceGuide;
  List<GlossaryEntry>? _cachedGlossary;

  /// Loads and caches the [RatingScale] (Workbook Appendix A.4).
  Future<RatingScale> loadRatingScale({bool forceReload = false}) async {
    if (_cachedRatingScale != null && !forceReload) {
      return _cachedRatingScale!;
    }
    final raw = await bundle.loadString(ratingScalePath);
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    _cachedRatingScale = RatingScale.fromJson(jsonMap);
    return _cachedRatingScale!;
  }

  /// Loads and caches the [EscalationTriggers] (Workbook Appendix A.5).
  Future<EscalationTriggers> loadEscalationTriggers({
    bool forceReload = false,
  }) async {
    if (_cachedEscalationTriggers != null && !forceReload) {
      return _cachedEscalationTriggers!;
    }
    final raw = await bundle.loadString(escalationTriggersPath);
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    _cachedEscalationTriggers = EscalationTriggers.fromJson(jsonMap);
    return _cachedEscalationTriggers!;
  }

  /// Loads and caches the [EvidenceGuide] (Workbook Appendix A.6).
  Future<EvidenceGuide> loadEvidenceGuide({bool forceReload = false}) async {
    if (_cachedEvidenceGuide != null && !forceReload) {
      return _cachedEvidenceGuide!;
    }
    final raw = await bundle.loadString(evidencePath);
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    _cachedEvidenceGuide = EvidenceGuide.fromJson(jsonMap);
    return _cachedEvidenceGuide!;
  }

  /// Loads and caches all [GlossaryEntry] rows (Workbook Appendix A.7).
  ///
  /// Guaranteed to return exactly 65 bilingual glossary entries.
  Future<List<GlossaryEntry>> loadGlossary({bool forceReload = false}) async {
    if (_cachedGlossary != null && !forceReload) {
      return _cachedGlossary!;
    }
    final raw = await bundle.loadString(glossaryPath);
    final jsonList = jsonDecode(raw) as List<dynamic>;
    _cachedGlossary = jsonList
        .map((item) => GlossaryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cachedGlossary!;
  }

  /// Searches the glossary with the specified [query].
  ///
  /// Filter logic:
  /// - Empty or whitespace query returns all 65 entries.
  /// - Case-insensitive match against [en], [mr], [meaningEn], and [meaningMr].
  /// - Seamlessly supports both Latin and Devanagari query strings.
  Future<List<GlossaryEntry>> searchGlossary(String query) async {
    final list = await loadGlossary();
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return list;
    return list.where((entry) => entry.matches(clean)).toList();
  }

  /// Clears in-memory cached assets.
  void clearCache() {
    _cachedRatingScale = null;
    _cachedEscalationTriggers = null;
    _cachedEvidenceGuide = null;
    _cachedGlossary = null;
  }
}
