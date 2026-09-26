import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/audit_result.dart';
import '../../../data/models/cap.dart';
import '../../../data/models/checkpoint.dart';
import '../../../data/models/cro.dart';
import '../../../data/models/photo.dart';
import '../../../data/models/sop.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../data/repositories/cro_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S13 — Audit Detail (read-only view).
///
/// Implements Spec §5 S13 and SPRINT_S12_S17_CAPS.md §3 Step 7:
/// - Strictly read-only view of a submitted audit (immutable per Hard Rule #6).
/// - Header with audit type, date, auditor name, and submission time.
/// - Score card with overall %, band badge, and metric counts.
/// - SOP breakdown table with expandable checkpoint inspection.
/// - Non-compliances / fails list with finding text, evidence photos, and linked CAP status.
/// - Direct "+ Create CAP" launch to S15 for unlinked fails with pre-filled origin fields.
/// - Navigation to S16 CAP Detail for linked CAPs.
/// - Full-screen photo inspection dialog.
/// - Phase 2 stubs: Export PDF, Share to WhatsApp, and GM/Owner Verify Audit.
class AuditDetailScreen extends ConsumerStatefulWidget {
  const AuditDetailScreen({
    super.key,
    required this.auditId,
  });

  final String auditId;

  @override
  ConsumerState<AuditDetailScreen> createState() => _AuditDetailScreenState();
}

class _AuditDetailScreenState extends ConsumerState<AuditDetailScreen> {
  Audit? _audit;
  String _auditorName = '';
  List<Sop> _sops = const [];
  Map<String, Checkpoint> _checkpointsById = const {};
  List<AuditResult> _results = const [];
  Map<String, AuditResult> _resultsByCheckpointId = const {};
  Map<String, List<Photo>> _failPhotosByResultId = const {};
  Map<String, Cap> _linkedCapsByResultId = const {};
  Map<String, Cro> _crosById = const {};
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final audit = await AuditRepository.instance.getById(widget.auditId);
      if (audit == null) {
        if (mounted) {
          setState(() {
            _notFound = true;
            _loading = false;
          });
        }
        return;
      }

      // Load auditor name
      String auditorName = audit.auditorId;
      try {
        final auditor = await UserRepository.instance.getById(audit.auditorId);
        if (auditor != null) {
          auditorName = auditor.name;
        }
      } catch (_) {
        // Keep fallback
      }

      // Load SOPs and checkpoints
      final sops = await CheckpointRepository.instance.loadAllSops();
      final checkpoints =
          await CheckpointRepository.instance.loadDailyCheckpointsInAuditOrder();
      final cpMap = <String, Checkpoint>{
        for (final cp in checkpoints) cp.id: cp,
      };

      // Load audit results
      final results =
          await AuditRepository.instance.resultsForAudit(widget.auditId);
      final resMap = <String, AuditResult>{
        for (final r in results) r.checkpointId: r,
      };

      // Load fail photos, linked CAPs, and CRO details
      final photosMap = <String, List<Photo>>{};
      final capsMap = <String, Cap>{};
      final crosMap = <String, Cro>{};

      for (final r in results) {
        if (r.result == 'F') {
          final photos =
              await AuditRepository.instance.photosForResult(r.id);
          photosMap[r.id] = photos;

          final linkedCap = await CapRepository.instance.capForResult(r.id);
          if (linkedCap != null) {
            capsMap[r.id] = linkedCap;
          }

          if (r.croId != null && !crosMap.containsKey(r.croId)) {
            final cro = await CroRepository.instance.getById(r.croId!);
            if (cro != null) {
              crosMap[r.croId!] = cro;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _audit = audit;
        _auditorName = auditorName;
        _sops = sops;
        _checkpointsById = cpMap;
        _results = results;
        _resultsByCheckpointId = resMap;
        _failPhotosByResultId = photosMap;
        _linkedCapsByResultId = capsMap;
        _crosById = crosMap;
        _loading = false;
        _notFound = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showPhotoDialog(BuildContext context, String localPath) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(l10n.s13ViewPhoto, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.file(
                File(localPath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Could not load photo file'),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.s13Close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final auth = ref.watch(authProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s13Title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.s13Loading),
            ],
          ),
        ),
      );
    }

    if (_notFound || _audit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s13Title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.s13NotFound,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Audit ID: ${widget.auditId}',
                  style: const TextStyle(color: AppColors.gray600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.goNamed('s12_audit_history'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.s13BackToHistory),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final audit = _audit!;
    final scorePct = audit.compliancePct ?? 0.0;
    final color = bandColor(scorePct);

    final failResults =
        _results.where((r) => r.result == 'F').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.s13Title} — ${audit.auditDate}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('s12_audit_history');
            }
          },
        ),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.s13RefreshTooltip,
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Read-Only Immutability Banner & Audit Info
              _buildHeaderBanner(l10n, audit),
              const SizedBox(height: 16),

