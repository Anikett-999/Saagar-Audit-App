import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s05_home/home_screen.dart';
import 'package:saagar_audit_app/ui/screens/s22_reference/reference_index_screen.dart';
import 'package:saagar_audit_app/ui/widgets/language_toggle_button.dart';

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

Widget createReferenceIndexTestWidget({
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/reference',
        routes: [
          GoRoute(
            path: '/reference',
            name: 's22_reference_index',
            builder: (_, __) => const ReferenceIndexScreen(),
          ),
          GoRoute(
            path: '/reference/rating',
            name: 's23_rating_scale',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S23 Rating Scale')),
            ),
          ),
          GoRoute(
            path: '/reference/escalation',
            name: 's24_escalation_triggers',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S24 Escalation Triggers')),
            ),
          ),
          GoRoute(
            path: '/reference/evidence',
            name: 's25_evidence',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S25 Evidence')),
            ),
          ),
          GoRoute(
            path: '/reference/glossary',
            name: 's26_glossary',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S26 Glossary')),
            ),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
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

void main() {
  group('Screen S22 Reference Index Widget Tests (Spec §5 S22 & Sprint Plan)', () {
    testWidgets('renders all 4 reference cards, header banner and badges in English', (tester) async {
      await tester.pumpWidget(createReferenceIndexTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // AppBar title & Language toggle
      expect(find.text('Reference Data'), findsOneWidget);
      expect(find.byType(LanguageToggleButton), findsOneWidget);

      // Header Banner
      expect(find.text('Store Audit Handbook'), findsOneWidget);
      expect(
        find.text(
          'Workbook Appendices A.4–A.7. Built-in compliance standards and escalation rules for store operations.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);

      // Card 1: A.4 Rating Scale
      expect(find.byKey(const Key('s22_card_rating_scale')), findsOneWidget);
      expect(find.text('Rating Scale & Targets'), findsOneWidget);
      expect(
        find.text('5 compliance bands, tier targets, decimal precision rules (Appendix A.4)'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.4'), findsOneWidget);
      expect(find.byIcon(Icons.speed_outlined), findsOneWidget);

      // Card 2: A.5 Escalation Triggers
      expect(find.byKey(const Key('s22_card_escalation')), findsOneWidget);
      expect(find.text('Escalation Triggers'), findsOneWidget);
      expect(
        find.text('7 mandatory triggers, 4-part message format, 3 worked examples (Appendix A.5)'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.5'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);

      // Card 3: A.6 Evidence Guide
      expect(find.byKey(const Key('s22_card_evidence')), findsOneWidget);
      expect(find.text('Strong vs Weak Evidence'), findsOneWidget);
      expect(
        find.text('8 strong vs 8 weak evidence types, auditing standards (Appendix A.6)'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.6'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);

      // Card 4: A.7 Bilingual Glossary
      expect(find.byKey(const Key('s22_card_glossary')), findsOneWidget);
      expect(find.text('Bilingual Glossary'), findsOneWidget);
      expect(
        find.text('65 retail and audit terms in English & Marathi with live search (Appendix A.7)'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.7'), findsOneWidget);
      expect(find.byIcon(Icons.translate_outlined), findsOneWidget);
    });

    testWidgets('renders all texts and badges in Marathi preserving Rule #8 parity', (tester) async {
      await tester.pumpWidget(createReferenceIndexTestWidget(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('संदर्भ माहिती'), findsOneWidget);

      // Header Banner
      expect(find.text('स्टोअर ऑडिट कार्यपुस्तिका'), findsOneWidget);
      expect(
        find.text(
          'पुस्तिका परिशिष्टे A.४–A.७. स्टोअर कामकाजासाठी अंतर्निहित अनुपालन मानके आणि एस्केलेशन नियम.',
        ),
        findsOneWidget,
      );

      // Card 1: Rating Scale
      expect(find.text('रेटिंग स्केल आणि लक्ष्ये'), findsOneWidget);
      expect(
        find.text('५ अनुपालन पट्ट्या, स्तर लक्ष्ये, दशांश अचूकता नियम (परिशिष्ट A.४)'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.4'), findsOneWidget);

      // Card 2: Escalation Triggers
      expect(find.text('एस्केलेशन ट्रिगर'), findsOneWidget);
      expect(
        find.text('७ अनिवार्य ट्रिगर, ४-भाग संदेश स्वरूप, ३ उदाहरणे (परिशिष्ट A.५)'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.5'), findsOneWidget);

      // Card 3: Evidence Guide
      expect(find.text('मजबूत वि. दुर्बल पुरावा'), findsOneWidget);
      expect(
        find.text('८ मजबूत वि. ८ दुर्बल पुरावा प्रकार, ऑडिट मानके (परिशिष्ट A.६)'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.6'), findsOneWidget);

      // Card 4: Bilingual Glossary
      expect(find.text('द्विभाषी शब्दकोश'), findsOneWidget);
      expect(
        find.text('इंग्रजी आणि मराठीतील ६५ रिटेल व ऑडिट संज्ञा, थेट शोधासह (परिशिष्ट A.७)'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.7'), findsOneWidget);
    });

    testWidgets('tapping Rating Scale card navigates to s23_rating_scale', (tester) async {
      await tester.pumpWidget(createReferenceIndexTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('s22_card_rating_scale')));
      await tester.pumpAndSettle();

      expect(find.text('Target S23 Rating Scale'), findsOneWidget);
    });

    testWidgets('tapping Escalation Triggers card navigates to s24_escalation_triggers', (tester) async {
      await tester.pumpWidget(createReferenceIndexTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('s22_card_escalation')));
      await tester.pumpAndSettle();

      expect(find.text('Target S24 Escalation Triggers'), findsOneWidget);
    });

    testWidgets('tapping Evidence Guide card navigates to s25_evidence', (tester) async {
      await tester.pumpWidget(createReferenceIndexTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('s22_card_evidence')));
      await tester.pumpAndSettle();

      expect(find.text('Target S25 Evidence'), findsOneWidget);
    });

    testWidgets('tapping Bilingual Glossary card navigates to s26_glossary', (tester) async {
      await tester.pumpWidget(createReferenceIndexTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('s22_card_glossary')));
      await tester.pumpAndSettle();

      expect(find.text('Target S26 Glossary'), findsOneWidget);
    });

    testWidgets('renders overflow-free on narrow screens (320x480) in Marathi', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createReferenceIndexTestWidget(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      // Expect no overflow errors thrown
      expect(tester.takeException(), isNull);
      expect(find.text('संदर्भ माहिती'), findsOneWidget);
      expect(find.byKey(const Key('s22_card_rating_scale')), findsOneWidget);

      // Scroll down to verify bottom card renders cleanly without overflow
      await tester.scrollUntilVisible(
        find.byKey(const Key('s22_card_glossary')),
        200.0,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('s22_card_glossary')), findsOneWidget);
    });
  });

  group('S05 Home Screen Reference Entry Tile Integration', () {
    late FakeDatabase fakeDb;

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('tapping Reference tile on S05 Home navigates to /reference', (tester) async {
      const smUser = AuthUser(
        id: 'sm-1',
        name: 'Sunil SM',
        role: 'SM',
        languagePref: 'en',
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 's05_home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/reference',
            name: 's22_reference_index',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S22 Reference Index Screen')),
            ),
          ),
          GoRoute(
            path: '/login',
            name: 's04_login',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Login Screen')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(const AuthState(user: smUser)),
            ),
            localeProvider.overrideWith(
              (ref) => FakeLocaleNotifier(const Locale('en')),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Reference tile is present on Home Screen
      final referenceTileFinder = find.widgetWithText(ListTile, 'Reference');
      expect(referenceTileFinder, findsOneWidget);

      // Tap Reference tile
      await tester.tap(referenceTileFinder);
      await tester.pumpAndSettle();

      // Verify navigation reached Target S22 Reference Index Screen
      expect(find.text('Target S22 Reference Index Screen'), findsOneWidget);
    });
  });
}
