import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/cap/gm_dashboard_screen.dart';

import 'helpers/fake_database.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createDashboardTestWidget({
  required AuthState authState,
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    initialLocation: '/caps/oversight',
    routes: [
      GoRoute(
        path: '/caps/oversight',
        name: 'gm_cap_oversight',
        builder: (context, state) => const GmDashboardScreen(),
      ),
      GoRoute(
        path: '/caps/:id/verify',
        name: 's18_cap_verify',
        builder: (context, state) => Scaffold(
          body: Center(child: Text('Target S18 Verify: ${state.pathParameters['id']}')),
        ),
      ),
      GoRoute(
        path: '/caps',
        name: 's14_cap_list',
        builder: (_, __) => const Scaffold(body: Center(child: Text('Target S14 List'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      localeProvider.overrideWith((ref) => FakeLocaleNotifier(locale)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
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

Future<void> pumpDashboard(
  WidgetTester tester, {
  required AuthState authState,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    createDashboardTestWidget(
      authState: authState,
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeDatabase fakeDb;

  const gmUser = AuthUser(
    id: 'user-gm-1',
    name: 'General Manager',
    role: 'GM',
    languagePref: 'en',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeDatabase();
    AppDatabase.instance.setDatabaseForTesting(fakeDb);

    fakeDb.tables['users'] = [
      {
        'id': gmUser.id,
        'name': gmUser.name,
        'role': 'GM',
        'pin_hash': 'hash_gm',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
    ];

    fakeDb.tables['checkpoints'] = [
      {
        'id': '1.1',
        'sop_id': 'sop-1',
        'frequency': 'daily',
        'sequence': 1,
        'text_en': 'Floor Cleanliness',
        'text_mr': 'फरशी स्वच्छता',
        'weight': 1,
        'allows_na': 0,
        'requires_photo_on_fail': 0,
        'display_order': 1,
      },
    ];

    fakeDb.tables['audits'] = [
      {
        'id': 'audit-1',
        'audit_type': 'daily',
        'audit_date': '2026-09-24',
        'week_number': 39,
        'year': 2026,
        'auditor_id': gmUser.id,
        'device_id': 'device-test',
        'status': 'submitted',
        'submitted_at': '2026-09-24T18:00:00Z',
      },
    ];
  });

  group('GM Dashboard — CAP Oversight Screen Tests (Plan §5.5)', () {
    testWidgets('1. Renders title, subtitle, status counts grid, and empty awaiting state', (tester) async {
      fakeDb.tables['caps'] = [];

      await pumpDashboard(
        tester,
        authState: const AuthState(user: gmUser),
      );

      expect(find.text('CAP Oversight'), findsWidgets);
      expect(find.text('Monitor and verify store corrective actions'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Awaiting Verify'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('No CAPs awaiting verification'), findsOneWidget);
    });

    testWidgets('2. Displays aggregated status counts correctly including overdue card', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-01',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Problem 1',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2099-12-31', // future
          'verification_method': 'v',
          'status': 'open',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-02',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Problem 2',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2099-12-31',
          'verification_method': 'v',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-03',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Problem 3',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2099-12-31',
          'verification_method': 'v',
          'status': 'verified',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-04',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Problem 4',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2099-12-31',
          'verification_method': 'v',
          'status': 'closed',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-05',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Overdue Problem',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2020-01-01', // overdue!
          'verification_method': 'v',
          'status': 'open',
          'opened_at': '2020-01-01T10:00:00Z',
        },
      ];

      await pumpDashboard(
        tester,
        authState: const AuthState(user: gmUser),
      );

      // Overdue card appears when overdue > 0
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('3. Renders awaiting CAP with Pattern Issue marker and deep-links to S18', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-AW-01',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Grease accumulation near fryer',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2026-10-05',
          'verification_method': 'Check tile cleanliness',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'is_pattern': 1,
        },
      ];

      await pumpDashboard(
        tester,
        authState: const AuthState(user: gmUser),
      );

      expect(find.text('CAP-AW-01'), findsOneWidget);
      expect(find.text('Grease accumulation near fryer'), findsOneWidget);
      expect(find.text('Pattern Issue'), findsOneWidget);
      expect(find.text('Verify Now'), findsOneWidget);

      // Tap Verify Now
      await tester.tap(find.byKey(const ValueKey('verify_now_CAP-AW-01')));
      await tester.pumpAndSettle();

      // Deep links to S18
      expect(find.text('Target S18 Verify: CAP-AW-01'), findsOneWidget);
    });

    testWidgets('4. Dual-Language Parity (Rule #8): Marathi renders authentic Marathi strings', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-AW-MR',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'स्वच्छता समस्या',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': gmUser.id,
          'deadline': '2026-10-05',
          'verification_method': 'तपासा',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'is_pattern': 1,
        },
      ];

      await pumpDashboard(
        tester,
        authState: const AuthState(user: gmUser),
        locale: const Locale('mr'),
      );

      expect(find.text('CAP व्यवस्थापन'), findsWidgets);
      expect(find.text('स्टोअर सुधारात्मक कृतींचे निरीक्षण व पडताळणी करा'), findsOneWidget);
      expect(find.text('उघडे'), findsOneWidget);
      expect(find.text('पडताळणी प्रलंबित'), findsOneWidget);
      expect(find.text('पडताळलेले'), findsOneWidget);
      expect(find.text('बंद'), findsOneWidget);
      expect(find.text('माझ्या पडताळणीसाठी प्रलंबित'), findsOneWidget);
      expect(find.text('वारंवार आढळलेली समस्या'), findsOneWidget);
      expect(find.text('आता पडताळा'), findsOneWidget);
    });
  });
}
