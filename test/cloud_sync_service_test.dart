import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/providers/locale_provider.dart';
import 'package:saagar_audit_app/services/cloud_sync_service.dart';
import 'package:saagar_audit_app/ui/screens/s32_backup_export/backup_export_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

/// Test mock adapter implementing CloudSyncAdapter seam.
class TestCloudSyncAdapter implements CloudSyncAdapter {
  final Map<String, List<Map<String, dynamic>>> pushedData = {};
  final Map<String, List<Map<String, dynamic>>> mockRemoteData = {};
  int uploadedPhotosCount = 0;

  @override
  Future<int> pushRecords(String collection, List<Map<String, dynamic>> records) async {
    pushedData.putIfAbsent(collection, () => []).addAll(records);
    return records.length;
  }

  @override
  Future<List<Map<String, dynamic>>> pullRecords(String collection, DateTime? since) async {
    return mockRemoteData[collection] ?? [];
  }

  @override
  Future<String?> uploadPhoto(String localPath, String storagePath) async {
    uploadedPhotosCount++;
    return 'https://firebasestorage.googleapis.com/test/$storagePath';
  }
}

/// Fake Connectivity for testing online/offline states.
class FakeConnectivity extends Fake implements Connectivity {
  List<ConnectivityResult> currentResults = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(currentResults);
}

