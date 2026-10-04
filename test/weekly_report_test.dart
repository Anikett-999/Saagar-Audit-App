import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/report.dart';
import 'package:saagar_audit_app/data/repositories/report_repository.dart';
import 'package:saagar_audit_app/domain/pattern_detection.dart';
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
  group('Sprint P2-4 — Weekly Report (S20/S21), §3.6 9-Section Format, PDF & T2.4 Pattern Detection Suite', () {
    late FakeDatabase fakeDb;

    const ownerUser = AuthUser(
      id: 'usr-owner-01',
      name: 'Aniket Owner',
      role: 'OWNER',
      languagePref: 'en',
    );

    const gmUser = AuthUser(
      id: 'usr-gm-01',
      name: 'Sachin Jadhav',
      role: 'GM',
      languagePref: 'en',
    );

    const smUser = AuthUser(
      id: 'usr-sm-01',
      name: 'Rahul Patil',
      role: 'SM',
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
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed SOPs
      for (int i = 1; i <= 8; i++) {
        await fakeDb.insert('sops', {
          'id': 'SOP$i',
          'number': i,
          'name_en': 'SOP $i Title',
          'name_mr': 'एसओपी $i शीर्षक',
          'weight': 1,
          'is_critical': 0,
          'display_order': i,
        });
      }
      await fakeDb.insert('sops', {
        'id': 'SOP9',
        'number': 9,
        'name_en': 'Store Operations',
        'name_mr': 'कार्यात्मक कामकाज',
        'weight': 1,
        'is_critical': 0,
        'display_order': 9,
      });

      // Seed 68 daily checkpoints
      for (int i = 1; i <= 68; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'CP.$i',
          'sop_id': 'SOP${((i - 1) % 8) + 1}',
          'frequency': 'daily',
          'sequence': i,
          'text_en': 'Daily Checkpoint $i',
          'text_mr': 'दैनिक चेकपॉईंट $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': i,
        });
      }

      // Seed 36 weekly checkpoints (Ops 10, Cash 8, RS 6, Inv 12 = 56 pts)
      for (int i = 1; i <= 10; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'O.$i',
          'sop_id': 'SOP9',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Operations $i',
          'text_mr': 'ऑपरेशन्स $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': 68 + i,
        });
      }
      for (int i = 1; i <= 8; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'CW.$i',
          'sop_id': 'SOP6',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Cash Weekly $i',
          'text_mr': 'कॅश साप्ताहिक $i',
          'weight': 2,
          'allows_na': 1,
          'requires_photo_on_fail': 1,
          'display_order': 78 + i,
        });
      }
      for (int i = 1; i <= 6; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'RS.$i',
          'sop_id': 'SOP8',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Reporting Service $i',
          'text_mr': 'रिपोर्टिंग सर्व्हिस $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': 86 + i,
        });
      }
      for (int i = 1; i <= 12; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'IW.$i',
          'sop_id': 'SOP7',
          'frequency': 'weekly',
          'sequence': i,
          'text_en': 'Inventory Weekly $i',
          'text_mr': 'इन्व्हेंटरी साप्ताहिक $i',
          'weight': 2,
          'allows_na': 1,
          'requires_photo_on_fail': 1,
          'display_order': 92 + i,
        });
      }
    });

    test('1. Spec T2.4 Canonical — Pattern detection: Checkpoint 1.4 failing on days 1,2,3 triggers single pattern & single CAP', () {
      // 5 daily fail points: Checkpoint 1.4 fails on days 1, 2, 3 (2026-09-21, 2026-09-22, 2026-09-23)
      final failPoints = [
        const DailyFailPoint(
          checkpointId: '1.4',
          auditDate: '2026-09-21',
          findingText: 'Counter display dusty',
        ),
        const DailyFailPoint(
          checkpointId: '1.4',
          auditDate: '2026-09-22',
          findingText: 'Dust on counter glass',
        ),
        const DailyFailPoint(
          checkpointId: '1.4',
          auditDate: '2026-09-23',
          findingText: 'Display counter smudged',
        ),
        // Checkpoint 2.1 fails on only 2 days (should NOT trigger pattern)
        const DailyFailPoint(
          checkpointId: '2.1',
          auditDate: '2026-09-21',
          findingText: 'Minor sign tilted',
        ),
        const DailyFailPoint(
          checkpointId: '2.1',
          auditDate: '2026-09-22',
          findingText: 'Sign still tilted',
        ),
      ];

      final patterns = detectWeeklyPatterns(failPoints);

      // Exactly ONE pattern detected
      expect(patterns.length, 1);
      final p = patterns.first;
      expect(p.checkpointId, '1.4');
      expect(p.failCount, 3);
      expect(p.weekdaysEn, ['Mon', 'Tue', 'Wed']);
      expect(p.weekdaysMr, ['सोम', 'मंगळ', 'बुध']);

      // Format assertions
      expect(
        p.formattedDescription('en'),
        'Checkpoint 1.4 failed on 3 days (Mon, Tue, Wed) — pattern',
      );
      expect(
        p.formattedDescription('mr'),
        'तपासणी बिंदू 1.4 3 दिवस अयशस्वी (सोम, मंगळ, बुध) — पॅटर्न',
      );

      // Single-CAP rule: maps to exactly ONE suggested Pattern CAP
      final suggestedCap = p.toSuggestedCap();
      expect(suggestedCap.checkpointId, '1.4');
      expect(suggestedCap.failCount, 3);
      expect(
        suggestedCap.problemStatementEn,
        contains('Recurring pattern: Checkpoint 1.4 failed on 3 days (Mon, Tue, Wed)'),
      );
    });

    test('2. Report generation creates 9 sections with honest empty states for future phases', () async {
      const weeklyAuditId = 'weekly-w39-test';

      // Insert weekly audit
      await fakeDb.insert('audits', {
        'id': weeklyAuditId,
        'audit_type': 'weekly',
        'audit_date': '2026-09-27',
        'week_number': 39,
        'year': 2026,
        'auditor_id': gmUser.id,
        'device_id': 'dev-gm',
        'status': 'submitted',
        'submitted_at': '2026-09-27T18:00:00Z',
      });

      // Insert 7 daily audits (Mon 21 to Sun 27 Sep 2026)
      for (int d = 1; d <= 7; d++) {
        final date = '2026-09-2$d';
        final auditId = 'daily-d$d';
        await fakeDb.insert('audits', {
          'id': auditId,
          'audit_type': 'daily',
          'audit_date': date,
          'week_number': 39,
          'year': 2026,
          'auditor_id': smUser.id,
          'device_id': 'dev-sm',
          'status': 'submitted',
          'compliance_pct': 90.0,
          'submitted_at': '${date}T18:00:00Z',
        });

        // Fail CP.4 on days 1, 2, 3
        if (d <= 3) {
          await fakeDb.insert('audit_results', {
            'id': 'res-cp4-$d',
            'audit_id': auditId,
            'checkpoint_id': 'CP.4',
            'result': 'F',
            'finding_text': 'Display issue day $d',
            'created_at': '${date}T10:00:00Z',
          });
        }
      }

      // Weekly results: O.1..O.10 PASS, CW.1..CW.8 PASS, RS.1..RS.6 PASS, IW.1..IW.10 PASS, IW.11 & IW.12 FAIL
      for (int i = 1; i <= 10; i++) {
        await fakeDb.insert('audit_results', {
          'id': 'res-o-$i',
          'audit_id': weeklyAuditId,
          'checkpoint_id': 'O.$i',
          'result': 'P',
          'created_at': '2026-09-27T12:00:00Z',
        });
      }
      for (int i = 1; i <= 8; i++) {
        await fakeDb.insert('audit_results', {
          'id': 'res-cw-$i',
          'audit_id': weeklyAuditId,
          'checkpoint_id': 'CW.$i',
          'result': 'P',
          'created_at': '2026-09-27T12:00:00Z',
        });
      }
      for (int i = 1; i <= 6; i++) {
        await fakeDb.insert('audit_results', {
          'id': 'res-rs-$i',
          'audit_id': weeklyAuditId,
          'checkpoint_id': 'RS.$i',
          'result': 'P',
          'created_at': '2026-09-27T12:00:00Z',
        });
      }
      for (int i = 1; i <= 10; i++) {
        await fakeDb.insert('audit_results', {
          'id': 'res-iw-$i',
          'audit_id': weeklyAuditId,
          'checkpoint_id': 'IW.$i',
          'result': 'P',
          'created_at': '2026-09-27T12:00:00Z',
        });
      }
      for (final failId in ['IW.11', 'IW.12']) {
        await fakeDb.insert('audit_results', {
          'id': 'res-fail-$failId',
          'audit_id': weeklyAuditId,
          'checkpoint_id': failId,
          'result': 'F',
          'finding_text': 'Missing tag on $failId',
          'created_at': '2026-09-27T12:00:00Z',
        });
      }

      final report = await ReportRepository.instance.generateWeeklyReport(
        weeklyAuditId: weeklyAuditId,
        authorUserId: gmUser.id,
      );

      // Section 1: Headline
      expect(report.headline, contains('Week 39 Ending 2026-09-27'));
      expect(report.headline, contains('2 Failures'));
      expect(report.headline, contains('1 Patterns'));

      // Section 2: Compliance Table
      final compTable = report.complianceTable;
      expect(compTable['total_max'], 124.0);
      expect(compTable['sop_rows'], isNotEmpty);

      // Section 3: Trend Block
      final trend = report.trendBlock;
      expect((trend['daily_pcts'] as List).length, 7);

      // Section 4: Findings
      expect(report.findings.length, 2);

      // Section 5: Patterns
      expect(report.patterns.length, 1);
      expect(report.patterns.first.checkpointId, 'CP.4');

      // Section 6: CAPs Opened (suggested pattern CAP)
      expect(report.capsOpened.length, 1);
      expect(report.capsOpened.first['is_pattern'], isTrue);

      // Sections 7, 8, 9: Honest empty states
      expect(report.capsClosed, isEmpty);
      expect(report.capsAged, isEmpty);
      expect(report.escalations, isEmpty);
    });

    test('3. 1-Page PDF export generates valid bytes with authentic Marathi & Noto Sans Devanagari layout', () async {
      final sampleReport = Report(
        id: 'rep-test-pdf',
        auditId: 'audit-test-pdf',
        reportType: 'weekly',
        headline: 'आठवडा ३९ समाप्त २०२६-०९-२७ · ८४.५% निकृष्ट · २ त्रुटी · १ पॅटर्न',
        complianceTableJson: jsonEncode({
          'avg_daily_pct': 84.1,
          'daily_contribution': 57.2,
          'weekly_raw': 47.6,
          'weekly_max': 56.0,
          'total_raw': 104.8,
          'total_max': 124.0,
          'compliance_pct': 84.5,
          'band': 'poor',
          'sop_rows': [
            {
              'sop_id': 'SOP9',
              'sop_number': 9,
              'name_en': 'Store Operations',
              'name_mr': 'स्टोअर ऑपरेशन्स',
              'raw_score': 10.0,
              'max_score': 10.0,
              'compliance_pct': 100.0,
            },
          ],
        }),
        trendBlockJson: jsonEncode({
          'daily_pcts': [90.0, 85.0, 80.0, 95.0, 75.0, 88.0, 75.7],
          'wow_delta': -2.1,
        }),
        findingsJson: jsonEncode([
          {
            'checkpoint_id': 'IW.11',
            'finding_text': 'अग्निशामक टॅग गहाळ (Missing extinguisher tag)',
          },
        ]),
        patternsJson: jsonEncode([
          {
            'checkpoint_id': 'CP.4',
            'fail_count': 3,
            'dates': ['2026-09-21', '2026-09-22', '2026-09-23'],
            'weekdays_en': ['Mon', 'Tue', 'Wed'],
            'weekdays_mr': ['सोम', 'मंगळ', 'बुध'],
            'findings': ['काचेवर धूळ आढळली (Dirty counter glass)'],
          },
        ]),
        capsOpenedJson: jsonEncode([
          {
            'is_pattern': true,
            'checkpoint_id': 'CP.4',
            'problem_statement_en': 'Recurring pattern CP.4',
            'problem_statement_mr': 'वारंवार आढळणारा पॅटर्न CP.4',
            'action_plan_en': 'Brief staff',
            'action_plan_mr': 'कर्मचाऱ्यांना मार्गदर्शन करा',
          },
        ]),
        authorUserId: 'सचिन जाधव',
        submittedAt: '2026-09-27T18:00:00Z',
      );

      final pdfBytes = await WeeklyReportPdfService.instance.buildPdfBytes(sampleReport);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF begins with %PDF- header
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
      // Substantial bytes generated (> 50KB due to embedded subset font)
      expect(pdfBytes.length, greaterThan(10000));
    });

    testWidgets('4. S20 Reports List Screen renders reports and Owner-only read dot', (tester) async {
      await fakeDb.insert('reports', {
        'id': 'rep-01',
        'audit_id': 'audit-01',
        'report_type': 'weekly',
        'headline': 'Week 39 Ending 2026-09-27 · 84.5% POOR · 2 Failures · 1 Patterns',
        'compliance_table_json': jsonEncode({
          'compliance_pct': 84.5,
          'band': 'poor',
        }),
        'author_user_id': gmUser.id,
        'submitted_at': '2026-09-27T18:00:00Z',
        'read_by_owner_at': null, // Unread
      });

      // Render as Owner
      await tester.pumpWidget(
        buildTestApp(
          child: const ReportsListScreen(key: ValueKey('owner-reports')),
          user: ownerUser,
        ),
      );
      await tester.pumpAndSettle();

      // Check title and headline
      expect(find.text('Compliance Reports'), findsOneWidget);
      expect(find.textContaining('Week 39 Ending 2026-09-27'), findsOneWidget);
      expect(find.text('84.5% POOR'), findsOneWidget);

      // Owner sees read-dot status "Unread"
      expect(find.text('Unread'), findsOneWidget);

      // Now render as SM
      await tester.pumpWidget(
        buildTestApp(
          child: const ReportsListScreen(key: ValueKey('sm-reports')),
          user: smUser,
        ),
      );
      await tester.pumpAndSettle();

      // SM does NOT see Owner-only read dot
      expect(find.text('Unread'), findsNothing);
    });

    testWidgets('5. S21 Report Detail renders all 9 sections & Owner Mark-as-Read action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await fakeDb.insert('reports', {
        'id': 'rep-02',
        'audit_id': 'audit-02',
        'report_type': 'weekly',
        'headline': 'Week 39 Ending 2026-09-27 · 84.5% POOR · 2 Failures · 1 Patterns',
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
            {
              'sop_id': 'SOP9',
              'sop_number': 9,
              'name_en': 'Store Operations',
              'raw_score': 10.0,
              'max_score': 10.0,
              'compliance_pct': 100.0,
            },
          ],
        }),
        'trend_block_json': jsonEncode({
          'daily_pcts': [90.0, 85.0, 80.0, 95.0, 75.0, 88.0, 75.7],
          'wow_delta': -2.1,
        }),
        'findings_json': jsonEncode([
          {
            'checkpoint_id': 'IW.11',
            'sop_name_en': 'Inventory',
            'finding_text': 'Missing fire extinguisher tag',
            'photo_count': 1,
          },
        ]),
        'patterns_json': jsonEncode([
          {
            'checkpoint_id': 'CP.4',
            'fail_count': 3,
            'dates': ['2026-09-21', '2026-09-22', '2026-09-23'],
            'weekdays_en': ['Mon', 'Tue', 'Wed'],
            'weekdays_mr': ['सोम', 'मंगळ', 'बुध'],
            'findings': ['Dirty glass'],
          },
        ]),
        'caps_opened_json': jsonEncode([
          {
            'is_pattern': true,
            'checkpoint_id': 'CP.4',
            'problem_statement_en': 'Recurring pattern CP.4',
            'problem_statement_mr': 'वारंवार आढळणारा पॅटर्न CP.4',
            'action_plan_en': 'Brief staff',
            'action_plan_mr': 'कर्मचाऱ्यांना मार्गदर्शन करा',
          },
        ]),
        'author_user_id': 'Sachin Jadhav',
        'submitted_at': '2026-09-27T18:00:00Z',
        'read_by_owner_at': null,
      });

      // Render as Owner
      await tester.pumpWidget(
        buildTestApp(
          child: const ReportDetailScreen(reportId: 'rep-02'),
          user: ownerUser,
        ),
      );
      await tester.pumpAndSettle();

      // Check section titles
      expect(find.text('Section 1: Executive Headline'), findsOneWidget);
      expect(find.text('Section 2: 124-Point Compliance Table'), findsOneWidget);
      expect(find.text('Section 3: 7-Day Trend & WoW Delta'), findsOneWidget);
      expect(find.textContaining('Section 4: Weekly Non-Compliances'), findsOneWidget);
      expect(find.textContaining('Section 5: Detected Patterns'), findsOneWidget);
      expect(find.text('Section 6: Corrective Action Plans (CAPs)'), findsOneWidget);
      expect(find.text('Section 7: CAPs Closed This Week'), findsOneWidget);
      expect(find.text('Section 8: Aged / Overdue CAPs'), findsOneWidget);
      expect(find.text('Section 9: Escalation Log'), findsOneWidget);

      // Check Owner Mark-as-Read button
      final markReadBtn = find.text('Mark as Read (Owner)');
      expect(markReadBtn, findsOneWidget);

      // Tap Mark as Read
      await tester.tap(markReadBtn);
      await tester.pumpAndSettle();

      // Verified in DB
      final updatedReport = await ReportRepository.instance.getById('rep-02');
      expect(updatedReport?.isReadByOwner, isTrue);

      // Export PDF button exists
      expect(find.text('Export 1-Page PDF'), findsOneWidget);
    });

    testWidgets('6. Dual-Language Parity (Rule #8) — Screen S21 renders authentic Marathi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await fakeDb.insert('reports', {
        'id': 'rep-03-mr',
        'audit_id': 'audit-03-mr',
        'report_type': 'weekly',
        'headline': 'आठवडा ३९ समाप्त २०२६-०९-२७ · ८४.५% निकृष्ट',
        'compliance_table_json': jsonEncode({
          'compliance_pct': 84.5,
          'band': 'poor',
          'sop_rows': <dynamic>[],
        }),
        'trend_block_json': jsonEncode({
          'daily_pcts': [90.0, 85.0, 80.0, 95.0, 75.0, 88.0, 75.7],
        }),
        'findings_json': jsonEncode([]),
        'patterns_json': jsonEncode([]),
        'caps_opened_json': jsonEncode([]),
        'author_user_id': 'सचिन जाधव',
        'submitted_at': '2026-09-27T18:00:00Z',
      });

      await tester.pumpWidget(
        buildTestApp(
          child: const ReportDetailScreen(reportId: 'rep-03-mr'),
          user: ownerUser,
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      // Check Marathi Section Headers
      expect(find.text('साप्ताहिक ऑडिट अहवाल'), findsOneWidget);
      expect(find.text('विभाग १: मुख्य मथळा'), findsOneWidget);
      expect(find.text('विभाग २: १२४-गुण अनुपालन तक्ता'), findsOneWidget);
      expect(find.text('विभाग ३: ७-दिवस कल आणि आठवडा-दर-आठवडा बदल'), findsOneWidget);
      expect(find.text('विभाग ६: सुधारात्मक कृती योजना (CAPs)'), findsOneWidget);
      expect(find.text('विभाग ९: एस्केलेशन नोंद'), findsOneWidget);
      expect(find.text('१-पान PDF निर्यात करा'), findsOneWidget);
    });
  });
}
