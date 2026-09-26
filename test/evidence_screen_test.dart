import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/repositories/reference_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s25_evidence/evidence_screen.dart';
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

Widget createEvidenceTestWidget({
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/reference/evidence',
        routes: [
          GoRoute(
            path: '/reference',
            name: 's22_reference_index',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S22 Reference Index')),
            ),
          ),
          GoRoute(
            path: '/reference/evidence',
            name: 's25_evidence',
            builder: (_, __) => const EvidenceScreen(),
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

Future<void> pumpEvidence(
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
    createEvidenceTestWidget(locale: locale, router: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ReferenceRepository.instance.loadEvidenceGuide();
  });

  group('Screen S25 Evidence Guide Widget Tests (Spec §5 S25, §11.3 & Appendix A.6)', () {
    testWidgets('renders all 8 evidence standards, subtitle callout, and warning banner in English', (tester) async {
      await pumpEvidence(tester, locale: const Locale('en'));

      // AppBar title & Language toggle
      expect(find.widgetWithText(AppBar, 'Evidence Guide'), findsOneWidget);
      expect(find.byType(LanguageToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Header Banner
      expect(
        find.text('Workbook Appendix A.6 • 8 strong vs weak evidence standards'),
        findsOneWidget,
      );
      expect(find.text('Appendix A.6'), findsOneWidget);

      // Subtitle callout
      expect(
        find.textContaining('Every audit finding must be evidenced by something in the Strong Evidence column'),
        findsOneWidget,
      );

      // Section Header
      expect(find.text('8 Evidence Standards'), findsOneWidget);

      // All 8 comparison pairs
      for (int i = 1; i <= 8; i++) {
        expect(find.byKey(Key('s25_pair_$i')), findsOneWidget);
      }

      // Strong & Weak labels
      expect(find.text('STRONG EVIDENCE'), findsNWidgets(8));
      expect(find.text('WEAK EVIDENCE (UNACCEPTABLE)'), findsNWidgets(8));

      // Specific content checks
      expect(find.textContaining('Photographs with timestamp'), findsOneWidget);
      expect(find.textContaining('Photographs without timestamp'), findsOneWidget);

      expect(find.textContaining('Signed and dated register entries'), findsOneWidget);
      expect(find.textContaining('Unsigned documents'), findsOneWidget);

      expect(find.textContaining('Email/messaging audit trail with timestamp'), findsOneWidget);
      expect(find.textContaining('"I remember doing it"'), findsOneWidget);

      // Bottom Warning Banner
      expect(find.byKey(const Key('s25_warning_banner')), findsOneWidget);
      expect(find.text('Auditing vs Reporting Rule'), findsOneWidget);
      expect(
        find.textContaining('Every finding must rest on the left column.'),
        findsOneWidget,
      );
    });

    testWidgets('renders all content in Marathi preserving Rule #8 parity', (tester) async {
      await pumpEvidence(tester, locale: const Locale('mr'));

      // AppBar title & Header
      expect(find.widgetWithText(AppBar, 'पुरावा मार्गदर्शिका'), findsOneWidget);
      expect(
        find.text('पुस्तिका परिशिष्ट A.६ • ८ मजबूत वि. दुर्बल पुरावा मानके'),
        findsOneWidget,
      );
      expect(find.text('परिशिष्ट A.6'), findsOneWidget);

      // Subtitle callout in Marathi
      expect(
        find.textContaining('प्रत्येक ऑडिट निष्कर्षाला मजबूत पुरावा स्तंभातील कशाने तरी आधार हवा'),
        findsOneWidget,
      );

      // Section Header
      expect(find.text('८ पुरावा मानके'), findsOneWidget);

      // Strong & Weak labels in Marathi
      expect(find.text('मजबूत पुरावा'), findsNWidgets(8));
      expect(find.text('दुर्बल पुरावा (अस्वीकार्य)'), findsNWidgets(8));

      // Specific Marathi content checks
      expect(find.textContaining('वेळ-शिक्क्यासह फोटो'), findsOneWidget);
      expect(find.textContaining('वेळ-शिक्क्याशिवायचे फोटो'), findsOneWidget);

      expect(find.textContaining('सही व दिनांकित रजिस्टर नोंदी'), findsOneWidget);
      expect(find.textContaining('सही नसलेले दस्तऐवज'), findsOneWidget);

      expect(find.textContaining('वेळ-शिक्क्यासह ईमेल/संदेश ट्रेल'), findsOneWidget);
      expect(find.textContaining('"मला आठवते"'), findsOneWidget);

      // Bottom Warning Banner in Marathi
      expect(find.text('ऑडिट वि. रिपोर्टिंग नियम'), findsOneWidget);
      expect(
        find.textContaining('प्रत्येक निष्कर्ष डाव्या स्तंभावर विसावला पाहिजे.'),
        findsOneWidget,
      );
    });

    testWidgets('renders overflow-free on narrow screens (320x640) in Marathi', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createEvidenceTestWidget(locale: const Locale('mr')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(AppBar, 'पुरावा मार्गदर्शिका'), findsOneWidget);
    });

    testWidgets('tapping refresh button reloads data smoothly', (tester) async {
      await pumpEvidence(tester, locale: const Locale('en'));

      expect(find.widgetWithText(AppBar, 'Evidence Guide'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.refresh));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Evidence Guide'), findsOneWidget);
      expect(find.text('8 Evidence Standards'), findsOneWidget);
    });
  });
}
