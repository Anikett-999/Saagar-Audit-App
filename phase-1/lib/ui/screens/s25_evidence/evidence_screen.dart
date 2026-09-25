import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/reference/reference_models.dart';
import '../../../data/repositories/reference_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S25 — Reference: Strong vs Weak Evidence (Spec §5 S25, §11.3 & Workbook Appendix A.6).
///
/// Displays:
/// 1. 8 Evidence Standards (Strong Evidence vs Weak Evidence comparison pairs).
/// 2. Operational bottom warning banner ("Every finding must rest on strong evidence...").
class EvidenceScreen extends ConsumerStatefulWidget {
  const EvidenceScreen({super.key});

  @override
  ConsumerState<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends ConsumerState<EvidenceScreen> {
  EvidenceGuide? _guide;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cached = ReferenceRepository.instance.cachedEvidenceGuide;
    if (cached != null) {
      _guide = cached;
      _loading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData({bool forceReload = false}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(referenceRepositoryProvider);
      final guide = await repo.loadEvidenceGuide(forceReload: forceReload);
      if (!mounted) return;
      setState(() {
        _guide = guide;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s25Title),
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
              l10n.s25Loading,
              style: const TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _guide == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                l10n.s25Error,
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
                label: Text(l10n.s25Retry),
                onPressed: () => _loadData(forceReload: true),
              ),
            ],
          ),
        ),
      );
    }

    final guide = _guide!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildHeaderBanner(context, l10n),
        const SizedBox(height: 20),

        // Section header
        _buildSectionHeader(
          title: l10n.s25SectionPairsTitle,
          subtitle: l10n.s25SectionPairsSubtitle,
        ),
        const SizedBox(height: 10),

        // Subtitle context callout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navyLight.withAlpha(12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.navyLight.withAlpha(35)),
          ),
          child: Text(
            guide.subtitle(locale),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.navy,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 8 Evidence Comparison Cards
        ...guide.pairs.map(
          (pair) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildEvidencePairCard(pair, l10n, locale),
          ),
        ),
        const SizedBox(height: 8),

        // Bottom Warning Banner
        _buildWarningBanner(guide.warningBanner, l10n, locale),
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
              Icons.verified_outlined,
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
                        l10n.s25Title,
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
                        border:
                            Border.all(color: AppColors.navyLight.withAlpha(60)),
                      ),
                      child: Text(
                        l10n.s22CardBadgeAppendix('A.6'),
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
                  l10n.s25HeaderSubtitle,
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

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.gray600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEvidencePairCard(
    EvidencePair pair,
    AppLocalizations l10n,
    String locale,
  ) {
    return Card(
      key: Key('s25_pair_${pair.id}'),
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
            // Pair header badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.navy.withAlpha(40)),
                  ),
                  child: Text(
                    '#${pair.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Strong Evidence Box
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.good.withAlpha(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.good, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.good,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.s25StrongEvidenceLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.good,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pair.strong(locale),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gray800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Weak Evidence Box
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(10),
                  border: const Border(
                    left: BorderSide(color: AppColors.red, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.s25WeakEvidenceLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pair.weak(locale),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gray800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(
    EvidenceWarningBanner warning,
    AppLocalizations l10n,
    String locale,
  ) {
    return Container(
      key: const Key('s25_warning_banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withAlpha(100), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.s25WarningTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warning.text(locale),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
