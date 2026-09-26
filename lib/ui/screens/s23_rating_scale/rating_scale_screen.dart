import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/reference/reference_models.dart';
import '../../../data/repositories/reference_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S23 — Reference: Rating Scale (Spec §5 S23, §11.1 & Workbook Appendix A.4).
///
/// Displays:
/// 1. 5 Compliance Bands table/cards strictly mirroring the score engine cutoffs
///    (≥95% Excellent, ≥90% Good, ≥85% Fair, ≥80% Poor, <80% Critical).
/// 2. Tier-specific targets (Tier 1 daily, Tier 2 weekly, Tier 3 monthly).
/// 3. Critical decimal precision reminder banner ("89.9 is FAIR, not Good").
class RatingScaleScreen extends ConsumerStatefulWidget {
  const RatingScaleScreen({super.key});

  @override
  ConsumerState<RatingScaleScreen> createState() => _RatingScaleScreenState();
}

class _RatingScaleScreenState extends ConsumerState<RatingScaleScreen> {
  RatingScale? _scale;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cached = ReferenceRepository.instance.cachedRatingScale;
    if (cached != null) {
      _scale = cached;
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
      final scale = await repo.loadRatingScale(forceReload: forceReload);
      if (!mounted) return;
      setState(() {
        _scale = scale;
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

  Color _getBandColor(ComplianceBand band) {
    switch (band.color.toLowerCase()) {
      case 'green':
        return AppColors.excellent;
      case 'navy':
        return AppColors.navyLight;
      case 'amber':
        return AppColors.amber;
      case 'red':
        return AppColors.red;
      default:
        return bandColor(band.minPercentage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s23Title),
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
            tooltip: 'Refresh',
            onPressed: () => _loadData(forceReload: true),
          ),
        ],
      ),
      body: _buildBody(context, l10n, locale),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, String locale) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.s23Loading,
              style: const TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _scale == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                l10n.s23Error,
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
                label: Text(l10n.s23Retry),
                onPressed: () => _loadData(forceReload: true),
              ),
            ],
          ),
        ),
      );
    }

    final scale = _scale!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildHeaderBanner(context, l10n),
        const SizedBox(height: 20),
        _buildSectionHeader(
          title: l10n.s23SectionBandsTitle,
          subtitle: l10n.s23SectionBandsSubtitle,
        ),
        const SizedBox(height: 12),
        ...scale.bands.map(
          (band) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBandCard(band, l10n, locale),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(
          title: l10n.s23SectionTargetsTitle,
          subtitle: l10n.s23SectionTargetsSubtitle,
        ),
        const SizedBox(height: 12),
        ...scale.tierTargets.map(
          (target) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTierTargetCard(target, l10n, locale),
          ),
        ),
        const SizedBox(height: 12),
        _buildReminderBanner(scale.reminder, locale),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeaderBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.good.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.good.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.good,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.speed_outlined,
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
                        l10n.s23Title,
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
                        color: AppColors.good.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.good.withAlpha(60)),
                      ),
                      child: Text(
                        l10n.s22CardBadgeAppendix('A.4'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.good,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.s23HeaderSubtitle,
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

  Widget _buildBandCard(
    ComplianceBand band,
    AppLocalizations l10n,
    String locale,
  ) {
    final color = _getBandColor(band);

    return Card(
      key: Key('s23_band_${band.id}'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(70), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 5),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withAlpha(60)),
                    ),
                    child: Text(
                      band.name(locale),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    band.range(locale),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.s23ActionLabel}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            band.action(locale),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.s23WhoActsLabel}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            band.whoActs(locale),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierTargetCard(
    TierTarget target,
    AppLocalizations l10n,
    String locale,
  ) {
    return Card(
      key: Key('s23_tier_${target.tierEn.toLowerCase().replaceAll(' ', '_')}'),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.tier(locale),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              target.auditor(locale),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.navy.withAlpha(50)),
                  ),
                  child: Text(
                    target.targetPct(locale),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(
                  label: l10n.s23PassPointsLabel,
                  value: target.passPoints(locale),
                  accentColor: AppColors.good,
                ),
                _buildInfoChip(
                  label: l10n.s23TotalPointsLabel,
                  value: target.totalPoints(locale),
                  accentColor: AppColors.navyLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.gray600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderBanner(ReminderNotice reminder, String locale) {
    return Container(
      key: const Key('s23_reminder_banner'),
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
                  reminder.title(locale),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.text(locale),
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
