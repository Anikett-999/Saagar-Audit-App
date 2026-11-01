import 'dart:async';
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/db/database.dart';
import '../services/store_account_service.dart';

/// Logged-in user identity. Null when nobody is logged in.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.languagePref,
  });

  final String id;
  final String name;
  final String role; // 'SM' | 'GM' | 'OWNER'
  final String languagePref;

  bool get isOwner => role == 'OWNER';
  bool get isGm => role == 'GM';
  bool get isSm => role == 'SM';
}

/// Per-user lockout tracking to isolate failures and enforce progressive lockout (Item 8 / F23).
class UserLockoutInfo {
  const UserLockoutInfo({
    this.failureTimestamps = const [],
    this.lockoutUntil,
    this.consecutiveLockouts = 0,
  });

  factory UserLockoutInfo.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final rawFailures = (json['failures'] as List<dynamic>?) ?? [];
    final validFailures = <DateTime>[];
    for (final s in rawFailures) {
      final dt = DateTime.tryParse(s.toString());
      if (dt != null && now.difference(dt).inSeconds < 60) {
        validFailures.add(dt);
      }
    }
    DateTime? lockout;
    final rawLockout = json['lockoutUntil'] as String?;
    if (rawLockout != null) {
      final parsed = DateTime.tryParse(rawLockout);
      if (parsed != null && parsed.isAfter(now)) {
        lockout = parsed;
      }
    }
    return UserLockoutInfo(
      failureTimestamps: validFailures,
      lockoutUntil: lockout,
      consecutiveLockouts: (json['consecutiveLockouts'] as num?)?.toInt() ?? 0,
    );
  }

  final List<DateTime> failureTimestamps;
  final DateTime? lockoutUntil;
  final int consecutiveLockouts;

  int get failedAttempts {
    final now = DateTime.now();
    return failureTimestamps
        .where((t) => now.difference(t).inSeconds < 60)
        .length;
  }

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  Duration get lockoutRemaining {
    if (lockoutUntil == null) return Duration.zero;
    final left = lockoutUntil!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  UserLockoutInfo copyWith({
    List<DateTime>? failureTimestamps,
    DateTime? lockoutUntil,
    int? consecutiveLockouts,
    bool clearLockout = false,
  }) {
    return UserLockoutInfo(
      failureTimestamps: failureTimestamps ?? this.failureTimestamps,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      consecutiveLockouts: consecutiveLockouts ?? this.consecutiveLockouts,
    );
  }

  Map<String, dynamic> toJson() => {
        'failures': failureTimestamps.map((t) => t.toIso8601String()).toList(),
        'lockoutUntil': lockoutUntil?.toIso8601String(),
        'consecutiveLockouts': consecutiveLockouts,
      };
}

class AuthState {
  const AuthState({
    this.user,
    this.failureTimestamps = const [],
    this.lockoutUntil,
    this.userLockouts = const {},
  });

  final AuthUser? user;
  final List<DateTime> failureTimestamps;
  final DateTime? lockoutUntil;
  final Map<String, UserLockoutInfo> userLockouts;

  /// Returns true if the specific user (or fallback global) is locked out.
  bool isUserLockedOut(String? userId) {
    if (userId == null) {
      return isLockedOut;
    }
    final info = userLockouts[userId];
    if (info == null) return false;
    return info.isLockedOut;
  }

  /// Returns remaining lockout duration for a specific user.
  Duration userLockoutRemaining(String? userId) {
    if (userId == null) {
      return lockoutRemaining;
    }
    final info = userLockouts[userId];
    if (info == null) return Duration.zero;
    return info.lockoutRemaining;
  }

  /// Returns count of recent failed attempts for a specific user in rolling 60s.
  int userFailedAttempts(String? userId) {
    if (userId == null) {
      return failedAttempts;
    }
    final info = userLockouts[userId];
    if (info == null) return 0;
    return info.failedAttempts;
  }

