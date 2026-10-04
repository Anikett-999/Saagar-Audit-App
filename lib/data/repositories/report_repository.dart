import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/audit.dart';
import '../models/audit_result.dart';
import '../models/report.dart';
import '../repositories/audit_repository.dart';
import '../repositories/checkpoint_repository.dart';
import '../../domain/iso_week.dart';
import '../../domain/pattern_detection.dart';
import '../../domain/score_engine.dart';
import '../../domain/trend_analytics.dart';

/// Repository for generating, persisting, and querying reports (Workbook Day 3 §3.6).
class ReportRepository {
  ReportRepository._();
  static final ReportRepository instance = ReportRepository._();

  /// Generates and persists a 9-section weekly report for a submitted weekly audit.
  /// If a report already exists for [weeklyAuditId], it is refreshed and returned.
  Future<Report> generateWeeklyReport({
    required String weeklyAuditId,
    required String authorUserId,
  }) async {
    final db = AppDatabase.instance.db;

    // 1. Fetch the weekly audit
    final weeklyAudit = await AuditRepository.instance.getById(weeklyAuditId);
    if (weeklyAudit == null) {
      throw StateError('Cannot generate report: Audit $weeklyAuditId not found');
    }
    if (weeklyAudit.auditType != 'weekly') {
      throw StateError('Cannot generate weekly report for non-weekly audit');
    }

    final weekNumber = weeklyAudit.weekNumber;
    final year = weeklyAudit.year;

    // 2. Fetch the 7 daily audits for this week
    final dailyAudits = await AuditRepository.instance.findSubmittedDailyAuditsForWeek(
      weekNumber: weekNumber,
      year: year,
    );

    // 3. Compute 124-point weekly score rollup
    final weekDates = isoWeekDates(year: year, week: weekNumber);
    final List<double> dailyPcts = [];
    final List<String> dailyDateStrs = [];

    for (final date in weekDates) {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyDateStrs.add(dateStr);
      final match = dailyAudits.cast<Audit?>().firstWhere(
            (a) => a?.auditDate == dateStr,
            orElse: () => null,
          );
      dailyPcts.add(match?.compliancePct ?? 0.0);
    }

    // Load weekly checkpoint results
    final weeklyResults = await AuditRepository.instance.resultsForAudit(weeklyAuditId);
    final allCheckpoints = await CheckpointRepository.instance.loadAllCheckpoints();
    final cpMap = {for (final cp in allCheckpoints) cp.id: cp};

    final List<CheckpointMark> weeklyMarks = [];
    for (final r in weeklyResults) {
      final cp = cpMap[r.checkpointId];
      if (cp != null) {
        final verdict = r.result == 'P'
            ? Verdict.pass
            : (r.result == 'F' ? Verdict.fail : Verdict.na);
        weeklyMarks.add(
          CheckpointMark(
            checkpointId: r.checkpointId,
            result: verdict,
            weight: cp.weight,
          ),
        );
      }
    }

    final weeklyScore = computeWeeklyScore(
      dailyPcts: dailyPcts,
      weeklyMarks: weeklyMarks,
    );

    // 4. Pattern detection across all daily audits of this week (T2.4)
    final List<DailyFailPoint> failPoints = [];
    for (final da in dailyAudits) {
      final results = await AuditRepository.instance.resultsForAudit(da.id);
      for (final r in results) {
        if (r.result == 'F') {
          failPoints.add(
            DailyFailPoint(
              checkpointId: r.checkpointId,
              auditDate: da.auditDate,
              findingText: r.findingText,
              croId: r.croId,
            ),
          );
        }
      }
    }

    final patterns = detectWeeklyPatterns(failPoints);

    // 5. Build 9 Sections

    // Section 1: Headline
    final weekEndingDate = dailyDateStrs.isNotEmpty ? dailyDateStrs.last : weeklyAudit.auditDate;
    final failCount = weeklyResults.where((r) => r.result == 'F').length;
    final patternCount = patterns.length;
    final bandUpper = weeklyScore.band.name.toUpperCase();
    final headline =
        'Week $weekNumber Ending $weekEndingDate · ${weeklyScore.compliancePct.toStringAsFixed(1)}% $bandUpper · $failCount Failures · $patternCount Patterns';

    // Section 2: Compliance Table
    // Compute per-SOP breakdown for weekly checkpoints
    final allSops = await CheckpointRepository.instance.loadAllSops();
    final sopMap = {for (final s in allSops) s.id: s};

    final Map<String, List<AuditResult>> resultsBySop = {};
    for (final r in weeklyResults) {
      final cp = cpMap[r.checkpointId];
      if (cp != null) {
        resultsBySop.putIfAbsent(cp.sopId, () => []).add(r);
      }
    }

    final List<Map<String, dynamic>> sopRows = [];
    for (final entry in resultsBySop.entries) {
      final sop = sopMap[entry.key];
      if (sop == null) continue;
      double raw = 0;
      double max = 0;
      for (final r in entry.value) {
        final cp = cpMap[r.checkpointId];
        if (cp == null || r.result == 'NA') continue;
        max += cp.weight;
        if (r.result == 'P') raw += cp.weight;
      }
      final pct = max > 0 ? (raw / max) * 100 : 100.0;
      sopRows.add({
        'sop_id': sop.id,
        'sop_number': sop.number,
        'name_en': sop.nameEn,
        'name_mr': sop.nameMr,
        'raw_score': raw,
        'max_score': max,
        'compliance_pct': pct,
      });
    }

    final complianceTablePayload = {
      'avg_daily_pct': weeklyScore.avgDailyPct,
      'daily_contribution': weeklyScore.dailyContribution,
      'weekly_raw': weeklyScore.weeklyRaw,
      'weekly_max': weeklyScore.weeklyMax,
      'total_raw': weeklyScore.totalRaw,
      'total_max': weeklyScore.totalMax,
      'compliance_pct': weeklyScore.compliancePct,
      'band': weeklyScore.band.name,
      'sop_rows': sopRows,
    };

    // Section 3: Trend Block
    // Look up previous week's report if available
    final prevRows = await db.query(
      'reports',
      where: 'report_type = ? AND id != ?',
      whereArgs: ['weekly', weeklyAuditId],
      orderBy: 'submitted_at DESC',
      limit: 1,
    );
    double? prevWeekPct;
    if (prevRows.isNotEmpty) {
      final prevTable = jsonDecode(prevRows.first['compliance_table_json'] as String? ?? '{}');
      if (prevTable['compliance_pct'] is num) {
        prevWeekPct = (prevTable['compliance_pct'] as num).toDouble();
      }
    }
    final double? wowDelta = prevWeekPct != null ? (weeklyScore.compliancePct - prevWeekPct) : null;

    final trendBlockPayload = {
      'daily_pcts': dailyPcts,
      'daily_dates': dailyDateStrs,
      'weekly_pct': weeklyScore.compliancePct,
      'prev_week_pct': prevWeekPct,
      'wow_delta': wowDelta,
    };

    // Section 4: Findings (Weekly Fails)
    final List<Map<String, dynamic>> findingsPayload = [];
    for (final r in weeklyResults) {
      if (r.result == 'F') {
        final cp = cpMap[r.checkpointId];
        final sop = cp != null ? sopMap[cp.sopId] : null;
        final photos = await AuditRepository.instance.photosForResult(r.id);
        findingsPayload.add({
          'checkpoint_id': r.checkpointId,
          'text_en': cp?.textEn ?? '',
          'text_mr': cp?.textMr ?? '',
          'sop_name_en': sop?.nameEn ?? '',
          'sop_name_mr': sop?.nameMr ?? '',
          'finding_text': r.findingText ?? '',
          'photo_count': photos.length,
        });
      }
    }

    // Section 5: Patterns (T2.4)
    final patternsPayload = patterns.map((p) => p.toJson()).toList();

    // Section 6: CAPs Opened (Weekly fails + suggested pattern CAPs)
    final List<Map<String, dynamic>> capsOpenedPayload = [];
    // Suggested pattern CAPs (Single-CAP rule)
    for (final p in patterns) {
      capsOpenedPayload.add({
        'is_pattern': true,
        'checkpoint_id': p.checkpointId,
        'problem_statement_en': p.toSuggestedCap().problemStatementEn,
        'problem_statement_mr': p.toSuggestedCap().problemStatementMr,
        'action_plan_en': p.toSuggestedCap().suggestedActionEn,
        'action_plan_mr': p.toSuggestedCap().suggestedActionMr,
      });
    }

    // Section 7: CAPs Closed (P2-5 honest empty-state)
    final List<Map<String, dynamic>> capsClosedPayload = [];

    // Section 8: CAPs Aged (P2-5 honest empty-state)
    final List<Map<String, dynamic>> capsAgedPayload = [];

    // Section 9: Escalations (Phase 3 honest empty-state)
    final List<Map<String, dynamic>> escalationsPayload = [];

    // 6. Check if report already exists for this audit
    final existing = await getByAuditId(weeklyAuditId);
    final reportId = existing?.id ?? const Uuid().v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final reportMap = <String, Object?>{
      'id': reportId,
      'audit_id': weeklyAuditId,
      'report_type': 'weekly',
      'headline': headline,
      'compliance_table_json': jsonEncode(complianceTablePayload),
      'trend_block_json': jsonEncode(trendBlockPayload),
      'findings_json': jsonEncode(findingsPayload),
      'patterns_json': jsonEncode(patternsPayload),
      'caps_opened_json': jsonEncode(capsOpenedPayload),
      'caps_closed_json': jsonEncode(capsClosedPayload),
      'caps_aged_json': jsonEncode(capsAgedPayload),
      'escalations_json': jsonEncode(escalationsPayload),
      'author_user_id': authorUserId,
      'submitted_at': existing?.submittedAt ?? nowIso,
      'read_by_owner_at': existing?.readByOwnerAt,
      'pdf_local_path': existing?.pdfLocalPath,
      'pdf_cloud_url': existing?.pdfCloudUrl,
    };

    if (existing != null) {
      await db.update(
        'reports',
        reportMap,
        where: 'id = ?',
        whereArgs: [reportId],
      );
    } else {
      await db.insert('reports', reportMap);
    }

    return Report.fromMap(reportMap);
  }

