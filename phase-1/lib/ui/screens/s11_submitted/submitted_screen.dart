import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/draft_audit_provider.dart';
import '../../theme/app_colors.dart';

/// Screen S11 — Daily Audit — Submitted Confirmation (Spec §5 S11).
///
/// Celebrates completion, displays final score & band, shows offline sync indicator,
/// provides relevant band warnings (CAP / Escalation triggers), and routes to next steps.
class SubmittedScreen extends ConsumerStatefulWidget {
  const SubmittedScreen({super.key});

  @override
  ConsumerState<SubmittedScreen> createState() => _SubmittedScreenState();
}

class _SubmittedScreenState extends ConsumerState<SubmittedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(draftAuditProvider);
    final audit = state.audit;

    final scorePct = audit?.compliancePct ?? 0.0;
    final bandName = audit?.band?.toUpperCase() ?? 'PENDING';
    final color = bandColor(scorePct);

    String submittedTime = 'Just now';
    if (audit?.submittedAt != null) {
      try {
        final dt = DateTime.parse(audit!.submittedAt!).toLocal();
        submittedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final isFairOrBelow = scorePct < 90.0;
    final isPoorOrCritical = scorePct < 85.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.goNamed('s05_home');
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Animated Checkmark
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: AppColors.greenPale,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 72,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  l10n.s11Title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 26,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${l10n.s05SubmittedStatus} $submittedTime  ·  ${audit?.auditDate ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 28),

                // Final Score & Band Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${scorePct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          bandName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: color,
                          ),
                        ),
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            l10n.s10ScoreCard,
                            '${audit?.rawScore?.toInt() ?? 0} / ${audit?.maxScore?.toInt() ?? 0}',
                          ),
                          _statItem(l10n.btnPass, '${audit?.passCount ?? 0}', color: AppColors.green),
                          _statItem(l10n.btnFail, '${audit?.failCount ?? 0}', color: AppColors.red),
                          _statItem(l10n.btnNa, '${audit?.naCount ?? 0}', color: AppColors.gray600),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Offline-First Sync Indicator (Spec Rule #3 — strictly Phase 1 offline scope)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_queue, size: 18, color: AppColors.gray600),
                      const SizedBox(width: 8),
                      Text(
                        'Saved to SQLite  ·  ${l10n.s11OfflineSyncNotice}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Band-specific alerts
                if (isPoorOrCritical)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Score < 85.0% (Poor/Critical): Mandatory Escalation Trigger 1 activated.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isFairOrBelow)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.amber, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Action Recommended: Open Corrective Action Plans (CAPs) for recorded failures.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Navigation actions
                FilledButton(
                  onPressed: () => context.goNamed('s05_home'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    l10n.s11ReturnHome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String val, {Color? color}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
      ],
    );
  }
}
