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
import 'package:saagar_audit_app/ui/screens/s30_change_pin/change_pin_screen.dart';

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

Widget createChangePinTestWidget({
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
      home: const ChangePinScreen(),
    ),
  );
}

Future<void> pumpChangePin(
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
    createChangePinTestWidget(authState: authState, locale: locale),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S30 Change PIN Screen Tests (Spec §S30 & Sprint Plan)', () {
    late FakeDatabase fakeDb;

    const testUser = AuthUser(
      id: 'sm-user-001',
      name: 'Sunil SM',
      role: 'SM',
      languagePref: 'en',
    );

    const loggedInAuth = AuthState(user: testUser);

    // Initial PIN is '1234'
    final initialPinHash = hashPin('1234');

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      fakeDb.tables['users']!.add({
        'id': 'sm-user-001',
        'name': 'Sunil SM',
        'role': 'SM',
        'pin_hash': initialPinHash,
        'language_pref': 'en',
        'phone': '9876543210',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Renders all 3 PIN fields and the update button', (tester) async {
      await pumpChangePin(tester, authState: loggedInAuth);

      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('Sunil SM'), findsOneWidget);
      expect(find.text('Current 4-Digit PIN'), findsOneWidget);
      expect(find.text('New 4-Digit PIN'), findsOneWidget);
      expect(find.text('Confirm New 4-Digit PIN'), findsOneWidget);
      expect(find.text('Update PIN'), findsOneWidget);
    });

    testWidgets('Validates 4-digit PIN requirement on submit', (tester) async {
      await pumpChangePin(tester, authState: loggedInAuth);

      // Tap submit with empty fields
      await tester.tap(find.text('Update PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your current 4-digit PIN'), findsOneWidget);
      expect(find.text('Please enter a 4-digit numeric PIN'), findsOneWidget);
    });

    testWidgets('Validates that new PIN must differ from current PIN', (tester) async {
      await pumpChangePin(tester, authState: loggedInAuth);

      final fields = find.byType(TextFormField);
      // Enter '1234' in both current and new PIN
      await tester.enterText(fields.at(0), '1234');
      await tester.enterText(fields.at(1), '1234');
      await tester.enterText(fields.at(2), '1234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update PIN'));
      await tester.pumpAndSettle();

      expect(
        find.text('New PIN must be different from current PIN'),
        findsOneWidget,
      );
    });

    testWidgets('Validates matching confirmation PIN', (tester) async {
      await pumpChangePin(tester, authState: loggedInAuth);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '1234');
      await tester.enterText(fields.at(1), '5678');
      await tester.enterText(fields.at(2), '9999');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update PIN'));
      await tester.pumpAndSettle();

      expect(find.text('New PIN and confirmation do not match'), findsOneWidget);
    });

    testWidgets('Verifies current PIN with BCrypt: rejects incorrect current PIN', (tester) async {
      await pumpChangePin(tester, authState: loggedInAuth);

      final fields = find.byType(TextFormField);
      // Actual PIN is 1234, enter 9999 as current
      await tester.enterText(fields.at(0), '9999');
      await tester.enterText(fields.at(1), '5678');
      await tester.enterText(fields.at(2), '5678');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Current PIN is incorrect'), findsOneWidget);

      // Verify DB was NOT updated
      final user = await UserRepository.instance.getById('sm-user-001');
      expect(user!.pinHash, initialPinHash);
      expect(BCrypt.checkpw('1234', user.pinHash), isTrue);
      expect(BCrypt.checkpw('5678', user.pinHash), isFalse);
    });

    testWidgets('Successfully changes PIN and updates bcrypt hash in database', (tester) async {
      await pumpChangePin(tester, authState: loggedInAuth);

      final fields = find.byType(TextFormField);
      // Correct current PIN '1234', new PIN '7890'
      await tester.enterText(fields.at(0), '1234');
      await tester.enterText(fields.at(1), '7890');
      await tester.enterText(fields.at(2), '7890');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN changed successfully'), findsOneWidget);

      // Verify DB hash is updated and bcrypt checks against '7890'
      final user = await UserRepository.instance.getById('sm-user-001');
      expect(user!.pinHash, isNot(initialPinHash));
      expect(user.pinHash.startsWith(r'$2a$'), isTrue);
      expect(BCrypt.checkpw('7890', user.pinHash), isTrue);
      expect(BCrypt.checkpw('1234', user.pinHash), isFalse);
    });

    testWidgets('Unauthenticated user cannot access screen', (tester) async {
      await pumpChangePin(tester, authState: const AuthState());

      // Screen contents should not render
      expect(find.text('Current 4-Digit PIN'), findsNothing);
      expect(find.text('Update PIN'), findsNothing);
    });

    testWidgets('Renders all elements in Marathi with full localized parity (Rule #8)', (tester) async {
      await pumpChangePin(
        tester,
        authState: loggedInAuth,
        locale: const Locale('mr'),
      );

      expect(find.text('PIN बदला'), findsOneWidget);
      expect(find.text('सध्याचा ४-अंकी PIN'), findsOneWidget);
      expect(find.text('नवीन ४-अंकी PIN'), findsOneWidget);
      expect(find.text('नवीन ४-अंकी PIN ची पुष्टी करा'), findsOneWidget);
      expect(find.text('PIN अपडेट करा'), findsOneWidget);
    });
  });
}
