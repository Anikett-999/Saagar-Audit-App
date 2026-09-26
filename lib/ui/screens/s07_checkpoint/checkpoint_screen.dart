import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/checkpoint.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/draft_audit_provider.dart';
import '../../theme/app_colors.dart';

/// S7 Checkpoint Screen — the heart of the daily audit flow.
///
/// Per Spec §5 S7:
///   * Top progress bar "Checkpoint N of 68"
///   * SOP context chip (color-coded; critical SOPs ★ in gold)
///   * Three big buttons PASS / FAIL / NA
///   * PASS auto-advances after 200ms
///   * FAIL → S8 (Fail Detail)
///   * NA → modal asking reason, then advances
class CheckpointScreen extends ConsumerStatefulWidget {
  const CheckpointScreen({super.key});

  @override
  ConsumerState<CheckpointScreen> createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends ConsumerState<CheckpointScreen> {
  Map<String, String> _sopNamesById = const {};

  @override
  void initState() {
    super.initState();
    _loadSopNames();
  }

  Future<void> _loadSopNames() async {
    final sops = await CheckpointRepository.instance.loadAllSops();
    if (!mounted) return;
    setState(() {
      _sopNamesById = {for (final s in sops) s.id: s.nameEn};
    });
  }

  Future<void> _onPass(Checkpoint cp) async {
    await ref.read(draftAuditProvider.notifier).mark(Verdict.pass);
    // Tiny "good" haptic + slight pause so the user sees the tick.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _maybeFinishOrAdvance();
  }

  Future<void> _onFail(Checkpoint cp) async {
    // Navigate directly to S8. S8 captures finding text & photos, then
    // atomically saves the FAIL result and advances currentIndex.
    // If the user backs out of S8 without saving, no orphan record is written.
    await context.pushNamed('s08_fail_detail');
    if (!mounted) return;
    _maybeFinishOrAdvance();
  }

  Future<void> _onNa(Checkpoint cp) async {
    final reason = await _askNaReason(cp);
    if (reason == null) return; // user cancelled
    await ref
        .read(draftAuditProvider.notifier)
        .mark(Verdict.na, findingText: reason);
    if (!mounted) return;
    _maybeFinishOrAdvance();
  }

  void _maybeFinishOrAdvance() {
    final state = ref.read(draftAuditProvider);
    if (state.isComplete) {
      context.goNamed('s10_review');
    }
  }

  Future<String?> _askNaReason(Checkpoint cp) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.s07NaReasonPrompt),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: l10n.s07NaReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            onPressed: () {
              final r = controller.text.trim();
              if (r.length < 3) return;
              Navigator.of(ctx).pop(r);
            },
            child: Text(l10n.btnNa),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftAuditProvider);
    final cp = state.currentCheckpoint;

    if (!state.isActive || cp == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No active draft audit. Go back to Home and start one.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final total = state.checkpoints.length;
    final n = state.currentIndex + 1;
    final progress = n / total;
    final sopName = _sopNamesById[cp.sopId] ?? cp.sopId;
    final isCritical = cp.sopId == 'SOP6' || cp.sopId == 'SOP7';
    final cpText = cp.text(locale);
    final cpEvidence = cp.evidence(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s07CheckpointNumber(n, total)),
        leading: state.currentIndex == 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.goNamed('s05_home'),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(draftAuditProvider.notifier).goBack(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.gray200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: 4,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sopChip(sopName, cp.sopId, isCritical),
                  Text(
                    'CP ${cp.id}',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: AppColors.gray600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cpText,
                      style: const TextStyle(
                        fontFamily: 'DMSerifDisplay',
                        fontSize: 28,
                        color: AppColors.navy,
                        height: 1.25,
                      ),
                    ),
                    if (cpEvidence != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Evidence: $cpEvidence',
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: AppColors.gray600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (cp.requiresPhotoOnFail) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redPale,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.red),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: AppColors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.s08PhotoRequiredNotice,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _verdictButtons(l10n, cp),
            _miniStats(state),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sopChip(String name, String sopId, bool isCritical) {
    final bg = isCritical ? AppColors.goldPale : AppColors.gray100;
    final fg = isCritical ? AppColors.gold : AppColors.navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCritical)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child:
                  Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
            ),
          Text(
            name,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdictButtons(AppLocalizations l10n, Checkpoint cp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => _onPass(cp),
              child: Text(
                l10n.s07Pass,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => _onFail(cp),
              child: Text(
                l10n.s07Fail,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (cp.allowsNa)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _onNa(cp),
                child: Text(
                  l10n.s07Na,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniStats(DraftAuditState state) {
    Widget pill(String label, int count, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pill('PASS', state.passCount, AppColors.green),
          pill('FAIL', state.failCount, AppColors.red),
          pill('N/A', state.naCount, AppColors.gray600),
        ],
      ),
    );
  }
}
