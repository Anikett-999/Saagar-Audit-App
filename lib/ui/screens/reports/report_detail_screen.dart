import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/report.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/weekly_report_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S21: Weekly Report Detail (Workbook Day 3 §3.6 Nine-Section Format & Spec §5 S21).
class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  final String reportId;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _loading = true;
  Report? _report;
  bool _markingRead = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final report = await ReportRepository.instance.getById(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead() async {
    final report = _report;
    final user = ref.read(authProvider).user;
    if (report == null || user == null || !user.isOwner) return;

    setState(() => _markingRead = true);
    try {
      await ReportRepository.instance.markReadByOwner(
        reportId: report.id,
        ownerUserId: user.id,
      );
      final updated = await ReportRepository.instance.getById(report.id);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _markingRead = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.s21MarkedAsReadSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingRead = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _exportingPdf = true);
    try {
      await WeeklyReportPdfService.instance.shareOrPrintPdf(report);
      if (!mounted) return;
      setState(() => _exportingPdf = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _exportingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.s21PdfExportError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;
    final isOwner = currentUser?.isOwner ?? false;
    final locale = Localizations.localeOf(context).languageCode;
    final isMr = locale == 'mr';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s21ScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final report = _report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s21ScreenTitle)),
        body: const Center(child: Text('Report not found.')),
      );
    }

    final compTable = report.complianceTable;
    final pct = (compTable['compliance_pct'] as num?)?.toDouble() ?? 0.0;
    final bandName = (compTable['band'] as String?)?.toUpperCase() ?? 'UNKNOWN';
    final color = bandColor(pct);

    final trend = report.trendBlock;
    final findings = report.findings;
    final patterns = report.patterns;
    final capsOpened = report.capsOpened;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s21ScreenTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subtitle / Standard Banner
          Text(
            l10n.s21WorkbookSubtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 12),

          // --- Section 1: Executive Headline ---
          _sectionCard(
            title: l10n.s21HeadlineSection,
            icon: Icons.title,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.headline ?? 'Weekly Compliance Report',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Text(
                    '$bandName · ${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Section 2: 124-Point Compliance Table ---
          _sectionCard(
            title: l10n.s21ComplianceSection,
            icon: Icons.table_chart_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Rollup Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    children: [
                      _scoreRow(
                        l10n.s21DailyAvgContribution,
                        '${(compTable['daily_contribution'] as num?)?.toStringAsFixed(1) ?? "0.0"} / 68.0 pts (${(compTable['avg_daily_pct'] as num?)?.toStringAsFixed(1) ?? "0.0"}%)',
                      ),
                      const Divider(height: 12),
                      _scoreRow(
                        l10n.s21WeeklyOnlyCheckpoints,
                        '${(compTable['weekly_raw'] as num?)?.toStringAsFixed(1) ?? "0.0"} / ${(compTable['weekly_max'] as num?)?.toStringAsFixed(0) ?? "56"} pts',
                      ),
                      const Divider(height: 12),
                      _scoreRow(
                        l10n.s21CombinedTotal,
                        '${(compTable['total_raw'] as num?)?.toStringAsFixed(1) ?? "0.0"} / ${(compTable['total_max'] as num?)?.toStringAsFixed(0) ?? "124"} pts (${pct.toStringAsFixed(1)}% $bandName)',
                        isBold: true,
                        valueColor: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Per-SOP Table
                Text(
                  l10n.s21SopBreakdownHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                _buildSopTable(compTable['sop_rows'] as List<dynamic>?, isMr),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Section 3: 7-Day Trend Block & WoW Delta ---
          _sectionCard(
            title: l10n.s21TrendSection,
            icon: Icons.trending_up_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrendDays(trend),
                const SizedBox(height: 10),
                const Divider(),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.s21WeeklyRollup(pct.toStringAsFixed(1)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      trend['wow_delta'] != null
                          ? l10n.s21WowDelta(
                              ((trend['wow_delta'] as num).toDouble() >= 0 ? '+' : '') +
                                  (trend['wow_delta'] as num).toStringAsFixed(1),
                            )
                          : l10n.s21WowDeltaNa,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (trend['wow_delta'] as num?)?.toDouble() != null &&
                                (trend['wow_delta'] as num).toDouble() < 0
                            ? AppColors.red
                            : AppColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Section 4: Findings (Weekly Non-Compliances) ---
          _sectionCard(
            title: l10n.s21FindingsSection(findings.length),
            icon: Icons.warning_amber_rounded,
            child: findings.isEmpty
                ? Text(
                    l10n.s21NoFindings,
                    style: const TextStyle(color: AppColors.gray600, fontStyle: FontStyle.italic),
                  )
                : Column(
                    children: [
                      for (final f in findings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${f['checkpoint_id']} · ${isMr ? f['sop_name_mr'] : f['sop_name_en']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      f['finding_text']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13, color: AppColors.gray800),
                                    ),
                                    if ((f['photo_count'] as int? ?? 0) > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          l10n.s21PhotosCount(f['photo_count'] as int),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // --- Section 5: Patterns (T2.4) ---
          _sectionCard(
            title: l10n.s21PatternsSection(patterns.length),
            icon: Icons.bubble_chart_outlined,
            child: patterns.isEmpty
                ? Text(
                    l10n.s21NoPatterns,
                    style: const TextStyle(color: AppColors.gray600, fontStyle: FontStyle.italic),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in patterns) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.amberPale,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.amber),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checkpoint ${p.checkpointId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.s21PatternDetectedOnDays(
                                  p.failCount,
                                  isMr ? p.weekdaysMr.join(', ') : p.weekdaysEn.join(', '),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.amber,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.s21SuggestedPatternCap,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                isMr
                                    ? p.toSuggestedCap().suggestedActionMr
                                    : p.toSuggestedCap().suggestedActionEn,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          // --- Section 6: Corrective Action Plans (CAPs) ---
          _sectionCard(
            title: l10n.s21CapsSection,
            icon: Icons.assignment_turned_in_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.s21CapsOpenedHeader(capsOpened.length),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                for (final c in capsOpened)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${c['checkpoint_id']}: ${isMr ? c['problem_statement_mr'] : c['problem_statement_en']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                const Divider(height: 16),

                // Section 7: CAPs Closed (P2-5 honest empty state)
                Text(
                  l10n.s21CapsClosedHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.s21CapsClosedEmpty,
                  style: const TextStyle(color: AppColors.gray600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const Divider(height: 16),

                // Section 8: Aged CAPs (P2-5 honest empty state)
                Text(
                  l10n.s21CapsAgedHeader,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.s21CapsAgedEmpty,
                  style: const TextStyle(color: AppColors.gray600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Section 9: Escalations (Phase 3 honest empty state) ---
          _sectionCard(
            title: l10n.s21EscalationsSection,
            icon: Icons.campaign_outlined,
            child: Text(
              l10n.s21EscalationsEmpty,
              style: const TextStyle(color: AppColors.gray600, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 12),

          // --- Signature of Record ---
          _sectionCard(
            title: l10n.s21SignatureSection,
            icon: Icons.verified_user_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.s21AuditorSignature(
                    report.authorUserId ?? 'GM Auditor',
                    report.submittedAt != null ? report.submittedAt!.split('T').first : 'Submitted',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  report.isReadByOwner
                      ? l10n.s21OwnerSignature(report.readByOwnerAt?.split('T').first ?? '')
                      : l10n.s21OwnerSignaturePending,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: report.isReadByOwner ? AppColors.green : AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Bottom Actions ---
          if (isOwner) ...[
            ElevatedButton.icon(
              icon: _markingRead
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(report.isReadByOwner ? Icons.check_circle : Icons.mark_email_read),
              label: Text(report.isReadByOwner ? l10n.s20OwnerRead : l10n.s21MarkAsReadButton),
              onPressed: report.isReadByOwner || _markingRead ? null : _markAsRead,
            ),
            const SizedBox(height: 10),
          ],

          OutlinedButton.icon(
            icon: _exportingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(l10n.s21ExportPdfButton),
            onPressed: _exportingPdf ? null : _exportPdf,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSopTable(List<dynamic>? sopRows, bool isMr) {
    if (sopRows == null || sopRows.isEmpty) {
      return const Text('No SOP data', style: TextStyle(fontSize: 12));
    }

    return Table(
      border: TableBorder.all(color: AppColors.gray300, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(3.0),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.4),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppColors.gray100),
          children: [
            Padding(padding: EdgeInsets.all(4), child: Text('SOP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(4), child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(4), child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(4), child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        for (final s in sopRows)
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(4), child: Text('SOP ${s['sop_number'] ?? ''}', style: const TextStyle(fontSize: 11))),
              Padding(padding: const EdgeInsets.all(4), child: Text((isMr ? s['name_mr'] : s['name_en'])?.toString() ?? '', style: const TextStyle(fontSize: 11))),
              Padding(padding: const EdgeInsets.all(4), child: Text('${(s['raw_score'] as num?)?.toStringAsFixed(0)}/${(s['max_score'] as num?)?.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))),
              Padding(padding: const EdgeInsets.all(4), child: Text('${(s['compliance_pct'] as num?)?.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11))),
            ],
          ),
      ],
    );
  }

  Widget _buildTrendDays(Map<String, dynamic> trend) {
    final dailyPcts = (trend['daily_pcts'] as List?)?.cast<num>() ?? [];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (int i = 0; i < 7; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: i < dailyPcts.length && dailyPcts[i] > 0
                  ? bandColor(dailyPcts[i].toDouble()).withValues(alpha: 0.1)
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: i < dailyPcts.length && dailyPcts[i] > 0
                    ? bandColor(dailyPcts[i].toDouble()).withValues(alpha: 0.5)
                    : AppColors.gray300,
              ),
            ),
            child: Text(
              i < dailyPcts.length && dailyPcts[i] > 0
                  ? '${weekdays[i]}: ${dailyPcts[i].toStringAsFixed(0)}%'
                  : '${weekdays[i]}: Absent',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: i < dailyPcts.length && dailyPcts[i] > 0
                    ? bandColor(dailyPcts[i].toDouble())
                    : AppColors.gray600,
              ),
            ),
          ),
      ],
    );
  }
}
