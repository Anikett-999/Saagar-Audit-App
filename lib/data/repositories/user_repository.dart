import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/user.dart';

/// Repository for application users (Owner, GM, SM).
///
/// Implements Spec §S29, §S30, §S31 and Table 4.1 rules:
/// - Single-Owner rule: cannot add a second Owner.
/// - Immutability of history: users are deactivated, never hard-deleted.
/// - Role permissions: Owner can add SM/GM, deactivate, reset PINs.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  /// Lists all users including inactive, ordered alphabetically by name.
  Future<List<User>> listAll() async {
    final rows = await AppDatabase.instance.db.query(
      'users',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(User.fromMap).toList();
  }

  /// Lists active users only, ordered alphabetically by name.
  Future<List<User>> listActive() async {
    final rows = await AppDatabase.instance.db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(User.fromMap).toList();
  }

  /// Gets a single user by ID, or returns null if not found.
  Future<User?> getById(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  /// Adds a new SM or GM user.
  ///
  /// Throws [ArgumentError] if role is 'OWNER' or invalid.
  /// Spec §S29 strictly mandates: "Cannot have more than 1 Owner."
  Future<String> addUser({
    required String name,
    required String role,
    required String pinHash,
    String? phone,
    String languagePref = 'en',
    String? createdBy,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.length < 2 || trimmedName.length > 50) {
      throw ArgumentError(
        'User name must be between 2 and 50 characters (got ${trimmedName.length}).',
      );
    }

    if (role == 'OWNER') {
      throw ArgumentError(
        'Cannot create user with role OWNER. Only 1 Owner is permitted per Spec §S29.',
      );
    }

    if (role != 'SM' && role != 'GM') {
      throw ArgumentError(
        'Invalid role "$role". Allowed roles to create are "SM" or "GM" per Spec §S29.',
      );
    }

    if (languagePref != 'en' && languagePref != 'mr') {
      throw ArgumentError('Language preference must be "en" or "mr".');
    }

    final id = const Uuid().v4();
    await AppDatabase.instance.db.insert('users', {
      'id': id,
      'name': trimmedName,
      'role': role,
      'pin_hash': pinHash,
      'language_pref': languagePref,
      'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      'is_active': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'created_by': createdBy,
    });
    return id;
  }

  /// Deactivates a user. Per Spec §S29:
  /// "Cannot delete users (audit trail integrity). Only deactivate."
  ///
  /// Throws [StateError] if attempting to deactivate the sole Owner.
  Future<void> deactivate(String id) async {
    final user = await getById(id);
    if (user != null && user.isOwner) {
      throw StateError('Cannot deactivate the Owner per Spec §S29.');
    }

    await AppDatabase.instance.db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reactivates a previously deactivated user.
  Future<void> reactivate(String id) async {
    await AppDatabase.instance.db.update(
      'users',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Resets a user's PIN (performed by Owner in S29).
  Future<void> resetPin(String id, String newPinHash) async {
    await AppDatabase.instance.db.update(
      'users',
      {'pin_hash': newPinHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Changes a user's PIN (performed by self in S30).
  Future<void> changePin(String id, String newPinHash) async {
    await AppDatabase.instance.db.update(
      'users',
      {'pin_hash': newPinHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates language preference for a user (performed in S31).
  Future<void> updateLanguagePref(String id, String languagePref) async {
    if (languagePref != 'en' && languagePref != 'mr') {
      throw ArgumentError('Language preference must be "en" or "mr".');
    }

    await AppDatabase.instance.db.update(
      'users',
      {'language_pref': languagePref},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
