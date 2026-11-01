import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/db/database.dart';
import '../data/device_service.dart';
import 'cloud_sync_service.dart';

/// Exception thrown when attempting to pair a device after reaching the store limit (Max 2 devices).
class StoreDeviceLimitReachedException implements Exception {
  const StoreDeviceLimitReachedException([
    this.message = 'Store device limit reached (2/2 devices connected). Contact Owner to authorize a new device.',
  ]);
  final String message;

  @override
  String toString() => message;
}

/// Abstract cloud adapter seam for store credentials and device authorization.
abstract class StoreAccountCloudAdapter {
  Future<String?> fetchPasscodeHash(String storeCode);
  Future<void> savePasscodeHash(String storeCode, String hash);
  Future<List<Map<String, dynamic>>> fetchAuthorizedDevices(String storeCode);
  Future<void> registerDevice(String storeCode, Map<String, dynamic> deviceData);
  Future<void> updateDeviceMetadata(String storeCode, String deviceId, Map<String, dynamic> metadata);
  Future<void> revokeDevice(String storeCode, String deviceId);
  Future<bool> isDeviceAuthorized(String storeCode, String deviceId);
}

/// Production Firestore implementation of [StoreAccountCloudAdapter].
class FirestoreStoreAccountAdapter implements StoreAccountCloudAdapter {
  const FirestoreStoreAccountAdapter();

  static const _timeout = Duration(seconds: 4);

  @override
  Future<String?> fetchPasscodeHash(String storeCode) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeCode)
          .collection('config')
          .doc('security')
          .get()
          .timeout(_timeout);
      if (doc.exists) {
        return doc.data()?['store_passcode_hash'] as String?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> savePasscodeHash(String storeCode, String hash) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeCode)
        .collection('config')
        .doc('security')
        .set({
      'store_code': storeCode,
      'store_passcode_hash': hash,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': 'owner',
    }, SetOptions(merge: true),)
    .timeout(_timeout);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAuthorizedDevices(String storeCode) async {
    if (Firebase.apps.isEmpty) return [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeCode)
          .collection('devices')
          .where('is_authorized', isEqualTo: true)
          .get()
          .timeout(_timeout);
      return snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> registerDevice(String storeCode, Map<String, dynamic> deviceData) async {
    if (Firebase.apps.isEmpty) return;
    final deviceId = deviceData['device_id'] as String;
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeCode)
        .collection('devices')
        .doc(deviceId)
        .set({
      ...deviceData,
      'enrolled_at': FieldValue.serverTimestamp(),
      'last_seen_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true),)
    .timeout(_timeout);
  }

  @override
  Future<void> updateDeviceMetadata(
    String storeCode,
    String deviceId,
    Map<String, dynamic> metadata,
  ) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeCode)
        .collection('devices')
        .doc(deviceId)
        .set(metadata, SetOptions(merge: true))
        .timeout(_timeout);
  }

  @override
  Future<void> revokeDevice(String storeCode, String deviceId) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeCode)
        .collection('devices')
        .doc(deviceId)
        .set({
      'is_authorized': false,
      'revoked_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true),)
    .timeout(_timeout);
  }

  @override
  Future<bool> isDeviceAuthorized(String storeCode, String deviceId) async {
    if (Firebase.apps.isEmpty) return true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeCode)
          .collection('devices')
          .doc(deviceId)
          .get()
          .timeout(_timeout);
      if (!doc.exists) return true;
      return doc.data()?['is_authorized'] != false;
    } catch (_) {
      return true;
    }
  }
}

/// Service managing device-level Store Account pairing, passcode rotation,
/// and tenant authorization (Spec §1.2 & Client Ref: F27).
///
/// Prevents unauthenticated APK installs from reading or writing store data in Firebase.
/// Latur Combo Store: Titan World (WLMHW) & Helios (HEMW).
class StoreAccountService {
  StoreAccountService._();
  static final StoreAccountService instance = StoreAccountService._();

  static const String _prefStoreCodeKey = 'store_account_code';
  static const String _prefStoreNameKey = 'store_account_name';
  static const String _prefStorePairedKey = 'store_account_paired';
  static const String _prefStorePairedAtKey = 'store_account_paired_at';
  static const String _prefCustomPasscodeHashKey = 'store_account_passcode_hash';

  /// Primary store code representing the Saagar Traders combo store in Latur.
  static const String defaultStoreCode = 'WLMHW';
  static const String defaultStoreName = 'Saagar Traders — Latur (WLMHW & HEMW)';

  /// Authorized store passcode for Latur location.
  /// Known only to Saagar Traders management.
  static const String authorizedStoreKey = 'ST-LATUR-2026';

