import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'db/database.dart';

/// Per-install device identity. The UUID persists across app restarts but
/// resets on reinstall (SharedPreferences is wiped). Good enough for Spec
/// §4.2 — used to attribute audits and cap_log to a device.
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const _prefKey = 'device_id';
  static const _prefNicknameKey = 'device_nickname';
  static const _prefModelKey = 'device_model';

  String? _cachedId;
  String? _testModel;

  void configureForTesting({String? model}) {
    _testModel = model;
  }

  Future<String> getId() async {
    final cached = _cachedId;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_prefKey, id);
    }
    _cachedId = id;

    // Upsert into devices table if DB is open so audit FKs resolve.
    if (AppDatabase.instance.isOpen) {
      try {
        final db = AppDatabase.instance.db;
        await db.insert(
          'devices',
          {
            'id': id,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
            'sync_state': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (_) {}
    }
    return id;
  }

  /// Returns the hardware manufacturer and model (e.g. "Xiaomi Redmi Note 12").
  Future<String> getDeviceModelName() async {
    if (_testModel != null) return _testModel!;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefModelKey);
    if (cached != null && cached.isNotEmpty) return cached;

    String modelName = 'Store Terminal';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand.trim();
        final model = androidInfo.model.trim();
        if (brand.isNotEmpty && model.isNotEmpty) {
          final capitalizedBrand =
              brand.length > 1 ? brand[0].toUpperCase() + brand.substring(1) : brand.toUpperCase();
          if (model.toLowerCase().startsWith(brand.toLowerCase())) {
            modelName = model;
          } else {
            modelName = '$capitalizedBrand $model';
          }
        } else if (model.isNotEmpty) {
          modelName = model;
        } else {
          modelName = 'Android Device';
        }
      } else if (Platform.isWindows) {
        modelName = 'Windows Workstation';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        modelName = iosInfo.name;
      }
    } catch (_) {}

    await prefs.setString(_prefModelKey, modelName);
    return modelName;
  }

  /// Returns the custom device nickname given by the Store Owner (e.g. "Owner Phone", "Counter Tablet").
  Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefNicknameKey);
  }

  /// Sets a custom nickname for this device.
  Future<void> setNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNicknameKey, nickname.trim());
  }
}
