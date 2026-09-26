import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit_result.dart';
import '../../../data/models/checkpoint.dart';
import '../../../data/models/photo.dart';
import '../../../data/models/sop.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../domain/score_engine.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/draft_audit_provider.dart';
import '../../theme/app_colors.dart';

/// Screen S10 — Daily Audit — Review & Submit (Spec §5 S10).
///
/// Shows live computed score card, SOP-by-SOP breakdown table, full fails list
/// with evidence thumbnails and CAP deferred status, 500-char notes field,
/// and enforces mandatory-photo validation before locking the audit to 'submitted'.
class ReviewSubmitScreen extends ConsumerStatefulWidget {
  const ReviewSubmitScreen({super.key});

  @override
  ConsumerState<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends ConsumerState<ReviewSubmitScreen> {
  final _notesController = TextEditingController();
  List<Sop> _sops = const [];
  Map<String, AuditResult> _failResults = const {};
  Map<String, List<Photo>> _failPhotos = const {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final state = ref.read(draftAuditProvider);
    final audit = state.audit;
    final sops = await CheckpointRepository.instance.loadAllSops();

    if (audit == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final failResultsMap = <String, AuditResult>{};
    final failPhotosMap = <String, List<Photo>>{};

    final dbResults = await AuditRepository.instance.resultsForAudit(audit.id);
    for (final r in dbResults) {
      if (r.result == 'F') {
        failResultsMap[r.checkpointId] = r;
        final photos = await AuditRepository.instance.photosForResult(r.id);
        failPhotosMap[r.checkpointId] = photos;
      }
    }

    if (!mounted) return;
    setState(() {
      _sops = sops;
      _failResults = failResultsMap;
      _failPhotos = failPhotosMap;
      _loading = false;
    });
  }

  Future<void> _submitAudit() async {
    final state = ref.read(draftAuditProvider);
    final audit = state.audit;
    if (audit == null) return;

    if (!state.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot submit: only ${state.results.length} of ${state.checkpoints.length} checkpoints marked.',
          ),
        ),
      );
      return;
    }

    // Spec §5 S10 Mandatory Validation:
    // Every Fail with requires_photo_on_fail=1 MUST have at least 1 photo.
    final offendingCheckpoints = <Checkpoint>[];
    for (final cp in state.checkpoints) {
      final verdict = state.results[cp.id];
      if (verdict == Verdict.fail && cp.requiresPhotoOnFail) {
        final photos = _failPhotos[cp.id] ?? const [];
        if (photos.isEmpty) {
          offendingCheckpoints.add(cp);
        }
      }
    }

