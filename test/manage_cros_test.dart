import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/cro_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s28_manage_cros/manage_cros_screen.dart';

import 'helpers/fake_database.dart';

Widget createManageCrosTestWidget({
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
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
      home: const ManageCrosScreen(),
    ),
  );
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

Future<void> pumpManageCros(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(createManageCrosTestWidget(locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  group('S28 Manage CROs Screen Tests (Spec §S28 & Sprint Plan)', () {
    late FakeDatabase fakeDb;

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Shows empty state when no CROs exist in database', (tester) async {
      await pumpManageCros(tester);

      expect(find.text('Manage CROs'), findsOneWidget);
      expect(find.text('No CROs found. Tap + to add the first CRO.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Lists active and inactive CROs with proper status chips', (tester) async {
      fakeDb.tables['cros']!.addAll([
        {
          'id': 'cro-1',
          'name': 'Rahul Shinde',
          'counter': 'Titan',
          'shift': 'morning',
          'is_active': 1,
          'joined_at': '2026-09-01T08:00:00.000Z',
        },
        {
          'id': 'cro-2',
          'name': 'Pooja Patil',
          'counter': 'Helios',
          'shift': 'afternoon',
          'is_active': 0,
          'joined_at': '2026-09-01T08:00:00.000Z',
        },
      ]);

      await pumpManageCros(tester);

      expect(find.text('Rahul Shinde'), findsOneWidget);
      expect(find.text('Titan • Morning'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);

      expect(find.text('Pooja Patil'), findsOneWidget);
      expect(find.text('Helios • Afternoon'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Reactivate'), findsOneWidget);
    });

    testWidgets('Add CRO dialog validates input and saves to database', (tester) async {
      await pumpManageCros(tester);

      // Tap floating action button "+ Add CRO"
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add CRO'), findsWidgets); // Appbar/Dialog title
      expect(find.text('CRO Full Name'), findsOneWidget);

      // Try submitting empty -> should show validation error
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid name (minimum 2 characters)'), findsOneWidget);

      // Fill in name
      await tester.enterText(find.byType(TextFormField), 'Amit Verma');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog dismissed, new CRO appears in list
      expect(find.text('Amit Verma'), findsOneWidget);
      expect(find.text('Titan • Morning'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Verify in database
      final allCros = await CroRepository.instance.listAll();
      expect(allCros.length, 1);
      expect(allCros.first.name, 'Amit Verma');
      expect(allCros.first.counter, 'Titan');
      expect(allCros.first.shift, 'morning');
      expect(allCros.first.isActive, isTrue);
    });

    testWidgets('Edit CRO dialog modifies details correctly', (tester) async {
      fakeDb.tables['cros']!.add({
        'id': 'cro-edit-1',
        'name': 'Mahesh Joshi',
        'counter': 'Titan',
        'shift': 'morning',
        'is_active': 1,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageCros(tester);

      expect(find.text('Mahesh Joshi'), findsOneWidget);

      // Tap Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit CRO'), findsOneWidget);

      // Edit name
      await tester.enterText(find.byType(TextFormField), 'Mahesh R. Joshi');
      await tester.pumpAndSettle();

      // Select Helios counter
      await tester.tap(find.text('Helios'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Check updated on screen
      expect(find.text('Mahesh R. Joshi'), findsOneWidget);
      expect(find.text('Helios • Morning'), findsOneWidget);

      final updated = await CroRepository.instance.getById('cro-edit-1');
      expect(updated!.name, 'Mahesh R. Joshi');
      expect(updated.counter, 'Helios');
    });

    testWidgets('Deactivate CRO dialog confirms and updates repository preserving history', (tester) async {
      fakeDb.tables['cros']!.add({
        'id': 'cro-deact-1',
        'name': 'Sneha Kulkarni',
        'counter': 'Titan',
        'shift': 'morning',
        'is_active': 1,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageCros(tester);

      expect(find.text('Active'), findsOneWidget);

      // Tap Deactivate
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      // Confirm dialog appears with audit preservation note
      expect(find.text('Deactivate CRO?'), findsOneWidget);
      expect(
        find.textContaining('This CRO will be hidden from new audits'),
        findsOneWidget,
      );

      // Tap Cancel -> should stay active
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);

      // Tap Deactivate again and Confirm
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      // Tap Deactivate button inside dialog
      final dialogDeactivateBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Deactivate'),
      );
      await tester.tap(dialogDeactivateBtn);
      await tester.pumpAndSettle();

      // Status is now Inactive and Reactivate button shows
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Reactivate'), findsOneWidget);

      // Verify repository behavior:
      // Must NOT be in listActive() (disappears from new audit pickers)
      final active = await CroRepository.instance.listActive();
      expect(active.any((c) => c.id == 'cro-deact-1'), isFalse);

      // Must STILL be in listAll() (preserved for audit trail)
      final all = await CroRepository.instance.listAll();
      expect(all.any((c) => c.id == 'cro-deact-1'), isTrue);
    });

    testWidgets('Reactivate CRO restores status to active', (tester) async {
      fakeDb.tables['cros']!.add({
        'id': 'cro-react-1',
        'name': 'Nitin Kale',
        'counter': 'Helios',
        'shift': 'flexible',
        'is_active': 0,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageCros(tester);

      expect(find.text('Inactive'), findsOneWidget);

      // Tap Reactivate
      await tester.tap(find.text('Reactivate'));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);

      // Verify in repository
      final active = await CroRepository.instance.listActive();
      expect(active.any((c) => c.id == 'cro-react-1'), isTrue);
    });

    testWidgets('Renders all elements in Marathi with full localized parity (Rule #8)', (tester) async {
      fakeDb.tables['cros']!.add({
        'id': 'cro-mr-1',
        'name': 'सचिन तेंडुलकर',
        'counter': 'Titan',
        'shift': 'morning',
        'is_active': 1,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });

      await pumpManageCros(tester, locale: const Locale('mr'));

      // Title
      expect(find.text('सीआरओ व्यवस्थापन'), findsOneWidget);

      // CRO Card details
      expect(find.text('सचिन तेंडुलकर'), findsOneWidget);
      expect(find.text('टायटन • सकाळ'), findsOneWidget);
      expect(find.text('सक्रिय'), findsOneWidget);
      expect(find.text('संपादित करा'), findsOneWidget);
      expect(find.text('निष्क्रिय करा'), findsOneWidget);

      // Add CRO FAB
      expect(find.text('नवीन सीआरओ जोडा'), findsOneWidget);

      // Open Add dialog and check Marathi labels
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('सीआरओचे पूर्ण नाव'), findsOneWidget);
      expect(find.text('काउंटर'), findsOneWidget);
      expect(find.text('टायटन'), findsWidgets);
      expect(find.text('हेलिओस'), findsOneWidget);
      expect(find.text('शिफ्ट'), findsOneWidget);
      expect(find.text('सक्रिय स्थिती'), findsOneWidget);
      expect(find.text('जतन करा'), findsOneWidget);
      expect(find.text('रद्द करा'), findsOneWidget);
    });
  });
}
