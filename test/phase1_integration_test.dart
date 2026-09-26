import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/photo_service.dart';
import 'package:saagar_audit_app/data/repositories/audit_repository.dart';
import 'package:saagar_audit_app/domain/score_engine.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s03_first_setup/first_setup_screen.dart';
import 'package:saagar_audit_app/ui/screens/s04_login/login_screen.dart';
import 'package:saagar_audit_app/ui/screens/s05_home/home_screen.dart';
import 'package:saagar_audit_app/ui/screens/s06_start_audit/start_audit_screen.dart';
import 'package:saagar_audit_app/ui/screens/s07_checkpoint/checkpoint_screen.dart';
import 'package:saagar_audit_app/ui/screens/s08_fail_detail/fail_detail_screen.dart';
import 'package:saagar_audit_app/ui/screens/s10_review/review_submit_screen.dart';
import 'package:saagar_audit_app/ui/screens/s11_submitted/submitted_screen.dart';
import 'package:saagar_audit_app/ui/theme/app_theme.dart';
import 'package:saagar_audit_app/ui/widgets/language_toggle_button.dart';

import 'helpers/fake_database.dart';

GoRouter _buildTestRouter({String initialLocation = '/setup'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/setup',
        name: 's03_first_setup',
        builder: (_, __) => const FirstSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 's04_login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 's05_home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/audit/start',
        name: 's06_start_audit',
        builder: (_, __) => const StartAuditScreen(),
      ),
      GoRoute(
        path: '/audit/checkpoint',
        name: 's07_checkpoint',
        builder: (_, __) => const CheckpointScreen(),
      ),
      GoRoute(
        path: '/audit/fail-detail',
        name: 's08_fail_detail',
        builder: (_, __) => const FailDetailScreen(),
      ),
      GoRoute(
        path: '/audit/review',
        name: 's10_review',
        builder: (_, __) => const ReviewSubmitScreen(),
      ),
      GoRoute(
        path: '/audit/submitted',
        name: 's11_submitted',
        builder: (_, __) => const SubmittedScreen(),
      ),
    ],
  );
}

Widget _buildTestApp({required GoRouter router}) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        return MaterialApp.router(
          title: 'Phase 1 Integration Test',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
          locale: locale ?? const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    ),
  );
}

