import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/escalation.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/escalation_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/escalation_engine.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/draft_audit_provider.dart';
import '../../../services/escalation_service.dart';
import '../../../utils/app_date_format.dart';
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
  List<Escalation> _escalations = const [];
  Map<String, User> _recipients = const {};

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
    _loadAuditEscalations();
  }

  Future<void> _loadAuditEscalations() async {
    final audit = ref.read(draftAuditProvider).audit;
    if (audit != null) {
      final list = await EscalationRepository.instance.listForAudit(audit.id);
      final recipients = <String, User>{};
      for (final esc in list) {
        if (!recipients.containsKey(esc.raisedToUserId)) {
          final u = await UserRepository.instance.getById(esc.raisedToUserId);
          if (u != null) recipients[esc.raisedToUserId] = u;
        }
      }
      if (mounted) {
        setState(() {
          _escalations = list;
          _recipients = recipients;
        });
      }
    }
  }

  Future<void> _shareWhatsApp(Escalation esc, AppLocalizations l10n) async {
    final audit = ref.read(draftAuditProvider).audit;
    final draft = EscalationDraft(
      triggerNumber: esc.triggerNumber,
      triggerLabel: esc.triggerLabel,
      sourceType: esc.sourceType,
      targetRole: 'GM',
      urgency: esc.urgency,
      deliveryChannel: 'whatsapp',
      whatHappened: esc.whatHappened,
      evidence: esc.evidence ?? 'None recorded',
      impact: esc.impact ?? 'None recorded',
      requestedAction: esc.requestedAction ?? 'None recorded',
    );
    final msg = EscalationEngine.buildEscalationMessage(
      draft,
      auditDate: audit?.auditDate ?? '',
      auditType: audit?.auditType ?? 'daily',
    );

    final launched = await EscalationService.instance.launchWhatsAppForEscalation(esc, msg.full, markSent: false);
    if (!mounted) return;

    if (!launched) {
      await EscalationService.instance.copyToClipboard(msg.full);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s11MessageCopied),
          backgroundColor: AppColors.amber,
        ),
      );
      return;
    }

    final recipientName = _recipients[esc.raisedToUserId]?.name ?? 'the recipient';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.chat, color: AppColors.green, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.s33ConfirmWhatsAppTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(l10n.s33ConfirmWhatsAppPrompt(recipientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.s33ConfirmWhatsAppNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            child: Text(l10n.s33ConfirmWhatsAppYes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await EscalationRepository.instance.markWhatsAppSent(esc.id);
      await _loadAuditEscalations();
    }
  }

  Future<void> _markManuallySent(Escalation esc) async {
    await EscalationRepository.instance.markWhatsAppSent(esc.id);
    await _loadAuditEscalations();
  }

  Future<void> _copyMessage(Escalation esc, AppLocalizations l10n) async {
    final audit = ref.read(draftAuditProvider).audit;
    final draft = EscalationDraft(
      triggerNumber: esc.triggerNumber,
      triggerLabel: esc.triggerLabel,
      sourceType: esc.sourceType,
      targetRole: 'GM',
      urgency: esc.urgency,
      deliveryChannel: 'whatsapp',
      whatHappened: esc.whatHappened,
      evidence: esc.evidence ?? 'None recorded',
      impact: esc.impact ?? 'None recorded',
      requestedAction: esc.requestedAction ?? 'None recorded',
    );
    final msg = EscalationEngine.buildEscalationMessage(
      draft,
      auditDate: audit?.auditDate ?? '',
      auditType: audit?.auditType ?? 'daily',
    );
    await EscalationService.instance.copyToClipboard(msg.full);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.s11MessageCopied)),
    );
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
    final isWeekly = audit?.auditType == 'weekly';
    final isMonthly = audit?.auditType == 'monthly';

    final scorePct = audit?.compliancePct ?? 0.0;
    final bandName = audit?.band?.toUpperCase() ?? 'PENDING';
    final color = bandColor(scorePct);

    final submittedTime = AppDateFormat.formatTime(audit?.submittedAt, fallback: 'Just now');

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
                  isWeekly
                      ? l10n.s11WeeklyTitle
                      : (isMonthly ? l10n.s11MonthlyTitle : l10n.s11Title),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 26,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isWeekly
                      ? '${l10n.s05SubmittedStatus} $submittedTime  ·  ${l10n.s05WeekNumberLabel(audit?.weekNumber ?? 0, audit?.year ?? 0)}'
                      : isMonthly
                          ? '${l10n.s05SubmittedStatus} $submittedTime  ·  ${l10n.s05MonthYearLabel(DateFormat('MMMM').format(audit?.auditDate != null ? DateTime.parse(audit!.auditDate) : DateTime.now()), audit?.year ?? DateTime.now().year)}'
                          : '${l10n.s05SubmittedStatus} $submittedTime  ·  ${audit?.auditDate ?? ''}',
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

                // Band-specific alerts & Escalations
                if (_escalations.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: AppColors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.s11EscalationsAlertTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final esc in _escalations) _buildEscalationCard(esc, l10n),
                  const SizedBox(height: 8),
                ] else if (isPoorOrCritical)
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

  Widget _buildEscalationCard(Escalation esc, AppLocalizations l10n) {
    final urgencyColor = switch (esc.urgency) {
      'immediate' => AppColors.red,
      'same_day' || 'same_night' => AppColors.amber,
      _ => AppColors.navy,
    };
    final urgencyLabel = switch (esc.urgency) {
      'immediate' => l10n.s33UrgencyImmediate,
      'same_day' => l10n.s33UrgencySameDay,
      'same_night' => l10n.s33UrgencySameNight,
      _ => l10n.s33UrgencyNextAudit,
    };
    final recipientName = _recipients[esc.raisedToUserId]?.name ?? 'General Manager';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgencyColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.s33TriggerLabel(esc.triggerNumber),
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urgencyLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: esc.whatsappSent
                      ? AppColors.green.withValues(alpha: 0.12)
                      : AppColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      esc.whatsappSent ? Icons.check : Icons.access_time,
                      size: 12,
                      color: esc.whatsappSent ? AppColors.green : AppColors.amberDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      esc.whatsappSent
                          ? l10n.s33WhatsAppSentBadge
                          : l10n.s33WhatsAppUnconfirmedBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: esc.whatsappSent ? AppColors.green : AppColors.amberDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            esc.whatHappened,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: $recipientName',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _shareWhatsApp(esc, l10n),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.chat, size: 16),
                label: Text(l10n.s11ShareWhatsApp, style: const TextStyle(fontSize: 13)),
              ),
              if (!esc.whatsappSent)
                OutlinedButton.icon(
                  onPressed: () => _markManuallySent(esc),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.check, size: 16, color: AppColors.green),
                  label: Text(l10n.s11MarkAsSent, style: const TextStyle(fontSize: 13)),
                ),
              OutlinedButton.icon(
                onPressed: () => _copyMessage(esc, l10n),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: Text(l10n.s33CopyAction, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
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
