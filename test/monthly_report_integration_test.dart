import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/report.dart';
import 'package:saagar_audit_app/data/repositories/report_repository.dart';
import 'package:saagar_audit_app/domain/trend_analytics.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/services/weekly_report_pdf_service.dart';
import 'package:saagar_audit_app/ui/screens/reports/report_detail_screen.dart';
import 'package:saagar_audit_app/ui/screens/reports/reports_list_screen.dart';

import 'helpers/fake_database.dart';

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  bool registerFailure({DateTime? at}) => false;

  @override
  void logout() {
    state = const AuthState();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Sprint P3-4 — Monthly Reports (S20/S21) & Multi-Week Trend Analytics Suite', () {
    late FakeDatabase fakeDb;

    const ownerUser = AuthUser(
      id: 'usr-owner-01',
      name: 'Aniket Owner',
      role: 'OWNER',
      languagePref: 'en',
    );

    Widget buildTestApp({
      required Widget child,
      AuthUser? user,
      Locale locale = const Locale('en'),
    }) {
      return ProviderScope(
        key: ValueKey('scope_${user?.id}_${locale.languageCode}'),
        overrides: [
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(AuthState(user: user)),
          ),
          localeProvider.overrideWith(
            (ref) => FakeLocaleNotifier(locale),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    setUp(() async {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed checkpoints
      await fakeDb.insert('sops', {
        'id': 'SOP2',
        'number': 2,
        'name_en': 'Cash Counter & Safe',
        'name_mr': 'कॅश काउंटर आणि तिजोरी',
        'weight': 2,
        'is_critical': 1,
        'display_order': 2,
      });
      await fakeDb.insert('sops', {
        'id': 'SOP7',
        'number': 7,
        'name_en': 'Inventory & Stock Storage',
        'name_mr': 'इन्व्हेंटरी आणि साठा स्टोरेज',
        'weight': 2,
        'is_critical': 1,
        'display_order': 7,
      });
      await fakeDb.insert('sops', {
        'id': 'SOP4',
        'number': 4,
        'name_en': 'Customer Database Integrity',
        'name_mr': 'ग्राहक डेटाबेस अखंडता',
        'weight': 1,
        'is_critical': 0,
        'display_order': 4,
      });

      await fakeDb.insert('checkpoints', {
        'id': 'MC.1',
        'sop_id': 'SOP2',
        'sequence': 1,
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 1,
        'text_en': 'Recount Safe Cash Float against physical register',
        'text_mr': 'तिजोरीतील कॅश फ्लोट प्रत्यक्ष रजिस्टरशी ताडून मोजा',
        'frequency': 'monthly',
      });
      await fakeDb.insert('checkpoints', {
        'id': 'MC.2',
        'sop_id': 'SOP7',
        'sequence': 2,
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 2,
        'text_en': 'Recount all units in one high-value display tray',
        'text_mr': 'एका उच्च मूल्याच्या डिस्प्ले ट्रेमधील सर्व युनिट्स मोजा',
        'frequency': 'monthly',
      });
      await fakeDb.insert('checkpoints', {
        'id': 'MC.3',
        'sop_id': 'SOP4',
        'sequence': 3,
        'weight': 1,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 3,
        'text_en': 'Cross-check 15 customer DB entries for correct mobile & name',
        'text_mr': 'योग्य मोबाईल आणि नावासाठी १५ ग्राहक डेटाबेस नोंदी तपासा',
        'frequency': 'monthly',
      });
    });

    test('1. generateMonthlyReport assembles spot-checks, trends, CAPs, escalations & upserts report', () async {
      // Setup monthly audit
      const monthlyAuditId = 'audit-monthly-2026-09';
      await fakeDb.insert('audits', {
        'id': monthlyAuditId,
        'audit_date': '2026-09-30',
        'year': 2026,
        'month_number': 9,
        'week_number': 39,
        'audit_type': 'monthly',
        'auditor_id': 'usr-owner-01',
        'device_id': 'dev-01',
        'status': 'submitted',
        'compliance_pct': 100.0,
        'band': 'excellent',
        'submitted_at': '2026-09-30T18:00:00Z',
      });

      await fakeDb.insert('audit_results', {
        'id': 'res-mc1',
        'audit_id': monthlyAuditId,
        'checkpoint_id': 'MC.1',
        'result': 'P',
        'created_at': '2026-09-30T17:00:00Z',
      });
      await fakeDb.insert('audit_results', {
        'id': 'res-mc2',
        'audit_id': monthlyAuditId,
        'checkpoint_id': 'MC.2',
        'result': 'P',
        'created_at': '2026-09-30T17:00:00Z',
      });
      await fakeDb.insert('audit_results', {
        'id': 'res-mc3',
        'audit_id': monthlyAuditId,
        'checkpoint_id': 'MC.3',
        'result': 'P',
        'created_at': '2026-09-30T17:00:00Z',
      });

      // 4 Weekly reports for September
      for (int w = 36; w <= 39; w++) {
        final day = (w - 35) * 7;
        await fakeDb.insert('reports', {
          'id': 'rep-weekly-$w',
          'audit_id': 'audit-weekly-$w',
          'report_type': 'weekly',
          'headline': 'Week $w Compliance Report',
          'compliance_table_json': jsonEncode({
            'compliance_pct': 90.0 + (w - 36),
            'sop_rows': [
              {'sop_id': 'SOP2', 'compliance_pct': 95.0},
              {'sop_id': 'SOP7', 'compliance_pct': 88.0},
            ],
          }),
          'trend_block_json': jsonEncode({
            'daily_pcts': [90.0, 92.0, 88.0, 94.0, 91.0, 89.0, 93.0],
          }),
          'submitted_at': '2026-09-${day.toString().padLeft(2, '0')}T18:00:00Z',
        });
      }

      // Add a CAP opened, closed, aged
      await fakeDb.insert('caps', {
        'id': 'cap-sept-01',
        'origin_audit_id': monthlyAuditId,
        'origin_checkpoint_id': 'MC.1',
        'problem_statement': 'Safe cash discrepancy ₹200',
        'status': 'open',
        'deadline': '2026-10-05',
        'opened_at': '2026-09-15T10:00:00Z',
        'root_cause': 'Register discrepancy',
        'why_1': 'Count mismatch',
        'responsible_user_id': 'usr-owner-01',
        'verification_method': 'Recount',
      });
      await fakeDb.insert('caps', {
        'id': 'cap-sept-02',
        'origin_audit_id': monthlyAuditId,
        'origin_checkpoint_id': 'MC.2',
        'problem_statement': 'Tray tag displaced',
        'status': 'closed',
        'deadline': '2026-09-20',
        'opened_at': '2026-09-10T10:00:00Z',
        'closed_at': '2026-09-18T10:00:00Z',
        'root_cause': 'Tag loose',
        'why_1': 'Displaced',
        'responsible_user_id': 'usr-owner-01',
        'verification_method': 'Inspect',
      });
      await fakeDb.insert('caps', {
        'id': 'cap-sept-03',
        'origin_audit_id': monthlyAuditId,
        'origin_checkpoint_id': 'MC.3',
        'problem_statement': 'Customer DB entry pending update',
        'status': 'aged',
        'deadline': '2026-09-10',
        'opened_at': '2026-09-01T10:00:00Z',
        'aged_count': 1,
        'root_cause': 'Pending verification',
        'why_1': 'Overdue',
        'responsible_user_id': 'usr-owner-01',
        'verification_method': 'Verify DB',
      });

      // Escalation raised
      await fakeDb.insert('escalations', {
        'id': 'esc-sept-01',
        'trigger_number': 3,
        'trigger_label': 'Cash variance > ₹500',
        'source_type': 'audit',
        'source_audit_id': monthlyAuditId,
        'raised_to_user_id': 'usr-owner-01',
        'urgency': 'same_day',
        'what_happened': 'Safe cash float recount variance > ₹500',
        'status': 'open',
        'raised_at': '2026-09-30T17:00:00Z',
      });

      final report = await ReportRepository.instance.generateMonthlyReport(
        monthlyAuditId: monthlyAuditId,
        authorUserId: 'usr-owner-01',
      );

      expect(report.reportType, equals('monthly'));
      expect(report.auditId, equals(monthlyAuditId));
      expect(report.headline, contains('September 2026'));
      expect(report.headline, contains('100.0% EXCELLENT'));

      final comp = report.complianceTable;
      expect(comp['monthly_spot_check_pct'], equals(100.0));
      expect(comp['monthly_band'], equals('excellent'));
      expect((comp['monthly_sop_rows'] as List).length, equals(3));
      expect(comp['weekly_avg_pct'], isNotNull);

      final trend = report.trendBlock;
      final series = (trend['weekly_series'] as List);
      expect(series.length, equals(4));
      expect(trend['has_sufficient_data'], isTrue);

      expect(report.capsOpened.length, equals(3));
      expect(report.capsClosed.length, equals(1));
      expect(report.capsAged.length, equals(1));
      expect(report.escalations.length, equals(1));

      // Idempotency: re-running does not create duplicate report
      final reRun = await ReportRepository.instance.generateMonthlyReport(
        monthlyAuditId: monthlyAuditId,
        authorUserId: 'usr-owner-01',
      );
      expect(reRun.id, equals(report.id));
      final allReports = await ReportRepository.instance.listReports(reportType: 'monthly');
      expect(allReports.length, equals(1));
    });

    testWidgets('2. S21 ReportDetailScreen renders monthly view with trend charts, spot-checks & rollup', (tester) async {
      const reportId = 'rep-monthly-test-01';
      const trendResult = TrendAnalysisResult(
        weeklySeries: [
          WeeklyDataPoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-07', overallPct: 92.0, perSopPct: {'SOP2': 90.0, 'SOP7': 94.0}),
          WeeklyDataPoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-14', overallPct: 91.0, perSopPct: {'SOP2': 89.0, 'SOP7': 93.0}),
          WeeklyDataPoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-21', overallPct: 89.0, perSopPct: {'SOP2': 86.0, 'SOP7': 92.0}),
          WeeklyDataPoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-28', overallPct: 88.0, perSopPct: {'SOP2': 84.0, 'SOP7': 92.0}),
        ],
        movingAverages: [
          MovingAveragePoint(weekNumber: 36, year: 2026, weekEnding: '2026-09-07', value: null),
          MovingAveragePoint(weekNumber: 37, year: 2026, weekEnding: '2026-09-14', value: null),
          MovingAveragePoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-21', value: null),
          MovingAveragePoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-28', value: 90.0),
        ],
        detectedPatterns: [
          TrendPattern(
            type: TrendPatternType.slowSlide,
            nameEn: 'Slow Slide Detected',
            nameMr: 'मंद घसरण आढळली',
            descriptionEn: '3 consecutive weekly declines',
            descriptionMr: 'सलग ३ आठवडे गुणांमध्ये घट',
            severity: 'warning',
          ),
        ],
        hasSufficientData: true,
      );

      await fakeDb.insert('reports', {
        'id': reportId,
        'audit_id': 'audit-monthly-test',
        'report_type': 'monthly',
        'headline': 'September 2026 · Spot-Check: 100.0% EXCELLENT · 4-Week MA: 90.0%',
        'compliance_table_json': jsonEncode({
          'monthly_spot_check_pct': 100.0,
          'monthly_band': 'excellent',
          'weekly_avg_pct': 90.0,
          'monthly_sop_rows': [
            {'sop_number': 2, 'name_en': 'Cash Counter & Safe', 'raw_score': 2.0, 'max_score': 2.0, 'compliance_pct': 100.0},
            {'sop_number': 7, 'name_en': 'Inventory', 'raw_score': 2.0, 'max_score': 2.0, 'compliance_pct': 100.0},
          ],
        }),
        'trend_block_json': jsonEncode(trendResult.toJson()),
        'findings_json': jsonEncode([]),
        'patterns_json': jsonEncode(trendResult.detectedPatterns.map((p) => p.toJson()).toList()),
        'caps_opened_json': jsonEncode([
          {'problem_statement': 'Safe cash recount check', 'status': 'open'},
        ]),
        'caps_closed_json': jsonEncode([]),
        'caps_aged_json': jsonEncode([]),
        'escalations_json': jsonEncode([]),
        'author_user_id': 'Aniket Owner',
        'submitted_at': '2026-09-30T18:00:00Z',
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(
          child: const ReportDetailScreen(reportId: reportId),
          user: ownerUser,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Sections
      expect(find.text('Monthly Trend Report'), findsOneWidget);
      expect(find.text('Section 1: Executive Headline'), findsOneWidget);
      expect(find.text('Section 2: Strategic Spot-Checks'), findsOneWidget);
      expect(find.text('Section 3: Multi-Week Trend Analytics'), findsOneWidget);
      expect(find.text('Overall Compliance Trend'), findsOneWidget);
      expect(find.text('Slow Slide Detected'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Export Monthly PDF'), 300);
      expect(find.text('Export Monthly PDF'), findsOneWidget);

      // Verify Owner Mark as Read button is present
      expect(find.text('Mark as Read (Owner)'), findsOneWidget);
    });

    testWidgets('3. S21 ReportDetailScreen renders authentic Marathi for monthly report', (tester) async {
      const reportId = 'rep-monthly-mr-01';
      const trendResult = TrendAnalysisResult(
        weeklySeries: [],
        movingAverages: [],
        detectedPatterns: [],
        hasSufficientData: false,
      );

      await fakeDb.insert('reports', {
        'id': reportId,
        'audit_id': 'audit-monthly-mr',
        'report_type': 'monthly',
        'headline': 'सप्टेंबर २०२६ · स्पॉट-तपासणी: १००.०% उत्कृष्ट',
        'compliance_table_json': jsonEncode({
          'monthly_spot_check_pct': 100.0,
          'monthly_band': 'excellent',
          'weekly_avg_pct': 88.5,
          'monthly_sop_rows': <dynamic>[],
        }),
        'trend_block_json': jsonEncode(trendResult.toJson()),
        'findings_json': jsonEncode([]),
        'patterns_json': jsonEncode([]),
        'caps_opened_json': jsonEncode([]),
        'caps_closed_json': jsonEncode([]),
        'caps_aged_json': jsonEncode([]),
        'escalations_json': jsonEncode([]),
        'author_user_id': 'अनिकेत मालक',
        'submitted_at': '2026-09-30T18:00:00Z',
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(
          child: const ReportDetailScreen(reportId: reportId),
          user: ownerUser,
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('मासिक कल अहवाल'), findsOneWidget);
      expect(find.text('विभाग २: धोरणात्मक स्पॉट-तपासण्या'), findsOneWidget);
      expect(find.text('विभाग ३: बहु-आठवडा कल विश्लेषण'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('मासिक PDF निर्यात करा'), 300);
      expect(find.text('मासिक PDF निर्यात करा'), findsOneWidget);
    });

    testWidgets('4. S20 ReportsListScreen filters by Monthly and renders type chip', (tester) async {
      await fakeDb.insert('reports', {
        'id': 'rep-weekly-01',
        'audit_id': 'aud-w-01',
        'report_type': 'weekly',
        'headline': 'Week 39 · 84.5% Poor',
        'compliance_table_json': jsonEncode({'compliance_pct': 84.5, 'band': 'poor'}),
        'submitted_at': '2026-09-27T18:00:00Z',
      });

      await fakeDb.insert('reports', {
        'id': 'rep-monthly-01',
        'audit_id': 'aud-m-01',
        'report_type': 'monthly',
        'headline': 'September 2026 · 100.0% Excellent',
        'compliance_table_json': jsonEncode({'monthly_spot_check_pct': 100.0, 'monthly_band': 'excellent'}),
        'submitted_at': '2026-09-30T18:00:00Z',
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(
          child: const ReportsListScreen(),
          user: ownerUser,
        ),
      );
      await tester.pumpAndSettle();

      // Both weekly and monthly chips exist
      expect(find.text('Weekly'), findsWidgets);
      expect(find.text('Monthly'), findsWidgets);

      // Tap 'Monthly' filter chip
      final monthlyChip = find.widgetWithText(ChoiceChip, 'Monthly');
      expect(monthlyChip, findsOneWidget);
      await tester.tap(monthlyChip);
      await tester.pumpAndSettle();

      // Only monthly report is shown
      expect(find.text('September 2026 · 100.0% Excellent'), findsOneWidget);
      expect(find.text('Week 39 · 84.5% Poor'), findsNothing);
    });

    test('5. WeeklyReportPdfService generates valid PDF bytes for monthly report', () async {
      final monthlyReport = Report(
        id: 'rep-pdf-monthly-01',
        auditId: 'aud-pdf-01',
        reportType: 'monthly',
        headline: 'September 2026 · Spot-Check: 100.0% EXCELLENT · 4-Week MA: 91.5%',
        complianceTableJson: jsonEncode({
          'monthly_spot_check_pct': 100.0,
          'monthly_band': 'excellent',
          'weekly_avg_pct': 91.5,
          'monthly_sop_rows': [
            {'sop_number': 2, 'name_en': 'Safe Cash', 'raw_score': 2.0, 'max_score': 2.0, 'compliance_pct': 100.0},
            {'sop_number': 7, 'name_en': 'Display Tray', 'raw_score': 2.0, 'max_score': 2.0, 'compliance_pct': 100.0},
            {'sop_number': 4, 'name_en': 'Customer DB', 'raw_score': 1.0, 'max_score': 1.0, 'compliance_pct': 100.0},
          ],
        }),
        trendBlockJson: jsonEncode({
          'weekly_series': [
            {'week_ending': '2026-09-07', 'overall_pct': 90.0},
            {'week_ending': '2026-09-14', 'overall_pct': 92.0},
            {'week_ending': '2026-09-21', 'overall_pct': 91.0},
            {'week_ending': '2026-09-28', 'overall_pct': 93.0},
          ],
          'moving_averages': [
            {'week_ending': '2026-09-07', 'value': null},
            {'week_ending': '2026-09-14', 'value': null},
            {'week_ending': '2026-09-21', 'value': null},
            {'week_ending': '2026-09-28', 'value': 91.5},
          ],
          'detected_patterns': [
            {'type': 'volatility', 'name_en': 'Stable Trend', 'description_en': 'Consistent high compliance'},
          ],
          'mom_delta': 1.5,
          'has_sufficient_data': true,
        }),
        findingsJson: jsonEncode([]),
        patternsJson: jsonEncode([]),
        capsOpenedJson: jsonEncode([
          {'problem_statement': 'Display tray alignment', 'status': 'open'},
        ]),
        capsClosedJson: jsonEncode([]),
        capsAgedJson: jsonEncode([]),
        escalationsJson: jsonEncode([]),
        authorUserId: 'Aniket (Owner)',
        submittedAt: '2026-09-30T18:00:00Z',
      );

      final pdfBytes = await WeeklyReportPdfService.instance.buildPdfBytes(monthlyReport);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF magic header %PDF-
      expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), equals('%PDF-'));
    });
  });
}