              // 2. Score Card (Compliance % + Band + Metric Counts)
              _buildScoreCard(l10n, audit, color),
              const SizedBox(height: 20),

              // 3. SOP Breakdown Table & Checkpoint Accordions
              _buildSopBreakdownSection(l10n, locale),
              const SizedBox(height: 20),

              // 4. Non-Compliances (Fails) with Findings, Photos & CAP Links
              _buildFailsSection(l10n, locale, failResults),
              const SizedBox(height: 20),

              // 5. Auditor Notes (if present)
              if (audit.notes != null && audit.notes!.trim().isNotEmpty) ...[
                _buildNotesSection(l10n, audit.notes!.trim()),
                const SizedBox(height: 20),
              ],

              // 6. Action Buttons & Phase 2 Stubs
              _buildActionsSection(l10n, auth.user?.role),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(AppLocalizations l10n, Audit audit) {
    final submittedTime = audit.submittedAt != null
        ? audit.submittedAt!.substring(0, 16).replaceFirst('T', ' ')
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: AppColors.gray600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.s13ReadOnlyBanner,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: audit.status == 'verified'
                      ? AppColors.greenPale
                      : AppColors.amberPale,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: audit.status == 'verified'
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                ),
                child: Text(
                  audit.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: audit.status == 'verified'
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 4),
                    Text(
                      l10n.s13Date(audit.auditDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.gray800),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category_outlined, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 4),
                    Text(
                      l10n.s13AuditType(audit.auditType.toUpperCase()),
                      style: const TextStyle(fontSize: 12, color: AppColors.gray800),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 4),
                    Text(
                      l10n.s13Auditor(_auditorName),
                      style: const TextStyle(fontSize: 12, color: AppColors.gray800),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.gray600),
                    const SizedBox(width: 4),
                    Text(
                      l10n.s13SubmittedAt(submittedTime),
                      style: const TextStyle(fontSize: 12, color: AppColors.gray800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(AppLocalizations l10n, Audit audit, Color color) {
    final compliance = audit.compliancePct ?? 0.0;
    final bandName = audit.band?.toUpperCase() ?? 'PENDING';
    final rawScore = (audit.rawScore ?? 0.0).toStringAsFixed(0);
    final maxScore = (audit.maxScore ?? 0.0).toStringAsFixed(0);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${compliance.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    l10n.s13ScoreCard,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
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
            ],
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricItem(
                l10n.s13Points,
                '$rawScore / $maxScore',
              ),
              _metricItem(
                l10n.btnPass,
                '${audit.passCount}',
                color: AppColors.green,
              ),
              _metricItem(
                l10n.btnFail,
                '${audit.failCount}',
                color: AppColors.red,
              ),
              _metricItem(
                l10n.btnNa,
                '${audit.naCount}',
                color: AppColors.gray600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildSopBreakdownSection(AppLocalizations l10n, String locale) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.s13SopBreakdown,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 18,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  l10n.s13ExpandSopTooltip,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // SOP Summary Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 44,
              columns: const [
                DataColumn(
                  label: Text('SOP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text(
                    'P',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'F',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'NA',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray600),
                  ),
                ),
                DataColumn(
                  label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: _sops.map((sop) {
                final sopCps = _checkpointsById.values
                    .where((cp) => cp.sopId == sop.id)
                    .toList();
                var p = 0;
                var f = 0;
                var na = 0;
                var pts = 0.0;
                var maxPts = 0.0;

                for (final cp in sopCps) {
                  final result = _resultsByCheckpointId[cp.id];
                  if (result == null) continue;
                  if (result.result == 'P') {
                    p++;
                    pts += cp.weight;
                    maxPts += cp.weight;
                  } else if (result.result == 'F') {
                    f++;
                    maxPts += cp.weight;
                  } else {
                    na++;
                  }
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${sop.id} (${sop.name(locale)})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text('$p')),
                    DataCell(
                      Text(
                        '$f',
                        style: TextStyle(
                          color: f > 0 ? AppColors.red : null,
                          fontWeight: f > 0 ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                    DataCell(Text('$na')),
                    DataCell(Text('${pts.toInt()} / ${maxPts.toInt()}')),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Expandable Checkpoints Accordion per SOP
          ..._sops.map((sop) {
            final sopCps = _checkpointsById.values
                .where((cp) => cp.sopId == sop.id)
                .toList();

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('sop_tile_${sop.id}'),
                title: Text(
                  '${sop.id} — ${sop.name(locale)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                subtitle: Text(
                  '${sopCps.length} Checkpoints',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
                children: [
                  for (final cp in sopCps) _buildCheckpointRow(cp, locale),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCheckpointRow(Checkpoint cp, String locale) {
    final result = _resultsByCheckpointId[cp.id];
    final verdict = result?.result ?? '—';

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    if (verdict == 'P') {
      badgeColor = AppColors.green;
      badgeBg = AppColors.greenPale;
      badgeIcon = Icons.check_circle_outline;
    } else if (verdict == 'F') {
      badgeColor = AppColors.red;
      badgeBg = AppColors.redPale;
      badgeIcon = Icons.cancel_outlined;
    } else {
      badgeColor = AppColors.gray600;
      badgeBg = AppColors.gray100;
      badgeIcon = Icons.remove_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 14, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  verdict,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CP ${cp.id} — ${cp.text(locale)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Weight: ${cp.weight} pts',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailsSection(
    AppLocalizations l10n,
    String locale,
    List<AuditResult> failResults,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.s13FailsTitle(failResults.length),
              style: const TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 18,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: failResults.isEmpty ? AppColors.greenPale : AppColors.redPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${failResults.length}',
                style: TextStyle(
                  color: failResults.isEmpty ? AppColors.green : AppColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (failResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greenPale,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greenMid),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.s13NoFails,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final result in failResults)
            _buildFailCard(l10n, locale, result),
      ],
    );
  }

  Widget _buildFailCard(
    AppLocalizations l10n,
    String locale,
    AuditResult result,
  ) {
    final cp = _checkpointsById[result.checkpointId];
    final cpTitle = cp != null ? cp.text(locale) : 'Checkpoint ${result.checkpointId}';
    final finding = result.findingText ?? '—';
    final photos = _failPhotosByResultId[result.id] ?? const [];
    final linkedCap = _linkedCapsByResultId[result.id];
    final cro = result.croId != null ? _crosById[result.croId] : null;

    return Container(
      key: ValueKey('fail_card_${result.checkpointId}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.redPale,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CP ${result.checkpointId}',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (cp != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${cp.sopId})',
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (cp != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${cp.weight} pts',
                      style: const TextStyle(fontSize: 11, color: AppColors.gray600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cpTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.s13Finding(finding),
            style: const TextStyle(fontSize: 13, color: AppColors.gray800),
          ),
          if (cro != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 14, color: AppColors.gray600),
                const SizedBox(width: 4),
                Text(
                  l10n.s13Cro(cro.name),
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, idx) => InkWell(
                  onTap: () => _showPhotoDialog(context, photos[idx].localPath),
                  borderRadius: BorderRadius.circular(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Image.file(
                          File(photos[idx].localPath),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: AppColors.gray200,
                            child: const Icon(
                              Icons.broken_image,
                              size: 24,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Linked CAP or Create CAP affordance
          if (linkedCap != null) ...[
            InkWell(
              onTap: () => context.pushNamed(
                's16_cap_detail',
                pathParameters: {'id': linkedCap.id},
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amberPale.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 18,
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.s13LinkedCap}: ${linkedCap.id}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          Text(
                            'Status: ${linkedCap.status.toUpperCase()} • Due: ${linkedCap.deadline}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.gray600,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: ValueKey('create_cap_${result.checkpointId}'),
                onPressed: () {
                  context.pushNamed(
                    's15_cap_create',
                    queryParameters: {
                      'auditId': _audit!.id,
                      'checkpointId': result.checkpointId,
                      'resultId': result.id,
                      'problem': result.findingText ?? '',
                    },
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.add_task, size: 16),
                label: Text(l10n.s13CreateCap),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(AppLocalizations l10n, String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment_outlined, size: 18, color: AppColors.gray600),
              const SizedBox(width: 8),
              Text(
                l10n.s13NotesTitle,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 16,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(fontSize: 14, color: AppColors.gray800),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(AppLocalizations l10n, String? userRole) {
    final isSubmitted = _audit?.status == 'submitted';
    final isManagement = userRole == 'OWNER' || userRole == 'GM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GM/Owner Verify Audit button (Phase 2 stub)
        if (isSubmitted && isManagement) ...[
          Tooltip(
            message: l10n.s13VerifyAuditTooltip,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.s13VerifyAuditTooltip)),
                );
              },
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(l10n.s13VerifyAudit),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // PDF Export & WhatsApp Share Row (Phase 2 stubs per sprint plan)
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Tooltip(
                message: l10n.s13ExportPdfTooltip,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.s13ExportPdfTooltip)),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(l10n.s13ExportPdf),
                ),
              ),
              Tooltip(
                message: l10n.s13ShareWhatsAppTooltip,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.s13ShareWhatsAppTooltip)),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(l10n.s13ShareWhatsApp),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('s12_audit_history');
            }
          },
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(l10n.s13BackToHistory),
        ),
      ],
    );
  }
}
