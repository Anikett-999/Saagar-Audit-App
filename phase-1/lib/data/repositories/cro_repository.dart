import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/cro.dart';

class CroRepository {
  CroRepository._();
  static final CroRepository instance = CroRepository._();

  Future<List<Cro>> listActive() async {
    final rows = await AppDatabase.instance.db.query(
      'cros',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Cro.fromMap).toList();
  }

  /// Lists all CROs including inactive ones, ordered alphabetically.
  /// Needed for S28 Manage CROs.
  Future<List<Cro>> listAll() async {
    final rows = await AppDatabase.instance.db.query(
      'cros',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Cro.fromMap).toList();
  }

  /// Gets a single CRO by ID.
  Future<Cro?> getById(String id) async {
    final rows = await AppDatabase.instance.db.query(
      'cros',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Cro.fromMap(rows.first);
  }

  Future<String> add({
    required String name,
    required String counter,
    String shift = 'flexible',
  }) async {
    final id = const Uuid().v4();
    await AppDatabase.instance.db.insert('cros', {
      'id': id,
      'name': name.trim(),
      'counter': counter,
      'shift': shift,
      'is_active': 1,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    });
    return id;
  }

  /// Updates CRO details.
  Future<void> update({
    required String id,
    required String name,
    required String counter,
    required String shift,
    bool? isActive,
  }) async {
    final values = <String, Object?>{
      'name': name.trim(),
      'counter': counter,
      'shift': shift,
    };
    if (isActive != null) {
      values['is_active'] = isActive ? 1 : 0;
    }
    await AppDatabase.instance.db.update(
      'cros',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deactivate(String id) async {
    await AppDatabase.instance.db.update(
      'cros',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reactivate(String id) async {
    await AppDatabase.instance.db.update(
      'cros',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
