import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saagar_audit_app/data/repositories/reference_repository.dart';
import 'package:saagar_audit_app/domain/score_engine.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s23_rating_scale/rating_scale_screen.dart';
import 'package:saagar_audit_app/ui/widgets/language_toggle_button.dart';

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);

  @override
  Future<void> set(Locale locale) async {
    state = locale;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createRatingScaleTestWidget({
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  final effectiveRouter = router ??
      GoRouter(
        initialLocation: '/reference/rating',
        routes: [
          GoRoute(
            path: '/reference',
            name: 's22_reference_index',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Target S22 Reference Index')),
            ),
          ),
          GoRoute(
            path: '/reference/rating',
            name: 's23_rating_scale',
            builder: (_, __) => const RatingScaleScreen(),
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

Future<void> pumpRatingScale(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  GoRouter? router,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    createRatingScaleTestWidget(locale: locale, router: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ReferenceRepository.instance.loadRatingScale();
  });

  group('Screen S23 Rating Scale Widget Tests (Spec §5 S23, §11.1 & Appendix A.4)', () {
    testWidgets('renders all 5 compliance bands, 3 tier targets, and reminder banner in English', (tester) async {
      await pumpRatingScale(tester, locale: const Locale('en'));

      // AppBar title & Language toggle
      expect(find.widgetWithText(AppBar, 'Rating Scale'), findsOneWidget);
      expect(find.byType(LanguageToggleButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Header Banner
      expect(find.text('Workbook Appendix A.4 • 5 compliance bands & tier targets'), findsOneWidget);
      expect(find.text('Appendix A.4'), findsOneWidget);

      // Section 1: Compliance Bands
      expect(find.text('Compliance Bands'), findsOneWidget);
      expect(find.byKey(const Key('s23_band_excellent')), findsOneWidget);
      expect(find.text('EXCELLENT'), findsOneWidget);
      expect(find.text('≥ 95% (95.0% – 100.0%)'), findsOneWidget);
      expect(find.text('Reward; document practice for replication'), findsOneWidget);

      expect(find.byKey(const Key('s23_band_good')), findsOneWidget);
      expect(find.text('GOOD'), findsOneWidget);
      expect(find.text('≥ 90% (90.0% – 94.9%)'), findsOneWidget);
      expect(find.text('Note minor fixes for next day; no CAP needed'), findsOneWidget);

      expect(find.byKey(const Key('s23_band_fair')), findsOneWidget);
      expect(find.text('FAIR'), findsOneWidget);
      expect(find.text('≥ 85% (85.0% – 89.9%)'), findsOneWidget);
      expect(find.text('Written CAP required'), findsOneWidget);

      expect(find.byKey(const Key('s23_band_poor')), findsOneWidget);
      expect(find.text('POOR'), findsOneWidget);
      expect(find.text('≥ 80% (80.0% – 84.9%)'), findsOneWidget);
      expect(find.text('Urgent CAP + escalate one tier up'), findsOneWidget);

      expect(find.byKey(const Key('s23_band_critical')), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('< 80% (Below 80.0%)'), findsOneWidget);
      expect(find.text('Same-day escalation; full root-cause analysis'), findsOneWidget);

      // Section 2: Tier Targets
      expect(find.text('Tier Targets'), findsOneWidget);
      expect(find.byKey(const Key('s23_tier_tier_1_daily')), findsOneWidget);
      expect(find.text('Tier 1 daily'), findsOneWidget);
      expect(find.text('90%+'), findsOneWidget);
      expect(find.text('Store Manager'), findsOneWidget);
      expect(find.textContaining('81+ weighted'), findsOneWidget);
      expect(find.textContaining('90 weighted'), findsOneWidget);

      expect(find.byKey(const Key('s23_tier_tier_2_weekly')), findsOneWidget);
      expect(find.text('Tier 2 weekly'), findsOneWidget);
      expect(find.text('92%+'), findsOneWidget);
      expect(find.text('GM'), findsOneWidget);
      expect(find.textContaining('114+ weighted'), findsOneWidget);
      expect(find.textContaining('124 weighted'), findsOneWidget);

      expect(find.byKey(const Key('s23_tier_tier_3_monthly')), findsOneWidget);
      expect(find.text('Tier 3 monthly'), findsOneWidget);
      expect(find.text('95%+'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);

      // Section 3: Critical Reminder Callout Banner
      expect(find.byKey(const Key('s23_reminder_banner')), findsOneWidget);
      expect(find.text('WARNING: Strict Decimal Precision'), findsOneWidget);
      expect(
        find.textContaining('Always score with one decimal place. 89.9 is FAIR, not Good.'),
        findsOneWidget,
      );
    });

    testWidgets('renders all content in Marathi preserving Rule #8 parity', (tester) async {
      await pumpRatingScale(tester, locale: const Locale('mr'));

      // AppBar title & Header
      expect(find.widgetWithText(AppBar, 'रेटिंग स्केल'), findsOneWidget);
      expect(find.text('पुस्तिका परिशिष्ट A.४ • ५ अनुपालन पट्ट्या आणि स्तर लक्ष्ये'), findsOneWidget);
      expect(find.text('परिशिष्ट A.4'), findsOneWidget);

      // Section 1: Compliance Bands in Marathi
      expect(find.text('५ अनुपालन पट्ट्या'), findsOneWidget);
      expect(find.text('उत्कृष्ट'), findsOneWidget);
      expect(find.text('≥ ९५% (९५.०% – १००.०%)'), findsOneWidget);
      expect(find.text('चांगले'), findsOneWidget);
      expect(find.text('≥ ९०% (९०.०% – ९४.९%)'), findsOneWidget);
      expect(find.text('बरे'), findsOneWidget);
      expect(find.text('≥ ८५% (८५.०% – ८९.९%)'), findsOneWidget);
      expect(find.text('वाईट'), findsOneWidget);
      expect(find.text('≥ ८०% (८०.०% – ८४.९%)'), findsOneWidget);
      expect(find.text('अत्यावश्यक'), findsOneWidget);
      expect(find.text('< ८०% (८०.०% खाली)'), findsOneWidget);

      // Section 2: Tier Targets in Marathi
      expect(find.text('स्तर लक्ष्ये'), findsOneWidget);
      expect(find.text('टियर १ दैनंदिन'), findsOneWidget);
      expect(find.text('९०%+'), findsOneWidget);
      expect(find.text('स्टोअर मॅनेजर'), findsOneWidget);
      expect(find.textContaining('८१+ वजनी'), findsOneWidget);
      expect(find.textContaining('९० वजनी'), findsOneWidget);

      expect(find.text('टियर २ साप्ताहिक'), findsOneWidget);
      expect(find.text('९२%+'), findsOneWidget);
      expect(find.text('जीएम (जनरल मॅनेजर)'), findsOneWidget);

      expect(find.text('टियर ३ मासिक'), findsOneWidget);
      expect(find.text('९५%+'), findsOneWidget);
      expect(find.text('मालक'), findsOneWidget);

      // Section 3: Reminder banner in Marathi
      expect(find.text('सूचना: अचूक दशांश शिस्त'), findsOneWidget);
      expect(
        find.textContaining('८९.९ बरे आहे, चांगले नाही.'),
        findsOneWidget,
      );
    });

    test('band boundaries in rating_scale.json strictly align with score engine bandFromCompliance', () async {
      final scale = await ReferenceRepository.instance.loadRatingScale();

      // Check all 5 bands
      expect(scale.bands.length, 5);

      final excellent = scale.bands.firstWhere((b) => b.id == 'excellent');
      expect(bandFromCompliance(excellent.minPercentage), Band.excellent);
      expect(excellent.minPercentage, 95.0);

      final good = scale.bands.firstWhere((b) => b.id == 'good');
      expect(bandFromCompliance(good.minPercentage), Band.good);
      expect(good.minPercentage, 90.0);
      expect(bandFromCompliance(good.maxPercentage), Band.good);
      expect(good.maxPercentage, 94.9);

      final fair = scale.bands.firstWhere((b) => b.id == 'fair');
      expect(bandFromCompliance(fair.minPercentage), Band.fair);
      expect(fair.minPercentage, 85.0);
      expect(bandFromCompliance(fair.maxPercentage), Band.fair);
      expect(fair.maxPercentage, 89.9);

      final poor = scale.bands.firstWhere((b) => b.id == 'poor');
      expect(bandFromCompliance(poor.minPercentage), Band.poor);
      expect(poor.minPercentage, 80.0);
      expect(bandFromCompliance(poor.maxPercentage), Band.poor);
      expect(poor.maxPercentage, 84.9);

      final critical = scale.bands.firstWhere((b) => b.id == 'critical');
      expect(bandFromCompliance(critical.minPercentage), Band.critical);
      expect(critical.minPercentage, 0.0);
      expect(bandFromCompliance(critical.maxPercentage), Band.critical);
      expect(critical.maxPercentage, 79.9);

      // Verify Tier 1 canonical invariant: 81 / 90 = 90.0% Good
      final tier1 = scale.tierTargets.firstWhere((t) => t.tierEn.contains('Tier 1'));
      expect(tier1.targetPctEn, '90%+');
      expect(tier1.passPointsEn, contains('81'));
      expect(tier1.totalPointsEn, contains('90'));
    });

    testWidgets('renders overflow-free on narrow screens (320x640) in Marathi', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createRatingScaleTestWidget(locale: const Locale('mr')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('s23_band_excellent')), findsOneWidget);

      // Scroll to reminder banner
      await tester.scrollUntilVisible(
        find.byKey(const Key('s23_reminder_banner')),
        200.0,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('s23_reminder_banner')), findsOneWidget);
    });

    testWidgets('tapping refresh button reloads data smoothly', (tester) async {
      await pumpRatingScale(tester, locale: const Locale('en'));

      expect(find.widgetWithText(AppBar, 'Rating Scale'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.refresh));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Rating Scale'), findsOneWidget);
      expect(find.byKey(const Key('s23_band_good')), findsOneWidget);
    });
  });
}
