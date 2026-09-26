import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S22 — Reference Tab Index (Spec §5 S22 & SPRINT_S22_S26).
///
/// Serves as the index for the app's built-in copy of Workbook Appendices A.4–A.7.
/// Displays 4 navigation cards to S23 (Rating Scale), S24 (Escalation Triggers),
/// S25 (Evidence Guide), and S26 (Bilingual Glossary).
class ReferenceIndexScreen extends StatelessWidget {
  const ReferenceIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s22Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildHeaderBanner(context, l10n),
          const SizedBox(height: 16),
          _buildReferenceCard(
            key: const Key('s22_card_rating_scale'),
            context: context,
            appendixCode: 'A.4',
            title: l10n.s22RatingScaleTitle,
            subtitle: l10n.s22RatingScaleSubtitle,
            icon: Icons.speed_outlined,
            accentColor: AppColors.good,
            onTap: () => context.pushNamed('s23_rating_scale'),
          ),
          const SizedBox(height: 12),
          _buildReferenceCard(
            key: const Key('s22_card_escalation'),
            context: context,
            appendixCode: 'A.5',
            title: l10n.s22EscalationTitle,
            subtitle: l10n.s22EscalationSubtitle,
            icon: Icons.warning_amber_outlined,
            accentColor: AppColors.amber,
            onTap: () => context.pushNamed('s24_escalation_triggers'),
          ),
          const SizedBox(height: 12),
          _buildReferenceCard(
            key: const Key('s22_card_evidence'),
            context: context,
            appendixCode: 'A.6',
            title: l10n.s22EvidenceTitle,
            subtitle: l10n.s22EvidenceSubtitle,
            icon: Icons.verified_outlined,
            accentColor: AppColors.navyLight,
            onTap: () => context.pushNamed('s25_evidence'),
          ),
          const SizedBox(height: 12),
          _buildReferenceCard(
            key: const Key('s22_card_glossary'),
            context: context,
            appendixCode: 'A.7',
            title: l10n.s22GlossaryTitle,
            subtitle: l10n.s22GlossarySubtitle,
            icon: Icons.translate_outlined,
            accentColor: AppColors.gold,
            onTap: () => context.pushNamed('s26_glossary'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withAlpha(25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.goldLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.s22HeaderTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.s22HeaderSubtitle,
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

  Widget _buildReferenceCard({
    required Key key,
    required BuildContext context,
    required String appendixCode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      key: key,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
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
                            title,
                            style: const TextStyle(
                              fontSize: 15,
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
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.gray300),
                          ),
                          child: Text(
                            l10n.s22CardBadgeAppendix(appendixCode),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gray600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
