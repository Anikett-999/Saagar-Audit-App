import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s15_cap_create/cap_create_screen.dart';
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

Widget createCapCreateTestWidget({
  required AuthState authState,
  Locale locale = const Locale('en'),
  String? originAuditId,
  String? originCheckpointId,
  String? originResultId,
  String? initialProblemStatement,
}) {
  final router = GoRouter(
    initialLocation: '/caps/new',
    routes: [
      GoRoute(
        path: '/caps/new',
        name: 's15_cap_create',
        builder: (_, __) => CapCreateScreen(
          originAuditId: originAuditId,
          originCheckpointId: originCheckpointId,
          originResultId: originResultId,
          initialProblemStatement: initialProblemStatement,
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

Future<void> pumpCapCreate(
  WidgetTester tester, {
  required AuthState authState,
  Locale locale = const Locale('en'),
  String? originAuditId,
  String? originCheckpointId,
  String? originResultId,
  String? initialProblemStatement,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    createCapCreateTestWidget(
      authState: authState,
      locale: locale,
      originAuditId: originAuditId,
      originCheckpointId: originCheckpointId,
      originResultId: originResultId,
      initialProblemStatement: initialProblemStatement,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S15 CAP Create Screen Tests (Workbook Appx A.3 & Spec §5 S15)', () {
    late FakeDatabase fakeDb;

    const smUser = AuthUser(
      id: 'user-sm',
      name: 'Sunil SM',
      role: 'SM',
      languagePref: 'en',
    );

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed users table with SM, GM, and OWNER
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

      // Seed checkpoints table
      fakeDb.tables['checkpoints']!.addAll([
        {
          'id': '1.1',
          'sop_id': 'sop-1',
          'frequency': 'daily',
          'sequence': 1,
          'text_en': 'Store entrance glass clean',
          'text_mr': 'प्रवेशद्वाराची काच स्वच्छ',
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
          'text_en': 'Floor tiles swept and mopped',
          'text_mr': 'फरशी झाडलेली आणि पुसलेली',
          'weight': 1,
          'allows_na': 0,
          'requires_photo_on_fail': 1,
          'display_order': 2,
        },
      ]);

      // Seed audits table
      fakeDb.tables['audits']!.add({
        'id': 'audit-101',
        'audit_type': 'daily',
        'store_id': 'WLMHW',
        'auditor_id': 'user-sm',
        'status': 'submitted',
        'audit_date': '2026-09-21',
        'week_number': 38,
        'year': 2026,
        'device_id': 'dev-1',
        'submitted_at': '2026-09-21T18:00:00.000Z',
      });
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Renders 10-field template including auto-generated CAP ID preview', (tester) async {
      await pumpCapCreate(tester, authState: const AuthState(user: smUser));

      // Title & Subtitle
      expect(find.text('New Corrective Action Plan'), findsOneWidget);
      expect(find.text('10-field root cause & action template'), findsOneWidget);

      // 1. CAP ID preview
      expect(find.text('CAP ID (Auto-Generated)'), findsOneWidget);
      expect(find.textContaining('CAP-'), findsWidgets);

      // 2. Origin section
      expect(find.text('1. Originating Finding'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_checkpoint_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_audit_dropdown')), findsOneWidget);

      // 3 & 4 & 5. Problem & 5-Whys section
      expect(find.text('2. Problem & 5-Whys Analysis'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_problem_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_why1_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_why2_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_why3_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_why4_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_why5_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_root_cause_field')), findsOneWidget);

      // 6. Action steps (initial 3)
      expect(find.text('3. Action Steps (3 to 5 steps)'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_step_field_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_step_field_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_step_field_2')), findsOneWidget);

      // 7, 8, 9. Ownership & Verification
      expect(find.text('4. Ownership & Verification'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_responsible_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_deadline_picker')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_verification_field')), findsOneWidget);

      // 10. Create button
      expect(find.byKey(const ValueKey('s15_create_button')), findsOneWidget);
    });

    testWidgets('Pre-fills origin fields when launched with extras', (tester) async {
      await pumpCapCreate(
        tester,
        authState: const AuthState(user: smUser),
        originAuditId: 'audit-101',
        originCheckpointId: '1.2',
        initialProblemStatement: 'Floor dirty with dust and footprints',
      );

      final problemField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('s15_problem_field')),
      );
      expect(problemField.controller?.text, 'Floor dirty with dust and footprints');
    });

    testWidgets('Form validation blocks submission when required fields are empty', (tester) async {
      await pumpCapCreate(tester, authState: const AuthState(user: smUser));

      // Tap submit with empty inputs
      await tester.tap(find.byKey(const ValueKey('s15_create_button')));
      await tester.pumpAndSettle();

      expect(find.text('Problem statement is required'), findsOneWidget);
      expect(find.text('Why 1 is required'), findsOneWidget);
      expect(find.text('Root cause is required'), findsOneWidget);
    });

    testWidgets('Dynamic action steps enforce 3 to 5 bounded rows', (tester) async {
      await pumpCapCreate(tester, authState: const AuthState(user: smUser));

      // Initially 3 steps: remove buttons are hidden / not present
      expect(find.byKey(const ValueKey('s15_remove_step_0')), findsNothing);
      expect(find.byKey(const ValueKey('s15_remove_step_1')), findsNothing);
      expect(find.byKey(const ValueKey('s15_remove_step_2')), findsNothing);
      expect(find.text('3/5'), findsOneWidget);

      // Add Step 4
      await tester.tap(find.byKey(const ValueKey('s15_add_step_button')));
      await tester.pumpAndSettle();

      expect(find.text('4/5'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_step_field_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_remove_step_3')), findsOneWidget);

      // Add Step 5
      await tester.tap(find.byKey(const ValueKey('s15_add_step_button')));
      await tester.pumpAndSettle();

      expect(find.text('5/5'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_step_field_4')), findsOneWidget);
      // At 5 steps, Add Step button is hidden/disabled
      expect(find.byKey(const ValueKey('s15_add_step_button')), findsNothing);

      // Remove Step 5
      await tester.tap(find.byKey(const ValueKey('s15_remove_step_4')));
      await tester.pumpAndSettle();

      expect(find.text('4/5'), findsOneWidget);
      expect(find.byKey(const ValueKey('s15_step_field_4')), findsNothing);
      expect(find.byKey(const ValueKey('s15_add_step_button')), findsOneWidget);
    });

    testWidgets('Empty action step blocks submission', (tester) async {
      await pumpCapCreate(tester, authState: const AuthState(user: smUser));

      // Fill problem statement, why1, root cause
      await tester.enterText(
        find.byKey(const ValueKey('s15_problem_field')),
        'Counter dirty',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_why1_field')),
        'Staff absent',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_root_cause_field')),
        'No roster backup',
      );

      // Leave step 0, 1, 2 empty and submit
      await tester.tap(find.byKey(const ValueKey('s15_create_button')));
      await tester.pumpAndSettle();

      expect(find.text('Action step cannot be empty'), findsWidgets);
    });

    testWidgets('Successful creation writes cap, actions, and cap_log atomically, then navigates to S16', (tester) async {
      await pumpCapCreate(tester, authState: const AuthState(user: smUser));

      // Fill in all required fields
      await tester.enterText(
        find.byKey(const ValueKey('s15_problem_field')),
        'Display counter glass smeared with fingerprints',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_why1_field')),
        'Morning cleaning was rushed',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_why2_field')),
        'Cleaner arrived late due to rain',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_root_cause_field')),
        'No backup opening checklist verification done before opening shutter',
      );

      // Fill 3 action steps
      await tester.enterText(
        find.byKey(const ValueKey('s15_step_field_0')),
        'Wipe down all glass counters with Colin spray immediately',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_step_field_1')),
        'Institute counter inspection before store opening each morning',
      );
      await tester.enterText(
        find.byKey(const ValueKey('s15_step_field_2')),
        'Review cleanliness checklist during evening muster',
      );

      // Submit
      await tester.ensureVisible(find.byKey(const ValueKey('s15_create_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('s15_create_button')));
      await tester.pumpAndSettle();

      // Verify Database state
      expect(fakeDb.tables['caps']!.length, 1);
      final cap = fakeDb.tables['caps']!.first;
      expect(cap['status'], 'open');
      expect(cap['problem_statement'], 'Display counter glass smeared with fingerprints');
      expect(cap['why_1'], 'Morning cleaning was rushed');
      expect(cap['why_2'], 'Cleaner arrived late due to rain');
      expect(cap['root_cause'], 'No backup opening checklist verification done before opening shutter');

      // Verify 3 cap_actions created
      expect(fakeDb.tables['cap_actions']!.length, 3);
      expect(fakeDb.tables['cap_actions']![0]['action_text'], 'Wipe down all glass counters with Colin spray immediately');
      expect(fakeDb.tables['cap_actions']![0]['sequence'], 1);
      expect(fakeDb.tables['cap_actions']![0]['is_done'], 0);

      // Verify cap_log created
      expect(fakeDb.tables['cap_log']!.length, 1);
      expect(fakeDb.tables['cap_log']!.first['event'], 'created');
      expect(fakeDb.tables['cap_log']!.first['to_status'], 'open');

      // Verify navigation to S16 Detail
      expect(find.text('Target S16 Detail: ${cap['id']}'), findsOneWidget);
    });

    testWidgets('Rule #8 Dual-Language Parity: Marathi locale renders localized UI', (tester) async {
      await pumpCapCreate(
        tester,
        authState: const AuthState(user: smUser),
        locale: const Locale('mr'),
      );

      // Title & Subtitle in Marathi
      expect(find.text('नवीन सुधारात्मक कृती योजना'), findsOneWidget);
      expect(find.text('१०-फील्ड मूळ कारण आणि कृती टेम्पलेट'), findsOneWidget);

      // Section titles in Marathi
      expect(find.text('१. मूळ निष्कर्ष'), findsOneWidget);
      expect(find.text('२. समस्या आणि ५-का? विश्लेषण'), findsOneWidget);
      expect(find.text('३. कृती पावले (३ ते ५ पावले)'), findsOneWidget);
      expect(find.text('४. मालकी आणि पडताळणी'), findsOneWidget);

      // Labels in Marathi
      expect(find.text('का? १ (प्राथमिक कारण)'), findsOneWidget);
      expect(find.text('मूळ कारण'), findsOneWidget);
      expect(find.text('CAP तयार करा'), findsOneWidget);
      expect(find.text('पाऊल जोडा'), findsOneWidget);
    });
  });
}
