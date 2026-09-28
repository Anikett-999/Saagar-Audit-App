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
