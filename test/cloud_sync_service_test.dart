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
import 'package:saagar_audit_app/services/store_account_service.dart';
import 'package:saagar_audit_app/ui/screens/s32_backup_export/backup_export_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

/// Test mock adapter implementing CloudSyncAdapter seam.
class TestCloudSyncAdapter implements CloudSyncAdapter {
  final Map<String, List<Map<String, dynamic>>> pushedData = {};
  final Map<String, List<Map<String, dynamic>>> mockRemoteData = {};
  int uploadedPhotosCount = 0;
  String? failPushCollection;
  String? failPullCollection;

  @override
  Future<int> pushRecords(String collection, List<Map<String, dynamic>> records) async {
    if (collection == failPushCollection) {
      throw StateError('push failed for $collection');
    }
    pushedData.putIfAbsent(collection, () => []).addAll(records);
    return records.length;
  }

  @override
  Future<List<Map<String, dynamic>>> pullRecords(String collection, DateTime? since) async {
    if (collection == failPullCollection) {
      throw StateError('pull failed for $collection');
    }
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

/// Test mock adapter for Store Account cloud operations.
class TestStoreAccountCloudAdapter implements StoreAccountCloudAdapter {
  String? cloudPasscodeHash;
  final List<Map<String, dynamic>> devices = [];

  @override
  Future<String?> fetchPasscodeHash(String storeCode) async => cloudPasscodeHash;

  @override
  Future<void> savePasscodeHash(String storeCode, String hash) async {
    cloudPasscodeHash = hash;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAuthorizedDevices(String storeCode) async {
    return devices.where((d) => d['is_authorized'] == true).toList();
  }

  @override
  Future<void> registerDevice(String storeCode, Map<String, dynamic> deviceData) async {
    final idx = devices.indexWhere((d) => d['device_id'] == deviceData['device_id']);
    if (idx >= 0) {
      devices[idx] = Map<String, dynamic>.from(deviceData);
    } else {
      devices.add(Map<String, dynamic>.from(deviceData));
    }
  }

  @override
  Future<void> updateDeviceMetadata(
    String storeCode,
    String deviceId,
    Map<String, dynamic> metadata,
  ) async {
    final idx = devices.indexWhere((d) => d['device_id'] == deviceId);
    if (idx >= 0) {
      devices[idx].addAll(metadata);
    }
  }

  @override
  Future<void> revokeDevice(String storeCode, String deviceId) async {
    final idx = devices.indexWhere((d) => d['device_id'] == deviceId);
    if (idx >= 0) {
      devices[idx]['is_authorized'] = false;
    }
  }

  @override
  Future<bool> isDeviceAuthorized(String storeCode, String deviceId) async {
    final dev = devices.firstWhere(
      (d) => d['device_id'] == deviceId,
      orElse: () => {'is_authorized': true},
    );
    return dev['is_authorized'] != false;
  }
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
    fakeConnectivity.currentResults = [ConnectivityResult.wifi];

    CloudSyncService.instance.configureForTesting(
      database: fakeDb,
      adapter: testAdapter,
      connectivity: fakeConnectivity,
    );
    StoreAccountService.instance.configureForTesting(cloudAdapter: TestStoreAccountCloudAdapter());

    await StoreAccountService.instance.pairStoreAccount(storeKey: 'ST-LATUR-2026');
  });

  group('CloudSyncService Core Logic Tests', () {
    test('Store Account Security Gate: unauthenticated device is strictly blocked from cloud sync (F27)', () async {
      await StoreAccountService.instance.unpairStoreAccount();

      final result = await CloudSyncService.instance.syncAll();
      expect(result.success, isFalse);
      expect(result.status, equals(CloudSyncStatus.unconfigured));
      expect(result.message, contains('Device is not signed in to an authorized store account'));
      expect(testAdapter.pushedData.isEmpty, isTrue);
    });

    test('Offline resilience: returns SyncResult.offline when no network', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.none];

      final result = await CloudSyncService.instance.syncAll();
      expect(result.success, isFalse);
      expect(result.status, equals(CloudSyncStatus.offline));
      expect(testAdapter.pushedData.isEmpty, isTrue);
    });

    test('A failed table push returns an error and does not advance the sync checkpoint', () async {
      fakeDb.tables['audits']!.add({
        'id': 'audit_retry',
        'status': 'submitted',
        'created_at': DateTime.now().toIso8601String(),
      });
      testAdapter.failPushCollection = 'audits';

      final result = await CloudSyncService.instance.syncAll(force: true);
      final prefs = await SharedPreferences.getInstance();

      expect(result.success, isFalse);
      expect(result.status, equals(CloudSyncStatus.error));
      expect(result.message, contains('Failed to push audits'));
      expect(prefs.getString(CloudSyncService.prefKeyLastSync), isNull);
    });

    test('A failed table pull returns an error and does not advance the sync checkpoint', () async {
      testAdapter.failPullCollection = 'cros';

      final result = await CloudSyncService.instance.syncAll(force: true);
      final prefs = await SharedPreferences.getInstance();

      expect(result.success, isFalse);
      expect(result.status, equals(CloudSyncStatus.error));
      expect(result.message, contains('Failed to pull cros'));
      expect(prefs.getString(CloudSyncService.prefKeyLastSync), isNull);
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

    test('Inbound sync applies every pull page beyond Firestore page size', () async {
      testAdapter.mockRemoteData['cros'] = List.generate(
        225,
        (index) => {
          'id': 'cro_page_$index',
          'name': 'CRO $index',
          'counter': 'Titan',
          'shift': 'morning',
          'is_active': 1,
          'joined_at': '2026-10-02T10:00:00Z',
        },
      );

      final result = await CloudSyncService.instance.syncAll();

      expect(result.success, isTrue);
      expect(result.pulledRecords, equals(225));
      expect(fakeDb.tables['cros']!.length, equals(225));
    });

    test('Role-Based Inbound Scoping: SM cannot pull users, reports, or escalations', () async {
      testAdapter.mockRemoteData['users'] = [
        {'id': 'u_gm_1', 'name': 'GM User', 'role': 'GM'},
      ];
      testAdapter.mockRemoteData['cros'] = [
        {'id': 'cro_1', 'name': 'Staff 1', 'is_active': 1},
      ];
      testAdapter.mockRemoteData['reports'] = [
        {'id': 'rep_1', 'type': 'weekly_strategic'},
      ];
      testAdapter.mockRemoteData['escalations'] = [
        {'id': 'esc_1', 'target_role': 'OWNER'},
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
      expect(
        localAudits.any((a) => a['id'] == 'a_weekly_1'),
        isFalse,
        reason: 'SM must never pull weekly/managerial audits',
      );

      final localUsers = fakeDb.tables['users']!;
      expect(
        localUsers.any((u) => u['id'] == 'u_gm_1'),
        isFalse,
        reason: 'SM must never pull user profiles',
      );

      final localReports = fakeDb.tables['reports']!;
      expect(
        localReports.any((r) => r['id'] == 'rep_1'),
        isFalse,
        reason: 'SM must never pull managerial reports',
      );

      final localEscalations = fakeDb.tables['escalations']!;
      expect(
        localEscalations.any((e) => e['id'] == 'esc_1'),
        isFalse,
        reason: 'SM must never pull managerial escalations',
      );
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
        },
      ];

      final result = await CloudSyncService.instance.syncAll(userRole: 'OWNER');
      expect(result.success, isTrue);

      final localUsers = fakeDb.tables['users']!;
      final ownerUser = localUsers.firstWhere((u) => u['id'] == 'u_owner_1');
      expect(
        ownerUser['pin_hash'],
        equals('existing_secure_local_hash'),
        reason: 'Inviolable Rule: Local pin_hash must NEVER be overwritten by cloud pull',
      );
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

    testWidgets('S32 displays Store Account Tenant Shield and Auto-Sync switch', (tester) async {
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

      // Verify Store Account Card is present and connected
      expect(find.text('Store Account (Tenant Shield)'), findsOneWidget);
      expect(find.text('Store Account Connected'), findsOneWidget);
      expect(find.textContaining('Saagar Traders — Latur (WLMHW & HEMW)'), findsWidgets);

      // Verify Auto-Sync switch is present
      expect(find.text('Automatic Background Sync'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('S32 prompts for Store Passcode when device is unpaired', (tester) async {
      await StoreAccountService.instance.unpairStoreAccount();

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

      // Unpaired state: shows Store Account Required and Sign In button
      expect(find.text('Store Account Required'), findsOneWidget);
      final connectBtn = find.text('Sign In to Store Account');
      expect(connectBtn, findsOneWidget);

      // Tap Sign In to Store Account button
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Store Account Sign-In'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter invalid passcode
      await tester.enterText(find.byType(TextField), 'WRONG-KEY');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Error shown
      expect(find.text('Invalid store passcode. Please check and try again.'), findsOneWidget);

      // Enter valid passcode
      await tester.enterText(find.byType(TextField), 'ST-LATUR-2026');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Success SnackBar and dialog closed
      expect(find.text('Device successfully paired to store account.'), findsOneWidget);
      expect(find.text('Store Account Connected'), findsOneWidget);
    });

    test('Store Account Pairing requires active internet (throws SocketException if offline)', () async {
      await StoreAccountService.instance.unpairStoreAccount();
      fakeConnectivity.currentResults = [ConnectivityResult.none];
      expect(
        () => StoreAccountService.instance.pairStoreAccount(storeKey: 'ST-LATUR-2026'),
        throwsA(isA<SocketException>()),
      );
    });

    test('Passcode Rotation requires active internet (throws SocketException if offline)', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.none];
      expect(
        () => StoreAccountService.instance.rotateStorePasscode(
          currentPasscode: 'ST-LATUR-2026',
          newPasscode: 'ST-LATUR-OCT26',
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('Passcode Rotation validates current passcode and minimum length', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.wifi];
      // Invalid current passcode
      final invalidCurrent = await StoreAccountService.instance.rotateStorePasscode(
        currentPasscode: 'WRONG-OLD-CODE',
        newPasscode: 'ST-LATUR-OCT26',
      );
      expect(invalidCurrent, isFalse);

      // Too short new passcode (< 6 chars)
      final tooShort = await StoreAccountService.instance.rotateStorePasscode(
        currentPasscode: 'ST-LATUR-2026',
        newPasscode: 'ABC',
      );
      expect(tooShort, isFalse);
    });

    test('Passcode Rotation updates cloud adapter and caches BCrypt hash', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.wifi];
      final testCloud = TestStoreAccountCloudAdapter();
      StoreAccountService.instance.configureForTesting(cloudAdapter: testCloud);

      final success = await StoreAccountService.instance.rotateStorePasscode(
        currentPasscode: 'ST-LATUR-2026',
        newPasscode: 'ST-LATUR-OCT26',
      );
      expect(success, isTrue);
      expect(testCloud.cloudPasscodeHash, isNotNull);

      // Old passcode is now rejected
      final oldValid = await StoreAccountService.instance.validatePasscode('ST-LATUR-2026');
      expect(oldValid, isFalse);

      // New passcode is accepted
      final newValid = await StoreAccountService.instance.validatePasscode('ST-LATUR-OCT26');
      expect(newValid, isTrue);
    });

    test('Multiple devices (Owner, SM, GM, surplus) can pair seamlessly without arbitrary limit', () async {
      final testCloud = TestStoreAccountCloudAdapter();
      testCloud.devices.addAll([
        {'device_id': 'owner-phone', 'is_authorized': true},
        {'device_id': 'sm-phone', 'is_authorized': true},
        {'device_id': 'gm-phone', 'is_authorized': true},
      ]);
      StoreAccountService.instance.configureForTesting(cloudAdapter: testCloud);

      // 4th surplus tablet pairs successfully with valid passcode
      final paired = await StoreAccountService.instance.pairStoreAccount(storeKey: 'ST-LATUR-2026');
      expect(paired, isTrue);
      expect(await StoreAccountService.instance.isDevicePaired(), isTrue);
    });

    test('Remote Kill Switch: revoked device is uncoupled during sync pass', () async {
      await StoreAccountService.instance.unpairStoreAccount();
      final testCloud = TestStoreAccountCloudAdapter();
      StoreAccountService.instance.configureForTesting(cloudAdapter: testCloud);

      // Pair device
      await StoreAccountService.instance.pairStoreAccount(storeKey: 'ST-LATUR-2026');
      expect(await StoreAccountService.instance.isDevicePaired(), isTrue);

      // Simulate Owner revoking this device remotely
      final deviceId = testCloud.devices.first['device_id'] as String;
      await StoreAccountService.instance.revokeRemoteDevice(deviceId: deviceId);

      // Sync attempt detects revocation
      final result = await CloudSyncService.instance.syncAll();
      expect(result.success, isFalse);
      expect(result.message, contains('revoked by store Owner'));
      expect(await StoreAccountService.instance.isDevicePaired(), isFalse);
    });
    test('Owner can rename devices and device heartbeat records user role and active time', () async {
      await StoreAccountService.instance.unpairStoreAccount();
      final testCloud = TestStoreAccountCloudAdapter();
      StoreAccountService.instance.configureForTesting(cloudAdapter: testCloud);

      await StoreAccountService.instance.pairStoreAccount(storeKey: 'ST-LATUR-2026');
      final devices = await StoreAccountService.instance.getAuthorizedDevices();
      expect(devices, isNotEmpty);
      final currentDev = devices.first;
      final devId = currentDev['device_id'] as String;

      // Owner renames device
      await StoreAccountService.instance.updateDeviceNickname(
        deviceId: devId,
        nickname: "Owner's Primary Phone",
      );

      final updatedDevices = await StoreAccountService.instance.getAuthorizedDevices();
      final renamedDev = updatedDevices.firstWhere((d) => d['device_id'] == devId);
      expect(renamedDev['nickname'], equals("Owner's Primary Phone"));

      // Heartbeat records user role
      await StoreAccountService.instance.recordDeviceHeartbeat(
        userName: 'Aniket',
        userRole: 'OWNER',
      );
      final heartbeatDev = (await StoreAccountService.instance.getAuthorizedDevices())
          .firstWhere((d) => d['device_id'] == devId);
      expect(heartbeatDev['last_user_name'], equals('Aniket'));
      expect(heartbeatDev['last_user_role'], equals('OWNER'));
    });
  });
}