    if (offendingCheckpoints.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 36),
          title: const Text('Missing Required Photos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following critical checkpoints require photo evidence before submission:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              for (final cp in offendingCheckpoints)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• CP ${cp.id} (${cp.sopId})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Back to Review'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final notes = _notesController.text.trim();
      await ref
          .read(draftAuditProvider.notifier)
          .submitAudit(notes: notes.isEmpty ? null : notes);

      if (!mounted) return;
      context.goNamed('s11_submitted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting audit: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftAuditProvider);
    final audit = state.audit;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (audit == null || state.checkpoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s10Title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active draft audit to review.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.goNamed('s05_home'),
                child: Text(l10n.s11ReturnHome),
              ),
            ],
          ),
        ),
      );
    }

    // Build marks for scoreDaily calculation.
    // Only include checkpoints that have actually been marked — unmarked
    // checkpoints must NOT default to PASS, or an incomplete audit's preview
    // score is inflated. (Submit path already blocks on incomplete audits.)
    final marks = state.checkpoints
        .where((cp) => state.results.containsKey(cp.id))
        .map((cp) {
      final verdict = state.results[cp.id]!;
      return CheckpointMark(
        checkpointId: cp.id,
        result: verdict,
        weight: cp.weight,
      );
    }).toList();

    final score = scoreDaily(marks);
    final failCheckpoints = state.checkpoints
        .where((cp) => state.results[cp.id] == Verdict.fail)
        .toList();

    final color = bandColor(score.compliancePct);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.s10Title} — ${audit.auditDate}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('s07_checkpoint'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!state.isComplete) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.amberPale,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.s10IncompleteWarning,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.goNamed('s07_checkpoint'),
                        child: Text(l10n.btnContinue),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // 1. Score Card (large, prominent)
              _buildScoreCard(l10n, score, color),
              const SizedBox(height: 24),

              // 2. Breakdown by SOP
              _buildSopBreakdown(l10n, locale, state, marks),
              const SizedBox(height: 24),

              // 3. Fails List with Evidence & CAP Status
              _buildFailsSection(l10n, locale, failCheckpoints),
              const SizedBox(height: 24),

              // 4. Auditor Notes (max 500 chars)
              _buildNotesSection(l10n),
              const SizedBox(height: 32),

              // 5. Action Buttons
              FilledButton(
                onPressed: (_submitting || !state.isComplete) ? null : _submitAudit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        l10n.s10SubmitButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.goNamed('s05_home'),
                child: Text(
                  '${l10n.btnSaveDraft} & ${l10n.s11ReturnHome}',
                  style: const TextStyle(color: AppColors.gray600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(AppLocalizations l10n, ScoreResult score, Color color) {
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
                    '${score.compliancePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    l10n.s10ScoreCard,
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
                  score.band.name.toUpperCase(),
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
                l10n.s10ScoreCard,
                '${score.rawScore.toStringAsFixed(0)} / ${score.maxScore.toStringAsFixed(0)}',
              ),
              _metricItem(l10n.btnPass, '${score.passCount}', color: AppColors.green),
              _metricItem(l10n.btnFail, '${score.failCount}', color: AppColors.red),
              _metricItem(l10n.btnNa, '${score.naCount}', color: AppColors.gray600),
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

  Widget _buildSopBreakdown(
    AppLocalizations l10n,
    String locale,
    DraftAuditState state,
    List<CheckpointMark> marks,
  ) {
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
            child: Text(
              l10n.s10SopBreakdown,
              style: const TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 18,
                color: AppColors.navy,
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 44,
              columns: const [
                DataColumn(label: Text('SOP', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green))),
                DataColumn(label: Text('F', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red))),
                DataColumn(label: Text('NA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray600))),
                DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _sops.map((sop) {
                final sopCps = state.checkpoints.where((cp) => cp.sopId == sop.id).toList();
                var p = 0;
                var f = 0;
                var na = 0;
                var pts = 0.0;
                var maxPts = 0.0;

                for (final cp in sopCps) {
                  // Skip unmarked checkpoints — do not count them as PASS.
                  if (!state.results.containsKey(cp.id)) continue;
                  final v = state.results[cp.id]!;
                  if (v == Verdict.pass) {
                    p++;
                    pts += cp.weight;
                    maxPts += cp.weight;
                  } else if (v == Verdict.fail) {
                    f++;
                    maxPts += cp.weight;
                  } else {
                    na++;
                  }
                }

                return DataRow(
                  cells: [
                    DataCell(Text('${sop.id} (${sop.name(locale)})', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('$p')),
                    DataCell(Text('$f', style: TextStyle(color: f > 0 ? AppColors.red : null))),
                    DataCell(Text('$na')),
                    DataCell(Text('${pts.toInt()} / ${maxPts.toInt()}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailsSection(
    AppLocalizations l10n,
    String locale,
    List<Checkpoint> failCheckpoints,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.s10FailsTitle(failCheckpoints.length),
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
                color: failCheckpoints.isEmpty ? AppColors.greenPale : AppColors.redPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${failCheckpoints.length}',
                style: TextStyle(
                  color: failCheckpoints.isEmpty ? AppColors.green : AppColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (failCheckpoints.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greenPale,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greenMid),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.green),
                SizedBox(width: 12),
                Text(
                  'No failures recorded in this audit!',
                  style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          for (final cp in failCheckpoints) _buildFailCard(l10n, locale, cp),
      ],
    );
  }

  Widget _buildFailCard(AppLocalizations l10n, String locale, Checkpoint cp) {
    final result = _failResults[cp.id];
    final photos = _failPhotos[cp.id] ?? const [];
    final finding = result?.findingText ?? 'No finding text recorded';

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redPale,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CP ${cp.id}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cp.text(locale),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CAP Deferred',
                  style: TextStyle(fontSize: 11, color: AppColors.gray600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Finding: $finding',
            style: const TextStyle(fontSize: 13, color: AppColors.gray800),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, idx) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(photos[idx].localPath),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.gray200,
                      child: const Icon(Icons.broken_image, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ] else if (cp.requiresPhotoOnFail) ...[
            const SizedBox(height: 6),
            Text(
              '⚠️ ${l10n.s10MissingPhotoWarning}',
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.s10NotesLabel,
          style: const TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 16,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add general audit observations or context (up to 500 characters)...',
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gray300),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
