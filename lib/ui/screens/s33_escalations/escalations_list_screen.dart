import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/escalation.dart';
import '../../../data/repositories/escalation_repository.dart';
import '../../../domain/escalation_engine.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/escalation_service.dart';
import '../../../services/notification_service.dart';
import '../../theme/app_colors.dart';

/// Screen S33 — Escalations List & Detail (Spec §7 & Appendix A.5).
///
/// Displays open, acknowledged, and resolved escalation alerts for GM and Owner.
/// Provides acknowledge/resolve actions, WhatsApp deep linking, and clipboard copying.
class EscalationsListScreen extends ConsumerStatefulWidget {
  const EscalationsListScreen({super.key});

  @override
  ConsumerState<EscalationsListScreen> createState() => _EscalationsListScreenState();
}

class _EscalationsListScreenState extends ConsumerState<EscalationsListScreen> {
  String _selectedFilter = 'open'; // 'open' | 'acknowledged' | 'resolved' | 'all'
  List<Escalation> _escalations = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEscalations();
  }

  Future<void> _loadEscalations() async {
    setState(() => _loading = true);
    final status = _selectedFilter == 'all' ? null : _selectedFilter;
    final list = await EscalationRepository.instance.listAll(status: status);
    if (!mounted) return;
    setState(() {
      _escalations = list;
      _loading = false;
    });
  }

  Future<void> _acknowledge(Escalation escalation, AppLocalizations l10n) async {
    await EscalationRepository.instance.acknowledge(escalation.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.s33AcknowledgeSuccess)),
    );
    await _loadEscalations();
  }

  Future<void> _showResolveDialog(Escalation escalation, AppLocalizations l10n) async {
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.s33ResolveAction),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.s33ResolutionNotesTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.s33ResolutionNotesHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.s33ResolutionNotesRequired;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            child: Text(l10n.s33ResolveAction),
          ),
        ],
      ),
    );

    if (confirmed == true && notesController.text.trim().isNotEmpty) {
      await EscalationRepository.instance.resolve(
        escalation.id,
        resolutionNotes: notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.s33ResolveSuccess)),
      );
      await _loadEscalations();
    }
  }

  Future<void> _showManualEscalationDialog(AppLocalizations l10n) async {
    final whatController = TextEditingController();
    final evidenceController = TextEditingController();
    final impactController = TextEditingController();
    final actionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.s33RaiseManualTitle),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: whatController,
                  decoration: InputDecoration(
                    labelText: l10n.s33WhatHappenedLabel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: evidenceController,
                  decoration: InputDecoration(
                    labelText: l10n.s33EvidenceLabel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: impactController,
                  decoration: InputDecoration(
                    labelText: l10n.s33ImpactLabel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: actionController,
                  decoration: InputDecoration(
                    labelText: l10n.s33ActionLabel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            child: Text(l10n.s33SaveManualButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final draft = EscalationEngine.createManualEscalation(
        raisedByUserId: user.id,
        whatHappened: whatController.text.trim(),
        evidence: evidenceController.text.trim(),
        impact: impactController.text.trim(),
        requestedAction: actionController.text.trim(),
      );

      final esc = await EscalationRepository.instance.raise(draft);
      final msg = EscalationEngine.buildEscalationMessage(
        draft,
        auditDate: DateTime.now().toIso8601String().split('T').first,
        auditType: 'manual',
      );

      await NotificationService.instance.showNotification(
        id: esc.hashCode.abs() % 100000,
        title: msg.summary,
        body: draft.whatHappened,
      );

      if (draft.deliveryChannel == 'whatsapp') {
        await EscalationService.instance.launchWhatsAppForEscalation(esc, msg.full);
      }

      await _loadEscalations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    final isAuthorized = user != null && (user.role == 'OWNER' || user.role == 'GM');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s33EscalationsTitle),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('s05_home'),
        ),
      ),
      floatingActionButton: isAuthorized
          ? FloatingActionButton.extended(
              onPressed: () => _showManualEscalationDialog(l10n),
              icon: const Icon(Icons.add_alert_outlined),
              label: Text(l10n.s33RaiseManualTitle),
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
            )
          : null,
      body: Column(
        children: [
          _buildFilterBar(l10n),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _escalations.isEmpty
                    ? _buildEmptyState(l10n)
                    : RefreshIndicator(
                        onRefresh: _loadEscalations,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _escalations.length,
                          itemBuilder: (ctx, i) => _buildEscalationCard(_escalations[i], l10n),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('open', l10n.s33FilterOpen),
            const SizedBox(width: 8),
            _filterChip('acknowledged', l10n.s33FilterAcknowledged),
            const SizedBox(width: 8),
            _filterChip('resolved', l10n.s33FilterResolved),
            const SizedBox(width: 8),
            _filterChip('all', l10n.s33FilterAll),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.navy.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.navy : AppColors.gray600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedFilter = filterKey);
          _loadEscalations();
        }
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.green,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.s33EmptyOpen,
              style: const TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 20,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.s33EmptyOpenDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
            ),
          ],
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

    final formattedDate = esc.raisedAt.isNotEmpty
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(esc.raisedAt).toLocal())
        : '';

    final draft = EscalationDraft(
      triggerNumber: esc.triggerNumber,
      triggerLabel: esc.triggerLabel,
      sourceType: esc.sourceType,
      targetRole: 'GM',
      urgency: esc.urgency,
      deliveryChannel: esc.whatsappSent ? 'whatsapp' : 'in_app',
      whatHappened: esc.whatHappened,
      evidence: esc.evidence ?? 'None recorded',
      impact: esc.impact ?? 'None recorded',
      requestedAction: esc.requestedAction ?? 'None recorded',
    );

    final msg = EscalationEngine.buildEscalationMessage(
      draft,
      auditDate: formattedDate,
      auditType: esc.sourceType,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esc.isOpen ? urgencyColor.withValues(alpha: 0.6) : AppColors.gray200,
          width: esc.isOpen ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header pills: Trigger, Urgency, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.s33TriggerLabel(esc.triggerNumber),
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgencyLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                const Spacer(),
                _statusBadge(esc.status, l10n),
              ],
            ),
            const SizedBox(height: 12),

            // Headline
            Text(
              esc.whatHappened,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),

            // Date & WhatsApp sent indicator
            Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
                if (esc.whatsappSent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 12, color: AppColors.green),
                        const SizedBox(width: 4),
                        Text(
                          l10n.s33WhatsAppSentBadge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 4-Part Evidence Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _partRow('2. Evidence', esc.evidence ?? 'None recorded'),
                  const SizedBox(height: 6),
                  _partRow('3. Impact', esc.impact ?? 'None recorded'),
                  const SizedBox(height: 6),
                  _partRow('4. Action', esc.requestedAction ?? 'None recorded'),
                ],
              ),
            ),

            if (esc.isResolved && esc.resolutionNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.task_alt, size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resolution: ${esc.resolutionNotes}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await EscalationService.instance.copyToClipboard(msg.full);
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.s33CopiedSuccess)),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: Text(l10n.s33CopyAction),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final launched = await EscalationService.instance.launchWhatsAppForEscalation(esc, msg.full);
                    if (!launched) {
                      await EscalationService.instance.copyToClipboard(msg.full);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('WhatsApp not launched. Message copied to clipboard!'),
                          backgroundColor: AppColors.amber,
                        ),
                      );
                    } else if (mounted) {
                      await _loadEscalations();
                    }
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16, color: AppColors.green),
                  label: Text(l10n.s33WhatsAppAction),
                ),
                if (esc.isOpen)
                  FilledButton(
                    onPressed: () => _acknowledge(esc, l10n),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.amber),
                    child: Text(l10n.s33AcknowledgeAction),
                  ),
                if (!esc.isResolved)
                  FilledButton(
                    onPressed: () => _showResolveDialog(esc, l10n),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                    child: Text(l10n.s33ResolveAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _partRow(String partTitle, String partContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partTitle,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        Text(
          partContent,
          style: const TextStyle(fontSize: 13, color: AppColors.gray800),
        ),
      ],
    );
  }

  Widget _statusBadge(String status, AppLocalizations l10n) {
    final (label, color) = switch (status) {
      'acknowledged' => (l10n.s33FilterAcknowledged, AppColors.amber),
      'resolved' => (l10n.s33FilterResolved, AppColors.green),
      _ => (l10n.s33FilterOpen, AppColors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
