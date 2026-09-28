import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/report.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S20: Weekly Reports List (Workbook Day 3 §3.6 & Spec §5 S20).
class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  bool _loading = true;
  List<Report> _reports = [];
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final reports = await ReportRepository.instance.listReports(
        reportType: 'weekly',
        year: _selectedYear,
      );
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;
    final isOwner = currentUser?.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s20ScreenTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(l10n.s20FilterAll),
                    selected: _selectedYear == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedYear = null);
                        _loadReports();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(DateTime.now().year.toString()),
                    selected: _selectedYear == DateTime.now().year,
                    onSelected: (selected) {
                      setState(() => _selectedYear = selected ? DateTime.now().year : null);
                      _loadReports();
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Reports List or Empty State
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    child: _reports.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.assessment_outlined,
                                        size: 64,
                                        color: AppColors.gray400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.s20EmptyTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.navy,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.s20EmptySubtitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.gray600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              return _buildReportCard(context, l10n, report, isOwner);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    AppLocalizations l10n,
    Report report,
    bool isOwner,
  ) {
    final compTable = report.complianceTable;
    final pct = (compTable['compliance_pct'] as num?)?.toDouble() ?? 0.0;
    final bandName = (compTable['band'] as String?)?.toUpperCase() ?? 'UNKNOWN';
    final color = bandColor(pct);

    final submittedDateStr = report.submittedAt != null
        ? report.submittedAt!.split('T').first
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.pushNamed(
            's21_report_detail',
            pathParameters: {'id': report.id},
          );
          if (mounted) _loadReports();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Date/Header + Score Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.headline ?? 'Weekly Report · $submittedDateStr',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color, width: 1),
                    ),
                    child: Text(
                      l10n.s20ReportCardScore(pct.toStringAsFixed(1), bandName),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Owner-only Read Status Dot (Spec §5 S20)
              if (isOwner) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: report.isReadByOwner ? AppColors.green : AppColors.gray400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      report.isReadByOwner ? l10n.s20OwnerRead : l10n.s20OwnerUnread,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: report.isReadByOwner ? AppColors.green : AppColors.gray600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.gray400,
                    ),
                  ],
                ),
              ] else ...[
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
