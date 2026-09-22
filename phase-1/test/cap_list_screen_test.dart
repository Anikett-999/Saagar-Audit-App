import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s14_cap_list/cap_list_screen.dart';

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

Widget createCapListTestWidget({
  required AuthState authState,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/caps',
        routes: [
          GoRoute(
            path: '/caps',
            name: 's14_cap_list',
            builder: (_, __) => const CapListScreen(),
          ),
          GoRoute(
            path: '/caps/new',
            name: 's15_cap_create',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S15 Create')),
            ),
          ),
          GoRoute(
            path: '/caps/:id',
            name: 's16_cap_detail',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Target S16 Detail: ${state.pathParameters['id']}'),
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

Future<void> pumpCapList(
  WidgetTester tester, {
  required AuthState authState,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    createCapListTestWidget(
      authState: authState,
      locale: locale,
      router: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S14 CAP List Screen Tests (Spec §5 S14 & Sprint Plan)', () {
    late FakeDatabase fakeDb;

    const ownerUser = AuthUser(
      id: 'user-owner',
      name: 'Pramod Owner',
      role: 'OWNER',
      languagePref: 'en',
    );

    const smUser = AuthUser(
      id: 'user-sm',
      name: 'Sunil SM',
      role: 'SM',
      languagePref: 'en',
    );

    const gmUser = AuthUser(
      id: 'user-gm',
      name: 'Ganesh GM',
      role: 'GM',
      languagePref: 'en',
    );

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed users table
      fakeDb.tables['users']!.addAll([
        {
          'id': 'user-owner',
          'name': 'Pramod Owner',
          'role': 'OWNER',
          'pin_hash': 'hash',
          'language_pref': 'en',
          'is_active': 1,
          'created_at': '2026-09-01T00:00:00.000Z',
        },
        {
          'id': 'user-sm',
          'name': 'Sunil SM',
          'role': 'SM',
          'pin_hash': 'hash',
          'language_pref': 'en',
          'is_active': 1,
          'created_at': '2026-09-01T00:00:00.000Z',
        },
        {
          'id': 'user-gm',
          'name': 'Ganesh GM',
          'role': 'GM',
          'pin_hash': 'hash',
          'language_pref': 'en',
          'is_active': 1,
          'created_at': '2026-09-01T00:00:00.000Z',
        },
      ]);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Empty state renders when no CAPs exist in database', (tester) async {
      await pumpCapList(tester, authState: const AuthState(user: ownerUser));

      expect(find.text('Corrective Action Plans'), findsOneWidget);
      expect(find.text('Track and resolve audit findings'), findsOneWidget);
      expect(find.text('No CAPs Found'), findsOneWidget);
      expect(find.text('No corrective actions match the selected filter.'), findsOneWidget);
      expect(find.byKey(const ValueKey('s14_create_fab')), findsOneWidget);
      expect(find.text('New CAP'), findsWidgets);
    });

    testWidgets('Lists CAPs with ID, status badge, problem statement, and deadline', (tester) async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W38-01',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': 'cp-1',
        'origin_result_id': 'res-1',
        'problem_statement': 'Display glass counter dirty with fingerprints',
        'why_1': 'Not cleaned',
        'root_cause': 'Checklist missed',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-20',
        'verification_method': 'Visual inspect',
        'status': 'open',
        'opened_at': '2026-09-15T10:00:00.000Z',
        'aged_count': 0,
        'extension_count': 0,
        'cloud_sync_status': 'local',
      });

      await pumpCapList(tester, authState: const AuthState(user: ownerUser));

      expect(find.text('CAP-2026-W38-01'), findsOneWidget);
      expect(find.text('Display glass counter dirty with fingerprints'), findsOneWidget);
      expect(find.text('Responsible: Sunil SM'), findsOneWidget);
      expect(find.text('Open'), findsWidgets); // Status badge and filter chip
      expect(find.textContaining('Overdue'), findsOneWidget);
    });

    testWidgets('Deadline badges render proper color-coded status (overdue, dueSoon, ok)', (tester) async {
      final now = DateTime.now();
      final overdueDate = now.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
      final dueSoonDate = now.add(const Duration(hours: 12)).toIso8601String().substring(0, 10);
      final okDate = now.add(const Duration(days: 5)).toIso8601String().substring(0, 10);

      fakeDb.tables['caps']!.addAll([
        {
          'id': 'CAP-2026-W38-01',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-1',
          'problem_statement': 'Overdue problem issue',
          'why_1': 'Reason',
          'root_cause': 'Root',
          'responsible_user_id': 'user-sm',
          'deadline': overdueDate,
          'verification_method': 'Method',
          'status': 'open',
          'opened_at': now.toIso8601String(),
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-2026-W38-02',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-2',
          'problem_statement': 'Due soon problem issue',
          'why_1': 'Reason',
          'root_cause': 'Root',
          'responsible_user_id': 'user-gm',
          'deadline': dueSoonDate,
          'verification_method': 'Method',
          'status': 'open',
          'opened_at': now.toIso8601String(),
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-2026-W38-03',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-3',
          'problem_statement': 'OK deadline problem issue',
          'why_1': 'Reason',
          'root_cause': 'Root',
          'responsible_user_id': 'user-owner',
          'deadline': okDate,
          'verification_method': 'Method',
          'status': 'open',
          'opened_at': now.toIso8601String(),
          'aged_count': 0,
          'extension_count': 0,
        },
      ]);

      await pumpCapList(tester, authState: const AuthState(user: ownerUser));

      expect(find.text('Overdue ($overdueDate)'), findsOneWidget);
      expect(find.text('Due Soon ($dueSoonDate)'), findsOneWidget);
      expect(find.text('Due: $okDate'), findsOneWidget);
    });

    testWidgets('Filter chips switch view between All, Open, Done, Aged, Closed', (tester) async {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 4)).toIso8601String().substring(0, 10);
      final futureDate = now.add(const Duration(days: 4)).toIso8601String().substring(0, 10);

      fakeDb.tables['caps']!.addAll([
        {
          'id': 'CAP-OPEN',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-1',
          'problem_statement': 'Open CAP Task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': futureDate,
          'verification_method': 'm',
          'status': 'open',
          'opened_at': now.toIso8601String(),
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-DONE',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-2',
          'problem_statement': 'Done CAP Task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': futureDate,
          'verification_method': 'm',
          'status': 'done',
          'opened_at': now.toIso8601String(),
          'done_at': now.toIso8601String(),
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-AGED',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-3',
          'problem_statement': 'Aged CAP Task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': pastDate,
          'verification_method': 'm',
          'status': 'aged',
          'opened_at': now.toIso8601String(),
          'aged_count': 1,
          'extension_count': 0,
        },
        {
          'id': 'CAP-CLOSED',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-4',
          'problem_statement': 'Closed CAP Task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': pastDate,
          'verification_method': 'm',
          'status': 'closed',
          'opened_at': now.toIso8601String(),
          'closed_at': now.toIso8601String(),
          'aged_count': 0,
          'extension_count': 0,
        },
      ]);

      await pumpCapList(tester, authState: const AuthState(user: ownerUser));

      // Default filter is All
      expect(find.text('Open CAP Task'), findsOneWidget);
      expect(find.text('Done CAP Task'), findsOneWidget);
      expect(find.text('Aged CAP Task'), findsOneWidget);
      expect(find.text('Closed CAP Task'), findsOneWidget);

      // Filter: Open
      await tester.tap(find.byKey(const ValueKey('filter_open')));
      await tester.pumpAndSettle();
      expect(find.text('Open CAP Task'), findsOneWidget);
      expect(find.text('Done CAP Task'), findsNothing);
      expect(find.text('Closed CAP Task'), findsNothing);

      // Filter: Done
      await tester.tap(find.byKey(const ValueKey('filter_done')));
      await tester.pumpAndSettle();
      expect(find.text('Open CAP Task'), findsNothing);
      expect(find.text('Done CAP Task'), findsOneWidget);
      expect(find.text('Closed CAP Task'), findsNothing);

      // Filter: Aged
      await tester.tap(find.byKey(const ValueKey('filter_aged')));
      await tester.pumpAndSettle();
      expect(find.text('Aged CAP Task'), findsOneWidget);
      expect(find.text('Done CAP Task'), findsNothing);

      // Filter: Closed
      await tester.tap(find.byKey(const ValueKey('filter_closed')));
      await tester.pumpAndSettle();
      expect(find.text('Closed CAP Task'), findsOneWidget);
      expect(find.text('Open CAP Task'), findsNothing);
    });

    testWidgets('Search bar dynamically filters list by problem statement or CAP ID', (tester) async {
      fakeDb.tables['caps']!.addAll([
        {
          'id': 'CAP-2026-W38-01',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-1',
          'problem_statement': 'Display glass counter dirty',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-2026-W38-02',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': 'cp-2',
          'problem_statement': 'Fire extinguisher expired tag',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-gm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
      ]);

      await pumpCapList(tester, authState: const AuthState(user: ownerUser));

      expect(find.text('Display glass counter dirty'), findsOneWidget);
      expect(find.text('Fire extinguisher expired tag'), findsOneWidget);

      // Search by keyword
      await tester.enterText(find.byKey(const ValueKey('s14_search_field')), 'extinguisher');
      await tester.pumpAndSettle();

      expect(find.text('Display glass counter dirty'), findsNothing);
      expect(find.text('Fire extinguisher expired tag'), findsOneWidget);

      // Search by CAP ID
      await tester.enterText(find.byKey(const ValueKey('s14_search_field')), 'W38-01');
      await tester.pumpAndSettle();

      expect(find.text('Display glass counter dirty'), findsOneWidget);
      expect(find.text('Fire extinguisher expired tag'), findsNothing);
    });

    testWidgets('Role scoping: SM only sees assigned CAPs or CAPs from authored audits', (tester) async {
      fakeDb.tables['audits']!.add({
        'id': 'audit-sm-1',
        'audit_type': 'daily',
        'store_id': 'WLMHW',
        'auditor_id': 'user-sm',
        'status': 'submitted',
        'audit_date': '2026-09-20',
        'week_number': 38,
        'year': 2026,
        'device_id': 'dev-1',
      });

      fakeDb.tables['caps']!.addAll([
        {
          'id': 'CAP-SM-ASSIGNED',
          'origin_audit_id': 'audit-other',
          'origin_checkpoint_id': 'cp-1',
          'problem_statement': 'SM assigned task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-SM-AUTHORED',
          'origin_audit_id': 'audit-sm-1',
          'origin_checkpoint_id': 'cp-2',
          'problem_statement': 'From SM audit but assigned to GM',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-gm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-GM-ONLY',
          'origin_audit_id': 'audit-gm-other',
          'origin_checkpoint_id': 'cp-3',
          'problem_statement': 'GM private task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-gm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
      ]);

      // When SM logs in: sees SM-assigned and SM-authored, but NOT GM-only
      await pumpCapList(tester, authState: const AuthState(user: smUser));

      expect(find.text('SM assigned task'), findsOneWidget);
      expect(find.text('From SM audit but assigned to GM'), findsOneWidget);
      expect(find.text('GM private task'), findsNothing);
    });

    testWidgets('Role scoping: GM and OWNER see all CAPs', (tester) async {
      fakeDb.tables['audits']!.add({
        'id': 'audit-sm-1',
        'audit_type': 'daily',
        'store_id': 'WLMHW',
        'auditor_id': 'user-sm',
        'status': 'submitted',
        'audit_date': '2026-09-20',
        'week_number': 38,
        'year': 2026,
        'device_id': 'dev-1',
      });

      fakeDb.tables['caps']!.addAll([
        {
          'id': 'CAP-SM-ASSIGNED',
          'origin_audit_id': 'audit-other',
          'origin_checkpoint_id': 'cp-1',
          'problem_statement': 'SM assigned task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-sm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-SM-AUTHORED',
          'origin_audit_id': 'audit-sm-1',
          'origin_checkpoint_id': 'cp-2',
          'problem_statement': 'From SM audit but assigned to GM',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-gm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
        {
          'id': 'CAP-GM-ONLY',
          'origin_audit_id': 'audit-gm-other',
          'origin_checkpoint_id': 'cp-3',
          'problem_statement': 'GM private task',
          'why_1': 'w',
          'root_cause': 'rc',
          'responsible_user_id': 'user-gm',
          'deadline': '2026-09-30',
          'verification_method': 'm',
          'status': 'open',
          'opened_at': '2026-09-15T10:00:00.000Z',
          'aged_count': 0,
          'extension_count': 0,
        },
      ]);

      // When GM logs in: sees ALL CAPs
      await pumpCapList(tester, authState: const AuthState(user: gmUser));

      expect(find.text('SM assigned task'), findsOneWidget);
      expect(find.text('From SM audit but assigned to GM'), findsOneWidget);
      expect(find.text('GM private task'), findsOneWidget);
    });

    testWidgets('Navigation: FAB navigates to S15 and tapping card navigates to S16', (tester) async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W38-99',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': 'cp-1',
        'problem_statement': 'Tap to view detail',
        'why_1': 'w',
        'root_cause': 'rc',
        'responsible_user_id': 'user-owner',
        'deadline': '2026-09-30',
        'verification_method': 'm',
        'status': 'open',
        'opened_at': '2026-09-15T10:00:00.000Z',
        'aged_count': 0,
        'extension_count': 0,
      });

      await pumpCapList(tester, authState: const AuthState(user: ownerUser));

      // Tap card -> navigates to S16 detail
      await tester.tap(find.byKey(const ValueKey('cap_item_CAP-2026-W38-99')));
      await tester.pumpAndSettle();
      expect(find.text('Target S16 Detail: CAP-2026-W38-99'), findsOneWidget);

      // Go back to list
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Tap to view detail'), findsOneWidget);

      // Tap FAB -> navigates to S15 create
      await tester.tap(find.byKey(const ValueKey('s14_create_fab')));
      await tester.pumpAndSettle();
      expect(find.text('Target S15 Create'), findsOneWidget);
    });

    testWidgets('Rule #8 Dual-Language Parity: Marathi locale renders localized UI', (tester) async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W38-MR',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': 'cp-1',
        'problem_statement': 'काऊंटर स्वच्छ नाही',
        'why_1': 'कारण',
        'root_cause': 'मूळ कारण',
        'responsible_user_id': 'user-sm',
        'deadline': '2026-09-30',
        'verification_method': 'तपासणी',
        'status': 'open',
        'opened_at': '2026-09-15T10:00:00.000Z',
        'aged_count': 0,
        'extension_count': 0,
      });

      await pumpCapList(
        tester,
        authState: const AuthState(user: ownerUser),
        locale: const Locale('mr'),
      );

      // Title & Subtitle in Marathi
      expect(find.text('सुधारात्मक कृती योजना (CAP)'), findsOneWidget);
      expect(find.text('ऑडिट निष्कर्षांचा मागोवा आणि निराकरण'), findsOneWidget);

      // Filter chips in Marathi
      expect(find.text('सर्व'), findsOneWidget);
      expect(find.text('उघडे'), findsWidgets); // chip + status badge
      expect(find.text('पूर्ण (पडताळणी प्रलंबित)'), findsOneWidget);
      expect(find.text('जुनी ⚠'), findsOneWidget);
      expect(find.text('बंद'), findsOneWidget);

      // Card items
      expect(find.text('काऊंटर स्वच्छ नाही'), findsOneWidget);
      expect(find.text('जबाबदार: Sunil SM'), findsOneWidget);
      expect(find.text('नवीन CAP'), findsOneWidget);
    });
  });
}
