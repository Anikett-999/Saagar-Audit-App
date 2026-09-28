import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/cap/s18_cap_verify_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

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

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createVerifyTestWidget({
  required AuthState authState,
  required String capId,
  Locale locale = const Locale('en'),
  Future<String?> Function()? onPickPhoto,
}) {
  final router = GoRouter(
    initialLocation: '/caps/$capId/verify',
    routes: [
      GoRoute(
        path: '/caps/:id/verify',
        name: 's18_cap_verify',
        builder: (context, state) => S18CapVerifyScreen(
          capId: state.pathParameters['id']!,
          onPickPhoto: onPickPhoto,
        ),
      ),
      GoRoute(
        path: '/caps/:id',
        name: 's16_cap_detail',
        builder: (_, __) => const Scaffold(body: Center(child: Text('Target S16 Detail'))),
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

Future<void> pumpVerify(
  WidgetTester tester, {
  required AuthState authState,
  required String capId,
  Locale locale = const Locale('en'),
  Future<String?> Function()? onPickPhoto,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    createVerifyTestWidget(
      authState: authState,
      capId: capId,
      locale: locale,
      onPickPhoto: onPickPhoto,
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

  const smUser = AuthUser(
    id: 'user-sm-1',
    name: 'Store Manager',
    role: 'SM',
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
      {
        'id': smUser.id,
        'name': smUser.name,
        'role': 'SM',
        'pin_hash': 'hash_sm',
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
      {
        'id': '1.2',
        'sop_id': 'sop-1',
        'frequency': 'daily',
        'sequence': 2,
        'text_en': 'Fire Extinguisher Gauge',
        'text_mr': 'अग्निशामक गेज',
        'weight': 2,
        'allows_na': 0,
        'requires_photo_on_fail': 1,
        'display_order': 2,
      },
    ];

    fakeDb.tables['audits'] = [
      {
        'id': 'audit-1',
        'audit_type': 'daily',
        'audit_date': '2026-09-24',
        'week_number': 39,
        'year': 2026,
        'auditor_id': smUser.id,
        'device_id': 'device-test',
        'status': 'submitted',
        'submitted_at': '2026-09-24T18:00:00Z',
      },
    ];
  });

  group('Screen S18 — CAP Verify Tests (Spec §5 S18 & Plan §5.2)', () {
    testWidgets('1. Renders header, problem statement, origin checkpoint, and verification method hero card', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-01',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Floor is stained with grease',
          'why_1': 'Mop was greasy',
          'root_cause': 'Degreaser solution missing',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'Re-inspect floor with white cloth test',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'is_pattern': 1,
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: gmUser),
        capId: 'CAP-V-01',
      );

      expect(find.text('Verify CAP'), findsOneWidget);
      expect(find.text('CAP-V-01'), findsOneWidget);
      expect(find.text('Pattern Issue'), findsOneWidget);
      expect(find.text('Floor is stained with grease'), findsOneWidget);
      expect(find.text('Re-inspect floor with white cloth test'), findsOneWidget);
      expect(find.text('Does the corrective action pass verification?'), findsOneWidget);
      expect(find.text('Pass & Verify'), findsOneWidget);
      expect(find.text('Verification Failed'), findsOneWidget);
    });

    testWidgets('2. Photo gate: requires_photo_on_fail=1 shows REQUIRED badge, blocks Pass & Verify until photo attached', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-02',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.2', // CP 1.2 requires photo on fail
          'problem_statement': 'Fire extinguisher expired',
          'why_1': 'Vendor delayed',
          'root_cause': 'Contract renewal lapse',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'Inspect certified tag and pressure gauge',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'is_pattern': 0,
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: gmUser),
        capId: 'CAP-V-02',
        onPickPhoto: () async => '/mock/test/verify_gauge.jpg',
      );

      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Mandatory photo evidence is required to verify this checkpoint.'), findsOneWidget);

      // Button is disabled when no photo is attached
      final passButton = tester.widget<ElevatedButton>(find.byKey(const ValueKey('s18_pass_verify_button')));
      expect(passButton.onPressed, isNull);

      // Tap take photo button
      await tester.tap(find.byKey(const ValueKey('s18_take_photo_button')));
      await tester.pumpAndSettle();

      // Photo is now attached
      expect(find.text('Verification photo attached'), findsOneWidget);

      // Button is now enabled!
      final enabledPassButton = tester.widget<ElevatedButton>(find.byKey(const ValueKey('s18_pass_verify_button')));
      expect(enabledPassButton.onPressed, isNotNull);

      // Tap Pass & Verify
      await tester.tap(find.byKey(const ValueKey('s18_pass_verify_button')));
      await tester.pumpAndSettle();

      // CAP row in fakeDb must now be 'verified'
      final updated = fakeDb.tables['caps']!.firstWhere((c) => c['id'] == 'CAP-V-02');
      expect(updated['status'], equals('verified'));
      expect(updated['verified_by'], equals(gmUser.id));

      // Photos row created with context='cap_verification'
      final photos = fakeDb.tables['photos']!.where((p) => p['cap_id'] == 'CAP-V-02').toList();
      expect(photos.length, equals(1));
      expect(photos.first['context'], equals('cap_verification'));
      expect(photos.first['local_path'], equals('/mock/test/verify_gauge.jpg'));
    });

    testWidgets('3. Checkpoint without photo requirement has Pass & Verify enabled immediately', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-03',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1', // CP 1.1 does NOT require photo on fail
          'problem_statement': 'Floor dirty',
          'why_1': 'Mop dirty',
          'root_cause': 'No mop head replacements',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'Inspect floor',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'is_pattern': 0,
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: gmUser),
        capId: 'CAP-V-03',
      );

      expect(find.text('REQUIRED'), findsNothing);
      final passButton = tester.widget<ElevatedButton>(find.byKey(const ValueKey('s18_pass_verify_button')));
      expect(passButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('s18_pass_verify_button')));
      await tester.pumpAndSettle();

      final updated = fakeDb.tables['caps']!.firstWhere((c) => c['id'] == 'CAP-V-03');
      expect(updated['status'], equals('verified'));
    });

    testWidgets('4. Verification Failed button opens choice dialog to Extend or Reopen at Plan', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-04',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Floor dirty',
          'why_1': 'Mop dirty',
          'root_cause': 'No spares',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'Inspect floor',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'extension_count': 0,
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: gmUser),
        capId: 'CAP-V-04',
      );

      // Tap Verification Failed
      await tester.tap(find.byKey(const ValueKey('s18_fail_verify_button')));
      await tester.pumpAndSettle();

      // Dialog opens with Extend and Reopen options
      expect(find.text('Verification Failed'), findsWidgets);
      expect(find.byKey(const ValueKey('s18_fail_extend_choice')), findsOneWidget);
      expect(find.byKey(const ValueKey('s18_fail_reopen_choice')), findsOneWidget);

      // Choose Extend
      await tester.tap(find.byKey(const ValueKey('s18_fail_extend_choice')));
      await tester.pumpAndSettle();

      expect(find.text('Extend CAP Deadline'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('s18_extend_reason_input')), 'Additional cleaning crew needed');
      await tester.tap(find.byKey(const ValueKey('s18_confirm_extend_button')));
      await tester.pumpAndSettle();

      // CAP updated with extension
      final updated = fakeDb.tables['caps']!.firstWhere((c) => c['id'] == 'CAP-V-04');
      expect(updated['extension_count'], equals(1));
      expect(updated['latest_extension_reason'], equals('Additional cleaning crew needed'));
      expect(updated['status'], equals('done')); // stays done per plan §5.1
    });

    testWidgets('5. Role Guard: SM user sees Access Denied and cannot verify', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-05',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Test',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'm',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: smUser),
        capId: 'CAP-V-05',
      );

      expect(find.text('Access Denied. Only GM and Owner may verify CAPs.'), findsOneWidget);
      expect(find.byKey(const ValueKey('s18_pass_verify_button')), findsNothing);
    });

    testWidgets('6. Dual-Language Parity (Rule #8): Marathi locale renders authentic Marathi strings', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-06',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'Floor dirty',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'पडताळणी पद्धत तपशील',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
          'is_pattern': 1,
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: gmUser),
        capId: 'CAP-V-06',
        locale: const Locale('mr'),
      );

      expect(find.text('CAP पडताळणी'), findsOneWidget);
      expect(find.text('वारंवार आढळलेली समस्या'), findsOneWidget);
      expect(find.text('उत्तीर्ण व पडताळा'), findsOneWidget);
      expect(find.text('पडताळणी अयशस्वी'), findsOneWidget);
      expect(find.text('सुधारात्मक कृती पडताळणीत उत्तीर्ण झाली आहे का?'), findsOneWidget);
    });

    testWidgets('7. Dual-Language Parity: Marathi Access Denied view and Back button', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-07',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.2',
          'problem_statement': 'Fire extinguisher expired',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'm',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: smUser),
        capId: 'CAP-V-07',
        locale: const Locale('mr'),
      );
      expect(find.text('प्रवेश नाकारला. केवळ GM आणि मालकच CAP पडताळणी करू शकतात.'), findsOneWidget);
      expect(find.text('मागे'), findsOneWidget);
    });

    testWidgets('8. Dual-Language Parity: Marathi REQUIRED badge on mandatory photo gate', (tester) async {
      fakeDb.tables['caps'] = [
        {
          'id': 'CAP-V-08',
          'origin_audit_id': 'audit-1',
          'origin_checkpoint_id': '1.2', // CP 1.2 requires photo on fail
          'problem_statement': 'Fire extinguisher expired',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': smUser.id,
          'deadline': '2026-10-01',
          'verification_method': 'm',
          'status': 'done',
          'opened_at': '2026-09-20T10:00:00Z',
        },
      ];

      await pumpVerify(
        tester,
        authState: const AuthState(user: gmUser),
        capId: 'CAP-V-08',
        locale: const Locale('mr'),
      );
      expect(find.text('आवश्यक'), findsOneWidget);
    });
  });
}
