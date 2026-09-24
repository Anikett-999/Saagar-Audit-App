import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s12_audit_history/audit_history_screen.dart';
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

Widget createAuditHistoryTestWidget({
  required AuthState authState,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/audits',
        routes: [
          GoRoute(
            path: '/audits',
            name: 's12_audit_history',
            builder: (_, __) => const AuditHistoryScreen(),
          ),
          GoRoute(
            path: '/audits/:id',
            name: 's13_audit_detail',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Target S13 Detail: ${state.pathParameters['id']}'),
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

Future<void> pumpAuditHistory(
  WidgetTester tester, {
  required AuthState authState,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createAuditHistoryTestWidget(
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

  const smUser1 = AuthUser(
    id: 'user-sm-1',
    name: 'Rahul Sharma',
    role: 'SM',
    languagePref: 'en',
  );

  const gmUser = AuthUser(
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
        'id': 'user-sm-2',
        'store_id': 'HEMW',
        'name': 'Amit Shinde',
        'role': 'sm',
        'pin_hash': 'h2',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
      {
        'id': 'user-gm-1',
        'store_id': 'WLMHW',
        'name': 'Priya Patel',
        'role': 'gm',
        'pin_hash': 'h3',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
    ];

    fakeDb.tables['audits'] = [];
  });

  tearDown(() {
    AppDatabase.instance.setDatabaseForTesting(null);
  });

  group('S12 Audit History Screen Tests (Spec §5 S12)', () {
    testWidgets('Renders empty state when no submitted audits exist', (tester) async {
      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: smUser1),
      );

      expect(find.text('Audit History'), findsOneWidget);
      expect(find.text('No audits found'), findsOneWidget);
      expect(find.text('Complete and submit a daily audit to view history here.'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('Renders audit cards with date, auditor name, score %, band, and fail count', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-001',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'raw_score': 81.0,
          'max_score': 90.0,
          'compliance_pct': 90.0,
          'band': 'good',
          'fail_count': 2,
          'pass_count': 60,
          'na_count': 6,
          'submitted_at': '2026-09-24T18:00:00Z',
        },
      ];

      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: smUser1),
      );

      // Verify Audit Card Elements
      expect(find.byKey(const ValueKey('audit_card_audit-001')), findsOneWidget);
      expect(find.text('Date: 2026-09-24'), findsOneWidget);
      expect(find.text('Auditor: Rahul Sharma'), findsOneWidget);
      expect(find.text('Daily'), findsWidgets);
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('2 Fails'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
    });

    testWidgets('Role scoping: SM only sees audits authored by them', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-sm1',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': 92.0,
          'band': 'good',
          'fail_count': 1,
          'submitted_at': '2026-09-24T10:00:00Z',
        },
        {
          'id': 'audit-sm2',
          'audit_type': 'daily',
          'audit_date': '2026-09-23',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-2',
          'device_id': 'dev-2',
          'status': 'submitted',
          'compliance_pct': 88.0,
          'band': 'fair',
          'fail_count': 4,
          'submitted_at': '2026-09-23T10:00:00Z',
        },
      ];

      // Viewing as SM1
      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: smUser1),
      );

      // SM1 only sees audit-sm1
      expect(find.byKey(const ValueKey('audit_card_audit-sm1')), findsOneWidget);
      expect(find.byKey(const ValueKey('audit_card_audit-sm2')), findsNothing);
    });

    testWidgets('Role scoping: GM sees audits from all auditors', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-sm1',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': 92.0,
          'band': 'good',
          'fail_count': 1,
          'submitted_at': '2026-09-24T10:00:00Z',
        },
        {
          'id': 'audit-sm2',
          'audit_type': 'daily',
          'audit_date': '2026-09-23',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-2',
          'device_id': 'dev-2',
          'status': 'submitted',
          'compliance_pct': 88.0,
          'band': 'fair',
          'fail_count': 4,
          'submitted_at': '2026-09-23T10:00:00Z',
        },
      ];

      // Viewing as GM
      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: gmUser),
      );

      // GM sees both
      expect(find.byKey(const ValueKey('audit_card_audit-sm1')), findsOneWidget);
      expect(find.byKey(const ValueKey('audit_card_audit-sm2')), findsOneWidget);
    });

    testWidgets('Excludes draft and hidden audits from history list', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-draft',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'draft',
          'submitted_at': null,
        },
        {
          'id': 'audit-hidden',
          'audit_type': 'daily',
          'audit_date': '2026-09-23',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'hidden',
          'submitted_at': '2026-09-23T10:00:00Z',
        },
        {
          'id': 'audit-submitted',
          'audit_type': 'daily',
          'audit_date': '2026-09-22',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': 95.0,
          'band': 'excellent',
          'fail_count': 0,
          'submitted_at': '2026-09-22T10:00:00Z',
        },
      ];

      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: gmUser),
      );

      expect(find.byKey(const ValueKey('audit_card_audit-draft')), findsNothing);
      expect(find.byKey(const ValueKey('audit_card_audit-hidden')), findsNothing);
      expect(find.byKey(const ValueKey('audit_card_audit-submitted')), findsOneWidget);
    });

    testWidgets('Filter chip toggles unverified audits', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-sub',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': 91.0,
          'band': 'good',
          'fail_count': 1,
          'submitted_at': '2026-09-24T10:00:00Z',
        },
        {
          'id': 'audit-ver',
          'audit_type': 'daily',
          'audit_date': '2026-09-23',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'verified',
          'compliance_pct': 96.0,
          'band': 'excellent',
          'fail_count': 0,
          'submitted_at': '2026-09-23T10:00:00Z',
        },
      ];

      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: gmUser),
      );

      // Initially All shows both
      expect(find.byKey(const ValueKey('audit_card_audit-sub')), findsOneWidget);
      expect(find.byKey(const ValueKey('audit_card_audit-ver')), findsOneWidget);

      // Tap Unverified filter chip
      await tester.tap(find.byKey(const ValueKey('s12_filter_unverified')));
      await tester.pumpAndSettle();

      // Only unverified (submitted) is shown
      expect(find.byKey(const ValueKey('audit_card_audit-sub')), findsOneWidget);
      expect(find.byKey(const ValueKey('audit_card_audit-ver')), findsNothing);
    });

    testWidgets('Tapping audit card navigates to S13 Audit Detail', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-001',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': 90.0,
          'band': 'good',
          'fail_count': 0,
          'submitted_at': '2026-09-24T18:00:00Z',
        },
      ];

      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: smUser1),
      );

      // Tap audit card
      await tester.tap(find.byKey(const ValueKey('audit_card_audit-001')));
      await tester.pumpAndSettle();

      // Verify navigated to target S13 detail
      expect(find.text('Target S13 Detail: audit-001'), findsOneWidget);
    });

    testWidgets('Rule #8 Dual-Language Parity: Marathi locale renders localized UI', (tester) async {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-001',
          'audit_type': 'daily',
          'audit_date': '2026-09-24',
          'week_number': 39,
          'year': 2026,
          'auditor_id': 'user-sm-1',
          'device_id': 'dev-1',
          'status': 'submitted',
          'compliance_pct': 90.0,
          'band': 'good',
          'fail_count': 0,
          'submitted_at': '2026-09-24T18:00:00Z',
        },
      ];

      await pumpAuditHistory(
        tester,
        authState: const AuthState(user: smUser1),
        locale: const Locale('mr'),
      );

      // Localized Title
      expect(find.text('ऑडिट इतिहास'), findsOneWidget);

      // Localized Filter Chips
      expect(find.text('सर्व'), findsOneWidget);
      expect(find.text('दैनंदिन'), findsWidgets);
      expect(find.text('अपडताळलेले'), findsOneWidget);

      // Localized Card Content
      expect(find.text('तारीख: 2026-09-24'), findsOneWidget);
      expect(find.text('ऑडिटर: Rahul Sharma'), findsOneWidget);
      expect(find.text('सादर केले'), findsOneWidget);
      expect(find.text('चांगले'), findsOneWidget);
      expect(find.textContaining('नापास'), findsOneWidget);
    });
  });
}
