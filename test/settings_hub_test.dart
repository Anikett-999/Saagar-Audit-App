import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s27_settings/settings_screen.dart';

Widget createSettingsTestWidget({
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
      home: const SettingsScreen(),
    ),
  );
}

Future<void> pumpSettings(
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
    createSettingsTestWidget(authState: authState, locale: locale),
  );
  await tester.pumpAndSettle();
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

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('S27 Settings Hub Widget Tests (Spec §S27 & Sprint Plan)', () {
    const ownerUser = AuthUser(
      id: 'owner-1',
      name: 'Aniket Owner',
      role: 'OWNER',
      languagePref: 'en',
    );

    const smUser = AuthUser(
      id: 'sm-1',
      name: 'Sunil SM',
      role: 'SM',
      languagePref: 'en',
    );

    const gmUser = AuthUser(
      id: 'gm-1',
      name: 'Ganesh GM',
      role: 'GM',
      languagePref: 'en',
    );

    testWidgets('Owner sees Manage Users and all other sections', (tester) async {
      await pumpSettings(
        tester,
        authState: const AuthState(user: ownerUser),
      );

      // Top bar & User Card
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Aniket Owner'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);

      // Section headers
      expect(find.text('MANAGEMENT'), findsOneWidget);
      expect(find.text('PREFERENCES & DATA'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);

      // Tiles
      expect(find.text('Manage CROs'), findsOneWidget);
      expect(find.text('Manage Users'), findsOneWidget);
      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('Language / भाषा'), findsOneWidget);
      expect(find.text('Backup & Export'), findsOneWidget);
      expect(find.text('About Saagar Audit'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('SM user HIDES Manage Users completely', (tester) async {
      await pumpSettings(
        tester,
        authState: const AuthState(user: smUser),
      );

      // SM user details
      expect(find.text('Sunil SM'), findsOneWidget);
      expect(find.text('Store Manager'), findsOneWidget);

      // Manage CROs is visible to SM
      expect(find.text('Manage CROs'), findsOneWidget);

      // Manage Users MUST NOT be present anywhere in the widget tree
      expect(find.text('Manage Users'), findsNothing);

      // Other settings are present
      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('Language / भाषा'), findsOneWidget);
      expect(find.text('Backup & Export'), findsOneWidget);
      expect(find.text('About Saagar Audit'), findsOneWidget);
    });

    testWidgets('GM user HIDES Manage Users completely', (tester) async {
      await pumpSettings(
        tester,
        authState: const AuthState(user: gmUser),
      );

      expect(find.text('Ganesh GM'), findsOneWidget);
      expect(find.text('General Manager'), findsOneWidget);
      expect(find.text('Manage CROs'), findsOneWidget);

      // Manage Users MUST NOT be present
      expect(find.text('Manage Users'), findsNothing);
    });

    testWidgets('Tapping About opens About Dialog with app info', (tester) async {
      await pumpSettings(
        tester,
        authState: const AuthState(user: ownerUser),
      );

      await tester.tap(find.text('About Saagar Audit'));
      await tester.pumpAndSettle();

      expect(find.text('About Priority 1 Audit'), findsOneWidget);
      expect(find.textContaining('Titan World (WLMHW) & Helios (HEMW)'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('About Priority 1 Audit'), findsNothing);
    });

    testWidgets('Renders in Marathi with full localized parity (Rule #8)', (tester) async {
      await pumpSettings(
        tester,
        authState: const AuthState(user: ownerUser),
        locale: const Locale('mr'),
      );

      // Localized headers & titles
      expect(find.text('सेटिंग्ज'), findsOneWidget);
      expect(find.text('व्यवस्थापन'), findsOneWidget);
      expect(find.text('प्राधान्ये आणि डेटा'), findsOneWidget);
      expect(find.text('खाते'), findsOneWidget);
      expect(find.text('सीआरओ व्यवस्थापन'), findsOneWidget);
      expect(find.text('वापरकर्ता व्यवस्थापन'), findsOneWidget);
      expect(find.text('PIN बदला'), findsOneWidget);
      expect(find.text('भाषा / Language'), findsOneWidget);
      expect(find.text('बॅकअप व निर्यात'), findsOneWidget);
      expect(find.text('अॅपबद्दल माहिती'), findsOneWidget);
      expect(find.text('लॉगआउट'), findsOneWidget);
    });
  });
}
