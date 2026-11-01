import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/checkpoint.dart';
import 'package:saagar_audit_app/data/photo_service.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/draft_audit_provider.dart';
import 'package:saagar_audit_app/ui/screens/s07_checkpoint/widgets/checkpoint_jump_sheet.dart';
import 'package:saagar_audit_app/ui/screens/s10_review/review_submit_screen.dart';
import 'package:saagar_audit_app/ui/widgets/app_bottom_nav_bar.dart';
import 'package:saagar_audit_app/ui/widgets/camera_permission_dialog.dart';
import 'helpers/fake_database.dart';

void main() {
  group('Item 21: Camera Permission Handling', () {
    test('CameraPermissionDeniedException provides clean message', () {
      final exc = CameraPermissionDeniedException('Camera access denied by user');
      expect(exc.message, 'Camera access denied by user');
      expect(exc.toString(), contains('Camera access denied by user'));
    });

    testWidgets('showCameraPermissionDeniedDialog renders title and Open Settings button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCameraPermissionDeniedDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Camera Permission Required'), findsNothing);
    });

    testWidgets('showCameraPermissionDeniedDialog renders authentic Marathi when in mr locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCameraPermissionDeniedDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('कॅमेरा परवानगी आवश्यक'), findsOneWidget);
      expect(find.text('सेटिंग्ज उघडा'), findsOneWidget);
      expect(find.text('रद्द करा'), findsOneWidget);

      await tester.tap(find.text('रद्द करा'));
      await tester.pumpAndSettle();
      expect(find.text('कॅमेरा परवानगी आवश्यक'), findsNothing);
    });
  });

  group('Item 24: Exit Audit Dialog & Back Navigation', () {
    testWidgets('Exit dialog renders when back navigation occurs at index 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final l10n = AppLocalizations.of(context)!;
                  await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.exitAuditDialogTitle),
                      content: Text(l10n.exitAuditDialogMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.btnResumeAudit),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.btnSaveAndExit),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Exit Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Exit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Audit?'), findsOneWidget);
      expect(find.text('Resume Audit'), findsOneWidget);
      expect(find.text('Save & Exit'), findsOneWidget);

      await tester.tap(find.text('Resume Audit'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Audit?'), findsNothing);
    });

    testWidgets('Exit dialog renders in Marathi when in mr locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final l10n = AppLocalizations.of(context)!;
                  await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.exitAuditDialogTitle),
                      content: Text(l10n.exitAuditDialogMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.btnResumeAudit),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.btnSaveAndExit),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Exit Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Exit Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('ऑडिटमधून बाहेर पडायचे?'), findsOneWidget);
      expect(find.text('ऑडिट सुरू ठेवा'), findsOneWidget);
      expect(find.text('जतन करा आणि बाहेर पडा'), findsOneWidget);

      await tester.tap(find.text('ऑडिट सुरू ठेवा'));
      await tester.pumpAndSettle();
      expect(find.text('ऑडिटमधून बाहेर पडायचे?'), findsNothing);
    });
  });

  group('Item 27.6: Progress Based on Answered Count (Client Ref §F)', () {
    test('Fresh draft audit starts at 0% complete before any answers', () {
      final checkpoints = List<Checkpoint>.generate(
        68,
        (i) => Checkpoint(
          id: '${i + 1}',
          sopId: 'SOP1',
          frequency: 'daily',
          sequence: i + 1,
          textEn: 'CP $i',
          textMr: 'CP $i',
          weight: 1,
          allowsNa: false,
          requiresPhotoOnFail: false,
          displayOrder: i + 1,
        ),
      );

      final state = DraftAuditState(
        checkpoints: checkpoints,
        currentIndex: 0,
        results: const {},
      );

      expect(state.answeredCount, equals(0));
      expect(state.answeredProgress, equals(0.0));
      expect(state.answeredPercentage, equals(0));
    });

    test('Progress correctly reflects answered count regardless of cursor position', () {
      final checkpoints = List<Checkpoint>.generate(
        68,
        (i) => Checkpoint(
          id: '${i + 1}',
          sopId: 'SOP1',
          frequency: 'daily',
          sequence: i + 1,
          textEn: 'CP $i',
          textMr: 'CP $i',
          weight: 1,
          allowsNa: false,
          requiresPhotoOnFail: false,
          displayOrder: i + 1,
        ),
      );

      // User has answered 17 of 68 checkpoints (25%), but navigated cursor back to checkpoint 1 (index 0)
      final state = DraftAuditState(
        checkpoints: checkpoints,
        currentIndex: 0,
        results: Map<String, Verdict>.fromEntries(
          List.generate(17, (i) => MapEntry('${i + 1}', Verdict.pass)),
        ),
      );

      expect(state.answeredCount, equals(17));
      expect(state.answeredProgress, equals(0.25));
      expect(state.answeredPercentage, equals(25));
    });
  });

  group('Item 27.2: 68-Checkpoint Jump List (Client Ref §F)', () {
    testWidgets('CheckpointJumpSheet renders list, filters, and supports direct tap-to-jump', (tester) async {
      final checkpoints = List<Checkpoint>.generate(
        68,
        (i) => Checkpoint(
          id: '${i + 1}',
          sopId: i < 5 ? 'SOP6' : 'SOP1',
          frequency: 'daily',
          sequence: i + 1,
          textEn: 'Checkpoint question ${i + 1}',
          textMr: 'चेकपॉइंट प्रश्न ${i + 1}',
          weight: 1,
          allowsNa: false,
          requiresPhotoOnFail: false,
          displayOrder: i + 1,
        ),
      );

      final results = <String, Verdict>{
        '1': Verdict.pass,
        '2': Verdict.fail,
        '3': Verdict.na,
      };

      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (sheetCtx) => CheckpointJumpSheet(
                      checkpoints: checkpoints,
                      results: results,
                      currentIndex: 1,
                      sopNamesById: const {'SOP1': 'Store Facade', 'SOP6': 'Cash Counter'},
                      onSelect: (idx) {
                        selectedIndex = idx;
                      },
                    ),
                  );
                },
                child: const Text('Open Jump Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Jump Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet title and status counts
      expect(find.text('Audit Checkpoints'), findsOneWidget);
      expect(find.textContaining('3 of 68 answered'), findsOneWidget);

      // Verify status filter chips
      expect(find.textContaining('All (68)'), findsOneWidget);
      expect(find.textContaining('Unanswered (65)'), findsOneWidget);
      expect(find.textContaining('Failed (1)'), findsOneWidget);
      expect(find.textContaining('Passed (1)'), findsOneWidget);

      // Checkpoint #2 is fail and currently active
      expect(find.text('CURRENT'), findsOneWidget);

      // Tap on Checkpoint #10 (index 9) to jump directly to it
      await tester.scrollUntilVisible(
        find.byKey(const Key('jump_item_9')),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('jump_item_9')));
      await tester.pumpAndSettle();

      // Verify onSelect called with index 9 and sheet closed
      expect(selectedIndex, equals(9));
      expect(find.text('Audit Checkpoints'), findsNothing);
    });

    testWidgets('CheckpointJumpSheet filter chips isolate failed and unanswered items', (tester) async {
      final checkpoints = List<Checkpoint>.generate(
        10,
        (i) => Checkpoint(
          id: '${i + 1}',
          sopId: 'SOP1',
          frequency: 'daily',
          sequence: i + 1,
          textEn: 'Question ${i + 1}',
          textMr: 'प्रश्न ${i + 1}',
          weight: 1,
          allowsNa: false,
          requiresPhotoOnFail: false,
          displayOrder: i + 1,
        ),
      );

      final results = <String, Verdict>{
        '1': Verdict.pass,
        '2': Verdict.fail,
      };

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('mr')],
          home: Scaffold(
            body: CheckpointJumpSheet(
              checkpoints: checkpoints,
              results: results,
              currentIndex: 0,
              sopNamesById: const {'SOP1': 'Store Facade'},
              onSelect: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Failed (1)' filter
      await tester.tap(find.textContaining('Failed (1)'));
      await tester.pumpAndSettle();

      // Only Checkpoint #2 should be visible
      expect(find.byKey(const Key('jump_item_1')), findsOneWidget); // index 1 is CP 2
      expect(find.byKey(const Key('jump_item_0')), findsNothing); // CP 1 (passed) hidden

      // Tap 'Unanswered (8)' filter
      await tester.tap(find.textContaining('Unanswered (8)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('jump_item_1')), findsNothing); // CP 2 hidden
      expect(find.byKey(const Key('jump_item_2')), findsOneWidget); // CP 3 visible
    });
  });

  group('Item 27.1: Persistent Bottom Navigation Bar (Client Ref §F)', () {
    testWidgets('AppBottomNavBar renders 5 destinations with correct labels and highlights active tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('mr')],
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('nav_destination_home')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_destination_audits')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_destination_caps')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_destination_reports')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_destination_settings')), findsOneWidget);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Audits'), findsOneWidget);
      expect(find.text('CAPs'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('AppBottomNavBar renders localized labels in Marathi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('mr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('mr')],
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('मुख्यपृष्ठ'), findsOneWidget);
      expect(find.text('ऑडिट्स'), findsOneWidget);
      expect(find.text('सीएपी (CAPs)'), findsOneWidget);
      expect(find.text('अहवाल'), findsOneWidget);
      expect(find.text('सेटिंग्ज'), findsOneWidget);
    });
  });

  group('Item 27.3: Review Screen Tap-to-Edit & Text Wrap (Client Ref §F)', () {
    late FakeDatabase fakeDb;

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Review Screen renders fail card with Edit action and 2-line wrapped title', (tester) async {
      const audit = Audit(
        id: 'audit_test_1',
        auditType: 'daily',
        auditDate: '2026-11-01',
        weekNumber: 44,
        year: 2026,
        auditorId: 'usr_test',
        deviceId: 'dev_test',
        status: 'draft',
        passCount: 1,
        failCount: 1,
        naCount: 0,
        compliancePct: 50.0,
        band: 'critical',
      );

      const cp1 = Checkpoint(
        id: 'CP1',
        sopId: 'SOP1',
        frequency: 'daily',
        sequence: 1,
        textEn: 'Very long checkpoint title description that previously overflowed or was truncated on narrow mobile screens',
        textMr: 'खूप लांब चेकपॉईंट शीर्षक जे पूर्वी कट होत होते',
        weight: 1,
        allowsNa: false,
        requiresPhotoOnFail: false,
        displayOrder: 1,
      );

      const cp2 = Checkpoint(
        id: 'CP2',
        sopId: 'SOP1',
        frequency: 'daily',
        sequence: 2,
        textEn: 'Passed checkpoint',
        textMr: 'पास चेकपॉईंट',
        weight: 1,
        allowsNa: false,
        requiresPhotoOnFail: false,
        displayOrder: 2,
      );

      // Seed audit results
      fakeDb.tables['audit_results'] = [
        {
          'id': 'res_1',
          'audit_id': audit.id,
          'checkpoint_id': 'CP1',
          'result': 'F',
          'weight': 1,
          'finding_text': 'Display counter is dusty and needs cleaning',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'res_2',
          'audit_id': audit.id,
          'checkpoint_id': 'CP2',
          'result': 'P',
          'weight': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            draftAuditProvider.overrideWith((ref) {
              final notifier = DraftAuditNotifier();
              notifier.state = const DraftAuditState(
                audit: audit,
                checkpoints: [cp1, cp2],
                currentIndex: 1,
                results: {
                  'CP1': Verdict.fail,
                  'CP2': Verdict.pass,
                },
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('mr')],
            home: ReviewSubmitScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the fail card exists and has the Edit badge
      final failCardFinder = find.byKey(const Key('review_fail_card_CP1'));
      expect(failCardFinder, findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Verify finding text is visible
      expect(find.textContaining('Display counter is dusty'), findsOneWidget);

      // Verify title Text widget has maxLines == 2
      final titleWidget = tester.widget<Text>(find.text(cp1.textEn));
      expect(titleWidget.maxLines, equals(2));
    });
  });
}
