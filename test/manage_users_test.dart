import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/user_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s29_manage_users/manage_users_screen.dart';

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

Widget createManageUsersTestWidget({
  required AuthState authState,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      localeProvider.overrideWith((ref) => FakeLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ManageUsersScreen(),
    ),
  );
}

Future<void> pumpManageUsers(
  WidgetTester tester, {
  required AuthState authState,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    createManageUsersTestWidget(authState: authState, locale: locale),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S29 Manage Users Screen Tests (Spec §S29 & Sprint Plan)', () {
    late FakeDatabase fakeDb;

    const ownerAuth = AuthState(
      user: AuthUser(
        id: 'owner-uuid-001',
        name: 'Aniket Owner',
        role: 'OWNER',
        languagePref: 'en',
      ),
    );

    const smAuth = AuthState(
      user: AuthUser(
        id: 'sm-uuid-001',
        name: 'Store Manager',
        role: 'SM',
        languagePref: 'en',
      ),
    );

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Shows empty state when no users exist in database', (tester) async {
      await pumpManageUsers(tester, authState: ownerAuth);

      expect(find.text('Manage Users'), findsOneWidget);
      expect(find.text('No users found.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Lists users with role badges (Owner, GM, SM) and status chips', (tester) async {
      fakeDb.tables['users']!.addAll([
        {
          'id': 'user-1',
          'name': 'Aniket Owner',
          'role': 'OWNER',
          'pin_hash': r'$2a$10$dummyHash1',
          'language_pref': 'en',
          'phone': '9876543210',
          'is_active': 1,
          'created_at': '2026-09-01T08:00:00.000Z',
        },
        {
          'id': 'user-2',
          'name': 'Vikram GM',
          'role': 'GM',
          'pin_hash': r'$2a$10$dummyHash2',
          'language_pref': 'en',
          'phone': '9876543211',
          'is_active': 1,
          'created_at': '2026-09-01T08:00:00.000Z',
        },
        {
          'id': 'user-3',
          'name': 'Sunil SM',
          'role': 'SM',
          'pin_hash': r'$2a$10$dummyHash3',
          'language_pref': 'en',
          'phone': '9876543212',
          'is_active': 0,
          'created_at': '2026-09-01T08:00:00.000Z',
        },
      ]);

      await pumpManageUsers(tester, authState: ownerAuth);

      // Verify names
      expect(find.text('Aniket Owner'), findsOneWidget);
      expect(find.text('Vikram GM'), findsOneWidget);
      expect(find.text('Sunil SM'), findsOneWidget);

      // Verify role badges (Owner uses s27OwnerBadge = 'Owner')
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('General Manager (GM)'), findsOneWidget);
      expect(find.text('Store Manager (SM)'), findsOneWidget);

      // Verify status chips
      expect(find.text('Active'), findsNWidgets(2));
      expect(find.text('Inactive'), findsOneWidget);

      // Inactive user Sunil SM shows Reactivate action
      expect(find.text('Reactivate'), findsOneWidget);
    });

    testWidgets('Add User dialog allows SM or GM only, hashes PIN, and saves to database', (tester) async {
      await pumpManageUsers(tester, authState: ownerAuth);

      // Tap FAB "+ Add User"
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add User'), findsWidgets);
      expect(find.text('Store Manager (SM)'), findsOneWidget);
      expect(find.text('General Manager (GM)'), findsOneWidget);
      // Guardrail: OWNER is NEVER offered as an option in the add user dialog
      expect(find.text('OWNER'), findsNothing);

      // Try saving empty -> validates name and PIN
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please enter a valid name (2–50 characters)'),
        findsOneWidget,
      );

      // Fill in Name
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Rajesh Shinde');

      // Select GM role
      await tester.tap(find.text('General Manager (GM)'));
      await tester.pumpAndSettle();

      // Enter phone
      await tester.enterText(textFields.at(1), '9812345678');

      // Enter mismatched PINs
      await tester.enterText(textFields.at(2), '4321');
      await tester.enterText(textFields.at(3), '9999');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('PINs do not match'), findsOneWidget);

      // Enter matching 4-digit PIN
      await tester.enterText(textFields.at(3), '4321');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify user appears on screen
      expect(find.text('Rajesh Shinde'), findsOneWidget);
      expect(find.text('General Manager (GM)'), findsOneWidget);
      expect(find.text('9812345678'), findsOneWidget);

      // Verify in database: PIN must be bcrypt-hashed, NOT plaintext
      final usersInDb = await UserRepository.instance.listAll();
      final added = usersInDb.firstWhere((u) => u.name == 'Rajesh Shinde');
      expect(added.role, 'GM');
      expect(added.phone, '9812345678');
      expect(added.isActive, isTrue);
      expect(added.pinHash, isNot('4321'));
      expect(added.pinHash.startsWith(r'$2a$'), isTrue);
      expect(BCrypt.checkpw('4321', added.pinHash), isTrue);
    });

    testWidgets('Deactivating Owner row is blocked in UI with notification', (tester) async {
      fakeDb.tables['users']!.add({
        'id': 'owner-uuid-001',
        'name': 'Aniket Owner',
        'role': 'OWNER',
        'pin_hash': r'$2a$10$dummyHash1',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageUsers(tester, authState: ownerAuth);

      // Tap Deactivate on Owner row
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      // Friendly snackbar notice appears; no confirmation dialog was shown
      expect(
        find.text('The Owner account cannot be deactivated per Spec §S29.'),
        findsOneWidget,
      );
      expect(find.text('Deactivate User?'), findsNothing);

      // Owner remains active in database
      final ownerInDb = await UserRepository.instance.getById('owner-uuid-001');
      expect(ownerInDb!.isActive, isTrue);
    });

    testWidgets('Deactivating SM user performs soft-deactivation preserving history', (tester) async {
      fakeDb.tables['users']!.add({
        'id': 'sm-1',
        'name': 'Kavita SM',
        'role': 'SM',
        'pin_hash': r'$2a$10$dummyHashSm',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageUsers(tester, authState: ownerAuth);

      expect(find.text('Active'), findsOneWidget);

      // Tap Deactivate
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      // Dialog opens explaining audit trail integrity
      expect(find.text('Deactivate User?'), findsOneWidget);
      expect(
        find.textContaining('all historical audit records remain untouched'),
        findsOneWidget,
      );

      // Tap Cancel -> remains active
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);

      // Tap Deactivate again and confirm
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
      await tester.pumpAndSettle();

      // Status changes to Inactive and Reactivate button appears
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Reactivate'), findsOneWidget);

      // Verify in DB: soft-deleted (is_active = 0), never removed
      final userInDb = await UserRepository.instance.getById('sm-1');
      expect(userInDb, isNotNull);
      expect(userInDb!.isActive, isFalse);
    });

    testWidgets('Reactivate button restores inactive user to active', (tester) async {
      fakeDb.tables['users']!.add({
        'id': 'sm-deact',
        'name': 'Deepak SM',
        'role': 'SM',
        'pin_hash': r'$2a$10$dummyHashSm',
        'language_pref': 'en',
        'is_active': 0,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageUsers(tester, authState: ownerAuth);

      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Reactivate'), findsOneWidget);

      await tester.tap(find.text('Reactivate'));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);

      final userInDb = await UserRepository.instance.getById('sm-deact');
      expect(userInDb!.isActive, isTrue);
    });

    testWidgets('Reset PIN dialog updates bcrypt hash in repository', (tester) async {
      fakeDb.tables['users']!.add({
        'id': 'sm-pin-test',
        'name': 'Prakash SM',
        'role': 'SM',
        'pin_hash': r'$2a$10$oldHash1234567890123456789012345678901234567890123456',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageUsers(tester, authState: ownerAuth);

      // Tap Reset PIN
      await tester.tap(find.text('Reset PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Reset PIN for Prakash SM'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      // Try invalid PIN
      await tester.enterText(textFields.at(0), '12');
      await tester.enterText(textFields.at(1), '12');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a 4-digit numeric PIN'), findsOneWidget);

      // Enter valid new PIN '8899'
      await tester.enterText(textFields.at(0), '8899');
      await tester.enterText(textFields.at(1), '8899');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('PIN reset successfully'), findsOneWidget);

      // Verify database updated with bcrypt hash of '8899'
      final userInDb = await UserRepository.instance.getById('sm-pin-test');
      expect(userInDb!.pinHash, isNot(r'$2a$10$oldHash1234567890123456789012345678901234567890123456'));
      expect(BCrypt.checkpw('8899', userInDb.pinHash), isTrue);
    });

    testWidgets('Non-Owner user role is blocked by route guard', (tester) async {
      // Pass SM user instead of OWNER
      await pumpManageUsers(tester, authState: smAuth);

      // Screen contents (Manage Users AppBar) should not render
      expect(find.text('Manage Users'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Renders in Marathi locale without missing key errors', (tester) async {
      fakeDb.tables['users']!.add({
        'id': 'user-mr',
        'name': 'गणेश शिंदे',
        'role': 'SM',
        'pin_hash': r'$2a$10$dummyHash',
        'language_pref': 'mr',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageUsers(
        tester,
        authState: ownerAuth,
        locale: const Locale('mr'),
      );

      // Verify Marathi localized title and badges
      expect(find.text('वापरकर्ता व्यवस्थापन'), findsOneWidget);
      expect(find.text('गणेश शिंदे'), findsOneWidget);
      expect(find.text('स्टोअर व्यवस्थापक (SM)'), findsOneWidget);
      expect(find.text('सक्रिय'), findsOneWidget);
      expect(find.text('PIN रीसेट करा'), findsOneWidget);
      expect(find.text('निष्क्रिय करा'), findsOneWidget);
    });
  });
}
