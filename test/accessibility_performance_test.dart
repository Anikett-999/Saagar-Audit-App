import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/domain/trend_analytics.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/ui/theme/app_colors.dart';
import 'package:saagar_audit_app/ui/widgets/language_toggle_button.dart';
import 'package:saagar_audit_app/ui/widgets/pin_numpad.dart';
import 'package:saagar_audit_app/ui/widgets/trend_chart.dart';

void main() {
  group('Sprint P4-2 — Accessibility & Performance Test Suite', () {
    testWidgets('1. PinNumpad provides descriptive TalkBack semantics for digits, backspace, and dot progress',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinNumpad(
              onPinComplete: (_) {},
            ),
          ),
        ),
      );

      // Verify dots container announces initial state
      expect(
        tester.getSemantics(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '0 of 4 digits entered',
          ),
        ),
        isNotNull,
      );

      // Verify all digits have button semantics and labels
      for (int i = 0; i <= 9; i++) {
        final digitFinder = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true && w.properties.label == '$i',
        );
        expect(
          digitFinder,
          findsOneWidget,
          reason: 'Digit $i missing button semantics',
        );
      }

      // Verify backspace has button semantics and 'Backspace' label
      final backspaceFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true && w.properties.label == 'Backspace',
      );
      expect(backspaceFinder, findsOneWidget);

      // Enter 2 digits and verify dot count update
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();

      expect(
        tester.getSemantics(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '2 of 4 digits entered',
          ),
        ),
        isNotNull,
      );

      handle.dispose();
    });

    testWidgets('2. LanguageToggleButton has accessible semantics and meets >= 48x48 min touch target',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('mr')],
            home: Scaffold(
              body: Center(
                child: LanguageToggleButton(),
              ),
            ),
          ),
        ),
      );

      // Verify minimum touch target size is at least 48x48
      final buttonSize = tester.getSize(find.byType(LanguageToggleButton));
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Verify Semantics container exists
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.button == true || w.properties.label != null),
      );
      expect(semanticsFinder, findsWidgets);
    });

    testWidgets('3. TrendChartWidget builds accessible TalkBack summary for screen readers in EN and MR',
        (WidgetTester tester) async {
      const sampleTrend = TrendAnalysisResult(
        weeklySeries: [
          WeeklyDataPoint(
            weekNumber: 38,
            year: 2026,
            weekEnding: '2026-09-20',
            overallPct: 92.5,
            perSopPct: {'SOP1': 95.0, 'SOP2': 90.0},
            perSopFailCount: {},
          ),
          WeeklyDataPoint(
            weekNumber: 39,
            year: 2026,
            weekEnding: '2026-09-27',
            overallPct: 94.0,
            perSopPct: {'SOP1': 96.0, 'SOP2': 92.0},
            perSopFailCount: {},
          ),
          WeeklyDataPoint(
            weekNumber: 40,
            year: 2026,
            weekEnding: '2026-10-04',
            overallPct: 91.0,
            perSopPct: {'SOP1': 93.0, 'SOP2': 89.0},
            perSopFailCount: {},
          ),
        ],
        movingAverages: [
          MovingAveragePoint(weekNumber: 38, year: 2026, weekEnding: '2026-09-20', value: null),
          MovingAveragePoint(weekNumber: 39, year: 2026, weekEnding: '2026-09-27', value: null),
          MovingAveragePoint(weekNumber: 40, year: 2026, weekEnding: '2026-10-04', value: 92.5),
        ],
        detectedPatterns: [
          TrendPattern(
            type: TrendPatternType.slowSlide,
            nameEn: 'Slow Slide',
            nameMr: 'हळूहळू घसरण',
            descriptionEn: '3 consecutive weeks of decline',
            descriptionMr: 'सलग ३ आठवडे घसरण',
            severity: 'warning',
          ),
        ],
        hasSufficientData: true,
      );

      // Test English summary
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrendChartWidget(
                trendResult: sampleTrend,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      final enSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('Compliance trend chart') &&
            w.properties.label!.contains('3 weeks of data') &&
            w.properties.label!.contains('Latest compliance: 91.0%') &&
            w.properties.label!.contains('1 pattern detected'),
      );
      expect(enSemantics, findsOneWidget);

      // Verify chart canvas is wrapped in ExcludeSemantics so raw touch points are not announced
      expect(find.byType(ExcludeSemantics), findsWidgets);

      // Test Marathi summary
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrendChartWidget(
                trendResult: sampleTrend,
                locale: 'mr',
              ),
            ),
          ),
        ),
      );

      final mrSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('अनुपालन कल तक्ता'),
      );
      expect(mrSemantics, findsOneWidget);
    });

    test('4. Color contrast ratios meet WCAG AA >= 4.5:1 threshold for dark accents', () {
      double relativeLuminance(Color color) {
        double channelLuminance(int channel) {
          final sRGB = channel / 255.0;
          return sRGB <= 0.03928
              ? sRGB / 12.92
              : pow((sRGB + 0.055) / 1.055, 2.4).toDouble();
        }

        final argb = color.toARGB32();
        final r = (argb >> 16) & 0xFF;
        final g = (argb >> 8) & 0xFF;
        final b = argb & 0xFF;

        return 0.2126 * channelLuminance(r) +
            0.7152 * channelLuminance(g) +
            0.0722 * channelLuminance(b);
      }

      double contrastRatio(Color fg, Color bg) {
        final l1 = relativeLuminance(fg);
        final l2 = relativeLuminance(bg);
        final lighter = max(l1, l2);
        final darker = min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
      }

      // AppColors.goldDark against white and cream
      final goldDarkVsWhite = contrastRatio(AppColors.goldDark, AppColors.white);
      final goldDarkVsCream = contrastRatio(AppColors.goldDark, AppColors.cream);
      expect(
        goldDarkVsWhite,
        greaterThanOrEqualTo(4.5),
        reason: 'goldDark must meet WCAG AA 4.5:1 on white',
      );
      expect(
        goldDarkVsCream,
        greaterThanOrEqualTo(4.5),
        reason: 'goldDark must meet WCAG AA 4.5:1 on cream',
      );

      // AppColors.amberDark against white and cream
      final amberDarkVsWhite = contrastRatio(AppColors.amberDark, AppColors.white);
      final amberDarkVsCream = contrastRatio(AppColors.amberDark, AppColors.cream);
      expect(
        amberDarkVsWhite,
        greaterThanOrEqualTo(4.5),
        reason: 'amberDark must meet WCAG AA 4.5:1 on white',
      );
      expect(
        amberDarkVsCream,
        greaterThanOrEqualTo(4.5),
        reason: 'amberDark must meet WCAG AA 4.5:1 on cream',
      );

      // Primary brand Navy against white
      final navyVsWhite = contrastRatio(AppColors.navy, AppColors.white);
      expect(navyVsWhite, greaterThan(10.0));
    });
  });
}
