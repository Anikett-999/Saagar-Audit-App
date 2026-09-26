import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/user_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s04_login/login_screen.dart';
import 'package:saagar_audit_app/ui/screens/s31_language/settings_language_screen.dart';
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
  void updateUserLanguagePref(String languagePref) {
    if (state.user != null) {
      state = state.copyWith(
        user: AuthUser(
          id: state.user!.id,
          name: state.user!.name,
          role: state.user!.role,
          languagePref: languagePref,
        ),
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createSettingsLanguageTestWidget({
  required AuthState authState,
  required LocaleNotifier localeNotifier,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      localeProvider.overrideWith((ref) => localeNotifier),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final currentLocale = ref.watch(localeProvider) ?? const Locale('en');
        return MaterialApp(
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsLanguageScreen(),
        );
      },
    ),
  );
}

Future<void> pumpSettingsLanguage(
  WidgetTester tester, {
  required AuthState authState,
  required LocaleNotifier localeNotifier,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    createSettingsLanguageTestWidget(
      authState: authState,
      localeNotifier: localeNotifier,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S31 Settings Language Screen Tests (Spec §S31 & Sprint Plan)', () {
    late FakeDatabase fakeDb;

    const testUser = AuthUser(
      id: 'owner-uuid-001',
      name: 'Aniket Owner',
      role: 'OWNER',
      languagePref: 'en',
    );

    const loggedInAuth = AuthState(user: testUser);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      fakeDb.tables['users']!.add({
        'id': 'owner-uuid-001',
        'name': 'Aniket Owner',
        'role': 'OWNER',
        'pin_hash': r'$2a$10$dummyHashOwner',
        'language_pref': 'en',
        'phone': '9876543210',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Renders language options with current selection indicator', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpSettingsLanguage(
        tester,
        authState: loggedInAuth,
        localeNotifier: localeNotifier,
      );

      expect(find.text('Language / भाषा'), findsOneWidget);
      expect(find.text('Choose your preferred app language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('मराठी (Marathi)'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
    });

    testWidgets('Tapping Marathi updates localeProvider, SQLite users.language_pref, and shows feedback', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpSettingsLanguage(
        tester,
        authState: loggedInAuth,
        localeNotifier: localeNotifier,
      );

      // Tap Marathi option
      await tester.tap(find.text('मराठी (Marathi)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Live switch in localeProvider
      expect(localeNotifier.state, const Locale('mr'));

      // 2. Persisted to SQLite users table
      final user = await UserRepository.instance.getById('owner-uuid-001');
      expect(user!.languagePref, 'mr');

      // 3. Shows localized success feedback SnackBar
      expect(find.text('भाषा पसंती जतन केली'), findsOneWidget);
    });

    testWidgets('Tapping English updates localeProvider and SQLite users.language_pref', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('mr'));
      await pumpSettingsLanguage(
        tester,
        authState: loggedInAuth,
        localeNotifier: localeNotifier,
      );

      // Tap English option
      await tester.tap(find.text('English'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Live switch in localeProvider
      expect(localeNotifier.state, const Locale('en'));

      // 2. Persisted to SQLite users table
      final user = await UserRepository.instance.getById('owner-uuid-001');
      expect(user!.languagePref, 'en');

      // 3. Shows success feedback SnackBar
      expect(find.text('Language preference saved'), findsOneWidget);
    });

    testWidgets('Unauthenticated user cannot access language screen', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpSettingsLanguage(
        tester,
        authState: const AuthState(),
        localeNotifier: localeNotifier,
      );

      // Content does not render
      expect(find.text('Choose your preferred app language'), findsNothing);
      expect(find.text('English'), findsNothing);
    });

    testWidgets('Login screen honors stored user language_pref upon login', (tester) async {
      // Seed an SM user with Marathi preference in DB
      fakeDb.tables['users']!.add({
        'id': 'sm-mr-001',
        'name': 'Suresh SM',
        'role': 'SM',
        'pin_hash': hashPin('4321'),
        'language_pref': 'mr',
        'phone': '9876543211',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      final localeNotifier = FakeLocaleNotifier(const Locale('en'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => localeNotifier),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final currentLocale = ref.watch(localeProvider) ?? const Locale('en');
              return MaterialApp(
                locale: currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: const LoginScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Suresh SM from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Suresh SM').last);
      await tester.pumpAndSettle();

      // Enter PIN '4321' on custom PinNumpad
      for (final digit in ['4', '3', '2', '1']) {
        await tester.tap(find.text(digit));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // Upon login, localeProvider is updated to Suresh SM's language_pref ('mr')
      expect(localeNotifier.state, const Locale('mr'));
    });

    testWidgets('Renders all elements in Marathi with full localized parity (Rule #8)', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('mr'));
      await pumpSettingsLanguage(
        tester,
        authState: loggedInAuth,
        localeNotifier: localeNotifier,
      );

      expect(find.text('भाषा / Language'), findsOneWidget);
      expect(find.text('तुमची पसंतीची अॅप भाषा निवडा'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('मराठी (Marathi)'), findsOneWidget);
      expect(find.text('सध्याची'), findsOneWidget);
    });
  });
}
