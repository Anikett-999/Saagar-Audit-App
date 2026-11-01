import 'package:flutter/material.dart';

import '../../../../data/models/checkpoint.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/draft_audit_provider.dart';
import '../../../theme/app_colors.dart';

enum JumpFilter { all, unanswered, failed, passed, na }

/// Item 27.2: 68-Checkpoint Jump List bottom sheet.
///
/// Gives auditors instant bird's-eye visibility of answered, unanswered,
/// and failed checkpoints, allowing 1-tap jumping to any checkpoint in the audit.
class CheckpointJumpSheet extends StatefulWidget {
  const CheckpointJumpSheet({
    super.key,
    required this.checkpoints,
    required this.results,
    required this.currentIndex,
    required this.sopNamesById,
    required this.onSelect,
  });

  final List<Checkpoint> checkpoints;
  final Map<String, Verdict> results;
  final int currentIndex;
  final Map<String, String> sopNamesById;
  final ValueChanged<int> onSelect;

  @override
  State<CheckpointJumpSheet> createState() => _CheckpointJumpSheetState();
}

class _CheckpointJumpSheetState extends State<CheckpointJumpSheet> {
  JumpFilter _currentFilter = JumpFilter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll automatically to current checkpoint after layout if in list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!mounted || widget.currentIndex < 0 || widget.currentIndex >= widget.checkpoints.length) {
      return;
    }
    // Estimate ~84px per item height
    final targetOffset = (widget.currentIndex * 84.0).clamp(
      0.0,
      _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 10000.0,
    );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    final total = widget.checkpoints.length;
    final answered = widget.results.length;
    final failed = widget.results.values.where((v) => v == Verdict.fail).length;
    final passed = widget.results.values.where((v) => v == Verdict.pass).length;
    final na = widget.results.values.where((v) => v == Verdict.na).length;
    final unanswered = total - answered;

    // Filter list
    final filteredIndices = <int>[];
    for (var i = 0; i < total; i++) {
      final cp = widget.checkpoints[i];
      final verdict = widget.results[cp.id];
      switch (_currentFilter) {
        case JumpFilter.all:
          filteredIndices.add(i);
          break;
        case JumpFilter.unanswered:
          if (verdict == null) filteredIndices.add(i);
          break;
        case JumpFilter.failed:
          if (verdict == Verdict.fail) filteredIndices.add(i);
          break;
        case JumpFilter.passed:
          if (verdict == Verdict.pass) filteredIndices.add(i);
          break;
        case JumpFilter.na:
          if (verdict == Verdict.na) filteredIndices.add(i);
          break;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.s07JumpListTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 20,
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$answered of $total answered  •  $progressPercentage% completed',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gray600),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: '${l10n.s07JumpListFilterAll} ($total)',
                  filter: JumpFilter.all,
                  selectedColor: AppColors.navy,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${l10n.s07JumpListFilterUnanswered} ($unanswered)',
                  filter: JumpFilter.unanswered,
                  selectedColor: AppColors.gray800,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${l10n.s07JumpListFilterFailed} ($failed)',
                  filter: JumpFilter.failed,
                  selectedColor: AppColors.red,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '${l10n.s07JumpListFilterPassed} ($passed)',
                  filter: JumpFilter.passed,
                  selectedColor: AppColors.green,
                ),
                if (na > 0) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '${l10n.s07JumpListFilterNa} ($na)',
                    filter: JumpFilter.na,
                    selectedColor: AppColors.amber,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray200),

          // List content
          Expanded(
            child: filteredIndices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentFilter == JumpFilter.failed
                                ? Icons.verified_outlined
                                : Icons.info_outline,
                            size: 44,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentFilter == JumpFilter.failed
                                ? 'No failed checkpoints recorded'
                                : 'No checkpoints match this filter',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 15,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredIndices.length,
                    itemBuilder: (context, idx) {
                      final originalIndex = filteredIndices[idx];
                      final cp = widget.checkpoints[originalIndex];
                      final verdict = widget.results[cp.id];
                      final isCurrent = originalIndex == widget.currentIndex;
                      final sopName = widget.sopNamesById[cp.sopId] ?? cp.sopId;
                      final isCritical = cp.sopId == 'SOP6' || cp.sopId == 'SOP7';

                      return _buildCheckpointItem(
                        context: context,
                        index: originalIndex,
                        cp: cp,
                        verdict: verdict,
                        isCurrent: isCurrent,
                        sopName: sopName,
                        isCritical: isCritical,
                        locale: locale,
                        l10n: l10n,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int get progressPercentage {
    if (widget.checkpoints.isEmpty) return 0;
    return ((widget.results.length / widget.checkpoints.length) * 100).toInt();
  }

  Widget _buildFilterChip({
    required String label,
    required JumpFilter filter,
    required Color selectedColor,
  }) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _currentFilter = filter);
        }
      },
      selectedColor: selectedColor,
      backgroundColor: AppColors.gray100,
      labelStyle: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.white : AppColors.gray800,
      ),
      side: BorderSide(
        color: isSelected ? selectedColor : AppColors.gray300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildCheckpointItem({
    required BuildContext context,
    required int index,
    required Checkpoint cp,
    required Verdict? verdict,
    required bool isCurrent,
    required String sopName,
    required bool isCritical,
    required String locale,
    required AppLocalizations l10n,
  }) {
    final (badgeBg, badgeFg, badgeIcon, badgeLabel) = _verdictDetails(verdict, l10n);

    return InkWell(
      key: Key('jump_item_$index'),
      onTap: () {
        widget.onSelect(index);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.goldPale.withValues(alpha: 0.5) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? AppColors.navy : AppColors.gray200,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sequence Number badge
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.navy : AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? AppColors.white : AppColors.navy,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCritical ? AppColors.goldPale : AppColors.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isCritical ? '★ $sopName' : sopName,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCritical ? AppColors.goldDark : AppColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.s07JumpListCurrentBadge.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cp.text(locale),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      color: AppColors.gray800,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Verdict status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeFg.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 14, color: badgeFg),
                  const SizedBox(width: 4),
                  Text(
                    badgeLabel,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData, String) _verdictDetails(Verdict? v, AppLocalizations l10n) {
    if (v == null) {
      return (
        AppColors.gray100,
        AppColors.gray600,
        Icons.radio_button_unchecked,
        l10n.s07JumpListPendingBadge,
      );
    }
    switch (v) {
      case Verdict.pass:
        return (
          AppColors.greenPale,
          AppColors.green,
          Icons.check_circle_rounded,
          l10n.s07Pass,
        );
      case Verdict.fail:
        return (
          AppColors.redPale,
          AppColors.red,
          Icons.cancel_rounded,
          l10n.s07Fail,
        );
      case Verdict.na:
        return (
          AppColors.amberPale,
          AppColors.amber,
          Icons.remove_circle_outline_rounded,
          l10n.s07Na,
        );
    }
  }
}
