import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/repositories/reference_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s24_escalation_triggers/escalation_triggers_screen.dart';
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

Widget createEscalationTriggersTestWidget({
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/reference/escalation',
        routes: [
          GoRoute(
            path: '/reference',
            name: 's22_reference_index',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S22 Reference Index')),
            ),
          ),
          GoRoute(
            path: '/reference/escalation',
            name: 's24_escalation_triggers',
            builder: (_, __) => const EscalationTriggersScreen(),
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

Future<void> pumpEscalationTriggers(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    createEscalationTriggersTestWidget(locale: locale, router: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ReferenceRepository.instance.loadEscalationTriggers();
  });

  group('Screen S24 Escalation Triggers Widget Tests (Spec §5 S24, §11.2 & Appendix A.5)', () {
    testWidgets('renders all 7 triggers, message format, never-escalates rules, and 3 examples in English', (tester) async {
      await pumpEscalationTriggers(tester, locale: const Locale('en'));

      // AppBar title & Language toggle
      expect(find.widgetWithText(AppBar, 'Escalation Triggers'), findsOneWidget);
      expect(find.byType(LanguageToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Header Banner
      expect(
        find.text('Workbook Appendix A.5 • 7 mandatory escalation triggers & rules'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.5'), findsOneWidget);

      // Section 1: 7 Mandatory Triggers
      expect(find.text('7 Mandatory Escalation Triggers'), findsOneWidget);
      for (int i = 1; i <= 7; i++) {
        expect(find.byKey(Key('s24_trigger_$i')), findsOneWidget);
      }
      expect(find.text('Daily audit Critical band'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('s24_trigger_1')),
          matching: find.textContaining('< 80%'),
        ),
        findsOneWidget,
      );
      expect(find.text('GM (Owner if Cash/Inv)'), findsOneWidget);

      expect(find.text('Single-day cash variance'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('s24_trigger_3')),
          matching: find.textContaining('> ₹500'),
        ),
        findsOneWidget,
      );

      expect(find.text('Theft / security / legal'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('s24_trigger_5')),
          matching: find.textContaining('Any indication'),
        ),
        findsOneWidget,
      );
      expect(find.text('Immediate'), findsOneWidget);

      // Section 2: 4-Part Message Format
      expect(find.text('Escalation Message Format (4 Parts)'), findsOneWidget);
      expect(find.byKey(const Key('s24_message_format_card')), findsOneWidget);
      expect(find.text('What happened'), findsOneWidget);
      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('Operational impact'), findsOneWidget);
      expect(find.text('Requested action'), findsOneWidget);

      // Section 3: What Never Escalates
      expect(find.byKey(const Key('s24_never_escalates_card')), findsOneWidget);
      expect(find.text('What Never Escalates'), findsOneWidget);
      expect(
        find.textContaining('Single-checkpoint Fails within Good or Excellent band'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Personal disagreements between Store Manager and CRO'),
        findsOneWidget,
      );

      // Section 4: 3 Worked Examples
      expect(find.text('Worked Example Messages'), findsOneWidget);
      expect(find.byKey(const Key('s24_example_1')), findsOneWidget);
      expect(find.byKey(const Key('s24_example_3')), findsOneWidget);
      expect(find.byKey(const Key('s24_example_5')), findsOneWidget);

      expect(find.textContaining('Example 1: Trigger 1'), findsOneWidget);
      expect(find.textContaining('Example 2: Trigger 3'), findsOneWidget);
      expect(find.textContaining('Example 3: Trigger 5'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Copy Message'), findsNWidgets(3));
    });

    testWidgets('renders all content in Marathi preserving Rule #8 parity', (tester) async {
      await pumpEscalationTriggers(tester, locale: const Locale('mr'));

      // AppBar title & Header
      expect(find.widgetWithText(AppBar, 'एस्केलेशन ट्रिगर'), findsOneWidget);
      expect(
        find.text('पुस्तिका परिशिष्ट A.५ • ७ अनिवार्य एस्केलेशन ट्रिगर्स आणि नियम'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.5'), findsOneWidget);

      // Section 1: 7 Triggers in Marathi
      expect(find.text('७ अनिवार्य एस्केलेशन ट्रिगर्स'), findsOneWidget);
      expect(find.text('दैनंदिन ऑडिट क्रिटिकल पट्टी'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('s24_trigger_1')),
          matching: find.textContaining('< ८०%'),
        ),
        findsOneWidget,
      );
      expect(find.text('GM (रोख/स्टॉक असल्यास मालक)'), findsOneWidget);
      expect(find.text('त्याच रात्री'), findsOneWidget);

      expect(find.text('एका दिवसाची रोख तफावत'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('s24_trigger_3')),
          matching: find.textContaining('> ₹५००'),
        ),
        findsOneWidget,
      );

      expect(find.text('चोरी / सुरक्षा / कायदेशीर'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('s24_trigger_5')),
          matching: find.textContaining('कोणताही संकेत'),
        ),
        findsOneWidget,
      );
      expect(find.text('तातडीने'), findsOneWidget);

      // Section 2: Message Format in Marathi
      expect(find.text('एस्केलेशन संदेश स्वरूप (४ भाग)'), findsOneWidget);
      expect(find.text('काय झाले'), findsOneWidget);
      expect(find.text('पुरावा'), findsOneWidget);
      expect(find.text('कार्यवाहक परिणाम'), findsOneWidget);
      expect(find.text('मागितलेली कृती'), findsOneWidget);

      // Section 3: What Never Escalates in Marathi
      expect(find.text('काय कधीच एस्केलेट होत नाही'), findsOneWidget);
      expect(
        find.textContaining('चांगले किंवा उत्कृष्ट पट्टीतले एकल-तपासणी बिंदू नापास'),
        findsOneWidget,
      );

      // Section 4: Worked Examples in Marathi
      expect(find.text('तयार उदाहरण संदेश'), findsOneWidget);
      expect(find.textContaining('उदाहरण १: ट्रिगर १'), findsOneWidget);
      expect(find.textContaining('उदाहरण २: ट्रिगर ३'), findsOneWidget);
      expect(find.textContaining('उदाहरण ३: ट्रिगर ५'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'संदेश कॉपी करा'), findsNWidgets(3));
    });

    testWidgets('renders overflow-free on narrow screens (320x640) in Marathi', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createEscalationTriggersTestWidget(locale: const Locale('mr')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppBar, 'एस्केलेशन ट्रिगर'), findsOneWidget);
    });

    testWidgets('tapping copy button copies example message to clipboard and shows snackbar', (tester) async {
      await pumpEscalationTriggers(tester, locale: const Locale('en'));

      final copyButtonFinder = find.widgetWithText(OutlinedButton, 'Copy Message').first;
      expect(copyButtonFinder, findsOneWidget);

      await tester.tap(copyButtonFinder);
      await tester.pump(); // Start snackbar animation
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Escalation message copied to clipboard'), findsOneWidget);
    });

    testWidgets('tapping refresh button reloads data smoothly', (tester) async {
      await pumpEscalationTriggers(tester, locale: const Locale('en'));

      expect(find.widgetWithText(AppBar, 'Escalation Triggers'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.refresh));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Escalation Triggers'), findsOneWidget);
      expect(find.text('7 Mandatory Escalation Triggers'), findsOneWidget);
    });
  });
}