Future<void> _enterNumpadPin(WidgetTester tester, String pin) async {
  for (var i = 0; i < pin.length; i++) {
    final digit = pin[i];
    final digitFinder = find.text(digit);
    expect(digitFinder, findsOneWidget);
    await tester.tap(digitFinder);
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabase fakeDb;

  setUp(() {
    SharedPreferences.setMockInitialValues({'language_pref': 'en'});
    fakeDb = FakeDatabase();
    AppDatabase.instance.setDatabaseForTesting(fakeDb);

    PhotoService.instance.captureAndStoreForTesting = ({required auditId}) async {
      return '/mock/photos/$auditId/evidence_1.jpg';
    };
    PhotoService.instance.fileSizeForTesting = (path) async => 102400;

    fakeDb.tables['sops'] = [
      {
        'id': 'SOP1',
        'number': 1,
        'name_en': 'Store Opening & Setup',
        'name_mr': 'दुकान उघडणे आणि तयारी',
        'weight': 1,
        'display_order': 1,
        'is_critical': 0,
      },
    ];

    fakeDb.tables['checkpoints'] = [
      {
        'id': '1.1',
        'sop_id': 'SOP1',
        'frequency': 'daily',
        'sequence': 1,
        'text_en': 'Store facade, entrance & signage clean and lit',
        'text_mr': 'दुकानाचा दर्शनी भाग, प्रवेशद्वार आणि फलक स्वच्छ',
        'evidence_en': 'Signage lights operational',
        'evidence_mr': 'दिवे सुरू',
        'weight': 9,
        'allows_na': 0,
        'requires_photo_on_fail': 0,
        'display_order': 1,
      },
      {
        'id': '1.2',
        'sop_id': 'SOP1',
        'frequency': 'daily',
        'sequence': 2,
        'text_en': 'Cash counter tidy and float tally verified',
        'text_mr': 'कॅश काउंटर व्यवस्थित आणि कॅश ताळेबंद',
        'evidence_en': 'Float register tally',
        'evidence_mr': 'कॅश नोंदवही',
        'weight': 1,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 2,
      },
      {
        'id': '1.3',
        'sop_id': 'SOP1',
        'frequency': 'daily',
        'sequence': 3,
        'text_en': 'Backroom security door locked and alarm armed',
        'text_mr': 'सुरक्षा दरवाजा बंद आणि अलार्म सुरू',
        'evidence_en': 'Physical lock check',
        'evidence_mr': 'कुलूप तपासणी',
        'weight': 5,
        'allows_na': 1,
        'requires_photo_on_fail': 0,
        'display_order': 3,
      },
    ];

    fakeDb.tables['cros'] = [
      {
        'id': 'cro-1',
        'name': 'Ramesh Shinde',
        'counter': 'Titan',
        'shift': 'Morning',
        'is_active': 1,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      },
    ];
  });

  tearDown(() {
    AppDatabase.instance.setDatabaseForTesting(null);
    PhotoService.instance.captureAndStoreForTesting = null;
    PhotoService.instance.fileSizeForTesting = null;
  });

  testWidgets(
      'Phase 1 Full Lifecycle Integration: S03 Setup -> S04 Login -> S05 Home (EN/MR toggle) -> S06 Start Audit -> S07 Checkpoints (PASS/FAIL+photo/NA) -> S10 Review (live 90.0% Good) -> S11 Submit -> Immutability StateError',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _buildTestRouter(initialLocation: '/setup');

    await tester.pumpWidget(_buildTestApp(router: router));
    await tester.pumpAndSettle();

    // -------------------------------------------------------------------------
    // 1. Screen S03: First-Time Setup
    // -------------------------------------------------------------------------
    expect(find.byType(FirstSetupScreen), findsOneWidget);
    expect(find.text('First-time setup'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Sunil Patil');
    await tester.pumpAndSettle();

    // Initial PIN
    await _enterNumpadPin(tester, '1234');
    await tester.pumpAndSettle();

    // Title updates to confirm PIN
    expect(find.text('Re-enter your PIN'), findsOneWidget);

    // Enter confirmation PIN: 1234
    await _enterNumpadPin(tester, '1234');
    await tester.pumpAndSettle();

    // Verify Owner user was persisted in DB
    expect(fakeDb.tables['users']!.length, 1);
    final ownerRow = fakeDb.tables['users']!.first;
    expect(ownerRow['name'], 'Sunil Patil');
    expect(ownerRow['role'], 'OWNER');
    expect(ownerRow['is_active'], 1);

    // -------------------------------------------------------------------------
    // 2. Screen S04: Login Screen
    // -------------------------------------------------------------------------
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('Sunil Patil'), findsWidgets);

    // Enter wrong PIN first (verify failure doesn't login)
    await _enterNumpadPin(tester, '9999');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Enter correct PIN
    await _enterNumpadPin(tester, '1234');
    await tester.pumpAndSettle();

    // -------------------------------------------------------------------------
    // 3. Screen S05: Home Dashboard & Rule #8 Bilingual In-Flow Switch
    // -------------------------------------------------------------------------
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hello, Sunil Patil'), findsOneWidget);
    expect(find.text('OWNER'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Start daily audit'), findsOneWidget);

    // Rule #8 in-flow toggle: switch to Marathi
    expect(find.byType(LanguageToggleButton), findsOneWidget);
    await tester.tap(find.byType(LanguageToggleButton));
    await tester.pumpAndSettle();

    // Verify UI re-rendered in authentic Marathi
    expect(find.text('दैनिक ऑडिट सुरू करा'), findsOneWidget);

    // Toggle back to English
    await tester.tap(find.byType(LanguageToggleButton));
    await tester.pumpAndSettle();
    expect(find.text('Start daily audit'), findsOneWidget);

    // Tap "Start daily audit" CTA
    await tester.tap(find.text('Start daily audit'));
    await tester.pumpAndSettle();

    // -------------------------------------------------------------------------
    // 4. Screen S06: Start Daily Audit
    // -------------------------------------------------------------------------
    expect(find.byType(StartAuditScreen), findsOneWidget);
    expect(find.text('Ramesh Shinde'), findsOneWidget);

    // Select CRO from duty roster
    await tester.tap(find.text('Ramesh Shinde'));
    await tester.pumpAndSettle();

    // Tap "Begin Audit"
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Begin Audit'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Begin Audit'));
    await tester.pumpAndSettle();

    // Verify draft audit row created in SQLite
    expect(fakeDb.tables['audits']!.length, 1);
    final draftRow = fakeDb.tables['audits']!.first;
    expect(draftRow['status'], 'draft');
    final auditId = draftRow['id'] as String;

    // -------------------------------------------------------------------------
    // 5. Screen S07: Checkpoints & S08: Fail Detail
    // -------------------------------------------------------------------------
    expect(find.byType(CheckpointScreen), findsOneWidget);

    // --- Checkpoint 1 of 3 (CP 1.1: weight 9, PASS) ---
    expect(find.text('Checkpoint 1 of 3'), findsOneWidget);
    expect(find.textContaining('Store facade'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'PASS'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final result1 = fakeDb.tables['audit_results']!
        .firstWhere((r) => r['checkpoint_id'] == '1.1');
    expect(result1['result'], 'P');
    expect(result1['weighted_points'], 9.0);

    // --- Checkpoint 2 of 3 (CP 1.2: weight 1, FAIL with mandatory photo) ---
    expect(find.text('Checkpoint 2 of 3'), findsOneWidget);
    expect(find.textContaining('Cash counter tidy'), findsOneWidget);

    // TC6 Back-Button Atomicity Check:
    // Tap FAIL -> opens S08 -> enter finding -> tap Back button without saving -> verify 0 rows written
    await tester.tap(find.widgetWithText(ElevatedButton, 'FAIL'));
    await tester.pumpAndSettle();
    expect(find.byType(FailDetailScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'Uncommitted scratch finding',
    );
    await tester.pumpAndSettle();

    // Back out of S08 without saving
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify back on CheckpointScreen and zero rows written for CP 1.2
    expect(find.byType(CheckpointScreen), findsOneWidget);
    expect(
      fakeDb.tables['audit_results']!
          .where((r) => r['checkpoint_id'] == '1.2'),
      isEmpty,
    );
    expect(fakeDb.tables['photos']!, isEmpty);

    // Now re-open S08 to complete CP 1.2 properly
    await tester.tap(find.widgetWithText(ElevatedButton, 'FAIL'));
    await tester.pumpAndSettle();
    expect(find.byType(FailDetailScreen), findsOneWidget);
    expect(find.text('REQUIRED'), findsOneWidget);

    // Enter finding text
    await tester.enterText(
      find.byType(TextField).first,
      'Cash drawer float short by 200 rupees, register unlatched.',
    );
    await tester.pumpAndSettle();

    // Mandatory photo gate assertion: attempt Save with 0 photos
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Finding'));
    await tester.pumpAndSettle();
    expect(
      find.text('Photo evidence is required for Cash and Inventory Fails.'),
      findsOneWidget,
    );
    expect(find.byType(FailDetailScreen), findsOneWidget);

    // Attach photo evidence via PhotoService test seam
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);

    // Now Save succeeds atomically and returns to S07
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Finding'));
    await tester.pumpAndSettle();

    final result2 = fakeDb.tables['audit_results']!
        .firstWhere((r) => r['checkpoint_id'] == '1.2');
    expect(result2['result'], 'F');
    expect(result2['weighted_points'], 0.0);
    expect(fakeDb.tables['photos']!.length, 1);
    expect(
      fakeDb.tables['photos']!.first['local_path'],
      '/mock/photos/$auditId/evidence_1.jpg',
    );

    // --- Checkpoint 3 of 3 (CP 1.3: weight 5, N/A) ---
    expect(find.byType(CheckpointScreen), findsOneWidget);
    expect(find.text('Checkpoint 3 of 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'NA'));
    await tester.pumpAndSettle();

    expect(find.text('Why is this checkpoint Not Applicable?'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      'Backroom secure room under scheduled maintenance',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'N/A'));
    await tester.pumpAndSettle();

    final result3 = fakeDb.tables['audit_results']!
        .firstWhere((r) => r['checkpoint_id'] == '1.3');
    expect(result3['result'], 'NA');
    expect(result3['weighted_points'], isNull);

    // All 3 checkpoints marked -> automatically routes to S10 Review
    // -------------------------------------------------------------------------
    // 6. Screen S10: Daily Audit Review & Live Score Calculation
    // -------------------------------------------------------------------------
    expect(find.byType(ReviewSubmitScreen), findsOneWidget);

    // Mathematical Score Engine Invariant Assertion:
    // CP 1.1: 9 pts earned, 9 max
    // CP 1.2: 0 pts earned, 1 max
    // CP 1.3: NA -> 0 earned, 0 max (denominator excluded!)
    // Raw = 9.0, Max = 10.0 -> Compliance % = 90.0% exactly -> Band = GOOD
    final expectedMarks = [
      const CheckpointMark(checkpointId: '1.1', result: Verdict.pass, weight: 9),
      const CheckpointMark(checkpointId: '1.2', result: Verdict.fail, weight: 1),
      const CheckpointMark(checkpointId: '1.3', result: Verdict.na, weight: 5),
    ];
    final expectedScore = scoreDaily(expectedMarks);
    expect(expectedScore.rawScore, 9.0);
    expect(expectedScore.maxScore, 10.0);
    expect(expectedScore.compliancePct, 90.0);
    expect(expectedScore.band, Band.good);

    // Assert on-screen score matches score engine exactly
    expect(find.textContaining('90.0%'), findsOneWidget);
    expect(find.text('GOOD'), findsOneWidget);
    expect(
      find.textContaining('Cash drawer float short by 200 rupees'),
      findsOneWidget,
    );

    // Enter auditor notes
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(
      find.byType(TextField).last,
      'Daily audit completed cleanly with verified observation.',
    );
    await tester.pumpAndSettle();

    // Tap "Submit Audit"
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit Audit'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit Audit'));
    await tester.pumpAndSettle();

    // -------------------------------------------------------------------------
    // 7. Screen S11: Submitted Confirmation & Offline Indicator
    // -------------------------------------------------------------------------
    expect(find.byType(SubmittedScreen), findsOneWidget);
    expect(find.text('Audit Submitted'), findsOneWidget);
    expect(find.text('90.0%'), findsOneWidget);
    expect(find.text('GOOD'), findsOneWidget);
    expect(find.textContaining('Saved to SQLite'), findsOneWidget);
    expect(find.textContaining('Will sync when online'), findsOneWidget);

    // -------------------------------------------------------------------------
    // 8. Hard Rule #6: Audit Immutability & Database Verification
    // -------------------------------------------------------------------------
    final submittedAudit = fakeDb.tables['audits']!.first;
    expect(submittedAudit['status'], 'submitted');
    expect(submittedAudit['raw_score'], 9.0);
    expect(submittedAudit['max_score'], 10.0);
    expect(submittedAudit['compliance_pct'], 90.0);
    expect(submittedAudit['band'], 'good');
    expect(submittedAudit['pass_count'], 1);
    expect(submittedAudit['fail_count'], 1);
    expect(submittedAudit['na_count'], 1);
    expect(
      submittedAudit['notes'],
      'Daily audit completed cleanly with verified observation.',
    );
    expect(submittedAudit['submitted_at'], isNotNull);

    // Hard Rule #6: Post-submit modification attempts MUST throw StateError
    expect(
      () => AuditRepository.instance.saveResult(
        auditId: auditId,
        checkpointId: '1.1',
        result: 'F',
        weight: 9,
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      () => AuditRepository.instance.submitAudit(
        auditId: auditId,
        rawScore: 0,
        maxScore: 0,
        compliancePct: 0,
        band: 'critical',
        passCount: 0,
        failCount: 0,
        naCount: 0,
      ),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets(
      'TC1: S03 First-Time Setup blocks mismatched PINs and creates no user',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _buildTestRouter(initialLocation: '/setup');
    await tester.pumpWidget(_buildTestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byType(FirstSetupScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Mismatched Admin');
    await tester.pumpAndSettle();

    // Initial PIN
    await _enterNumpadPin(tester, '1234');
    await tester.pumpAndSettle();

    // Mismatched confirm PIN
    await _enterNumpadPin(tester, '9876');
    await tester.pumpAndSettle();

    // Error message displayed
    expect(
      find.text('PINs do not match. Choose a new PIN.'),
      findsOneWidget,
    );

    // No user created in SQLite
    expect(fakeDb.tables['users']!, isEmpty);
  });
}
