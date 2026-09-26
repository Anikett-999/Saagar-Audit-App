import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s17_cap_mark_done/cap_mark_done_screen.dart';
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

Widget createCapMarkDoneTestWidget({
  required AuthState authState,
  required String capId,
  Locale locale = const Locale('en'),
  Future<String?> Function()? onPickPhoto,
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/caps/$capId/mark-done',
        routes: [
          GoRoute(
            path: '/caps/:id/mark-done',
            name: 's17_cap_mark_done',
            builder: (context, state) => CapMarkDoneScreen(
              capId: state.pathParameters['id']!,
              onPickPhoto: onPickPhoto,
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
          GoRoute(
            path: '/caps',
            name: 's14_cap_list',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S14 List')),
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

Future<void> pumpCapMarkDone(
  WidgetTester tester, {
  required AuthState authState,
  required String capId,
  Locale locale = const Locale('en'),
  Future<String?> Function()? onPickPhoto,
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    createCapMarkDoneTestWidget(
      authState: authState,
      capId: capId,
      locale: locale,
      onPickPhoto: onPickPhoto,
      router: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabase fakeDb;

  final smUser = const AuthUser(
    id: 'user-sm-1',
    name: 'Rahul Sharma',
    role: 'SM',
    languagePref: 'en',
  );

  final authStateSm = AuthState(user: smUser);

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
        'pin_hash': 'hash1',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
      {
        'id': 'user-gm-1',
        'store_id': 'WLMHW',
        'name': 'Priya Patel',
        'role': 'gm',
        'pin_hash': 'hash2',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
    ];

    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-2026-W38-01',
        'origin_audit_id': 'audit-001',
        'origin_checkpoint_id': 'cp-cash-01',
        'origin_result_id': 'result-001',
        'problem_statement': 'Counter cash drawer unlocked and unattended during peak hour.',
        'why_1': 'Staff left drawer key in lock.',
        'why_2': null,
        'why_3': null,
        'why_4': null,
        'why_5': null,
        'root_cause': 'Lack of cashier checklist reinforcement at shift handover.',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-09-28',
        'verification_method': 'Verify drawer is locked during random inspection.',
        'status': 'open',
        'opened_at': '2026-09-21T10:00:00Z',
        'done_at': null,
        'verified_at': null,
        'closed_at': null,
        'aged_count': 0,
        'extension_count': 0,
        'latest_extension_reason': null,
      },
    ];

    fakeDb.tables['cap_actions'] = [
      {
        'id': 'act-01',
        'cap_id': 'CAP-2026-W38-01',
        'sequence': 1,
        'action_text': 'Brief all cashiers on key protocol immediately.',
        'is_done': 1,
        'done_at': '2026-09-22T08:30:00Z',
        'done_by': 'user-sm-1',
        'done_notes': 'Briefing conducted',
      },
      {
        'id': 'act-02',
        'cap_id': 'CAP-2026-W38-01',
        'sequence': 2,
        'action_text': 'Install physical key tag with mandatory belt loop attachment.',
        'is_done': 1,
        'done_at': '2026-09-23T11:00:00Z',
        'done_by': 'user-sm-1',
        'done_notes': 'Tags distributed',
      },
      {
        'id': 'act-03',
        'cap_id': 'CAP-2026-W38-01',
        'sequence': 3,
        'action_text': 'Audit key log twice daily for 5 consecutive business days.',
        'is_done': 1,
        'done_at': '2026-09-24T09:00:00Z',
        'done_by': 'user-sm-1',
        'done_notes': 'Verified 5 days logged',
      },
    ];

    fakeDb.tables['cap_log'] = [
      {
        'id': 'log-01',
        'cap_id': 'CAP-2026-W38-01',
        'event': 'created',
        'from_status': null,
        'to_status': 'open',
        'actor_user_id': 'user-sm-1',
        'device_id': 'dev-1',
        'timestamp': '2026-09-21T10:00:00Z',
        'note': 'CAP opened',
      },
    ];

    fakeDb.tables['photos'] = [];
  });

  tearDown(() {
    AppDatabase.instance.setDatabaseForTesting(null);
  });

  group('S17 CAP Mark Done Screen Tests (Spec §5 S17)', () {
    testWidgets('Renders header summary, completed action steps, and confirm button enabled', (tester) async {
      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-2026-W38-01',
      );

      // Verify Screen Title
      expect(find.text('Mark CAP Done'), findsOneWidget);

      // Verify Summary Card
      expect(find.text('CAP-2026-W38-01'), findsOneWidget);
      expect(find.textContaining('Counter cash drawer unlocked'), findsOneWidget);
      expect(find.textContaining('Rahul Sharma'), findsOneWidget);
      expect(find.textContaining('Deadline: 2026-09-28'), findsOneWidget);

      // Verify Completed Action Steps Section
      expect(find.text('Completed Action Steps'), findsOneWidget);
      expect(find.text('All 3 action steps have been completed.'), findsOneWidget);
      expect(find.textContaining('Brief all cashiers'), findsOneWidget);
      expect(find.textContaining('Install physical key tag'), findsOneWidget);
      expect(find.textContaining('Audit key log twice daily'), findsOneWidget);

      // Verify Done Notes & Evidence Photo sections
      expect(find.text('Done Notes / Reflection (optional)'), findsOneWidget);
      expect(find.text('Completion Evidence Photo (optional)'), findsOneWidget);
      expect(find.byKey(const ValueKey('s17_take_photo_button')), findsOneWidget);

      // Verify Advisory Card
      expect(
        find.textContaining("transition its status to 'Done (Pending Verification)'"),
        findsOneWidget,
      );

      // Verify Confirm button is ENABLED
      final confirmBtn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('s17_confirm_button')),
      );
      expect(confirmBtn.onPressed, isNotNull);
    });

    testWidgets('Disables Confirm button and displays warning if any action step is incomplete', (tester) async {
      // Mark step 3 as incomplete
      fakeDb.tables['cap_actions']![2]['is_done'] = 0;
      fakeDb.tables['cap_actions']![2]['done_at'] = null;

      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-2026-W38-01',
      );

      // Warning banner displayed
      expect(find.textContaining('Warning: Incomplete action steps remain'), findsOneWidget);

      // Confirm button is DISABLED
      final confirmBtn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('s17_confirm_button')),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('Captures optional photo, adds done notes, and marks CAP done atomically', (tester) async {
      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-2026-W38-01',
        onPickPhoto: () async => '/mock/evidence/drawer_locked.jpg',
      );

      // Enter reflection notes
      await tester.enterText(
        find.byKey(const ValueKey('s17_done_notes_input')),
        'Key protocol implemented and verified with morning and evening audits.',
      );
      await tester.pump();

      // Tap Take Photo button
      await tester.tap(find.byKey(const ValueKey('s17_take_photo_button')));
      await tester.pumpAndSettle();

      // Verify photo preview is attached
      expect(find.text('1 photo attached'), findsOneWidget);
      expect(find.byKey(const ValueKey('s17_retake_photo_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('s17_remove_photo_button')), findsOneWidget);

      // Tap Confirm & Mark Done
      await tester.tap(find.byKey(const ValueKey('s17_confirm_button')));
      await tester.pumpAndSettle();

      // Verify database state:
      // 1. caps.status = 'done'
      final capRow = fakeDb.tables['caps']!.firstWhere(
        (c) => c['id'] == 'CAP-2026-W38-01',
      );
      expect(capRow['status'], 'done');
      expect(capRow['done_at'], isNotNull);

      // 2. cap_log: event = 'marked_done'
      final logs = fakeDb.tables['cap_log']!;
      final markDoneLog = logs.firstWhere((l) => l['event'] == 'marked_done');
      expect(markDoneLog['actor_user_id'], 'user-sm-1');
      expect(markDoneLog['from_status'], 'open');
      expect(markDoneLog['to_status'], 'done');
      expect(
        markDoneLog['note'],
        'Key protocol implemented and verified with morning and evening audits.',
      );

      // 3. photos: row inserted with context = 'cap_progress'
      final photos = fakeDb.tables['photos']!;
      expect(photos.length, 1);
      final photo = photos.first;
      expect(photo['cap_id'], 'CAP-2026-W38-01');
      expect(photo['context'], 'cap_progress');
      expect(photo['local_path'], '/mock/evidence/drawer_locked.jpg');
      expect(photo['uploaded_by'], 'user-sm-1');
      expect(photo['audit_result_id'], isNull);
    });

    testWidgets('Removes attached photo when Remove button is tapped', (tester) async {
      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-2026-W38-01',
        onPickPhoto: () async => '/mock/evidence/test_photo.jpg',
      );

      // Tap Take Photo
      await tester.tap(find.byKey(const ValueKey('s17_take_photo_button')));
      await tester.pumpAndSettle();
      expect(find.text('1 photo attached'), findsOneWidget);

      // Tap Remove Photo
      await tester.tap(find.byKey(const ValueKey('s17_remove_photo_button')));
      await tester.pumpAndSettle();

      // Verified photo removed and Take Photo button reappeared
      expect(find.text('1 photo attached'), findsNothing);
      expect(find.byKey(const ValueKey('s17_take_photo_button')), findsOneWidget);
    });

    testWidgets('Displays Not Found view if CAP ID does not exist', (tester) async {
      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-NON-EXISTENT',
      );

      expect(find.text('CAP not found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('Disables Confirm button if CAP is already in done status', (tester) async {
      fakeDb.tables['caps']!.first['status'] = 'done';

      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-2026-W38-01',
      );

      final confirmBtn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('s17_confirm_button')),
      );
      expect(confirmBtn.onPressed, isNull);
    });

    testWidgets('Rule #8 Dual-Language Parity: Marathi locale renders localized UI', (tester) async {
      await pumpCapMarkDone(
        tester,
        authState: authStateSm,
        capId: 'CAP-2026-W38-01',
        locale: const Locale('mr'),
      );

      // Localized Title
      expect(find.text('CAP पूर्ण म्हणून खूण करा'), findsOneWidget);

      // Localized Section Titles & Labels
      expect(find.text('समस्या विधान'), findsOneWidget);
      expect(find.textContaining('जबाबदार:'), findsOneWidget);
      expect(find.text('पूर्ण झालेली कृती पावले'), findsOneWidget);
      expect(find.textContaining('कृती पावले पूर्ण झाली आहेत'), findsOneWidget);
      expect(find.text('पूर्ण नोंदी / शेरे (ऐच्छिक)'), findsOneWidget);
      expect(find.text('पूर्णता पुरावा फोटो (ऐच्छिक)'), findsOneWidget);
      expect(find.text('फोटो काढा'), findsOneWidget);
      expect(find.text('पुष्टी करा आणि पूर्ण खूण करा'), findsOneWidget);
      expect(find.text('रद्द करा'), findsOneWidget);
    });
  });
}
