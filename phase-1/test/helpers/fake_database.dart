import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

/// In-memory fake database for unit tests verifying repository constraints and rules.
class FakeDatabase extends Fake implements Database {
  final Map<String, List<Map<String, Object?>>> tables = {
    'audits': [],
    'audit_results': [],
    'photos': [],
    'devices': [],
    'users': [],
    'cros': [],
    'sops': [],
    'checkpoints': [],
    'caps': [],
    'cap_actions': [],
    'cap_log': [],
    'reports': [],
    'escalations': [],
    'audit_log': [],
  };

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables.putIfAbsent(table, () => []);
    if (conflictAlgorithm == ConflictAlgorithm.replace) {
      final id = values['id'];
      if (id != null) {
        list.removeWhere((row) => row['id'] == id);
      }
      if (table == 'audit_results') {
        final auditId = values['audit_id'];
        final cpId = values['checkpoint_id'];
        list.removeWhere(
          (row) => row['audit_id'] == auditId && row['checkpoint_id'] == cpId,
        );
      }
    }
    list.add(Map<String, Object?>.from(values));
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final list = tables[table] ?? [];
    var results = List<Map<String, Object?>>.from(list);

    if (where == 'is_active = 1') {
      results = results
          .where((r) => r['is_active'] == 1 || r['is_active'] == true)
          .toList();
    } else if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      if (where == 'id = ?') {
        results = results.where((r) => r['id'] == whereArgs[0]).toList();
      } else if (where == 'id = ? AND is_active = 1') {
        results = results
            .where(
              (r) =>
                  r['id'] == whereArgs[0] &&
                  (r['is_active'] == 1 || r['is_active'] == true),
            )
            .toList();
      } else if (where == 'audit_id = ? AND checkpoint_id = ?') {
        results = results
            .where(
              (r) =>
                  r['audit_id'] == whereArgs[0] &&
                  r['checkpoint_id'] == whereArgs[1],
            )
            .toList();
      } else if (where == 'audit_id = ?') {
        results = results.where((r) => r['audit_id'] == whereArgs[0]).toList();
      } else if (where == 'audit_result_id = ?') {
        results =
            results.where((r) => r['audit_result_id'] == whereArgs[0]).toList();
      }
    }

    if (orderBy != null && orderBy.contains('name')) {
      results.sort((a, b) {
        final na = (a['name'] as String? ?? '').toLowerCase();
        final nb = (b['name'] as String? ?? '').toLowerCase();
        return na.compareTo(nb);
      });
    }

    if (columns != null && columns.isNotEmpty) {
      results = results.map((row) {
        final map = <String, Object?>{};
        for (final col in columns) {
          if (row.containsKey(col)) {
            map[col] = row[col];
          }
        }
        return map;
      }).toList();
    }

    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = tables[table] ?? [];
    var count = 0;
    for (var i = 0; i < list.length; i++) {
      var match = true;
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        if (where == "id = ? AND status = 'draft'") {
          match = list[i]['id'] == whereArgs[0] && list[i]['status'] == 'draft';
        } else if (where == 'id = ?') {
          match = list[i]['id'] == whereArgs[0];
        }
      }
      if (match) {
        final updated = Map<String, Object?>.from(list[i])..addAll(values);
        list[i] = updated;
        count++;
      }
    }
    return count;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (sql.contains('FROM users')) {
      final list = tables['users'] ?? [];
      var results = List<Map<String, Object?>>.from(list);
      if (sql.contains('is_active = 1')) {
        results = results
            .where((r) => r['is_active'] == 1 || r['is_active'] == true)
            .toList();
      }
      return results;
    }
    return [];
  }
}
