import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
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
  String _selectedType = 'all'; // 'all', 'weekly', 'monthly'
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      List<Report> reports = [];
      if (_selectedType == 'weekly') {
        reports = await ReportRepository.instance.listReports(
          reportType: 'weekly',
          year: _selectedYear,
        );
      } else if (_selectedType == 'monthly') {
        reports = await ReportRepository.instance.listReports(
          reportType: 'monthly',
          year: _selectedYear,
        );
      } else {
        final weekly = await ReportRepository.instance.listReports(
          reportType: 'weekly',
          year: _selectedYear,
        );
        final monthly = await ReportRepository.instance.listReports(
          reportType: 'monthly',
          year: _selectedYear,
        );
        reports = [...weekly, ...monthly]..sort((a, b) {
            final aDate = a.submittedAt ?? '';
            final bDate = b.submittedAt ?? '';
            return bDate.compareTo(aDate);
          });
      }

      // If reports is empty, check if there are submitted audits that haven't generated a report row yet
      if (reports.isEmpty) {
        final db = AppDatabase.instance.db;
        final submittedWeekly = await db.query(
          'audits',
          where: "status = 'submitted' AND audit_type = 'weekly'",
          orderBy: 'audit_date DESC',
        );
        for (final w in submittedWeekly) {
          final auditId = w['id'].toString();
          final existing = await ReportRepository.instance.getByAuditId(auditId);
          if (existing == null) {
            try {
              await ReportRepository.instance.generateWeeklyReport(
                weeklyAuditId: auditId,
                authorUserId: w['auditor_id']?.toString() ?? 'GM Auditor',
              );
            } catch (_) {}
          }
        }

        final submittedMonthly = await db.query(
          'audits',
          where: "status = 'submitted' AND audit_type = 'monthly'",
          orderBy: 'audit_date DESC',
        );
        for (final m in submittedMonthly) {
          final auditId = m['id'].toString();
          final existing = await ReportRepository.instance.getByAuditId(auditId);
          if (existing == null) {
            try {
              await ReportRepository.instance.generateMonthlyReport(
                monthlyAuditId: auditId,
                authorUserId: m['auditor_id']?.toString() ?? 'Owner Auditor',
              );
            } catch (_) {}
          }
        }

        if (_selectedType == 'weekly') {
          reports = await ReportRepository.instance.listReports(
            reportType: 'weekly',
            year: _selectedYear,
          );
        } else if (_selectedType == 'monthly') {
          reports = await ReportRepository.instance.listReports(
            reportType: 'monthly',
            year: _selectedYear,
          );
        } else {
          final weekly = await ReportRepository.instance.listReports(
            reportType: 'weekly',
            year: _selectedYear,
          );
          final monthly = await ReportRepository.instance.listReports(
            reportType: 'monthly',
            year: _selectedYear,
          );
          reports = [...weekly, ...monthly]..sort((a, b) {
              final aDate = a.submittedAt ?? '';
              final bDate = b.submittedAt ?? '';
              return bDate.compareTo(aDate);
            });
        }
      }

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

  Future<void> _generateSampleReport(String authorName) async {
    setState(() => _loading = true);
    try {
      final db = AppDatabase.instance.db;
      final reportId = 'rep-${DateTime.now().millisecondsSinceEpoch}';
      final auditId = 'audit-sample-${DateTime.now().millisecondsSinceEpoch}';

      await db.insert('reports', {
        'id': reportId,
        'audit_id': auditId,
        'report_type': 'weekly',
        'headline': 'आठवडा ३९ समाप्त २०२६-०९-२७ · ८४.५% निकृष्ट · २ त्रुटी · १ पॅटर्न',
        'compliance_table_json': jsonEncode({
          'avg_daily_pct': 84.1,
          'daily_contribution': 57.2,
          'weekly_raw': 47.6,
          'weekly_max': 56.0,
          'total_raw': 104.8,
          'total_max': 124.0,
          'compliance_pct': 84.5,
          'band': 'poor',
          'sop_rows': [
            {'sop_id': 'SOP9', 'sop_number': 9, 'name_en': 'Store Operations', 'name_mr': 'स्टोअर ऑपरेशन्स', 'raw_score': 10.0, 'max_score': 10.0, 'compliance_pct': 100.0},
            {'sop_id': 'SOP1', 'sop_number': 1, 'name_en': 'Cash Counter', 'name_mr': 'कॅश काउंटर', 'raw_score': 14.0, 'max_score': 16.0, 'compliance_pct': 87.5},
            {'sop_id': 'SOP2', 'sop_number': 2, 'name_en': 'Customer Service', 'name_mr': 'ग्राहक सेवा', 'raw_score': 6.0, 'max_score': 6.0, 'compliance_pct': 100.0},
            {'sop_id': 'SOP7', 'sop_number': 7, 'name_en': 'Inventory', 'name_mr': 'इन्व्हेंटरी', 'raw_score': 17.6, 'max_score': 24.0, 'compliance_pct': 73.3},
          ],
        }),
        'trend_block_json': jsonEncode({
          'daily_pcts': [90.0, 85.0, 80.0, 95.0, 75.0, 88.0, 75.7],
          'wow_delta': -2.1,
        }),
        'findings_json': jsonEncode([
          {'checkpoint_id': 'IW.11', 'sop_name_en': 'Inventory', 'sop_name_mr': 'इन्व्हेंटरी', 'finding_text': 'अग्निशामक टॅग गहाळ (Missing extinguisher tag)', 'photo_count': 1},
          {'checkpoint_id': 'CW.4', 'sop_name_en': 'Cash Counter', 'sop_name_mr': 'कॅश काउंटर', 'finding_text': 'हस्तलिखित बिल आढळले (Handwritten slip in cash drawer)', 'photo_count': 1},
        ]),
        'patterns_json': jsonEncode([
          {
            'checkpoint_id': 'CP.4',
            'fail_count': 3,
            'dates': ['2026-09-21', '2026-09-22', '2026-09-23'],
            'weekdays_en': ['Mon', 'Tue', 'Wed'],
            'weekdays_mr': ['सोम', 'मंगळ', 'बुध'],
            'findings': ['काचेवर धूळ आढळली (Dirty counter glass)'],
          }
        ]),
        'caps_opened_json': jsonEncode([
          {
            'is_pattern': true,
            'checkpoint_id': 'CP.4',
            'problem_statement_en': 'Recurring failure on Checkpoint CP.4 (Display Glass)',
            'problem_statement_mr': 'तपासणी बिंदू CP.4 वर वारंवार अयशस्वी (डिस्प्ले काच)',
            'action_plan_en': 'Brief morning shift CROs and inspect daily before 10 AM',
            'action_plan_mr': 'सकाळच्या शिफ्टमधील CRO ना सूचना द्या आणि सकाळी १० पूर्वी दररोज तपासणी करा',
          }
        ]),
        'author_user_id': authorName,
        'submitted_at': '2026-09-27T18:00:00Z',
        'read_by_owner_at': null,
      });

      await _loadReports();
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
                    selected: _selectedType == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = 'all');
                        _loadReports();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n.s20FilterWeekly),
                    selected: _selectedType == 'weekly',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = 'weekly');
                        _loadReports();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n.s20FilterMonthly),
                    selected: _selectedType == 'monthly',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = 'monthly');
                        _loadReports();
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: AppColors.gray300),
                  const SizedBox(width: 12),
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
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.play_arrow_rounded),
                                        label: Text(l10n.s05StartWeeklyAudit),
                                        onPressed: () async {
                                          await context.push('/audit/start?type=weekly');
                                          if (mounted) _loadReports();
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.auto_awesome),
                                        label: const Text('Generate Sample Weekly Report'),
                                        onPressed: () => _generateSampleReport(currentUser?.name ?? 'Aniket (Owner)'),
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
    final pct = (compTable['monthly_spot_check_pct'] as num?)?.toDouble() ??
        (compTable['compliance_pct'] as num?)?.toDouble() ??
        0.0;
    final bandName = ((compTable['monthly_band'] ?? compTable['band']) as String?)?.toUpperCase() ?? 'UNKNOWN';
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
              // Type chip & date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: report.reportType == 'monthly'
                          ? AppColors.navy.withValues(alpha: 0.1)
                          : AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: report.reportType == 'monthly' ? AppColors.navy : AppColors.gold,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      report.reportType == 'monthly' ? l10n.s20FilterMonthly : l10n.s20FilterWeekly,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: report.reportType == 'monthly' ? AppColors.navy : AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    submittedDateStr,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Top Row: Date/Header + Score Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.headline ?? '${report.reportType == 'monthly' ? 'Monthly' : 'Weekly'} Report · $submittedDateStr',
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