  int get failedAttempts {
    final now = DateTime.now();
    return failureTimestamps
        .where((t) => now.difference(t).inSeconds < 60)
        .length;
  }

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  Duration get lockoutRemaining {
    if (lockoutUntil == null) return Duration.zero;
    final left = lockoutUntil!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  AuthState copyWith({
    AuthUser? user,
    List<DateTime>? failureTimestamps,
    DateTime? lockoutUntil,
    Map<String, UserLockoutInfo>? userLockouts,
    bool clearUser = false,
    bool clearLockout = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      failureTimestamps: failureTimestamps ?? this.failureTimestamps,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      userLockouts: userLockouts ?? this.userLockouts,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(const AuthState()) {
    loadPersistedState();
  }

  SharedPreferences? _prefs;
  static const _prefLockoutUntil = 'auth_lockout_until';
  static const _prefFailures = 'auth_failure_timestamps';
  static const _prefUserLockouts = 'auth_user_lockouts_v2';

  /// Per Spec §5 S4 & Hard Rule #4: 5 wrong PINs within 60 seconds triggers
  /// lockout. We track attempts in a rolling 60-second window.
  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(seconds: 60);

  /// Progressive lockout duration based on consecutive lockout count:
  /// 1st = 60s (1 min), 2nd = 300s (5 min), 3rd+ = 900s (15 min).
  static Duration getLockoutDuration(int consecutiveCount) {
    if (consecutiveCount <= 1) {
      return const Duration(seconds: 60);
    } else if (consecutiveCount == 2) {
      return const Duration(minutes: 5);
    } else {
      return const Duration(minutes: 15);
    }
  }

  /// Restores persisted lockout and failed attempts across app restarts (DEF-01 / Item 8).
  Future<void> loadPersistedState({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      final now = DateTime.now();

      // Per-user lockout restoration
      final userLockouts = <String, UserLockoutInfo>{};
      final rawUserLockoutsStr = p.getString(_prefUserLockouts);
      if (rawUserLockoutsStr != null) {
        try {
          final decoded = jsonDecode(rawUserLockoutsStr) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            final info = UserLockoutInfo.fromJson(entry.value as Map<String, dynamic>);
            if (info.isLockedOut || info.failedAttempts > 0) {
              userLockouts[entry.key] = info;
            }
          }
        } catch (_) {}
      }

      // Legacy global fallback
      final lockoutStr = p.getString(_prefLockoutUntil);
      DateTime? lockout;
      if (lockoutStr != null) {
        final parsed = DateTime.tryParse(lockoutStr);
        if (parsed != null && parsed.isAfter(now)) {
          lockout = parsed;
        } else {
          await p.remove(_prefLockoutUntil);
        }
      }

      final failuresList = p.getStringList(_prefFailures);
      final validFailures = <DateTime>[];
      if (failuresList != null) {
        for (final s in failuresList) {
          final dt = DateTime.tryParse(s);
          if (dt != null && now.difference(dt).inSeconds < 60) {
            validFailures.add(dt);
          }
        }
      }

      state = state.copyWith(
        lockoutUntil: lockout,
        clearLockout: lockout == null,
        failureTimestamps: validFailures,
        userLockouts: userLockouts,
      );
    } catch (_) {
      // Safe fallback if shared_preferences channel is unavailable (e.g. pure unit tests)
    }
  }

  Future<void> _persistState() async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;

      // Save per-user lockouts
      final mapData = <String, dynamic>{};
      for (final entry in state.userLockouts.entries) {
        mapData[entry.key] = entry.value.toJson();
      }
      await p.setString(_prefUserLockouts, jsonEncode(mapData));

      // Legacy keys
      if (state.lockoutUntil != null) {
        await p.setString(
          _prefLockoutUntil,
          state.lockoutUntil!.toIso8601String(),
        );
      } else {
        await p.remove(_prefLockoutUntil);
      }
      await p.setStringList(
        _prefFailures,
        state.failureTimestamps.map((t) => t.toIso8601String()).toList(),
      );
    } catch (_) {
      // Safe fallback if shared_preferences channel is unavailable
    }
  }

