import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s16_cap_detail/cap_detail_screen.dart';
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

Widget createCapDetailTestWidget({
  required AuthState authState,
  required String capId,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/caps/$capId',
        routes: [
          GoRoute(
            path: '/caps/:id',
            name: 's16_cap_detail',
            builder: (context, state) => CapDetailScreen(
              capId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/caps/:id/mark-done',
            name: 's17_cap_mark_done',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Target S17 Mark Done: ${state.pathParameters['id']}'),
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

Future<void> pumpCapDetail(
  WidgetTester tester, {
  required AuthState authState,
  required String capId,
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    createCapDetailTestWidget(
      authState: authState,
      capId: capId,
      locale: locale,
      router: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabase fakeDb;

  const smUser = AuthUser(
    id: 'user-sm-1',
    name: 'Rahul SM',
    role: 'SM',
    languagePref: 'en',
  );

  const otherSmUser = AuthUser(
    id: 'user-sm-2',
    name: 'Priya SM',
    role: 'SM',
    languagePref: 'en',
  );

  const gmUser = AuthUser(
    id: 'user-gm-1',
    name: 'Vikram GM',
    role: 'GM',
    languagePref: 'en',
  );

  const ownerUser = AuthUser(
    id: 'user-owner-1',
    name: 'Aniket Owner',
    role: 'OWNER',
    languagePref: 'en',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeDatabase();
    AppDatabase.instance.setDatabaseForTesting(fakeDb);

    // Seed users
    fakeDb.tables['users'] = [
      {
        'id': smUser.id,
        'name': smUser.name,
        'role': 'SM',
        'pin_hash': 'hash1',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
      {
        'id': otherSmUser.id,
        'name': otherSmUser.name,
        'role': 'SM',
        'pin_hash': 'hash2',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
      {
        'id': gmUser.id,
        'name': gmUser.name,
        'role': 'GM',
        'pin_hash': 'hash3',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
      {
        'id': ownerUser.id,
        'name': ownerUser.name,
        'role': 'OWNER',
        'pin_hash': 'hash4',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T00:00:00Z',
      },
    ];

    // Seed checkpoints
    fakeDb.tables['checkpoints'] = [
      {
        'id': '1.1',
        'sop_id': 'sop-1',
        'frequency': 'daily',
        'sequence': 1,
        'text_en': 'Store opened on time and shutter clean',
        'text_mr': 'दुकान वेळेवर उघडले आणि शटर स्वच्छ आहे',
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 1,
      },
    ];

    // Seed audits
    fakeDb.tables['audits'] = [
      {
        'id': 'audit-1',
        'audit_type': 'daily',
        'audit_date': '2026-09-24',
        'week_number': 39,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'dev-1',
        'status': 'submitted',
      },
    ];
  });

  tearDown(() {
    AppDatabase.instance.setDatabaseForTesting(null);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Renders full 10 fields read-only, status badge, and deadline',
      (tester) async {
    const capId = 'CAP-2026-W39-01';

    fakeDb.tables['caps'] = [
      {
        'id': capId,
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 1,
        'problem_statement': 'Shutter was dirty and opened 20 minutes late.',
        'why_1': 'Keys were misplaced the previous night.',
        'why_2': 'Closing checklist was skipped.',
        'why_3': 'Staff was rushing to catch transport.',
        'root_cause': 'Lack of formalized key handover procedure at store closing.',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Daily check of key handover log for 5 days.',
        'status': 'open',
        'opened_at': '2026-09-24T10:00:00Z',
        'aged_count': 0,
        'extension_count': 0,
      },
    ];

    fakeDb.tables['cap_actions'] = [
      {
        'id': 'act-1',
        'cap_id': capId,
        'sequence': 1,
        'action_text': 'Draft standard key handover SOP checklist',
        'is_done': 1,
        'done_at': '2026-09-24T12:00:00Z',
        'done_by': smUser.id,
      },
      {
        'id': 'act-2',
        'cap_id': capId,
        'sequence': 2,
        'action_text': 'Conduct briefing with morning and evening cashiers',
        'is_done': 0,
      },
      {
        'id': 'act-3',
        'cap_id': capId,
        'sequence': 3,
        'action_text': 'Mount key deposit lockbox near manager desk',
        'is_done': 0,
      },
    ];

    fakeDb.tables['cap_log'] = [
      {
        'id': 'log-1',
        'cap_id': capId,
        'event': 'created',
        'actor_user_id': smUser.id,
        'timestamp': '2026-09-24T10:00:00Z',
        'note': 'CAP created with 3 action steps',
      },
      {
        'id': 'log-2',
        'cap_id': capId,
        'event': 'action_done',
        'actor_user_id': smUser.id,
        'timestamp': '2026-09-24T12:00:00Z',
        'note': null,
      },
    ];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: capId,
    );

    // Verify Title & Header
    expect(find.text(capId), findsOneWidget);
    expect(find.byKey(const ValueKey('s16_status_badge')), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Recurring Issue (Pattern)'), findsOneWidget);

    // Verify Origin Information
    expect(find.text('1. Origin Information'), findsOneWidget);
    expect(find.textContaining('1.1 — Store opened on time'), findsOneWidget);
    expect(find.textContaining('2026-09-24 (DAILY)'), findsOneWidget);

    // Verify Problem Statement & 5 Whys
    expect(find.text('2. Problem & 5-Whys Analysis'), findsOneWidget);
    expect(find.text('Shutter was dirty and opened 20 minutes late.'), findsOneWidget);
    expect(find.text('Why 1'), findsOneWidget);
    expect(find.text('Keys were misplaced the previous night.'), findsOneWidget);
    expect(find.text('Why 2'), findsOneWidget);
    expect(find.text('Closing checklist was skipped.'), findsOneWidget);
    expect(find.text('Lack of formalized key handover procedure at store closing.'), findsOneWidget);

    // Verify Ownership Card
    expect(find.text('3. Ownership & Verification'), findsOneWidget);
    expect(find.text('Rahul SM (SM)'), findsOneWidget);
    expect(find.text('Daily check of key handover log for 5 days.'), findsOneWidget);

    // Verify Action Steps (1 done out of 3 = 33%)
    expect(find.text('4. Action Steps (1/3)'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.textContaining('Step 1: Draft standard key handover'), findsOneWidget);
    expect(find.textContaining('Step 2: Conduct briefing'), findsOneWidget);
    expect(find.textContaining('Step 3: Mount key deposit'), findsOneWidget);

    // Verify Timeline Section
    expect(find.text('5. Event Timeline'), findsOneWidget);
    expect(find.text('CAP Created'), findsOneWidget);
    expect(find.text('Action Step Completed'), findsOneWidget);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Deadline badges render appropriate color-coded status',
      (tester) async {
    final now = DateTime.now();
    final yesterdayStr = now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
    final todayStr = now.toIso8601String().substring(0, 10);
    final futureStr = now.add(const Duration(days: 5)).toIso8601String().substring(0, 10);

    // 1. Overdue CAP
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-OVERDUE',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Overdue issue',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': yesterdayStr,
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-01T00:00:00Z',
      },
    ];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: 'CAP-OVERDUE',
    );

    expect(find.textContaining('Overdue by'), findsOneWidget);

    // 2. Due Today CAP
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-TODAY',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Due today issue',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': todayStr,
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-01T00:00:00Z',
      },
    ];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: 'CAP-TODAY',
    );

    expect(find.text('Due today'), findsOneWidget);

    // 3. Due in 5 Days CAP
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-FUTURE',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Future issue',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': futureStr,
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-01T00:00:00Z',
      },
    ];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: 'CAP-FUTURE',
    );

    expect(find.text('5 days left'), findsOneWidget);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Responsible user can toggle action steps and updates timeline',
      (tester) async {
    const capId = 'CAP-TOGGLE';

    fakeDb.tables['caps'] = [
      {
        'id': capId,
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Action toggle test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];

    fakeDb.tables['cap_actions'] = [
      {
        'id': 'act-toggle-1',
        'cap_id': capId,
        'sequence': 1,
        'action_text': 'First actionable step',
        'is_done': 0,
      },
      {
        'id': 'act-toggle-2',
        'cap_id': capId,
        'sequence': 2,
        'action_text': 'Second actionable step',
        'is_done': 0,
      },
    ];

    fakeDb.tables['cap_log'] = [
      {
        'id': 'log-create',
        'cap_id': capId,
        'event': 'created',
        'actor_user_id': smUser.id,
        'timestamp': '2026-09-24T00:00:00Z',
      },
    ];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser), // smUser is responsible
      capId: capId,
    );

    expect(find.text('4. Action Steps (0/2)'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // Tap action 1 checkbox to toggle it complete
    final step1Finder = find.byKey(const ValueKey('action_step_1'));
    expect(step1Finder, findsOneWidget);

    final checkbox1Finder = find.descendant(
      of: step1Finder,
      matching: find.byType(Checkbox),
    );
    await tester.tap(checkbox1Finder);
    await tester.pumpAndSettle();

    // Verify it is now 1/2 complete (50%)
    expect(find.text('4. Action Steps (1/2)'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    // Verify database record updated
    final updatedAction = fakeDb.tables['cap_actions']!.firstWhere((a) => a['id'] == 'act-toggle-1');
    expect(updatedAction['is_done'], 1);

    // Verify cap_log row written
    final actionLogs = fakeDb.tables['cap_log']!.where((l) => l['event'] == 'action_done');
    expect(actionLogs.isNotEmpty, isTrue);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Non-responsible user cannot toggle action steps and sees explanation',
      (tester) async {
    const capId = 'CAP-RESTRICTED';

    fakeDb.tables['caps'] = [
      {
        'id': capId,
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Restricted toggle test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id, // smUser is responsible
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];

    fakeDb.tables['cap_actions'] = [
      {
        'id': 'act-res-1',
        'cap_id': capId,
        'sequence': 1,
        'action_text': 'Step not owned by viewer',
        'is_done': 0,
      },
    ];

    fakeDb.tables['cap_log'] = [];

    // Pump with otherSmUser (not responsible)
    await pumpCapDetail(
      tester,
      authState: const AuthState(user: otherSmUser),
      capId: capId,
    );

    // Verify guidance notice is displayed
    expect(
      find.text('Only the assigned responsible user can check off action steps.'),
      findsOneWidget,
    );

    // Checkbox is disabled (onChanged is null)
    final checkboxFinder = find.byType(Checkbox);
    final checkbox = tester.widget<Checkbox>(checkboxFinder);
    expect(checkbox.onChanged, isNull);

    // Database remains unchanged
    expect(fakeDb.tables['cap_actions']!.first['is_done'], 0);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Mark Done button enabled ONLY when all action steps are done and navigates to S17',
      (tester) async {
    const capId = 'CAP-MARK-DONE';

    fakeDb.tables['caps'] = [
      {
        'id': capId,
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Mark done test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];

    fakeDb.tables['cap_actions'] = [
      {
        'id': 'act-done-1',
        'cap_id': capId,
        'sequence': 1,
        'action_text': 'Action step 1',
        'is_done': 1,
      },
      {
        'id': 'act-done-2',
        'cap_id': capId,
        'sequence': 2,
        'action_text': 'Action step 2',
        'is_done': 0, // Incomplete!
      },
    ];

    fakeDb.tables['cap_log'] = [];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: capId,
    );

    // Button should be disabled because action 2 is incomplete
    final buttonFinder = find.byKey(const ValueKey('s16_mark_done_button'));
    expect(buttonFinder, findsOneWidget);
    final elevatedButton = tester.widget<ElevatedButton>(buttonFinder);
    expect(elevatedButton.onPressed, isNull);
    expect(
      find.text('Complete all action steps to enable Mark Done'),
      findsOneWidget,
    );

    // Mark step 2 complete in database and refresh
    fakeDb.tables['cap_actions']![1]['is_done'] = 1;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Now button should be enabled!
    final enabledButton = tester.widget<ElevatedButton>(buttonFinder);
    expect(enabledButton.onPressed, isNotNull);

    // Tap Mark CAP Done button -> navigates to S17 target
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Target S17 Mark Done: $capId'), findsOneWidget);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Phase 2: Open CAP has disabled Request Extension button',
      (tester) async {
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-P2-OPEN',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Phase 2 open test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'open',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];
    fakeDb.tables['cap_actions'] = [];
    fakeDb.tables['cap_log'] = [];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: 'CAP-P2-OPEN',
    );

    expect(find.text('Request Extension'), findsOneWidget);
    expect(find.text('Phase 2 (Coming Soon)'), findsOneWidget);
    final extButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('s16_request_extension_button')),
    );
    expect(extButton.onPressed, isNull);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Phase 2: Done CAP has disabled Verify CAP button for GM',
      (tester) async {
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-P2-DONE',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Phase 2 done test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'done',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];
    fakeDb.tables['cap_actions'] = [];
    fakeDb.tables['cap_log'] = [];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: gmUser),
      capId: 'CAP-P2-DONE',
    );

    expect(find.text('Verify CAP'), findsOneWidget);
    final verifyButton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('s16_verify_button')),
    );
    expect(verifyButton.onPressed, isNull);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Phase 2: Verified CAP has disabled Close CAP button for GM',
      (tester) async {
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-P2-VERIFIED',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Phase 2 verified test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'verified',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];
    fakeDb.tables['cap_actions'] = [];
    fakeDb.tables['cap_log'] = [];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: gmUser),
      capId: 'CAP-P2-VERIFIED',
    );

    expect(find.text('Close CAP'), findsOneWidget);
    final closeButton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('s16_close_button')),
    );
    expect(closeButton.onPressed, isNull);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Phase 2: Closed CAP has disabled Reopen CAP button for Owner',
      (tester) async {
    fakeDb.tables['caps'] = [
      {
        'id': 'CAP-P2-CLOSED',
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'problem_statement': 'Phase 2 closed test',
        'why_1': 'Why 1',
        'root_cause': 'Root cause',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'Inspection',
        'status': 'closed',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];
    fakeDb.tables['cap_actions'] = [];
    fakeDb.tables['cap_log'] = [];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: ownerUser),
      capId: 'CAP-P2-CLOSED',
    );

    expect(find.text('Reopen CAP'), findsOneWidget);
    final reopenButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('s16_reopen_button')),
    );
    expect(reopenButton.onPressed, isNull);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Non-existent CAP ID displays Not Found view',
      (tester) async {
    fakeDb.tables['caps'] = [];
    fakeDb.tables['cap_actions'] = [];
    fakeDb.tables['cap_log'] = [];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: 'CAP-UNKNOWN',
    );

    expect(find.text('CAP not found'), findsOneWidget);
    expect(find.text('Back to CAP List'), findsOneWidget);
  });

  testWidgets(
      'S16 CAP Detail Screen Tests (Spec §5 S16) Rule #8 Dual-Language Parity: Marathi locale renders localized UI',
      (tester) async {
    const capId = 'CAP-MARATHI';

    fakeDb.tables['caps'] = [
      {
        'id': capId,
        'origin_audit_id': 'audit-1',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 1,
        'problem_statement': 'मराठी चाचणी समस्या विधान',
        'why_1': 'पहिले कारण',
        'root_cause': 'मूळ कारण प्रणाली',
        'responsible_user_id': smUser.id,
        'deadline': '2026-10-01',
        'verification_method': 'पडताळणी पद्धत चाचणी',
        'status': 'open',
        'opened_at': '2026-09-24T00:00:00Z',
      },
    ];

    fakeDb.tables['cap_actions'] = [
      {
        'id': 'act-mr-1',
        'cap_id': capId,
        'sequence': 1,
        'action_text': 'पहिले कृती पाऊल',
        'is_done': 1,
        'done_at': '2026-09-24T00:00:00Z',
        'done_by': smUser.id,
      },
      {
        'id': 'act-mr-2',
        'cap_id': capId,
        'sequence': 2,
        'action_text': 'दुसरे कृती पाऊल',
        'is_done': 1,
        'done_at': '2026-09-24T00:00:00Z',
        'done_by': smUser.id,
      },
    ];

    fakeDb.tables['cap_log'] = [
      {
        'id': 'log-mr-1',
        'cap_id': capId,
        'event': 'created',
        'actor_user_id': smUser.id,
        'timestamp': '2026-09-24T00:00:00Z',
      },
    ];

    await pumpCapDetail(
      tester,
      authState: const AuthState(user: smUser),
      capId: capId,
      locale: const Locale('mr'),
    );

    // Verify Marathi section headings
    expect(find.text('१. मूळ माहिती'), findsOneWidget);
    expect(find.text('२. समस्या आणि ५-का? विश्लेषण'), findsOneWidget);
    expect(find.text('३. मालकी आणि पडताळणी'), findsOneWidget);
    expect(find.textContaining('४. कृती पावले'), findsOneWidget);
    expect(find.text('५. घटना टाइमलाइन'), findsOneWidget);

    // Verify Marathi badge and button labels
    expect(find.text('उघडे'), findsOneWidget);
    expect(find.text('वारंवार समस्या (पॅटर्न)'), findsOneWidget);
    expect(find.text('CAP पूर्ण म्हणून खूण करा'), findsOneWidget);
    expect(find.text('CAP तयार केली'), findsOneWidget);
    expect(find.text('का? 1'), findsOneWidget);
    expect(find.text('मूळ कारण'), findsOneWidget);
  });
}
