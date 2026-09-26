import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/reference/reference_models.dart';
import '../../../data/repositories/reference_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S26 — Reference: Bilingual Glossary (Spec §5 S26, §11.4 & Workbook Appendix A.7).
///
/// Features:
/// 1. 65 bilingual retail & audit terms with English and Marathi definitions.
/// 2. Real-time live search filter matching terms and definitions in both English and Marathi (Devanagari).
/// 3. Dynamic results count indicator ("Showing X of 65 terms").
/// 4. Zero-match empty state with quick search reset.
/// 5. Handbook header banner with Appendix A.7 badge.
/// 6. Fully responsive layout with Wrap discipline for small screen safety.
class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GlossaryEntry> _allEntries = [];
  List<GlossaryEntry> _filteredEntries = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cached = ReferenceRepository.instance.cachedGlossary;
    if (cached != null) {
      _allEntries = cached;
      _filteredEntries = cached;
      _loading = false;
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceReload = false}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(referenceRepositoryProvider);
      final entries = await repo.loadGlossary(forceReload: forceReload);
      if (!mounted) return;
      setState(() {
        _allEntries = entries;
        _loading = false;
      });
      _onSearchChanged(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredEntries = _allEntries;
      } else {
        _filteredEntries =
            _allEntries.where((entry) => entry.matches(clean)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s26Title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('s22_reference_index');
            }
          },
        ),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(forceReload: true),
          ),
        ],
      ),
      body: _buildBody(context, l10n, locale),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.s26Loading,
              style: const TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                l10n.s26Error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.s26Retry),
                onPressed: () => _loadData(forceReload: true),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderBanner(context, l10n),
        const SizedBox(height: 16),
        _buildSearchBar(l10n),
        const SizedBox(height: 12),
        _buildStatusRow(l10n),
        const SizedBox(height: 12),
        if (_filteredEntries.isEmpty)
          _buildEmptyState(l10n)
        else
          ..._filteredEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGlossaryCard(entry, l10n, locale),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeaderBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyLight.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.s26Title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyLight.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.navyLight.withAlpha(60),
                        ),
                      ),
                      child: Text(
                        l10n.s22CardBadgeAppendix('A.7'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.s26HeaderSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return TextField(
      key: const Key('s26_search_input'),
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: l10n.s26SearchHint,
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.gray600),
        prefixIcon: const Icon(Icons.search, color: AppColors.navy),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                key: const Key('s26_clear_search_btn'),
                icon: const Icon(Icons.clear, size: 20, color: AppColors.gray600),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildStatusRow(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navy.withAlpha(12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.navy.withAlpha(35)),
          ),
          child: Text(
            l10n.s26ShowingCount(_filteredEntries.length, _allEntries.length),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
        ),
        if (_searchController.text.isNotEmpty)
          TextButton(
            key: const Key('s26_clear_search_text_btn'),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.s26ClearSearch,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.navyLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlossaryCard(
    GlossaryEntry entry,
    AppLocalizations l10n,
    String locale,
  ) {
    final isMr = locale == 'mr';
    final primaryMeaning = isMr ? entry.meaningMr : entry.meaningEn;
    final secondaryMeaning = isMr ? entry.meaningEn : entry.meaningMr;
    final primaryBadge = isMr ? l10n.s26MarathiLabel : l10n.s26EnglishLabel;
    final secondaryBadge = isMr ? l10n.s26EnglishLabel : l10n.s26MarathiLabel;

    return Card(
      key: Key('s26_item_${entry.en}'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terms Header with Wrap for small screens
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Text(
                        entry.en,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyLight.withAlpha(16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.navyLight.withAlpha(45),
                          ),
                        ),
                        child: Text(
                          entry.mr,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.gray200),
            const SizedBox(height: 10),

            // Primary definition (active locale)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    primaryBadge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    primaryMeaning,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Secondary definition (alternate locale)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    secondaryBadge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    secondaryMeaning,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.gray600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      key: const Key('s26_empty_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.s26EmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.s26EmptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.gray600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('s26_empty_clear_btn'),
            icon: const Icon(Icons.clear, size: 18),
            label: Text(l10n.s26ClearSearch),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
            ),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
        ],
      ),
    );
  }
}
