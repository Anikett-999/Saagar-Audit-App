import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s13_audit_detail/audit_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Widget createAuditDetailTestWidget({
  required String auditId,
  required AuthState authState,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/audits/$auditId',
        routes: [
          GoRoute(
            path: '/audits/:id',
            name: 's13_audit_detail',
            builder: (context, state) => AuditDetailScreen(
              auditId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/audits',
            name: 's12_audit_history',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S12 Audit History')),
            ),
          ),
          GoRoute(
            path: '/caps/new',
            name: 's15_cap_create',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text(
                  'Target S15 Create CAP: cp=${state.uri.queryParameters['checkpointId']} audit=${state.uri.queryParameters['auditId']}',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/caps/:id',
            name: 's16_cap_detail',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Target S16 CAP Detail: ${state.pathParameters['id']}'),
              ),
            ),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      localeProvider.overrideWith((ref) => FakeLocaleNotifier(locale)),
    ],
    child: MaterialApp.router(
      routerConfig: effectiveRouter,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<void> pumpAuditDetail(
  WidgetTester tester, {
  required String auditId,
  required AuthState authState,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createAuditDetailTestWidget(
      auditId: auditId,
      authState: authState,
      locale: locale,
      router: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabase fakeDb;

  const testAuditor = AuthUser(
    id: 'user-sm-1',
    name: 'Rahul Sharma',
    role: 'SM',
    languagePref: 'en',
  );

  const testGm = AuthUser(
    id: 'user-gm-1',
    name: 'Priya Patel',
    role: 'GM',
    languagePref: 'en',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeDatabase();
    AppDatabase.instance.setDatabaseForTesting(fakeDb);

    fakeDb.tables['users'] = [
      {
        'id': 'user-sm-1',
        'store_id': 'WLMHW',
        'name': 'Rahul Sharma',
        'role': 'sm',
        'pin_hash': 'h1',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
      {
        'id': 'user-gm-1',
        'store_id': 'WLMHW',
        'name': 'Priya Patel',
        'role': 'gm',
        'pin_hash': 'h2',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
    ];

    fakeDb.tables['cros'] = [
      {
        'id': 'cro-1',
        'name': 'Anil Kumar',
        'counter': 'Billing 1',
        'shift': 'morning',
        'is_active': 1,
        'joined_at': '2026-09-01T00:00:00Z',
      },
    ];

    fakeDb.tables['sops'] = [
      {
        'id': 'SOP 1',
        'number': 1,
        'name_en': 'Opening & Readiness',
        'name_mr': 'सुरूवात आणि सज्जता',
        'weight': 1,
        'is_critical': 0,
        'display_order': 1,
      },
      {
        'id': 'SOP 2',
        'number': 2,
        'name_en': 'Customer Experience',
        'name_mr': 'ग्राहक अनुभव',
        'weight': 1,
        'is_critical': 0,
        'display_order': 2,
      },
    ];

    fakeDb.tables['checkpoints'] = [
      {
        'id': '1.1',
        'sop_id': 'SOP 1',
        'frequency': 'daily',
        'sequence': 1,
        'text_en': 'Shutter opened on time',
        'text_mr': 'शटर वेळेवर उघडले',
        'evidence_en': 'Register timestamp',
        'evidence_mr': 'नोंदवही वेळ',
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 0,
        'display_order': 1,
      },
      {
        'id': '1.2',
        'sop_id': 'SOP 1',
        'frequency': 'daily',
        'sequence': 2,
        'text_en': 'Uniform clean & neat',
        'text_mr': 'गणवेश स्वच्छ आणि व्यवस्थित',
        'evidence_en': 'Staff badge and uniform',
        'evidence_mr': 'कर्मचारी बॅज आणि गणवेश',
        'weight': 3,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 2,
      },
      {
        'id': '2.1',
        'sop_id': 'SOP 2',
        'frequency': 'daily',
        'sequence': 3,
        'text_en': 'Greeting given to customers',
        'text_mr': 'ग्राहकांचे स्वागत केले',
        'evidence_en': 'Observation',
        'evidence_mr': 'निरीक्षण',
        'weight': 5,
        'allows_na': 0,
        'requires_photo_on_fail': 0,
        'display_order': 3,
      },
    ];

    fakeDb.tables['audits'] = [
      {
        'id': 'audit-101',
        'audit_type': 'daily',
        'audit_date': '2026-09-24',
        'week_number': 39,
        'year': 2026,
        'auditor_id': 'user-sm-1',
        'device_id': 'dev-1',
        'status': 'submitted',
        'raw_score': 7.0,
        'max_score': 10.0,
        'compliance_pct': 70.0,
        'band': 'critical',
        'pass_count': 2,
        'fail_count': 1,
        'na_count': 0,
        'submitted_at': '2026-09-24T18:30:00Z',
        'notes': 'Power fluctuation in morning shift',
      },
    ];

    fakeDb.tables['audit_results'] = [
      {
        'id': 'res-1',
        'audit_id': 'audit-101',
        'checkpoint_id': '1.1',
        'result': 'P',
        'weighted_points': 2.0,
        'finding_text': null,
        'cro_id': null,
        'created_at': '2026-09-24T18:10:00Z',
      },
      {
        'id': 'res-2',
        'audit_id': 'audit-101',
        'checkpoint_id': '1.2',
        'result': 'F',
        'weighted_points': 0.0,
        'finding_text': 'Missing name badge and stained apron',
        'cro_id': 'cro-1',
        'created_at': '2026-09-24T18:15:00Z',
      },
      {
        'id': 'res-3',
        'audit_id': 'audit-101',
        'checkpoint_id': '2.1',
        'result': 'P',
        'weighted_points': 5.0,
        'finding_text': null,
        'cro_id': null,
        'created_at': '2026-09-24T18:20:00Z',
      },
    ];

    fakeDb.tables['photos'] = [
      {
        'id': 'photo-1',
        'audit_result_id': 'res-2',
        'cap_id': null,
        'context': 'fail_evidence',
        'local_path': 'C:/mock_photos/uniform_fail.jpg',
        'upload_status': 'pending',
        'captured_at': '2026-09-24T18:16:00Z',
      },
    ];

    fakeDb.tables['caps'] = [];
  });

  tearDown(() {
    AppDatabase.instance.setDatabaseForTesting(null);
  });

  group('S13 Audit Detail Screen Tests (Spec §5 S13 & Hard Rule #6)', () {
    testWidgets('Renders header metadata, read-only banner and score card', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      // Read-only immutability banner
      expect(find.text('Submitted audit — read-only archive'), findsOneWidget);
      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.textContaining('Rahul Sharma'), findsOneWidget);
      expect(find.textContaining('2026-09-24'), findsAtLeastNWidgets(1));

      // Score card
      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Pass count
      expect(find.text('1'), findsAtLeastNWidgets(1)); // Fail count
    });

    testWidgets('Renders SOP Breakdown table and expandable checkpoint inspection', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      expect(find.text('SOP Breakdown'), findsOneWidget);
      expect(find.textContaining('SOP 1 (Opening & Readiness)'), findsOneWidget);
      expect(find.textContaining('SOP 2 (Customer Experience)'), findsOneWidget);

      // Expand SOP 1 tile
      final sop1Tile = find.byKey(const ValueKey('sop_tile_SOP 1'));
      expect(sop1Tile, findsOneWidget);
      await tester.tap(sop1Tile);
      await tester.pumpAndSettle();

      // Checkpoints in SOP 1 visible
      expect(find.textContaining('CP 1.1 — Shutter opened on time'), findsOneWidget);
      expect(find.textContaining('CP 1.2 — Uniform clean & neat'), findsOneWidget);
    });

    testWidgets('Renders non-compliances with findings, CRO attribution and photo thumbnails', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      expect(find.text('Non-Compliances (1)'), findsOneWidget);
      expect(find.byKey(const ValueKey('fail_card_1.2')), findsOneWidget);
      expect(find.text('CP 1.2'), findsOneWidget);
      expect(find.textContaining('Missing name badge and stained apron'), findsOneWidget);
      expect(find.textContaining('Anil Kumar'), findsOneWidget); // CRO attribution
    });

    testWidgets('Unlinked fail displays "+ Create CAP" button and navigates to S15 with params', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      final createCapBtn = find.byKey(const ValueKey('create_cap_1.2'));
      expect(createCapBtn, findsOneWidget);
      expect(find.text('+ Create CAP'), findsOneWidget);

      await tester.tap(createCapBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Target S15 Create CAP: cp=1.2 audit=audit-101'), findsOneWidget);
    });

    testWidgets('Linked CAP displays clickable CAP chip and navigates to S16 CAP Detail', (tester) async {
      // Add a linked CAP for res-2
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-01',
        'origin_audit_id': 'audit-101',
        'origin_checkpoint_id': '1.2',
        'origin_result_id': 'res-2',
        'problem_statement': 'Missing badge',
        'why_1': 'Forgotten',
        'root_cause': 'Lack of morning check',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Uniform check',
        'status': 'open',
        'opened_at': '2026-09-24T18:20:00Z',
      });

      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      expect(find.textContaining('Linked CAP: CAP-2026-W39-01'), findsOneWidget);
      expect(find.byKey(const ValueKey('create_cap_1.2')), findsNothing);

      // Tap linked CAP chip
      await tester.tap(find.textContaining('Linked CAP: CAP-2026-W39-01'));
      await tester.pumpAndSettle();

      expect(find.text('Target S16 CAP Detail: CAP-2026-W39-01'), findsOneWidget);
    });

    testWidgets('Auditor notes are displayed when present', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      expect(find.text('Auditor Notes'), findsOneWidget);
      expect(find.text('Power fluctuation in morning shift'), findsOneWidget);
    });

    testWidgets('Shows zero-fail clean card when audit has no non-compliances', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-perfect',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'raw_score': 10.0,
          'max_score': 10.0,
          'compliance_pct': 100.0,
          'band': 'excellent',
          'pass_count': 3,
          'fail_count': 0,
          'na_count': 0,
          'submitted_at': '2026-09-24T18:30:00Z',
        },
      ];
      fakeDb.tables['audit_results'] = [
        {
          'id': 'res-10',
          'audit_id': 'audit-perfect',
          'checkpoint_id': '1.1',
          'result': 'P',
          'weighted_points': 2.0,
          'created_at': '2026-09-24T18:10:00Z',
        },
      ];

      await pumpAuditDetail(
        tester,
        auditId: 'audit-perfect',
        authState: const AuthState(user: testAuditor),
      );

      expect(find.text('No failures recorded in this audit!'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('EXCELLENT'), findsOneWidget);
    });

    testWidgets('Displays Not Found state for non-existent audit ID', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-999-missing',
        authState: const AuthState(user: testAuditor),
      );

      expect(find.text('Audit not found'), findsOneWidget);
      expect(find.textContaining('audit-999-missing'), findsOneWidget);
      expect(find.text('Back to Audit History'), findsOneWidget);

      await tester.tap(find.text('Back to Audit History'));
      await tester.pumpAndSettle();

      expect(find.text('Target S12 Audit History'), findsOneWidget);
    });

    testWidgets('Rule #6 Audit Immutability: No edit or submit action exists', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );

      // Verify strict read-only nature: no Submit Audit, Save Draft, or Verdict buttons
      expect(find.text('Submit Audit'), findsNothing);
      expect(find.text('Save Draft'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('SM does not see Verify Audit action button', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
      );
      expect(find.text('Verify Audit'), findsNothing);
    });

    testWidgets('GM sees Verify Audit action stub', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testGm),
      );
      expect(find.text('Verify Audit'), findsOneWidget);
    });

    testWidgets('Rule #8 Dual-Language Parity (मराठी) renders authentic Devanagari labels', (tester) async {
      await pumpAuditDetail(
        tester,
        auditId: 'audit-101',
        authState: const AuthState(user: testAuditor),
        locale: const Locale('mr'),
      );

      // Marathi labels
      expect(find.text('सादर केलेले ऑडिट — फक्त-वाचन संग्रहण'), findsOneWidget);
      expect(find.text('ऑडिट गुण'), findsOneWidget);
      expect(find.text('एसओपी (SOP) तपशील'), findsOneWidget);
      expect(find.text('आढळलेले दोष (1)'), findsOneWidget);
      expect(find.text('+ CAP तयार करा'), findsOneWidget);
      expect(find.text('ऑडिट तपशील — 2026-09-24'), findsOneWidget);
      expect(find.text('ऑडिट इतिहासावर परत जा'), findsOneWidget);
    });
  });
}
