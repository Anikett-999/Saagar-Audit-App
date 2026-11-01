import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/user_repository.dart';

/// Secure service managing the Owner Master Recovery Code (Client Ref: F16).
///
/// Security Properties:
/// - Plaintext code is NEVER persisted.
/// - Salted BCrypt hash (cost factor 10) is stored in private SharedPreferences.
/// - Strictly excluded from all database exports and cloud sync payloads.
/// - Normalizes input to ignore dashes, spaces, and case (SG-XXXX-YYYY == sgxxxxyyyy).
class OwnerRecoveryService {
  OwnerRecoveryService._();
  static final OwnerRecoveryService instance = OwnerRecoveryService._();

  static const String _prefRecoveryHashKey = 'owner_recovery_code_hash';
  static const String _prefLastRecoveryGeneratedKey = 'owner_recovery_code_generated_at';

  /// Generates a readable 8-char code grouped as SG-XXXX-YYYY using
  /// unambiguous alphanumeric characters (omits 0/O, 1/I, L).
  String generateRecoveryCode() {
    const chars = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
    final random = Random.secure();
    final part1 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'SG-$part1-$part2';
  }

  /// Hashes and saves the recovery code in local private storage.
  /// The plaintext code is NEVER stored.
  Future<void> saveRecoveryCode(String plaintextCode) async {
    final cleanCode = normalizeCode(plaintextCode);
    final hash = BCrypt.hashpw(cleanCode, BCrypt.gensalt(logRounds: 10));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRecoveryHashKey, hash);
    await prefs.setString(
      _prefLastRecoveryGeneratedKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Verifies an entered recovery code against the stored BCrypt hash.
  Future<bool> verifyRecoveryCode(String enteredCode) async {
    final cleanCode = normalizeCode(enteredCode);
    if (cleanCode.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_prefRecoveryHashKey);
    if (storedHash == null || storedHash.isEmpty) return false;

    try {
      return BCrypt.checkpw(cleanCode, storedHash);
    } catch (_) {
      return false;
    }
  }

  /// Whether an owner recovery code has been provisioned.
  Future<bool> hasRecoveryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefRecoveryHashKey);
  }

  /// Resets the Owner's 4-digit PIN after verifying the recovery code.
  /// Throws [StateError] if no Owner exists in SQLite.
  Future<bool> resetOwnerPinWithRecoveryCode({
    required String recoveryCode,
    required String newPin,
  }) async {
    final valid = await verifyRecoveryCode(recoveryCode);
    if (!valid) return false;

    final owner = await UserRepository.instance.getOwner();
    if (owner == null) {
      throw StateError('Cannot reset PIN: No Owner user found in database.');
    }

    final newPinHash = BCrypt.hashpw(newPin, BCrypt.gensalt(logRounds: 10));
    await UserRepository.instance.resetPin(owner.id, newPinHash);
    return true;
  }

  /// Normalizes formatting (strips spaces, dashes, converts to uppercase).
  String normalizeCode(String code) {
    return code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }
}