  Future<void> _clearPersistedLockout() async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
      await p.remove(_prefLockoutUntil);
      await p.remove(_prefFailures);
      await p.remove(_prefUserLockouts);
    } catch (_) {
      // Safe fallback if shared_preferences channel is unavailable
    }
  }

  Future<void> _clearUserLockout(String userId) async {
    try {
      final updatedLockouts = Map<String, UserLockoutInfo>.from(state.userLockouts)..remove(userId);
      state = state.copyWith(
        userLockouts: updatedLockouts,
        clearLockout: true,
        failureTimestamps: const [],
      );
      await _persistState();
    } catch (_) {}
  }

  Future<void> _logSecurityLockout(
    String userId,
    Duration duration,
    int consecutive,
    DateTime lockoutEnd,
    DateTime now,
  ) async {
    try {
      final db = AppDatabase.instance.db;
      await db.insert('audit_log', {
        'table_name': 'users',
        'row_id': userId,
        'operation': 'update',
        'actor_user_id': userId,
        'payload_json': jsonEncode({
          'event': 'pin_lockout',
          'lockout_duration_seconds': duration.inSeconds,
          'consecutive_lockouts': consecutive,
          'locked_until': lockoutEnd.toIso8601String(),
        }),
        'timestamp': now.toUtc().toIso8601String(),
      });
    } catch (_) {
      // Safe fallback if database is not open (e.g. unit tests)
    }
  }

  /// Look up a user by id from the local DB and verify their PIN.
  /// Returns true on success and updates [state.user]; false otherwise.
  Future<bool> tryLogin({required String userId, required String pin}) async {
    if (state.isUserLockedOut(userId)) return false;

    final db = AppDatabase.instance.db;
    final rows = await db.query(
      'users',
      where: 'id = ? AND is_active = 1',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return registerFailureForUser(userId);

    final row = rows.first;
    final hash = row['pin_hash']! as String;

    if (!BCrypt.checkpw(pin, hash)) return registerFailureForUser(userId);

    // Success — clear lockout state for this user and stamp last_login_at.
    await _clearUserLockout(userId);
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    state = state.copyWith(
      user: AuthUser(
        id: row['id']! as String,
        name: row['name']! as String,
        role: row['role']! as String,
        languagePref: row['language_pref']! as String,
      ),
    );
    unawaited(
      StoreAccountService.instance.recordDeviceHeartbeat(
        userName: row['name'] as String?,
        userRole: row['role'] as String?,
      ),
    );
    return true;
  }

  Future<void>? lastPersistOperation;

  /// Registers a failed attempt for a specific user within rolling 60s window.
  /// 5 failures within 60s triggers progressive lockout (60s -> 5m -> 15m).
  bool registerFailureForUser(String userId, {DateTime? at}) {
    final now = at ?? DateTime.now();

    // 1. Maintain global legacy state (for backward compatibility and tests)
    final recentGlobal = state.failureTimestamps
        .where((t) => now.difference(t).inSeconds < 60)
        .toList()
      ..add(now);

    DateTime? globalLockout;
    if (recentGlobal.length >= _maxAttempts) {
      globalLockout = now.add(_lockoutDuration);
    }

    // 2. Per-user tracking
    final targetUserId = userId;
    final existingInfo = state.userLockouts[targetUserId] ?? const UserLockoutInfo();
    final recentUser = existingInfo.failureTimestamps
        .where((t) => now.difference(t).inSeconds < 60)
        .toList()
      ..add(now);

    UserLockoutInfo updatedInfo;
    if (recentUser.length >= _maxAttempts) {
      final newConsecutive = existingInfo.consecutiveLockouts + 1;
      final duration = getLockoutDuration(newConsecutive);
      final lockoutEnd = now.add(duration);
      updatedInfo = existingInfo.copyWith(
        failureTimestamps: const [],
        lockoutUntil: lockoutEnd,
        consecutiveLockouts: newConsecutive,
      );
      _logSecurityLockout(targetUserId, duration, newConsecutive, lockoutEnd, now);
    } else {
      updatedInfo = existingInfo.copyWith(
        failureTimestamps: recentUser,
      );
    }

    final updatedLockouts = Map<String, UserLockoutInfo>.from(state.userLockouts)
      ..[targetUserId] = updatedInfo;

    state = state.copyWith(
      failureTimestamps: globalLockout != null ? const [] : recentGlobal,
      lockoutUntil: globalLockout,
      clearLockout: globalLockout == null,
      userLockouts: updatedLockouts,
    );
    lastPersistOperation = _persistState();
    return false;
  }

  /// Registers a failed attempt within the rolling 60s window.
  /// Preserves exact signature for compatibility with mock implementations.
  bool registerFailure({DateTime? at}) {
    return registerFailureForUser('default', at: at);
  }

  void logout() {
    state = const AuthState();
    _clearPersistedLockout();
  }

  /// Updates language preference of the current logged-in user in memory.
  void updateUserLanguagePref(String languagePref) {
    if (state.user != null) {
      state = state.copyWith(
        user: AuthUser(
          id: state.user!.id,
          name: state.user!.name,
          role: state.user!.role,
          languagePref: languagePref,
        ),
      );
    }
  }

  /// Sets the active user directly (used after first-time setup or PIN recovery).
  void setCurrentUser(AuthUser user) {
    state = state.copyWith(user: user);
  }

  /// Clears any lockout for a user (e.g. after successful PIN reset with recovery code).
  Future<void> unlockUser(String userId) async {
    await _clearUserLockout(userId);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

/// Bcrypt-hashes a 4-digit PIN. Cost 10 per Spec §4.1.
String hashPin(String pin) => BCrypt.hashpw(pin, BCrypt.gensalt(logRounds: 10));

/// Creates a new user row in the local DB and returns its UUID. Used by S3
/// First-Time Setup (creates Owner) and S29 Manage Users (creates SM/GM).
Future<String> createUser({
  required String name,
  required String role, // 'SM' | 'GM' | 'OWNER'
  required String pin,
  String? phone,
  String languagePref = 'en',
  String? createdBy,
}) async {
  final db = AppDatabase.instance.db;
  final id = const Uuid().v4();
  await db.insert('users', {
    'id': id,
    'name': name,
    'role': role,
    'pin_hash': hashPin(pin),
    'language_pref': languagePref,
    'phone': phone,
    'is_active': 1,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'created_by': createdBy,
  });
  return id;
}
