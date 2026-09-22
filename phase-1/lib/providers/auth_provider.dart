import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/db/database.dart';

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
}

class AuthState {
  const AuthState({
    this.user,
    this.failureTimestamps = const [],
    this.lockoutUntil,
  });

  final AuthUser? user;
  final List<DateTime> failureTimestamps;
  final DateTime? lockoutUntil;

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
    bool clearUser = false,
    bool clearLockout = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      failureTimestamps: failureTimestamps ?? this.failureTimestamps,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
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

  /// Per Spec §5 S4 & Hard Rule #4: 5 wrong PINs within 60 seconds triggers
  /// a 60-second lockout. We track attempts in a rolling 60-second window.
  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(seconds: 60);

  /// Restores persisted lockout and failed attempts across app restarts (DEF-01).
  Future<void> loadPersistedState({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;

      final lockoutStr = p.getString(_prefLockoutUntil);
      DateTime? lockout;
      if (lockoutStr != null) {
        final parsed = DateTime.tryParse(lockoutStr);
        if (parsed != null && parsed.isAfter(DateTime.now())) {
          lockout = parsed;
        } else {
          await p.remove(_prefLockoutUntil);
        }
      }

      final failuresList = p.getStringList(_prefFailures);
      final now = DateTime.now();
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
      );
    } catch (_) {
      // Safe fallback if shared_preferences channel is unavailable (e.g. pure unit tests)
    }
  }

  Future<void> _persistState() async {
    try {
      final p = _prefs ?? await SharedPreferences.getInstance();
      _prefs = p;
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
    } catch (_) {
      // Safe fallback if shared_preferences channel is unavailable
    }
  }

  /// Look up a user by id from the local DB and verify their PIN.
  /// Returns true on success and updates [state.user]; false otherwise.
  Future<bool> tryLogin({required String userId, required String pin}) async {
    if (state.isLockedOut) return false;

    final db = AppDatabase.instance.db;
    final rows = await db.query(
      'users',
      where: 'id = ? AND is_active = 1',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return registerFailure();

    final row = rows.first;
    final hash = row['pin_hash']! as String;

    if (!BCrypt.checkpw(pin, hash)) return registerFailure();

    // Success — clear lockout state, failure timestamps, and stamp last_login_at.
    await _clearPersistedLockout();
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
    state = AuthState(
      user: AuthUser(
        id: row['id']! as String,
        name: row['name']! as String,
        role: row['role']! as String,
        languagePref: row['language_pref']! as String,
      ),
    );
    return true;
  }

  Future<void>? lastPersistOperation;

  /// Registers a failed attempt within the rolling 60s window.
  /// If 5 failures occur within 60s, a 60s lockout is triggered.
  bool registerFailure({DateTime? at}) {
    final now = at ?? DateTime.now();
    final recent = state.failureTimestamps
        .where((t) => now.difference(t).inSeconds < 60)
        .toList()
      ..add(now);

    if (recent.length >= _maxAttempts) {
      state = state.copyWith(
        failureTimestamps: const [],
        lockoutUntil: now.add(_lockoutDuration),
      );
    } else {
      state = state.copyWith(failureTimestamps: recent);
    }
    lastPersistOperation = _persistState();
    return false;
  }

  void logout() {
    state = const AuthState();
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