class FakeLocaleNotifier extends StateNotifier<Locale?> implements LocaleNotifier {
  FakeLocaleNotifier(super.state);
  @override
  Future<void> set(Locale locale) async => state = locale;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);
  @override
  bool registerFailure({DateTime? at}) => false;
  @override
  void logout() => state = const AuthState();
  @override
  void updateUserLanguagePref(String languagePref) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabase fakeDb;
  late TestCloudSyncAdapter testAdapter;
  late FakeConnectivity fakeConnectivity;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeDatabase();
    testAdapter = TestCloudSyncAdapter();
    fakeConnectivity = FakeConnectivity();

    CloudSyncService.instance.configureForTesting(
      database: fakeDb,
      adapter: testAdapter,
      connectivity: fakeConnectivity,
    );
  });

  group('CloudSyncService Core Logic Tests', () {
    test('Offline resilience: returns SyncResult.offline when no network', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.none];

      final result = await CloudSyncService.instance.syncAll();
      expect(result.success, isFalse);
      expect(result.status, equals(CloudSyncStatus.offline));
      expect(testAdapter.pushedData.isEmpty, isTrue);
    });

    test('Pending count calculation works for photos and audits', () async {
      // 1 pending photo
      fakeDb.tables['photos']!.add({
        'id': 'photo_1',
        'local_path': 'test/path.jpg',
        'upload_status': 'pending',
        'cloud_url': null,
      });

      // 1 completed audit
      fakeDb.tables['audits']!.add({
        'id': 'audit_1',
        'status': 'submitted',
        'created_at': DateTime.now().toIso8601String(),
      });

      final pendingCount = await CloudSyncService.instance.countPendingChanges();
      expect(pendingCount, equals(2));
    });

    test('Outbound sync pushes records and strictly strips pin_hash from users', () async {
      // Add a test user with a sensitive pin_hash
      fakeDb.tables['users']!.add({
        'id': 'u1',
        'username': 'owner',
        'role': 'OWNER',
        'pin_hash': 'secret_bcrypt_hash_12345',
        'created_at': '2026-10-01T10:00:00Z',
      });

      // Add audit and report
      fakeDb.tables['audits']!.add({
        'id': 'a1',
        'store_id': 'WLMHW',
        'status': 'submitted',
        'created_at': '2026-10-01T10:00:00Z',
      });

      final result = await CloudSyncService.instance.syncAll(force: true);
      expect(result.success, isTrue);
      expect(result.status, equals(CloudSyncStatus.success));

      // Rule 4 verification: pin_hash MUST NEVER be pushed to cloud
      final pushedUsers = testAdapter.pushedData['users'];
      expect(pushedUsers, isNotNull);
      expect(pushedUsers!.length, equals(1));
      expect(pushedUsers.first['id'], equals('u1'));
      expect(
        pushedUsers.first.containsKey('pin_hash'),
        isFalse,
        reason: 'Rule 4 violation: pin_hash leaked to cloud payload!',
      );

      // Audits pushed
      final pushedAudits = testAdapter.pushedData['audits'];
      expect(pushedAudits, isNotNull);
      expect(pushedAudits!.length, equals(1));
    });

    test('Photo upload updates local photo status to uploaded and sets cloud_url', () async {
      // Create a temporary file on disk so file.existsSync() passes
      final tempDir = Directory.systemTemp.createTempSync('photos_test');
      final tempFile = File('${tempDir.path}/test_photo.jpg')..writeAsStringSync('dummy_image_data');

      fakeDb.tables['photos']!.add({
        'id': 'photo_100',
        'local_path': tempFile.path,
        'upload_status': 'pending',
        'cloud_url': null,
      });

      final result = await CloudSyncService.instance.syncAll();
      expect(result.success, isTrue);
      expect(result.uploadedPhotos, equals(1));

      final updatedRow = fakeDb.tables['photos']!.firstWhere((r) => r['id'] == 'photo_100');
      expect(updatedRow['upload_status'], equals('uploaded'));
      expect(updatedRow['cloud_url'], isNotNull);
      expect(updatedRow['cloud_url'].toString(), contains('photo_100.jpg'));

      tempDir.deleteSync(recursive: true);
    });

    test('Inbound sync pulls remote CROs and CAPs into SQLite', () async {
      // Mock remote CRO and CAP in cloud adapter
      testAdapter.mockRemoteData['cros'] = [
        {
          'id': 'cro_remote_1',
          'store_id': 'WLMHW',
          'name': 'Pooja Patil',
          'is_active': 1,
        }
      ];

      testAdapter.mockRemoteData['caps'] = [
        {
          'id': 'cap_remote_1',
          'status': 'verified',
          'opened_at': '2026-10-02T10:00:00Z',
        }
      ];

      final result = await CloudSyncService.instance.syncAll();
      expect(result.success, isTrue);
      expect(result.pulledRecords, equals(2));

      // Verify inserted in SQLite tables
      final localCros = fakeDb.tables['cros']!;
      expect(localCros.any((c) => c['id'] == 'cro_remote_1'), isTrue);

      final localCaps = fakeDb.tables['caps']!;
      expect(localCaps.any((c) => c['id'] == 'cap_remote_1'), isTrue);
    });

    test('Role-Based Inbound Scoping: SM cannot pull users, reports, or escalations', () async {
      testAdapter.mockRemoteData['users'] = [
        {'id': 'u_gm_1', 'name': 'GM User', 'role': 'GM'}
      ];
      testAdapter.mockRemoteData['cros'] = [
        {'id': 'cro_1', 'name': 'Staff 1', 'is_active': 1}
      ];
      testAdapter.mockRemoteData['reports'] = [
        {'id': 'rep_1', 'type': 'weekly_strategic'}
      ];
      testAdapter.mockRemoteData['escalations'] = [
        {'id': 'esc_1', 'target_role': 'OWNER'}
      ];
      testAdapter.mockRemoteData['audits'] = [
        {'id': 'a_daily_1', 'audit_type': 'daily', 'status': 'submitted'},
        {'id': 'a_weekly_1', 'audit_type': 'weekly', 'status': 'submitted'},
      ];

      final result = await CloudSyncService.instance.syncAll(userRole: 'SM');
      expect(result.success, isTrue);

      // Verify SM strictly pulled cros and daily audit only
      final localCros = fakeDb.tables['cros']!;
      expect(localCros.any((c) => c['id'] == 'cro_1'), isTrue);

      final localAudits = fakeDb.tables['audits']!;
      expect(localAudits.any((a) => a['id'] == 'a_daily_1'), isTrue);
      expect(localAudits.any((a) => a['id'] == 'a_weekly_1'), isFalse,
          reason: 'SM must never pull weekly/managerial audits');

      final localUsers = fakeDb.tables['users']!;
      expect(localUsers.any((u) => u['id'] == 'u_gm_1'), isFalse,
          reason: 'SM must never pull user profiles');

      final localReports = fakeDb.tables['reports']!;
      expect(localReports.any((r) => r['id'] == 'rep_1'), isFalse,
          reason: 'SM must never pull managerial reports');

      final localEscalations = fakeDb.tables['escalations']!;
      expect(localEscalations.any((e) => e['id'] == 'esc_1'), isFalse,
          reason: 'SM must never pull managerial escalations');
    });

    test('Inviolable Security Rule: Owner sync pulls users but strictly preserves local pin_hash', () async {
      // Local user with existing pin hash
      fakeDb.tables['users']!.add({
        'id': 'u_owner_1',
        'name': 'Sagar Bora',
        'role': 'OWNER',
        'pin_hash': 'existing_secure_local_hash',
      });

      // Remote cloud user update has NO pin_hash
      testAdapter.mockRemoteData['users'] = [
        {
          'id': 'u_owner_1',
          'name': 'Sagar Bora Updated',
          'role': 'OWNER',
          'created_at': '2026-10-29T10:00:00Z',
        }
      ];

      final result = await CloudSyncService.instance.syncAll(userRole: 'OWNER');
      expect(result.success, isTrue);

      final localUsers = fakeDb.tables['users']!;
      final ownerUser = localUsers.firstWhere((u) => u['id'] == 'u_owner_1');
      expect(ownerUser['pin_hash'], equals('existing_secure_local_hash'),
          reason: 'Inviolable Rule: Local pin_hash must NEVER be overwritten by cloud pull');
    });
  });

  group('CloudSyncProvider & S32 UI Integration Tests', () {
    testWidgets('S32 renders live sync card and allows Owner to trigger sync', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const authUser = AuthUser(
        id: 'owner_1',
        name: 'Owner User',
        role: 'OWNER',
        languagePref: 'en',
      );

      const authState = AuthState(user: authUser);
      final localeNotifier = FakeLocaleNotifier(const Locale('en'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
            localeProvider.overrideWith((ref) => localeNotifier),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BackupExportScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Cloud Sync Section header and status
      expect(find.text('Cloud Synchronization'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);

      // Tap Sync Now button
      final syncBtn = find.text('Sync Now');
      await tester.ensureVisible(syncBtn);
      await tester.tap(syncBtn);
      await tester.pumpAndSettle();

      // Verify successful completion notice or status update
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
