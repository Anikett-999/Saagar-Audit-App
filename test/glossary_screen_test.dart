import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/repositories/reference_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s26_glossary/glossary_screen.dart';
import 'package:saagar_audit_app/ui/widgets/language_toggle_button.dart';

class FakeLocaleNotifier extends StateNotifier<Locale?>
    implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createGlossaryTestWidget({
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/reference/glossary',
        routes: [
          GoRoute(
            path: '/reference',
            name: 's22_reference_index',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S22 Reference Index')),
            ),
          ),
          GoRoute(
            path: '/reference/glossary',
            name: 's26_glossary',
            builder: (_, __) => const GlossaryScreen(),
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

Future<void> pumpGlossary(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(800, 15000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    createGlossaryTestWidget(locale: locale, router: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ReferenceRepository.instance.loadGlossary();
  });

  group('Screen S26 Bilingual Glossary Widget Tests (Spec §5 S26, §11.4 & Appendix A.7)', () {
    testWidgets('renders header banner, search bar, counter, and all 65 cards in English', (tester) async {
      await pumpGlossary(tester, locale: const Locale('en'));

      // AppBar title & Language toggle
      expect(find.widgetWithText(AppBar, 'Bilingual Glossary'), findsOneWidget);
      expect(find.byType(LanguageToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Header Banner
      expect(
        find.text('Workbook Appendix A.7 • 65 bilingual retail & audit terms with definitions'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.7'), findsOneWidget);

      // Search bar
      expect(find.byKey(const Key('s26_search_input')), findsOneWidget);
      expect(
        find.text('Search term or definition (English / मराठी)...'),
        findsOneWidget,
      );

      // Status count pill
      expect(find.text('Showing 65 of 65 terms'), findsOneWidget);

      // Specific sample entries across start, middle, and end
      expect(find.byKey(const Key('s26_item_Audit')), findsOneWidget);
      expect(find.text('Independent check of standard vs reality'), findsOneWidget);

      expect(find.byKey(const Key('s26_item_SOP')), findsOneWidget);
      expect(find.text('Standard Operating Procedure'), findsOneWidget);

      expect(find.byKey(const Key('s26_item_FIFO')), findsOneWidget);
      expect(find.text('First In, First Out — sell oldest first'), findsOneWidget);

      expect(find.byKey(const Key('s26_item_CAP')), findsOneWidget);
      expect(find.text('Corrective Action Plan'), findsOneWidget);

      expect(find.byKey(const Key('s26_item_Opening time')), findsOneWidget);
    });

    testWidgets('renders all content in Marathi preserving Rule #8 parity', (tester) async {
      await pumpGlossary(tester, locale: const Locale('mr'));

      // AppBar title & Header in Marathi
      expect(find.widgetWithText(AppBar, 'द्विभाषी शब्दकोश'), findsOneWidget);
      expect(
        find.text('पुस्तिका परिशिष्ट A.७ • व्याख्यांसह ६५ द्विभाषी रिटेल आणि ऑडिट संज्ञा'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.7'), findsOneWidget);

      // Search bar in Marathi
      expect(
        find.text('संज्ञा किंवा व्याख्या शोधा (English / मराठी)...'),
        findsOneWidget,
      );

      // Status count pill in Marathi
      expect(find.text('65 पैकी 65 संज्ञा दर्शवत आहे'), findsOneWidget);

      // Specific Marathi terms & definitions
      expect(find.byKey(const Key('s26_item_Audit')), findsOneWidget);
      expect(find.text('मानक वि. वास्तविकता यांची स्वतंत्र तपासणी'), findsOneWidget);

      expect(find.byKey(const Key('s26_item_SOP')), findsOneWidget);
      expect(find.text('प्रमाणित कार्यप्रणाली (एसओपी)'), findsOneWidget);

      expect(find.byKey(const Key('s26_item_FIFO')), findsOneWidget);
      expect(find.text('पहिल्यांदा आलेले, पहिल्यांदा बाहेर — जुने आधी विका'), findsOneWidget);
    });

    testWidgets('live search filters by English term query and restores on clear', (tester) async {
      await pumpGlossary(tester, locale: const Locale('en'));

      expect(find.text('Showing 65 of 65 terms'), findsOneWidget);

      // Enter search term 'FIFO'
      await tester.enterText(find.byKey(const Key('s26_search_input')), 'FIFO');
      await tester.pumpAndSettle();

      expect(find.text('Showing 1 of 65 terms'), findsOneWidget);
      expect(find.byKey(const Key('s26_item_FIFO')), findsOneWidget);
      expect(find.byKey(const Key('s26_item_SOP')), findsNothing);

      // Clear search via clear icon button
      expect(find.byKey(const Key('s26_clear_search_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('s26_clear_search_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Showing 65 of 65 terms'), findsOneWidget);
      expect(find.byKey(const Key('s26_item_FIFO')), findsOneWidget);
      expect(find.byKey(const Key('s26_item_SOP')), findsOneWidget);
    });

    testWidgets('live search filters by Devanagari Marathi query', (tester) async {
      await pumpGlossary(tester, locale: const Locale('mr'));

      // Enter search term 'तपासणी' (matches 'तपासणी बिंदू', 'स्वतंत्र तपासणी', etc.)
      await tester.enterText(find.byKey(const Key('s26_search_input')), 'तपासणी');
      await tester.pumpAndSettle();

      // Checkpoint and Audit entries match
      expect(find.byKey(const Key('s26_item_Audit')), findsOneWidget);
      expect(find.byKey(const Key('s26_item_Checkpoint')), findsOneWidget);
      expect(find.byKey(const Key('s26_item_FIFO')), findsNothing);
    });

    testWidgets('live search filters by definition meaning text', (tester) async {
      await pumpGlossary(tester, locale: const Locale('en'));

      // Search by partial definition 'Standard Operating Procedure'
      await tester.enterText(
        find.byKey(const Key('s26_search_input')),
        'Standard Operating Procedure',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('s26_item_SOP')), findsOneWidget);
      expect(find.text('Showing 1 of 65 terms'), findsOneWidget);
    });

    testWidgets('renders empty state when query matches zero terms and tapping reset button clears search', (tester) async {
      await pumpGlossary(tester, locale: const Locale('en'));

      await tester.enterText(
        find.byKey(const Key('s26_search_input')),
        'NonExistentQueryXYZ123',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('s26_empty_state')), findsOneWidget);
      expect(find.text('No matching terms found'), findsOneWidget);
      expect(
        find.text('Try searching with a different English or Marathi keyword'),
        findsOneWidget,
      );

      // Tap clear search button inside empty state
      await tester.tap(find.byKey(const Key('s26_empty_clear_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('s26_empty_state')), findsNothing);
      expect(find.text('Showing 65 of 65 terms'), findsOneWidget);
    });

    testWidgets('renders overflow-free on narrow screens (320x640) in Marathi', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createGlossaryTestWidget(locale: const Locale('mr')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppBar, 'द्विभाषी शब्दकोश'), findsOneWidget);
    });

    testWidgets('tapping refresh button reloads data smoothly', (tester) async {
      await pumpGlossary(tester, locale: const Locale('en'));

      expect(find.widgetWithText(AppBar, 'Bilingual Glossary'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.refresh));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Bilingual Glossary'), findsOneWidget);
      expect(find.text('Showing 65 of 65 terms'), findsOneWidget);
    });
  });
}
