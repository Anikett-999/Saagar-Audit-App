import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/backup_service.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/ui/screens/s32_backup_export/backup_export_screen.dart';
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
  void updateUserLanguagePref(String languagePref) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createBackupExportTestWidget({
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
          home: const BackupExportScreen(),
        );
      },
    ),
  );
}

Future<void> pumpBackupExport(
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
    createBackupExportTestWidget(
      authState: authState,
      localeNotifier: localeNotifier,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S32 Backup & Export Tests (Spec §S32 & Sprint Plan)', () {
    late FakeDatabase fakeDb;
    late Directory tempDir;

    const testOwner = AuthUser(
      id: 'owner-uuid-001',
      name: 'Aniket Owner',
      role: 'OWNER',
      languagePref: 'en',
    );

    const testSm = AuthUser(
      id: 'sm-uuid-001',
      name: 'Suresh SM',
      role: 'SM',
      languagePref: 'en',
    );

    const ownerAuth = AuthState(user: testOwner);
    const smAuth = AuthState(user: testSm);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed initial data across tables
      fakeDb.tables['users']!.add({
        'id': 'owner-uuid-001',
        'name': 'Aniket Owner',
        'role': 'OWNER',
        'pin_hash': r'$2a$10$hashedSecurityPin',
        'language_pref': 'en',
        'phone': '9876543210',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
      });

      fakeDb.tables['cros']!.add({
        'id': 'cro-uuid-001',
        'name': 'Rahul Shinde',
        'counter': 'Titan',
        'shift': 'morning',
        'is_active': 1,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });

      fakeDb.tables['sops']!.add({
        'id': 'SOP1',
        'number': 1,
        'name_en': 'Store Opening',
        'name_mr': 'दुकान उघडणे',
        'weight': 2,
        'is_critical': 1,
        'display_order': 1,
      });

      tempDir = await Directory.systemTemp.createTemp('saagar_backup_test_');
      BackupService.instance.setDirectoryForTesting(tempDir);
    });

    tearDown(() async {
      AppDatabase.instance.setDatabaseForTesting(null);
      BackupService.instance.setDirectoryForTesting(null);
      try {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('BackupService exports all 14 schema tables with accurate metadata and sensitive hashes', () async {
      final jsonResult = await BackupService.instance.exportDatabaseToJson(database: fakeDb);

      expect(jsonResult['app_name'], 'Saagar Audit App');
      expect(jsonResult['app_version'], '0.1.0+1');
      expect(jsonResult['schema_version'], 1);
      expect(jsonResult['tables_count'], 14);

      final tables = jsonResult['tables'] as Map<String, dynamic>;
      expect(tables.length, 14);

      // Verify all 14 schema tables exist in the export
      for (final table in BackupService.kDatabaseTables) {
        expect(tables.containsKey(table), isTrue, reason: 'Missing table $table in export');
      }

      // Check record counts and sensitive field presence
      final users = tables['users'] as List;
      expect(users.length, 1);
      expect(users.first['name'], 'Aniket Owner');
      expect(users.first['pin_hash'], r'$2a$10$hashedSecurityPin');

      final cros = tables['cros'] as List;
      expect(cros.length, 1);
      expect(cros.first['name'], 'Rahul Shinde');

      expect(jsonResult['total_records'], 3);
    });

    test('BackupService writes timestamped JSON file to target directory', () async {
      final result = await BackupService.instance.exportAndSaveToFile(
        database: fakeDb,
        targetDir: tempDir,
      );

      expect(result.tableCount, 14);
      expect(result.totalRecords, 3);
      expect(result.fileName, startsWith('saagar_audit_backup_'));
      expect(result.fileName, endsWith('.json'));

      final file = File(result.filePath);
      expect(file.existsSync(), isTrue);

      final fileContent = await file.readAsString();
      final parsed = jsonDecode(fileContent) as Map<String, dynamic>;
      expect(parsed['tables_count'], 14);
      expect(parsed['total_records'], 3);
    });

    testWidgets('Renders all core sections, security notice, and about card', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpBackupExport(
        tester,
        authState: ownerAuth,
        localeNotifier: localeNotifier,
      );

      expect(find.text('Backup & Export'), findsOneWidget);
      expect(find.text('Local SQLite Database Export & Cloud Sync'), findsOneWidget);
      expect(find.text('Export Local Database (JSON)'), findsOneWidget);
      expect(find.text('Security Notice: Exported backup contains audit trails, findings, and bcrypt security hashes. Store and transfer this file securely.'), findsOneWidget);
      expect(find.text('Export Database JSON'), findsOneWidget);
      expect(find.text('About Saagar Audit App'), findsOneWidget);
      expect(find.text('Version: 0.1.0+1 (Phase 1 Baseline)'), findsOneWidget);
    });

    testWidgets('Owner sees Firestore Cloud Sync section with Coming in Phase 4 badge and disabled button', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpBackupExport(
        tester,
        authState: ownerAuth,
        localeNotifier: localeNotifier,
      );

      // Cloud Sync Section is visible for Owner
      expect(find.text('Cloud Synchronization (Firestore)'), findsOneWidget);
      expect(find.textContaining('Coming in Phase 4'), findsNWidgets(3)); // Badge, notice, and button text
      expect(find.text('Status: Offline-First Mode (Local SQLite)'), findsOneWidget);
      expect(find.text('Coming in Phase 4. All audits and settings are safely stored locally on this device.'), findsOneWidget);

      // Verify Force Sync button is disabled
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('SM user does NOT see the Owner-only Firestore Cloud Sync section', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpBackupExport(
        tester,
        authState: smAuth,
        localeNotifier: localeNotifier,
      );

      // Cloud Sync section is hidden for SM
      expect(find.text('Cloud Synchronization (Firestore)'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);

      // Core export section remains visible
      expect(find.text('Export Local Database (JSON)'), findsOneWidget);
      expect(find.text('Export Database JSON'), findsOneWidget);
    });

    testWidgets('Tapping Export Database triggers file export and displays success AlertDialog', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpBackupExport(
        tester,
        authState: ownerAuth,
        localeNotifier: localeNotifier,
      );

      // Tap Export Database button within runAsync so real File I/O completes
      await tester.runAsync(() async {
        await tester.tap(find.text('Export Database JSON'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        var pollCount = 0;
        while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty && pollCount < 120) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          pollCount++;
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify success dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Export Successful'), findsOneWidget);
      expect(find.textContaining('Backup saved successfully (3 records across 14 tables).'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap OK to dismiss
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Unauthenticated user cannot access backup export screen', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));
      await pumpBackupExport(
        tester,
        authState: const AuthState(),
        localeNotifier: localeNotifier,
      );

      // Screen content does not render
      expect(find.text('Export Local Database (JSON)'), findsNothing);
      expect(find.text('Export Database JSON'), findsNothing);
    });

    testWidgets('Renders all elements in Marathi with full localized parity (Rule #8)', (tester) async {
      final localeNotifier = FakeLocaleNotifier(const Locale('mr'));
      await pumpBackupExport(
        tester,
        authState: ownerAuth,
        localeNotifier: localeNotifier,
      );

      expect(find.text('बॅकअप व निर्यात'), findsOneWidget);
      expect(find.text('स्थानिक SQLite डेटाबेस निर्यात आणि क्लाउड समक्रमण'), findsOneWidget);
      expect(find.text('स्थानिक डेटाबेस निर्यात करा (JSON)'), findsOneWidget);
      expect(find.text('डेटाबेस JSON निर्यात करा'), findsOneWidget);
      expect(find.text('क्लाउड समक्रमण (Firestore)'), findsOneWidget);
      expect(find.textContaining('फेज ४ मध्ये येत आहे'), findsNWidgets(2));
      expect(find.text('सागर ऑडिट अॅपबद्दल'), findsOneWidget);
    });
  });
}
