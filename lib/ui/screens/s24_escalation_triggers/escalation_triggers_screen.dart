import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/reference/reference_models.dart';
import '../../../data/repositories/reference_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S24 — Reference: Escalation Triggers (Spec §5 S24, §11.2 & Workbook Appendix A.5).
///
/// Displays:
/// 1. 7 Mandatory Escalation Triggers with thresholds, recipients, and timing.
/// 2. Escalation Message Format (Four Parts).
/// 3. What Never Escalates rules.
/// 4. 3 Worked Example Messages for common triggers with quick-copy support.
class EscalationTriggersScreen extends ConsumerStatefulWidget {
  const EscalationTriggersScreen({super.key});

  @override
  ConsumerState<EscalationTriggersScreen> createState() =>
      _EscalationTriggersScreenState();
}

class _EscalationTriggersScreenState
    extends ConsumerState<EscalationTriggersScreen> {
  EscalationTriggers? _triggers;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cached = ReferenceRepository.instance.cachedEscalationTriggers;
    if (cached != null) {
      _triggers = cached;
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
      final triggers =
          await repo.loadEscalationTriggers(forceReload: forceReload);
      if (!mounted) return;
      setState(() {
        _triggers = triggers;
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

  Color _getTriggerColor(int triggerNumber) {
    switch (triggerNumber) {
      case 1: // Critical band (< 80%)
      case 5: // Theft / security / legal
        return AppColors.red;
      case 3: // Cash variance > ₹500
      case 4: // Inventory variance > 2%
        return AppColors.amber;
      default:
        return AppColors.navyLight;
    }
  }

  void _copyExampleMessage(
    BuildContext context,
    WorkedExampleMessage example,
    AppLocalizations l10n,
    String locale,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(example.title(locale));
    buffer.writeln('${l10n.s24WhatHappenedLabel}: ${example.whatHappened(locale)}');
    buffer.writeln('${l10n.s24EvidenceLabel}: ${example.evidence(locale)}');
    buffer.writeln('${l10n.s24ImpactLabel}: ${example.impact(locale)}');
    buffer.writeln('${l10n.s24ActionLabel}: ${example.action(locale)}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.s24CopiedSnackbar),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s24Title),
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
              l10n.s24Loading,
              style: const TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _triggers == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                l10n.s24Error,
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
                label: Text(l10n.s24Retry),
                onPressed: () => _loadData(forceReload: true),
              ),
            ],
          ),
        ),
      );
    }

    final data = _triggers!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildHeaderBanner(context, l10n),
        const SizedBox(height: 20),

        // Section 1: 7 Mandatory Triggers
        _buildSectionHeader(
          title: l10n.s24SectionTriggersTitle,
          subtitle: l10n.s24SectionTriggersSubtitle,
        ),
        const SizedBox(height: 12),
        ...data.triggers.map(
          (trigger) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTriggerCard(trigger, l10n, locale),
          ),
        ),
        const SizedBox(height: 16),

        // Section 2: Message Format (4 Parts)
        _buildSectionHeader(
          title: l10n.s24SectionMessageFormatTitle,
          subtitle: l10n.s24SectionMessageFormatSubtitle,
        ),
        const SizedBox(height: 12),
        _buildMessageFormatCard(data.messageFormat, l10n, locale),
        const SizedBox(height: 20),

        // Section 3: What Never Escalates
        _buildNeverEscalatesCard(data.neverEscalates, l10n, locale),
        const SizedBox(height: 20),

        // Section 4: Worked Examples
        _buildSectionHeader(
          title: l10n.s24SectionExamplesTitle,
          subtitle: l10n.s24SectionExamplesSubtitle,
        ),
        const SizedBox(height: 12),
        ...data.examples.map(
          (example) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildExampleCard(example, l10n, locale),
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
        color: AppColors.amber.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_outlined,
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
                        l10n.s24Title,
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
                        color: AppColors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.amber.withAlpha(60)),
                      ),
                      child: Text(
                        l10n.s22CardBadgeAppendix('A.5'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.s24HeaderSubtitle,
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

  Widget _buildTriggerCard(
    EscalationTriggerItem trigger,
    AppLocalizations l10n,
    String locale,
  ) {
    final accentColor = _getTriggerColor(trigger.number);

    return Card(
      key: Key('s24_trigger_${trigger.number}'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withAlpha(70), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 5),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Trigger Number + Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accentColor.withAlpha(60)),
                    ),
                    child: Text(
                      '#${trigger.number}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trigger.name(locale),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Threshold callout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withAlpha(40)),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.s24ThresholdLabel}: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      TextSpan(
                        text: trigger.threshold(locale),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Details container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Escalate to
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.s24EscalateToLabel}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            trigger.escalateTo(locale),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // When
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.s24WhenLabel}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            trigger.when(locale),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray800,
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

  Widget _buildMessageFormatCard(
    MessageFormat messageFormat,
    AppLocalizations l10n,
    String locale,
  ) {
    return Card(
      key: const Key('s24_message_format_card'),
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
            Text(
              messageFormat.title(locale),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            ...messageFormat.parts.map((part) {
              final isLast = part.part == messageFormat.parts.length;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${part.part}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            part.title(locale),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            part.desc(locale),
                            style: const TextStyle(
                              fontSize: 12,
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNeverEscalatesCard(
    NeverEscalatesSection neverEscalates,
    AppLocalizations l10n,
    String locale,
  ) {
    return Container(
      key: const Key('s24_never_escalates_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.do_not_disturb_on_outlined,
                size: 20,
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  neverEscalates.title(locale),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.s24SectionNeverEscalatesSubtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 12),
          ...neverEscalates.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.navyLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text(locale),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    WorkedExampleMessage example,
    AppLocalizations l10n,
    String locale,
  ) {
    return Card(
      key: Key('s24_example_${example.triggerNumber}'),
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
            // Title & Trigger Tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    example.title(locale),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4 Parts breakdown
            _buildExamplePart(
              label: l10n.s24WhatHappenedLabel,
              content: example.whatHappened(locale),
              color: AppColors.navy,
            ),
            const SizedBox(height: 8),
            _buildExamplePart(
              label: l10n.s24EvidenceLabel,
              content: example.evidence(locale),
              color: AppColors.navyLight,
            ),
            const SizedBox(height: 8),
            _buildExamplePart(
              label: l10n.s24ImpactLabel,
              content: example.impact(locale),
              color: AppColors.amber,
            ),
            const SizedBox(height: 8),
            _buildExamplePart(
              label: l10n.s24ActionLabel,
              content: example.action(locale),
              color: AppColors.red,
            ),
            const SizedBox(height: 12),

            // Copy button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 14),
                label: Text(
                  l10n.s24CopyButton,
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navyLight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _copyExampleMessage(
                  context,
                  example,
                  l10n,
                  locale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplePart({
    required String label,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