  /// Generates and persists a monthly trend report for a submitted monthly audit.
  /// If a report already exists for [monthlyAuditId], it is refreshed and returned.
  ///
  /// Assembles:
  /// - Monthly spot-check scores (MC.1/MC.2/MC.3)
  /// - Multi-week trend series from existing weekly reports
  /// - 4-week moving average + three §4.5 trend patterns
  /// - Month's CAP + escalation rollup
  Future<Report> generateMonthlyReport({
    required String monthlyAuditId,
    required String authorUserId,
  }) async {
    final db = AppDatabase.instance.db;

    // 1. Fetch the monthly audit
    final monthlyAudit = await AuditRepository.instance.getById(monthlyAuditId);
    if (monthlyAudit == null) {
      throw StateError('Cannot generate monthly report: Audit $monthlyAuditId not found');
    }
    if (monthlyAudit.auditType != 'monthly') {
      throw StateError('Cannot generate monthly report for non-monthly audit');
    }

    final monthNumber = monthlyAudit.monthNumber ?? DateTime.now().month;
    final year = monthlyAudit.year;

    // 2. Fetch the month's weekly reports for trend analysis
    final weeklyReports = await listReports(reportType: 'weekly', year: year, month: monthNumber);

    // 3. Fetch daily audits for the month (for day-of-week clustering analysis)
    final dailyRows = await db.query(
      'audits',
      where: "year = ? AND audit_type = 'daily' AND status IN ('submitted', 'verified')",
      whereArgs: [year],
      orderBy: 'audit_date ASC',
    );
    final allDailyAudits = dailyRows.map(Audit.fromMap).toList();
    // Filter to the target month
    final monthDailyAudits = allDailyAudits.where((a) {
      final dt = DateTime.tryParse(a.auditDate);
      return dt != null && dt.month == monthNumber;
    }).toList();

    // 4. Run trend analytics
    final trendResult = TrendAnalytics.analyze(
      weeklyReports: weeklyReports,
      dailyAudits: monthDailyAudits,
    );

    // 5. Fetch monthly checkpoint results for the spot-check compliance table
    final monthlyResults = await AuditRepository.instance.resultsForAudit(monthlyAuditId);
    final allCheckpoints = await CheckpointRepository.instance.loadAllCheckpoints();
    final allSops = await CheckpointRepository.instance.loadAllSops();
    final cpMap = {for (final cp in allCheckpoints) cp.id: cp};
    final sopMap = {for (final s in allSops) s.id: s};

    // Build per-SOP breakdown from monthly audit results
    final Map<String, List<AuditResult>> resultsBySop = {};
    for (final r in monthlyResults) {
      final cp = cpMap[r.checkpointId];
      if (cp != null) {
        resultsBySop.putIfAbsent(cp.sopId, () => []).add(r);
      }
    }

    final List<Map<String, dynamic>> monthlySopRows = [];
    for (final entry in resultsBySop.entries) {
      final sop = sopMap[entry.key];
      if (sop == null) continue;
      double raw = 0;
      double max = 0;
      for (final r in entry.value) {
        final cp = cpMap[r.checkpointId];
        if (cp == null || r.result == 'NA') continue;
        max += cp.weight;
        if (r.result == 'P') raw += cp.weight;
      }
      final pct = max > 0 ? (raw / max) * 100 : 100.0;
      monthlySopRows.add({
        'sop_id': sop.id,
        'sop_number': sop.number,
        'name_en': sop.nameEn,
        'name_mr': sop.nameMr,
        'raw_score': raw,
        'max_score': max,
        'compliance_pct': pct,
      });
    }

    // Compute monthly spot-check overall score
    final monthlyPct = monthlyAudit.compliancePct ?? 0.0;
    final monthlyBand = monthlyAudit.band ?? 'unknown';

    // Weekly averages for context (average of the month's weekly report scores)
    double? weeklyAvgPct;
    if (trendResult.weeklySeries.isNotEmpty) {
      weeklyAvgPct = trendResult.weeklySeries
              .map((s) => s.overallPct)
              .reduce((a, b) => a + b) /
          trendResult.weeklySeries.length;
      weeklyAvgPct = double.parse(weeklyAvgPct.toStringAsFixed(1));
    }

    // Per-SOP average across all weekly reports in the window
    final Map<String, List<double>> sopPctsByWeek = {};
    for (final wp in trendResult.weeklySeries) {
      for (final e in wp.perSopPct.entries) {
        sopPctsByWeek.putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    final Map<String, double> avgSopPcts = {};
    for (final e in sopPctsByWeek.entries) {
      avgSopPcts[e.key] = double.parse(
        (e.value.reduce((a, b) => a + b) / e.value.length).toStringAsFixed(1),
      );
    }

    final complianceTablePayload = {
      'monthly_spot_check_pct': monthlyPct,
      'monthly_band': monthlyBand,
      'monthly_sop_rows': monthlySopRows,
      'weekly_avg_pct': weeklyAvgPct,
      'avg_sop_pcts': avgSopPcts,
      'compliance_pct': monthlyPct,
    };

    // 6. Build trend block (the star of the monthly report)
    final trendBlockPayload = trendResult.toJson();

    // 7. Build headline
    final momStr = trendResult.momDelta != null
        ? (trendResult.momDelta! >= 0
            ? '+${trendResult.momDelta!.toStringAsFixed(1)}'
            : trendResult.momDelta!.toStringAsFixed(1))
        : 'N/A';
    final maLatest = trendResult.movingAverages.isNotEmpty &&
            trendResult.movingAverages.last.value != null
        ? '${trendResult.movingAverages.last.value!.toStringAsFixed(1)}%'
        : 'N/A';
    final patternCount = trendResult.detectedPatterns.length;
    final monthName = _monthName(monthNumber);
    final headline =
        '$monthName $year · Spot-Check: ${monthlyPct.toStringAsFixed(1)}% ${monthlyBand.toUpperCase()} · 4-Week MA: $maLatest · MoM: $momStr · $patternCount Patterns';

    // 8. Findings — monthly audit fails + trend patterns
    final List<Map<String, dynamic>> findingsPayload = [];
    for (final r in monthlyResults) {
      if (r.result == 'F') {
        final cp = cpMap[r.checkpointId];
        final sop = cp != null ? sopMap[cp.sopId] : null;
        final photos = await AuditRepository.instance.photosForResult(r.id);
        findingsPayload.add({
          'checkpoint_id': r.checkpointId,
          'text_en': cp?.textEn ?? '',
          'text_mr': cp?.textMr ?? '',
          'sop_name_en': sop?.nameEn ?? '',
          'sop_name_mr': sop?.nameMr ?? '',
          'finding_text': r.findingText ?? '',
          'photo_count': photos.length,
        });
      }
    }

    // 9. Patterns — detected trend patterns
    final patternsPayload = trendResult.detectedPatterns.map((p) => p.toJson()).toList();

    // 10. CAPs — opened/closed/aged during the month
    final monthStart = '$year-${monthNumber.toString().padLeft(2, '0')}-01';
    final nextMonth = monthNumber < 12
        ? '$year-${(monthNumber + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    // CAPs opened during the month
    final capsOpenedRows = await db.query(
      'caps',
      where: "opened_at >= ? AND opened_at < ?",
      whereArgs: [monthStart, nextMonth],
      orderBy: 'opened_at DESC',
    );
    final capsOpenedPayload = capsOpenedRows
        .map(
          (r) => {
            'id': r['id'],
            'problem_statement': r['problem_statement'],
            'status': r['status'],
            'deadline': r['deadline'],
            'opened_at': r['opened_at'],
          },
        )
        .toList();

    // CAPs closed (verified/closed) during the month
    final capsClosedRows = await db.query(
      'caps',
      where: "status IN ('closed', 'verified') AND closed_at >= ? AND closed_at < ?",
      whereArgs: [monthStart, nextMonth],
      orderBy: 'closed_at DESC',
    );
    final capsClosedPayload = capsClosedRows
        .map(
          (r) => {
            'id': r['id'],
            'problem_statement': r['problem_statement'],
            'status': r['status'],
            'closed_at': r['closed_at'],
          },
        )
        .toList();

    // CAPs currently aged
    final capsAgedRows = await db.query(
      'caps',
      where: "status = 'aged'",
      orderBy: 'deadline ASC',
    );
    final capsAgedPayload = capsAgedRows
        .map(
          (r) => {
            'id': r['id'],
            'problem_statement': r['problem_statement'],
            'status': r['status'],
            'deadline': r['deadline'],
            'aged_count': r['aged_count'],
          },
        )
        .toList();

    // 11. Escalations raised during the month
    final escalationRows = await db.query(
      'escalations',
      where: "raised_at >= ? AND raised_at < ?",
      whereArgs: [monthStart, nextMonth],
      orderBy: 'raised_at DESC',
    );
    final escalationsPayload = escalationRows
        .map(
          (r) => {
            'id': r['id'],
            'trigger_number': r['trigger_number'],
            'trigger_label': r['trigger_label'],
            'urgency': r['urgency'],
            'status': r['status'],
            'raised_at': r['raised_at'],
            'what_happened': r['what_happened'],
            'impact': r['impact'],
          },
        )
        .toList();

    // 12. Upsert report (idempotent — same as weekly)
    final existing = await getByAuditId(monthlyAuditId);
    final reportId = existing?.id ?? const Uuid().v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final reportMap = <String, Object?>{
      'id': reportId,
      'audit_id': monthlyAuditId,
      'report_type': 'monthly',
      'headline': headline,
      'compliance_table_json': jsonEncode(complianceTablePayload),
      'trend_block_json': jsonEncode(trendBlockPayload),
      'findings_json': jsonEncode(findingsPayload),
      'patterns_json': jsonEncode(patternsPayload),
      'caps_opened_json': jsonEncode(capsOpenedPayload),
      'caps_closed_json': jsonEncode(capsClosedPayload),
      'caps_aged_json': jsonEncode(capsAgedPayload),
      'escalations_json': jsonEncode(escalationsPayload),
      'author_user_id': authorUserId,
      'submitted_at': existing?.submittedAt ?? nowIso,
      'read_by_owner_at': existing?.readByOwnerAt,
      'pdf_local_path': existing?.pdfLocalPath,
      'pdf_cloud_url': existing?.pdfCloudUrl,
    };

    if (existing != null) {
      await db.update(
        'reports',
        reportMap,
        where: 'id = ?',
        whereArgs: [reportId],
      );
    } else {
      await db.insert('reports', reportMap);
    }

    return Report.fromMap(reportMap);
  }

  /// English month name helper.
  static String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return (month >= 1 && month <= 12) ? names[month] : 'Month $month';
  }

  /// Gets report by its primary key ID.
  Future<Report?> getById(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Report.fromMap(rows.first);
  }

  /// Gets report by associated audit ID.
  Future<Report?> getByAuditId(String auditId) async {
    final rows = await AppDatabase.instance.db.query(
      'reports',
      where: 'audit_id = ?',
      whereArgs: [auditId],
    );
    if (rows.isEmpty) return null;
    return Report.fromMap(rows.first);
  }

  /// Lists reports filtered by report_type, ordered by submitted_at DESC.
  Future<List<Report>> listReports({
    String reportType = 'weekly',
    int? year,
    int? month,
  }) async {
    final rows = await AppDatabase.instance.db.query(
      'reports',
      where: 'report_type = ?',
      whereArgs: [reportType],
      orderBy: 'submitted_at DESC',
    );
    final all = rows.map(Report.fromMap).toList();
    if (year == null && month == null) return all;

    return all.where((r) {
      if (r.submittedAt == null) return false;
      final dt = DateTime.tryParse(r.submittedAt!);
      if (dt == null) return false;
      if (year != null && dt.year != year) return false;
      if (month != null && dt.month != month) return false;
      return true;
    }).toList();
  }

  /// Marks a report as read by Owner. Only callable when viewing user is Owner.
  Future<void> markReadByOwner({
    required String reportId,
    required String ownerUserId,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await AppDatabase.instance.db.update(
      'reports',
      {'read_by_owner_at': nowIso},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  /// Updates local PDF path for an exported report.
  Future<void> updatePdfPath({
    required String reportId,
    required String pdfLocalPath,
  }) async {
    await AppDatabase.instance.db.update(
      'reports',
      {'pdf_local_path': pdfLocalPath},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }
}