  /// Alternative accepted key formats for convenience (case-insensitive, ignores hyphens/spaces).
  static const List<String> _acceptedKeys = [
    'ST-LATUR-2026',
    'STLATUR2026',
    'SAAGAR2026',
    'WLMHW2026',
  ];

  StoreAccountCloudAdapter? _testCloudAdapter;

  /// Visible for testing to inject mock cloud adapter.
  @visibleForTesting
  void configureForTesting({StoreAccountCloudAdapter? cloudAdapter}) {
    _testCloudAdapter = cloudAdapter;
  }

  StoreAccountCloudAdapter get _cloudAdapter =>
      _testCloudAdapter ?? const FirestoreStoreAccountAdapter();

  /// Checks whether this device is currently signed in / paired to an authorized store account.
  Future<bool> isDevicePaired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefStorePairedKey) ?? false;
  }

  /// Gets the paired store code, or null if not paired.
  Future<String?> getPairedStoreCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefStoreCodeKey);
  }

  /// Gets the paired store name, or default combo store name if paired.
  Future<String?> getPairedStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefStoreNameKey);
  }

  /// Validates whether a given store key matches the authorized passcode
  /// (checks local hash, cloud hash if available, or factory keys).
  Future<bool> validatePasscode(
    String storeKey, {
    String storeCode = defaultStoreCode,
  }) async {
    final cleanKey = storeKey.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    final customHash = prefs.getString(_prefCustomPasscodeHashKey);

    // 1. Check local custom hash first
    if (customHash != null && customHash.isNotEmpty) {
      try {
        return BCrypt.checkpw(cleanKey, customHash);
      } catch (_) {
        return false;
      }
    }

    // 2. If online and cloud adapter available, check remote rotated hash
    final hasNet = await CloudSyncService.instance.isNetworkAvailable();
    if (hasNet) {
      try {
        final remoteHash = await _cloudAdapter.fetchPasscodeHash(storeCode);
        if (remoteHash != null && remoteHash.isNotEmpty) {
          if (BCrypt.checkpw(cleanKey, remoteHash)) {
            // Cache rotated hash locally
            await prefs.setString(_prefCustomPasscodeHashKey, remoteHash);
            return true;
          } else {
            // A rotated hash exists in cloud and doesn't match: factory key is revoked
            return false;
          }
        }
      } catch (_) {}
    }

    // 3. Fallback to factory keys ONLY if no custom/remote passcode is set
    return _acceptedKeys.any(
      (k) => k.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase() == cleanKey,
    );
  }

  /// Pairs this device with the store account using the store passcode.
  /// Throws [SocketException] if device is offline.
  /// Returns true on success, false if the passcode is invalid.
  Future<bool> pairStoreAccount({
    required String storeKey,
    String storeCode = defaultStoreCode,
    String storeName = defaultStoreName,
  }) async {
    final hasNet = await CloudSyncService.instance.isNetworkAvailable();
    if (!hasNet) {
      throw const SocketException('Internet connection required to sign in to store account.');
    }

    final isValid = await validatePasscode(storeKey, storeCode: storeCode);
    if (!isValid) return false;

    final deviceId = await DeviceService.instance.getId();
    final model = await DeviceService.instance.getDeviceModelName();
    final nickname = await DeviceService.instance.getNickname();

    // Register this device with the store cloud account
    try {
      await _cloudAdapter.registerDevice(storeCode, {
        'device_id': deviceId,
        'model': model,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
        'is_authorized': true,
        'enrolled_at': DateTime.now().toUtc().toIso8601String(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('StoreAccountService.pairStoreAccount registration notice: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefStorePairedKey, true);
    await prefs.setString(_prefStoreCodeKey, storeCode);
    await prefs.setString(_prefStoreNameKey, storeName);
    await prefs.setString(_prefStorePairedAtKey, DateTime.now().toUtc().toIso8601String());

    // Upsert into local SQLite devices table
    if (AppDatabase.instance.isOpen) {
      try {
        final db = AppDatabase.instance.db;
        await db.insert(
          'devices',
          {
            'id': deviceId,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
            'sync_state': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }

    return true;
  }

  /// Rotates the store passcode. Requires active internet connection.
  /// Throws [SocketException] if offline.
  /// Updates cloud configuration first, then saves locally to avoid split-brain.
  Future<bool> rotateStorePasscode({
    required String currentPasscode,
    required String newPasscode,
    String storeCode = defaultStoreCode,
  }) async {
    // Edge case 1: Internet connection check
    final hasNet = await CloudSyncService.instance.isNetworkAvailable();
    if (!hasNet) {
      throw const SocketException('Internet connection required to update Store Passcode.');
    }

    // Edge case 2: Validate current passcode
    final isCurrentValid = await validatePasscode(currentPasscode, storeCode: storeCode);
    if (!isCurrentValid) return false;

    // Edge case 3: Validate new passcode length & format
    final cleanNew = newPasscode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleanNew.length < 6) return false;

    // Edge case 4: BCrypt hash generation
    final salt = BCrypt.gensalt(logRounds: 10);
    final newHash = BCrypt.hashpw(cleanNew, salt);

    // Edge case 5: Atomic cloud update (if this fails, local is untouched)
    await _cloudAdapter.savePasscodeHash(storeCode, newHash);

    // Save locally only after cloud write succeeds
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCustomPasscodeHashKey, newHash);
    return true;
  }

  /// Checks whether this device is authorized in the cloud (remote kill switch check).
  Future<bool> isCurrentDeviceAuthorized({String storeCode = defaultStoreCode}) async {
    final deviceId = await DeviceService.instance.getId();
    return await _cloudAdapter.isDeviceAuthorized(storeCode, deviceId);
  }

  /// Updates the device nickname in cloud and local cache.
  Future<void> updateDeviceNickname({
    required String deviceId,
    required String nickname,
    String storeCode = defaultStoreCode,
  }) async {
    final currentId = await DeviceService.instance.getId();
    if (deviceId == currentId) {
      await DeviceService.instance.setNickname(nickname);
    }
    final code = await getPairedStoreCode() ?? storeCode;
    try {
      await _cloudAdapter.updateDeviceMetadata(code, deviceId, {
        'nickname': nickname.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('updateDeviceNickname remote notice: $e');
    }
  }

  /// Records heartbeat information (model, nickname, last active user) on sync or login.
  Future<void> recordDeviceHeartbeat({
    String? userName,
    String? userRole,
    String storeCode = defaultStoreCode,
  }) async {
    final isPaired = await isDevicePaired();
    if (!isPaired) return;
    final deviceId = await DeviceService.instance.getId();
    final code = await getPairedStoreCode() ?? storeCode;
    final model = await DeviceService.instance.getDeviceModelName();
    final nickname = await DeviceService.instance.getNickname();
    final payload = <String, dynamic>{
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      'model': model,
    };
    if (nickname != null && nickname.isNotEmpty) {
      payload['nickname'] = nickname;
    }
    if (userName != null && userName.isNotEmpty) {
      payload['last_user_name'] = userName;
    }
    if (userRole != null && userRole.isNotEmpty) {
      payload['last_user_role'] = userRole;
    }
    try {
      await _cloudAdapter.updateDeviceMetadata(code, deviceId, payload);
    } catch (_) {}
  }

  /// Fetches the list of authorized store devices (for Owner in Screen S32).
  Future<List<Map<String, dynamic>>> getAuthorizedDevices({String storeCode = defaultStoreCode}) async {
    final devices = await _cloudAdapter.fetchAuthorizedDevices(storeCode);
    final currentId = await DeviceService.instance.getId();
    final currentNickname = await DeviceService.instance.getNickname();
    final currentModel = await DeviceService.instance.getDeviceModelName();

    final result = <Map<String, dynamic>>[];
    bool foundCurrent = false;

    for (final d in devices) {
      final copy = Map<String, dynamic>.from(d);
      if (copy['device_id'] == currentId) {
        foundCurrent = true;
        if ((copy['nickname'] == null || (copy['nickname'] as String).isEmpty) &&
            currentNickname != null &&
            currentNickname.isNotEmpty) {
          copy['nickname'] = currentNickname;
        }
        if (copy['model'] == null || copy['model'] == 'Store Device') {
          copy['model'] = currentModel;
        }
      }
      result.add(copy);
    }

    if (!foundCurrent) {
      result.insert(0, {
        'device_id': currentId,
        'model': currentModel,
        if (currentNickname != null && currentNickname.isNotEmpty) 'nickname': currentNickname,
        'is_authorized': true,
        'enrolled_at': DateTime.now().toUtc().toIso8601String(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    return result;
  }

  /// Revokes remote device access (Kill Switch executed by Owner).
  Future<void> revokeRemoteDevice({
    required String deviceId,
    String storeCode = defaultStoreCode,
  }) async {
    await _cloudAdapter.revokeDevice(storeCode, deviceId);
  }

  /// Disconnects this device from the store account (performed by Owner only).
  Future<void> unpairStoreAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefStorePairedKey);
    await prefs.remove(_prefStoreCodeKey);
    await prefs.remove(_prefStoreNameKey);
    await prefs.remove(_prefStorePairedAtKey);
  }
}
