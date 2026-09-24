import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/cap.dart';
import '../../../data/models/cap_action.dart';
import '../../../data/models/cap_log_entry.dart';
import '../../../data/models/checkpoint.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S16 — Corrective Action Plan (CAP) Detail.
///
/// Implements full CAP inspection view per Spec §5 S16:
/// - Prominent status badge (Open / Done / Verified / Closed / Aged / Reopened)
/// - Deadline countdown (overdue / due soon / ok)
/// - All 10 template fields read-only
/// - Action steps checklist (toggleable only by responsible user)
/// - Event log timeline
/// - State/role-gated action buttons:
///   - "Mark CAP Done" enabled when open and all action steps are done
///   - Verify, Close, Request Extension, Reopen stubbed with Phase 2 notices
class CapDetailScreen extends ConsumerStatefulWidget {
  const CapDetailScreen({
    super.key,
    required this.capId,
  });

  final String capId;

  @override
  ConsumerState<CapDetailScreen> createState() => _CapDetailScreenState();
}

class _CapDetailScreenState extends ConsumerState<CapDetailScreen> {
  Cap? _cap;
  List<CapAction> _actions = [];
  List<CapLogEntry> _logs = [];
  Map<String, User> _userMap = {};
  Audit? _originAudit;
  Checkpoint? _originCheckpoint;

  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(CapDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capId != widget.capId) {
      _loadData();
    }
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }

    try {
      final cap = await CapRepository.instance.getById(widget.capId);
      if (cap == null) {
        if (mounted) {
          setState(() {
            _cap = null;
            _isLoading = false;
          });
        }
        return;
      }

      final actions = await CapRepository.instance.actionsFor(widget.capId);
      final logs = await CapRepository.instance.logFor(widget.capId);
      final users = await UserRepository.instance.listAll();
      final userMap = {for (final u in users) u.id: u};

      // Load origin checkpoint text
      Checkpoint? cp;
      try {
        final cps = await CheckpointRepository.instance.loadDailyCheckpointsInAuditOrder();
        for (final item in cps) {
          if (item.id == cap.originCheckpointId) {
            cp = item;
            break;
          }
        }
      } catch (_) {}

      // Load origin audit
      Audit? audit;
      try {
        audit = await AuditRepository.instance.getById(cap.originAuditId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cap = cap;
          _actions = actions;
          _logs = logs;
          _userMap = userMap;
          _originAudit = audit;
          _originCheckpoint = cp;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAction(CapAction action) async {
    final cap = _cap;
    if (cap == null) return;

    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null) return;

    final isResponsible = user.id == cap.responsibleUserId;
    if (!isResponsible) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s16OnlyResponsibleCanToggle),
            backgroundColor: AppColors.amber,
          ),
        );
      }
      return;
    }

    if (!cap.isOpen) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s16CapAlreadyDoneNotice),
            backgroundColor: AppColors.gray600,
          ),
        );
      }
      return;
    }

    setState(() => _isToggling = true);

    try {
      await CapRepository.instance.toggleAction(
        actionId: action.id,
        done: !action.isDone,
        userId: user.id,
      );
      await _loadData(showSpinner: false);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final errMsg = l10n != null
            ? l10n.s16ActionToggleFailed(e.toString())
            : 'Error: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  Future<void> _navigateToMarkDone() async {
    final cap = _cap;
    if (cap == null) return;

    // Navigate to S17 Mark Done route
    await context.pushNamed(
      's17_cap_mark_done',
      pathParameters: {'id': cap.id},
    );

    // Refresh after returning from S17
    if (mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.goNamed('s14_cap_list');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cap?.id ?? l10n.s16Title,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              l10n.s16Subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.goldPale),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.s16RefreshTooltip,
            onPressed: _isLoading ? null : _loadData,
          ),
          const LanguageToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cap == null
              ? _buildNotFound(l10n)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatusAndDeadlineContainer(l10n),
                        const SizedBox(height: 16),
                        _buildOriginCard(l10n, locale),
                        const SizedBox(height: 16),
                        _buildProblemAnd5WhysCard(l10n),
                        const SizedBox(height: 16),
                        _buildOwnershipCard(l10n),
                        const SizedBox(height: 16),
                        _buildActionStepsCard(l10n, auth.user),
                        const SizedBox(height: 16),
                        _buildActionButtonsCard(l10n, auth.user),
                        const SizedBox(height: 16),
                        _buildTimelineCard(l10n),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNotFound(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              l10n.s16NotFound,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/caps');
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.s16BackToCaps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndDeadlineContainer(AppLocalizations l10n) {
    final cap = _cap!;
    final deadlineStatus = cap.deadlineStatus();
    final diffDays = cap.daysUntilDeadline();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _statusBadge(l10n, cap.status),
                  _deadlineBadge(l10n, cap, deadlineStatus, diffDays),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.s16DeadlineLabel(cap.deadline),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
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

  Widget _statusBadge(AppLocalizations l10n, String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'open':
        bg = AppColors.navyLight.withValues(alpha: 0.12);
        fg = AppColors.navyLight;
        label = l10n.s16StatusOpen;
        break;
      case 'done':
        bg = Colors.purple.withValues(alpha: 0.12);
        fg = Colors.purple.shade800;
        label = l10n.s16StatusDone;
        break;
      case 'verified':
        bg = AppColors.greenPale;
        fg = AppColors.green;
        label = l10n.s16StatusVerified;
        break;
      case 'closed':
        bg = AppColors.gray200;
        fg = AppColors.gray800;
        label = l10n.s16StatusClosed;
        break;
      case 'aged':
        bg = AppColors.redPale;
        fg = AppColors.red;
        label = l10n.s16StatusAged;
        break;
      case 'reopened':
        bg = AppColors.amberPale;
        fg = AppColors.amber;
        label = l10n.s16StatusReopened;
        break;
      default:
        bg = AppColors.gray100;
        fg = AppColors.gray600;
        label = status;
    }

    return Container(
      key: const ValueKey('s16_status_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _deadlineBadge(
    AppLocalizations l10n,
    Cap cap,
    CapDeadlineStatus status,
    int? diffDays,
  ) {
    if (cap.status == 'done' || cap.status == 'verified' || cap.status == 'closed') {
      final dateStr = cap.doneAt?.substring(0, 10) ?? cap.deadline;
      return Container(
        key: const ValueKey('s16_deadline_badge'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.greenPale,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          l10n.s16CompletedOn(dateStr),
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case CapDeadlineStatus.overdue:
        bg = AppColors.redPale;
        fg = AppColors.red;
        icon = Icons.warning_amber_rounded;
        final overdueDays = diffDays != null ? (-diffDays).clamp(1, 999) : 1;
        text = l10n.s16OverdueByDays(overdueDays);
        break;
      case CapDeadlineStatus.dueSoon:
        bg = AppColors.amberPale;
        fg = AppColors.amber;
        icon = Icons.hourglass_top;
        if (diffDays == 0) {
          text = l10n.s16DueToday;
        } else {
          text = l10n.s16DueTomorrow;
        }
        break;
      case CapDeadlineStatus.ok:
        bg = AppColors.greenPale;
        fg = AppColors.green;
        icon = Icons.check_circle_outline;
        final remaining = diffDays ?? 2;
        text = l10n.s16DaysRemaining(remaining);
        break;
    }

    return Container(
      key: const ValueKey('s16_deadline_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginCard(AppLocalizations l10n, String locale) {
    final cap = _cap!;
    final cpText = _originCheckpoint != null
        ? '${cap.originCheckpointId} — ${_originCheckpoint!.text(locale)}'
        : cap.originCheckpointId;

    final auditText = _originAudit != null
        ? '${_originAudit!.auditDate} (${_originAudit!.auditType.toUpperCase()})'
        : cap.originAuditId;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s16SectionOrigin,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (cap.isPattern) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: Text(
                      l10n.s16PatternBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(l10n.s16OriginCheckpoint, cpText),
            const Divider(height: 16),
            _infoRow(l10n.s16OriginAudit, auditText),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemAnd5WhysCard(AppLocalizations l10n) {
    final cap = _cap!;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s16SectionAnalysis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Problem statement
            Text(
              l10n.s16ProblemStatement,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyMid),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
                border: const Border(left: BorderSide(color: AppColors.navy, width: 4)),
              ),
              child: Text(
                cap.problemStatement,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),

            // 5 Whys
            Text(
              l10n.s16WhysSubheader,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyMid),
            ),
            const SizedBox(height: 6),
            _whyItem(l10n.s16WhyLabel(1), cap.why1),
            if (cap.why2 != null && cap.why2!.trim().isNotEmpty)
              _whyItem(l10n.s16WhyLabel(2), cap.why2!),
            if (cap.why3 != null && cap.why3!.trim().isNotEmpty)
              _whyItem(l10n.s16WhyLabel(3), cap.why3!),
            if (cap.why4 != null && cap.why4!.trim().isNotEmpty)
              _whyItem(l10n.s16WhyLabel(4), cap.why4!),
            if (cap.why5 != null && cap.why5!.trim().isNotEmpty)
              _whyItem(l10n.s16WhyLabel(5), cap.why5!),
            const SizedBox(height: 16),

            // Root cause
            Text(
              l10n.s16RootCause,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyMid),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldPale,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                cap.rootCause,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whyItem(String label, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnershipCard(AppLocalizations l10n) {
    final cap = _cap!;
    final responsibleUser = _userMap[cap.responsibleUserId];
    final responsibleName = responsibleUser != null
        ? '${responsibleUser.name} (${responsibleUser.role})'
        : cap.responsibleUserId;

    final openedDate = cap.openedAt.length >= 10
        ? cap.openedAt.substring(0, 10)
        : cap.openedAt;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s16SectionOwnership,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(l10n.s16ResponsibleUser, responsibleName),
            const Divider(height: 16),
            _infoRow(l10n.s16VerificationMethod, cap.verificationMethod),
            const Divider(height: 16),
            _infoRow(l10n.s16OpenedAt(openedDate), ''),
            if (cap.agedCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.s16AgedCount(cap.agedCount),
                style: const TextStyle(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.bold),
              ),
            ],
            if (cap.extensionCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.s16ExtensionCount(cap.extensionCount),
                style: const TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.bold),
              ),
              if (cap.latestExtensionReason != null)
                Text(
                  l10n.s16LatestExtensionReason(cap.latestExtensionReason!),
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionStepsCard(AppLocalizations l10n, AuthUser? currentUser) {
    final cap = _cap!;
    final total = _actions.length;
    final doneCount = _actions.where((a) => a.isDone).length;
    final progress = total > 0 ? doneCount / total : 0.0;

    final isResponsible = currentUser != null && currentUser.id == cap.responsibleUserId;
    final canToggle = isResponsible && cap.isOpen;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s16SectionActionSteps(doneCount, total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.green : AppColors.navy,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            if (!canToggle && cap.isOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.s16OnlyResponsibleCanToggle,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.gray600),
                ),
              ),
            ..._actions.map((action) => _buildActionItem(l10n, action, canToggle)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(AppLocalizations l10n, CapAction action, bool canToggle) {
    final doneUserName = action.doneBy != null ? (_userMap[action.doneBy!]?.name ?? action.doneBy!) : '';
    final doneDate = action.doneAt != null && action.doneAt!.length >= 10
        ? action.doneAt!.substring(0, 10)
        : '';

    return Container(
      key: ValueKey('action_step_${action.sequence}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: action.isDone ? AppColors.greenPale.withValues(alpha: 0.5) : AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: action.isDone ? AppColors.greenMid : AppColors.gray200,
        ),
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: action.isDone,
        onChanged: _isToggling
            ? null
            : canToggle
                ? (_) => _toggleAction(action)
                : null,
        title: Text(
          '${l10n.s16StepLabel(action.sequence)}: ${action.actionText}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: action.isDone ? TextDecoration.lineThrough : null,
            color: action.isDone ? AppColors.gray600 : AppColors.navy,
          ),
        ),
        subtitle: action.isDone && doneUserName.isNotEmpty
            ? Text(
                l10n.s16ActionDoneBy(doneUserName, doneDate),
                style: const TextStyle(fontSize: 11, color: AppColors.green),
              )
            : null,
      ),
    );
  }

  Widget _buildActionButtonsCard(AppLocalizations l10n, AuthUser? currentUser) {
    final cap = _cap!;
    final allActionsDone = _actions.isNotEmpty && _actions.every((a) => a.isDone);
    final isResponsible = currentUser != null && currentUser.id == cap.responsibleUserId;
    final isGmOrOwner = currentUser != null && (currentUser.isGm || currentUser.isOwner);
    final isOwner = currentUser != null && currentUser.isOwner;
    final canMarkDone = (isResponsible || isGmOrOwner) && allActionsDone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Mark Done button
        if (cap.isOpen) ...[
          ElevatedButton.icon(
            key: const ValueKey('s16_mark_done_button'),
            onPressed: canMarkDone ? _navigateToMarkDone : null,
            icon: const Icon(Icons.check_circle),
            label: Text(
              l10n.s16MarkDoneButton,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.gray300,
              disabledForegroundColor: AppColors.gray600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (!allActionsDone)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.s16CompleteAllStepsToMarkDone,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.gray600),
              ),
            ),
          const SizedBox(height: 8),

          // Request Extension (Phase 2 stub)
          OutlinedButton.icon(
            key: const ValueKey('s16_request_extension_button'),
            onPressed: null, // Disabled per Phase 1 scope
            icon: const Icon(Icons.access_time),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.s16RequestExtensionButton),
                  const SizedBox(width: 8),
                  _phase2Badge(l10n),
                ],
              ),
            ),
          ),
        ],

        // 2. Verify button (for done status, GM/Owner)
        if (cap.isDone && isGmOrOwner) ...[
          ElevatedButton.icon(
            key: const ValueKey('s16_verify_button'),
            onPressed: null, // Disabled per Phase 1 scope
            icon: const Icon(Icons.verified),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.s16VerifyButton),
                  const SizedBox(width: 8),
                  _phase2Badge(l10n),
                ],
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],

        // 3. Close button (for verified status, GM/Owner)
        if (cap.isVerified && isGmOrOwner) ...[
          ElevatedButton.icon(
            key: const ValueKey('s16_close_button'),
            onPressed: null, // Disabled per Phase 1 scope
            icon: const Icon(Icons.lock),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.s16CloseButton),
                  const SizedBox(width: 8),
                  _phase2Badge(l10n),
                ],
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],

        // 4. Reopen button (for closed status, Owner)
        if (cap.isClosed && isOwner) ...[
          OutlinedButton.icon(
            key: const ValueKey('s16_reopen_button'),
            onPressed: null, // Disabled per Phase 1 scope
            icon: const Icon(Icons.replay),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.s16ReopenButton),
                  const SizedBox(width: 8),
                  _phase2Badge(l10n),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _phase2Badge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.s16Phase2Notice,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gray800),
      ),
    );
  }

  Widget _buildTimelineCard(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s16SectionTimeline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_logs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.s16NoTimelineEntries),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _logs.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, i) {
                  final entry = _logs[i];
                  return _timelineEntry(l10n, entry);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _timelineEntry(AppLocalizations l10n, CapLogEntry entry) {
    final actorUser = entry.actorUserId != null ? _userMap[entry.actorUserId!] : null;
    final actorName = actorUser != null
        ? '${actorUser.name} (${actorUser.role})'
        : entry.actorUserId ?? l10n.s16ActorSystem;

    final dateStr = entry.timestamp.length >= 16
        ? entry.timestamp.substring(0, 16).replaceFirst('T', ' ')
        : entry.timestamp;

    IconData icon;
    Color iconColor;
    String eventTitle;

    switch (entry.event) {
      case 'created':
        icon = Icons.add_circle_outline;
        iconColor = AppColors.navy;
        eventTitle = l10n.s16EventCreated;
        break;
      case 'action_done':
        icon = Icons.check_circle_outline;
        iconColor = AppColors.green;
        eventTitle = l10n.s16EventActionDone;
        break;
      case 'marked_done':
        icon = Icons.task_alt;
        iconColor = Colors.purple;
        eventTitle = l10n.s16EventMarkedDone;
        break;
      case 'verified':
        icon = Icons.verified_outlined;
        iconColor = AppColors.green;
        eventTitle = l10n.s16EventVerified;
        break;
      case 'closed':
        icon = Icons.lock_outline;
        iconColor = AppColors.gray800;
        eventTitle = l10n.s16EventClosed;
        break;
      case 'extended':
        icon = Icons.update;
        iconColor = AppColors.amber;
        eventTitle = l10n.s16EventExtended;
        break;
      case 'aged':
        icon = Icons.warning_amber;
        iconColor = AppColors.red;
        eventTitle = l10n.s16EventAged;
        break;
      case 'reopened':
        icon = Icons.replay;
        iconColor = Colors.deepOrange;
        eventTitle = l10n.s16EventReopened;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = AppColors.gray600;
        eventTitle = entry.event;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      eventTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: AppColors.gray600),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.s16ActorPrefix(actorName),
                style: const TextStyle(fontSize: 11, color: AppColors.navyMid),
              ),
              if (entry.note != null && entry.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry.note!,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.navyMid,
          ),
        ),
        if (value.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ],
    );
  }
}
