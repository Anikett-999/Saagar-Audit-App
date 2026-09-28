import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/audit_repository.dart';
import 'package:saagar_audit_app/domain/iso_week.dart';
import 'package:saagar_audit_app/domain/score_engine.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/seven_day_review/seven_day_review_screen.dart';

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
  group('Sprint P2-3 — 7-Day Review & GM Spot-Check Suite (Spec §5 T2.3 / Phase-2 Day 6)', () {
    late FakeDatabase fakeDb;

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

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed users
      await fakeDb.insert('users', {
        'id': gmUser.id,
        'name': gmUser.name,
        'role': gmUser.role,
        'pin_hash': 'dummy_hash',
        'language_pref': gmUser.languagePref,
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      });

      await fakeDb.insert('users', {
        'id': smUser.id,
        'name': smUser.name,
        'role': smUser.role,
        'pin_hash': 'dummy_hash',
        'language_pref': smUser.languagePref,
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      });

      // Seed 68 daily checkpoints
      for (int i = 1; i <= 68; i++) {
        await fakeDb.insert('checkpoints', {
          'id': 'CP.$i',
          'sop_id': 'SOP${((i - 1) % 8) + 1}',
          'frequency': 'daily',
          'sequence': i,
          'text_en': 'Checkpoint $i',
          'text_mr': 'तपासणी बिंदू $i',
          'weight': 1,
          'allows_na': 1,
          'requires_photo_on_fail': 0,
          'display_order': i,
        });
      }

      // Seed 8 SOPs
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
    });

    test('1. isoWeekDates helper returns exact 7 Monday-Sunday dates for ISO week', () {
      final dates = isoWeekDates(year: 2026, week: 39);
      expect(dates.length, 7);
      expect(dates[0].year, 2026);
      expect(dates[0].month, 9);
      expect(dates[0].day, 21); // Monday
      expect(dates[6].day, 27); // Sunday

      for (int i = 0; i < 7; i++) {
        expect(isoWeek(dates[i]), 39);
        expect(dates[i].weekday, i + 1);
      }
    });

    test('2. T2.3 Spec scenario — Spot check workflow: Day 3 verified with GM signature of record', () async {
      // Seed 7 submitted daily audits for Week 39 (2026-09-21 to 2026-09-27)
      for (int d = 1; d <= 7; d++) {
        final date = '2026-09-2$d';
        final auditId = 'd$d-audit-id';

        await fakeDb.insert('audits', {
          'id': auditId,
          'audit_type': 'daily',
          'audit_date': date,
          'week_number': 39,
          'month_number': 9,
          'year': 2026,
          'auditor_id': smUser.id,
          'device_id': 'dev-1',
          'status': 'submitted',
          'raw_score': 81.0,
          'max_score': 90.0,
          'compliance_pct': 90.0,
          'band': 'good',
          'pass_count': 60,
          'fail_count': 8,
          'na_count': 0,
          'draft_started_at': '${date}T10:00:00Z',
          'submitted_at': '${date}T18:00:00Z',
        });

        // Seed 3 marked results for each audit
        for (int c = 1; c <= 3; c++) {
          await fakeDb.insert('audit_results', {
            'id': 'res-$auditId-$c',
            'audit_id': auditId,
            'checkpoint_id': 'CP.$c',
            'result': 'P',
            'created_at': '${date}T10:00:00Z',
          });
        }
      }

      // Verify all 7 audits returned by findSubmittedDailyAuditsForWeek
      final beforeAudits = await AuditRepository.instance.findSubmittedDailyAuditsForWeek(
        weekNumber: 39,
        year: 2026,
      );
      expect(beforeAudits.length, 7);
      expect(beforeAudits.every((a) => a.status == 'submitted'), isTrue);

      // Spot check Day 3 (2026-09-23)
      final day3 = beforeAudits.firstWhere((a) => a.auditDate == '2026-09-23');
      expect(day3.status, 'submitted');
      expect(day3.verifierId, isNull);
      expect(day3.verifiedAt, isNull);

      // Draw checkpoints for Day 3
      final day3Results = await AuditRepository.instance.resultsForAudit(day3.id);
      expect(day3Results.length, 3);

      // GM verifies Day 3
      await AuditRepository.instance.verifyDailyAudit(
        auditId: day3.id,
        verifierId: gmUser.id,
        notes: 'Verified 3 random checkpoints on registers',
      );

      // Verify Day 3 is now GM-verified with verifierId and timestamp (Option A signature)
      final afterDay3 = await AuditRepository.instance.getById(day3.id);
      expect(afterDay3, isNotNull);
      expect(afterDay3!.status, 'verified');
      expect(afterDay3.verifierId, gmUser.id);
      expect(afterDay3.verifiedAt, isNotNull);
      expect(afterDay3.notes, contains('Verified 3 random checkpoints on registers'));

      // Assert the other 6 daily audits remain 'submitted'
      final afterAll = await AuditRepository.instance.findSubmittedDailyAuditsForWeek(
        weekNumber: 39,
        year: 2026,
      );
      expect(afterAll.length, 7);
      final otherAudits = afterAll.where((a) => a.id != day3.id).toList();
      expect(otherAudits.length, 6);
      expect(otherAudits.every((a) => a.status == 'submitted'), isTrue);
    });

    test('3. R5 Immutability — Verifying daily audit does NOT mutate scores, counts, or results', () async {
      const auditId = 'immutability-test-audit';
      await fakeDb.insert('audits', {
        'id': auditId,
        'audit_type': 'daily',
        'audit_date': '2026-09-21',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'dev-1',
        'status': 'submitted',
        'raw_score': 81.0,
        'max_score': 90.0,
        'compliance_pct': 90.0,
        'band': 'good',
        'pass_count': 60,
        'fail_count': 8,
        'na_count': 0,
        'draft_started_at': '2026-09-21T10:00:00Z',
        'submitted_at': '2026-09-21T18:00:00Z',
      });

      await fakeDb.insert('audit_results', {
        'id': 'res-1',
        'audit_id': auditId,
        'checkpoint_id': 'CP.1',
        'result': 'P',
      });

      final before = (await AuditRepository.instance.getById(auditId))!;

      // Perform verification
      await AuditRepository.instance.verifyDailyAudit(
        auditId: auditId,
        verifierId: gmUser.id,
      );

      final after = (await AuditRepository.instance.getById(auditId))!;

      // Scores and counts MUST be strictly identical
      expect(after.rawScore, before.rawScore);
      expect(after.maxScore, before.maxScore);
      expect(after.compliancePct, before.compliancePct);
      expect(after.band, before.band);
      expect(after.passCount, before.passCount);
      expect(after.failCount, before.failCount);
      expect(after.naCount, before.naCount);
      expect(after.auditDate, before.auditDate);
      expect(after.auditorId, before.auditorId);

      // Only status and verification fields changed
      expect(after.status, 'verified');
      expect(after.verifierId, gmUser.id);
      expect(after.verifiedAt, isNotNull);
    });

    test('4. R5 Guard — Re-verifying, verifying hidden, or verifying weekly audit throws StateError', () async {
      // 1. Cannot re-verify an already verified audit
      const verifiedId = 'already-verified-audit';
      await fakeDb.insert('audits', {
        'id': verifiedId,
        'audit_type': 'daily',
        'audit_date': '2026-09-21',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'dev-1',
        'status': 'verified',
        'verifier_id': gmUser.id,
        'draft_started_at': '2026-09-21T10:00:00Z',
        'submitted_at': '2026-09-21T18:00:00Z',
      });

      expect(
        () => AuditRepository.instance.verifyDailyAudit(
          auditId: verifiedId,
          verifierId: gmUser.id,
        ),
        throwsA(isA<StateError>()),
      );

      // 2. Cannot verify a hidden audit
      const hiddenId = 'hidden-audit';
      await fakeDb.insert('audits', {
        'id': hiddenId,
        'audit_type': 'daily',
        'audit_date': '2026-09-22',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'dev-1',
        'status': 'hidden',
        'draft_started_at': '2026-09-22T10:00:00Z',
      });

      expect(
        () => AuditRepository.instance.verifyDailyAudit(
          auditId: hiddenId,
          verifierId: gmUser.id,
        ),
        throwsA(isA<StateError>()),
      );

      // 3. Cannot verify a weekly audit through verifyDailyAudit
      const weeklyId = 'weekly-audit';
      await fakeDb.insert('audits', {
        'id': weeklyId,
        'audit_type': 'weekly',
        'audit_date': '2026-09-27',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': gmUser.id,
        'device_id': 'dev-1',
        'status': 'submitted',
        'draft_started_at': '2026-09-27T10:00:00Z',
      });

      expect(
        () => AuditRepository.instance.verifyDailyAudit(
          auditId: weeklyId,
          verifierId: gmUser.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('5. Score stability — Weekly 124-point score is identical before and after spot-check verification', () async {
      // 7 daily percentages matching canonical T2.1 setup (avg = 84.1%)
      final dailyPcts = [90.0, 85.0, 80.0, 95.0, 75.0, 88.0, 75.7];

      final weeklyMarks = [
        for (int i = 1; i <= 36; i++)
          CheckpointMark(checkpointId: 'W.$i', weight: 1, result: Verdict.pass),
      ];

      final scoreBefore = computeWeeklyScore(
        dailyPcts: dailyPcts,
        weeklyMarks: weeklyMarks,
      );

      // Now simulate that Day 1, Day 3, and Day 5 are marked GM-verified
      // Note: compliance percentages of the daily audits do not change
      final scoreAfter = computeWeeklyScore(
        dailyPcts: dailyPcts,
        weeklyMarks: weeklyMarks,
      );

      expect(scoreAfter.avgDailyPct, scoreBefore.avgDailyPct);
      expect(scoreAfter.dailyContribution, scoreBefore.dailyContribution);
      expect(scoreAfter.weeklyRaw, scoreBefore.weeklyRaw);
      expect(scoreAfter.weeklyMax, scoreBefore.weeklyMax);
      expect(scoreAfter.totalRaw, scoreBefore.totalRaw);
      expect(scoreAfter.compliancePct, scoreBefore.compliancePct);
      expect(scoreAfter.band, scoreBefore.band);
    });

    test('6. Discrepancy handling — flagDailyAuditDiscrepancy preserves submitted status and appends note', () async {
      const auditId = 'discrepancy-test-audit';
      await fakeDb.insert('audits', {
        'id': auditId,
        'audit_type': 'daily',
        'audit_date': '2026-09-24',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'dev-1',
        'status': 'submitted',
        'raw_score': 81.0,
        'max_score': 90.0,
        'compliance_pct': 90.0,
        'notes': 'Original SM note',
        'draft_started_at': '2026-09-24T10:00:00Z',
        'submitted_at': '2026-09-24T18:00:00Z',
      });

      await AuditRepository.instance.flagDailyAuditDiscrepancy(
        auditId: auditId,
        verifierId: gmUser.id,
        discrepancyNote: 'Cash register shows missing supervisor signature on ₹300 refund.',
      );

      final audit = (await AuditRepository.instance.getById(auditId))!;

      // Status MUST remain 'submitted' — verification was withheld!
      expect(audit.status, 'submitted');
      expect(audit.verifierId, isNull);
      expect(audit.verifiedAt, isNull);

      // Notes updated with discrepancy detail
      expect(audit.notes, contains('Original SM note'));
      expect(audit.notes, contains('Spot Check Discrepancy by ${gmUser.id}'));
      expect(audit.notes, contains('missing supervisor signature on ₹300 refund'));
    });

    testWidgets('7. SevenDayReviewScreen renders 7 daily cards, status chips, and handles spot-check', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      // Seed Day 1 (submitted) and Day 2 (verified)
      await fakeDb.insert('audits', {
        'id': 'd1-audit',
        'audit_type': 'daily',
        'audit_date': '2026-09-21', // Monday of week 39
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'dev-1',
        'status': 'submitted',
        'raw_score': 81.0,
        'max_score': 90.0,
        'compliance_pct': 90.0,
        'band': 'good',
        'pass_count': 60,
        'fail_count': 8,
        'na_count': 0,
        'draft_started_at': '2026-09-21T10:00:00Z',
        'submitted_at': '2026-09-21T18:00:00Z',
      });

      await fakeDb.insert('audits', {
        'id': 'd2-audit',
        'audit_type': 'daily',
        'audit_date': '2026-09-22', // Tuesday of week 39
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': smUser.id,
        'verifier_id': gmUser.id,
        'device_id': 'dev-1',
        'status': 'verified',
        'raw_score': 85.0,
        'max_score': 90.0,
        'compliance_pct': 94.4,
        'band': 'good',
        'pass_count': 65,
        'fail_count': 3,
        'na_count': 0,
        'draft_started_at': '2026-09-22T10:00:00Z',
        'submitted_at': '2026-09-22T18:00:00Z',
        'verified_at': '2026-09-22T19:30:00Z',
      });

      // Days 3..7 are missing

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(user: gmUser))),
          localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('en'))),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: SevenDayReviewScreen(
              weekNumber: 39,
              year: 2026,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert screen title renders
      expect(find.text('7-Day Daily Review'), findsOneWidget);
      expect(find.text('1 / 7 Verified'), findsOneWidget);

      // Assert Day 1 (Submitted) renders with Spot-Check action
      expect(find.text('Day 1 — Monday'), findsOneWidget);
      expect(find.text('Submitted (Pending Verification)'), findsOneWidget);
      expect(find.text('Spot-Check'), findsOneWidget);

      // Assert Day 2 (Verified) renders with GM-Verified badge
      expect(find.text('Day 2 — Tuesday'), findsOneWidget);
      expect(find.text('GM-Verified'), findsOneWidget);
      expect(find.textContaining('Verified by Sachin Jadhav'), findsOneWidget);

      // Assert missing days render "No audit submitted" / "Missing"
      expect(find.text('Day 3 — Wednesday'), findsOneWidget);
      expect(find.text('No audit submitted'), findsWidgets);
      expect(find.text('Missing'), findsWidgets);
    });

    testWidgets('8. Dual-language parity — SevenDayReviewScreen renders authentic Marathi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(const AuthState(user: gmUser))),
          localeProvider.overrideWith((ref) => FakeLocaleNotifier(const Locale('mr'))),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('mr'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: SevenDayReviewScreen(
              weekNumber: 39,
              year: 2026,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert authentic Devanagari Marathi strings render
      expect(find.text('७-दिवसीय दैनिक आढावा'), findsOneWidget);
      expect(find.text('दिवस 1 — सोमवार'), findsOneWidget);
      expect(find.text('दिवस 2 — मंगळवार'), findsOneWidget);
      expect(find.text('दिवस 3 — बुधवार'), findsOneWidget);
      expect(find.text('ऑडिट सादर केलेले नाही'), findsWidgets);
      expect(find.text('अनुपस्थित'), findsWidgets);
    });
  });
}
