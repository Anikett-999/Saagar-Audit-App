import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/audit_result.dart';
import '../../../data/models/checkpoint.dart';
import '../../../data/models/photo.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/iso_week.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S18 — 7-Day Daily Review & GM Spot-Check Screen (Spec §5 T2.3 / Phase-2 Day 6).
///
/// Surfaces the 7 daily audits for a weekly audit's ISO week.
/// Allows GM/Owner to randomly sample 3 checkpoints per day, validate against
/// original evidence and registers, and stamp the day as GM-verified.
class SevenDayReviewScreen extends ConsumerStatefulWidget {
  const SevenDayReviewScreen({
    super.key,
    this.weekNumber,
    this.year,
  });

  final int? weekNumber;
  final int? year;

  @override
  ConsumerState<SevenDayReviewScreen> createState() => _SevenDayReviewScreenState();
}

class _SevenDayReviewScreenState extends ConsumerState<SevenDayReviewScreen> {
  late int _weekNumber;
  late int _year;

  bool _loading = true;
  List<Audit> _dailyAudits = const [];
  Map<String, String> _userNames = const {};
  Map<String, Checkpoint> _checkpointsById = const {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekNumber = widget.weekNumber ?? isoWeek(now);
    _year = widget.year ?? now.year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final dailyAudits = await AuditRepository.instance.findSubmittedDailyAuditsForWeek(
        weekNumber: _weekNumber,
        year: _year,
      );

      final checkpoints = await CheckpointRepository.instance.loadAllCheckpoints();
      final cpMap = <String, Checkpoint>{for (final cp in checkpoints) cp.id: cp};

      final names = <String, String>{};
      for (final a in dailyAudits) {
        if (!names.containsKey(a.auditorId)) {
          final u = await UserRepository.instance.getById(a.auditorId);
          if (u != null) names[a.auditorId] = u.name;
        }
        if (a.verifierId != null && !names.containsKey(a.verifierId!)) {
          final u = await UserRepository.instance.getById(a.verifierId!);
          if (u != null) names[a.verifierId!] = u.name;
        }
      }

      if (!mounted) return;
      setState(() {
        _dailyAudits = dailyAudits;
        _checkpointsById = cpMap;
        _userNames = names;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _localizedWeekday(int weekday, String locale) {
    if (locale == 'mr') {
      switch (weekday) {
        case 1:
          return 'सोमवार';
        case 2:
          return 'मंगळवार';
        case 3:
          return 'बुधवार';
        case 4:
          return 'गुरुवार';
        case 5:
          return 'शुक्रवार';
        case 6:
          return 'शनिवार';
        case 7:
          return 'रविवार';
        default:
          return '';
      }
    }
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _openSpotCheck(Audit audit) async {
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null || user.isSm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only General Manager or Owner can perform spot-checks.')),
      );
      return;
    }

    // Load results for this audit
    final results = await AuditRepository.instance.resultsForAudit(audit.id);
    if (results.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No checkpoint results recorded for this audit.')),
      );
      return;
    }

    // Draw up to 3 checkpoints randomly
    final candidateResults = List<AuditResult>.from(results)..shuffle();
    final spotCheckResults = candidateResults.take(3).toList();

    // Load any photos attached to these results
    final photosByResultId = <String, List<Photo>>{};
    for (final r in spotCheckResults) {
      final photos = await AuditRepository.instance.photosForResult(r.id);
      photosByResultId[r.id] = photos;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SpotCheckSheet(
        audit: audit,
        verifierId: user.id,
        verifierName: user.name,
        results: spotCheckResults,
        photosByResultId: photosByResultId,
        checkpointsById: _checkpointsById,
        onVerified: () {
          Navigator.of(ctx).pop();
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.weeklyReviewVerifySuccess),
              backgroundColor: AppColors.green,
            ),
          );
        },
        onDiscrepancy: () {
          Navigator.of(ctx).pop();
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.weeklyReviewDiscrepancySuccess),
              backgroundColor: AppColors.amber,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final weekDates = isoWeekDates(year: _year, week: _weekNumber);

    // Count how many are verified
    final verifiedCount = _dailyAudits.where((a) => a.status == 'verified').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weeklyReviewTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Week Header Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.s05WeekNumberLabel(_weekNumber, _year),
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontFamily: 'DMSerifDisplay',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: verifiedCount == 7
                                    ? AppColors.green
                                    : (verifiedCount > 0 ? AppColors.gold : AppColors.gray600),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$verifiedCount / 7 Verified',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.weeklyReviewSubtitle,
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7 Day Cards (Day 1..7)
                  for (var i = 0; i < 7; i++) ...[
                    _buildDayCard(
                      dayIndex: i + 1,
                      date: weekDates[i],
                      locale: locale,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDayCard({
    required int dayIndex,
    required DateTime date,
    required String locale,
    required AppLocalizations l10n,
  }) {
    final dateStr = _formatDate(date);
    final weekdayStr = _localizedWeekday(date.weekday, locale);
    final headerTitle = l10n.weeklyReviewDayCardHeader(dayIndex, weekdayStr);

    final audit = _dailyAudits.cast<Audit?>().firstWhere(
          (a) => a?.auditDate == dateStr,
          orElse: () => null,
        );

    // Missing Audit State
    if (audit == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.weeklyReviewNoAuditSubmitted,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.weeklyReviewStatusMissing,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Submitted or Verified Audit State
    final isVerified = audit.status == 'verified';
    final pct = audit.compliancePct ?? 0.0;
    final color = bandColor(pct);
    final auditorName = _userNames[audit.auditorId] ?? audit.auditorId;
    final verifierName = audit.verifierId != null ? _userNames[audit.verifierId!] ?? audit.verifierId! : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isVerified ? AppColors.green : AppColors.gray300,
          width: isVerified ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.greenPale : AppColors.amberPale,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified ? AppColors.green : AppColors.amber,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle : Icons.schedule,
                      size: 13,
                      color: isVerified ? AppColors.green : AppColors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? l10n.weeklyReviewStatusVerified : l10n.weeklyReviewStatusSubmitted,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? AppColors.green : AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Score chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}% (${(audit.band ?? '').toUpperCase()})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                'P: ${audit.passCount}   F: ${audit.failCount}   NA: ${audit.naCount}',
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Auditor: $auditorName',
            style: const TextStyle(fontSize: 12, color: AppColors.gray800),
          ),
          if (isVerified && verifierName != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.weeklyReviewVerifiedBadge(
                verifierName,
                audit.verifiedAt != null && audit.verifiedAt!.length >= 16
                    ? audit.verifiedAt!.substring(0, 16).replaceFirst('T', ' ')
                    : '—',
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.pushNamed(
                    's13_audit_detail',
                    pathParameters: {'id': audit.id},
                  ),
                  child: Text(l10n.s13Title),
                ),
                if (!isVerified)
                  FilledButton.icon(
                    onPressed: () => _openSpotCheck(audit),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: Text(l10n.weeklyReviewStartSpotCheck),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Spot-Check Modal (Spec §5 T2.3).
class _SpotCheckSheet extends StatefulWidget {
  const _SpotCheckSheet({
    required this.audit,
    required this.verifierId,
    required this.verifierName,
    required this.results,
    required this.photosByResultId,
    required this.checkpointsById,
    required this.onVerified,
    required this.onDiscrepancy,
  });

  final Audit audit;
  final String verifierId;
  final String verifierName;
  final List<AuditResult> results;
  final Map<String, List<Photo>> photosByResultId;
  final Map<String, Checkpoint> checkpointsById;
  final VoidCallback onVerified;
  final VoidCallback onDiscrepancy;

  @override
  State<_SpotCheckSheet> createState() => _SpotCheckSheetState();
}

class _SpotCheckSheetState extends State<_SpotCheckSheet> {
  final Set<String> _verifiedResultIds = {};
  bool _submitting = false;

  void _showDiscrepancyDialog(AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.weeklyReviewDiscrepancyDialogTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.weeklyReviewDiscrepancyHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.weeklyReviewCancel),
          ),
          FilledButton(
            onPressed: () async {
              final note = controller.text.trim();
              if (note.isEmpty) return;
              Navigator.of(ctx).pop();
              setState(() => _submitting = true);
              try {
                await AuditRepository.instance.flagDailyAuditDiscrepancy(
                  auditId: widget.audit.id,
                  verifierId: widget.verifierId,
                  discrepancyNote: note,
                );
                widget.onDiscrepancy();
              } finally {
                if (mounted) setState(() => _submitting = false);
              }
            },
            child: Text(l10n.weeklyReviewConfirmDiscrepancy),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAndSign(AppLocalizations l10n) async {
    if (_verifiedResultIds.length < widget.results.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.weeklyReviewAllCheckpointsMustBeVerified)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await AuditRepository.instance.verifyDailyAudit(
        auditId: widget.audit.id,
        verifierId: widget.verifierId,
        notes: 'Verified 3 random spot-check checkpoints by ${widget.verifierName}',
      );
      widget.onVerified();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    }
  }

  void _showPhotoDialog(String localPath) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              child: Image.file(
                File(localPath),
                fit: BoxFit.contain,
                cacheWidth: 800,
                cacheHeight: 800,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Could not load photo'),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
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
    final allChecked = _verifiedResultIds.length == widget.results.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weeklyReviewSpotCheckTitle,
                        style: const TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 18,
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.audit.auditDate} · GM: ${widget.verifierName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.weeklyReviewSpotCheckSubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
            ),
          ),
          // 3 Checkpoints list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: widget.results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, idx) {
                final result = widget.results[idx];
                final cp = widget.checkpointsById[result.checkpointId];
                final isChecked = _verifiedResultIds.contains(result.id);
                final photos = widget.photosByResultId[result.id] ?? const [];

                final verdictStr = result.result == 'P'
                    ? 'PASS'
                    : (result.result == 'F' ? 'FAIL' : 'NA');
                final verdictColor = result.result == 'P'
                    ? AppColors.green
                    : (result.result == 'F' ? AppColors.red : AppColors.gray600);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isChecked ? AppColors.greenPale : AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked ? AppColors.green : AppColors.gray300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.navyLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CP ${result.checkpointId}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.weeklyReviewCheckpointStep(idx + 1, widget.results.length),
                              style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: verdictColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              verdictStr,
                              style: TextStyle(
                                color: verdictColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cp != null ? cp.text(locale) : 'Checkpoint ${result.checkpointId}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      if (result.findingText != null && result.findingText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Finding: ${result.findingText}',
                          style: const TextStyle(fontSize: 13, color: AppColors.gray800),
                        ),
                      ],
                      if (photos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, pIdx) => GestureDetector(
                              onTap: () => _showPhotoDialog(photos[pIdx].localPath),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(photos[pIdx].localPath),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  cacheWidth: 150,
                                  cacheHeight: 150,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 50,
                                    color: AppColors.gray200,
                                    child: const Icon(Icons.broken_image, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                if (isChecked) {
                                  _verifiedResultIds.remove(result.id);
                                } else {
                                  _verifiedResultIds.add(result.id);
                                }
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isChecked ? AppColors.green : AppColors.gray800,
                              side: BorderSide(
                                color: isChecked ? AppColors.green : AppColors.gray400,
                              ),
                            ),
                            icon: Icon(
                              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 18,
                            ),
                            label: Text(l10n.weeklyReviewMarkVerified),
                          ),
                          TextButton(
                            onPressed: () => _showDiscrepancyDialog(l10n),
                            child: Text(
                              l10n.weeklyReviewFlagDiscrepancy,
                              style: const TextStyle(color: AppColors.amber),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bottom verification action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: (_submitting || !allChecked)
                    ? null
                    : () => _verifyAndSign(l10n),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
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
                        l10n.weeklyReviewVerifyAndSignButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
