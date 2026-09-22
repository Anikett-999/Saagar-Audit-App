import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

/// In-memory fake database for unit tests verifying repository constraints and rules.
class FakeDatabase extends Fake implements Database, Transaction {
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
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    return await action(this);
  }

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

    if (where != null) {
      if (table == 'audits') {
        var argIdx = 0;
        if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['id'] == whereArgs[0]).toList();
        } else if (where == 'audit_id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['id'] == whereArgs[0]).toList();
        } else {
          if (where.contains("status IN ('submitted', 'verified')")) {
            results = results
                .where((r) => r['status'] == 'submitted' || r['status'] == 'verified')
                .toList();
          }
          if (where.contains("audit_type = 'daily'")) {
            results = results.where((r) => r['audit_type'] == 'daily').toList();
          }
          if (where.contains("status = 'submitted'") && !where.contains("status IN")) {
            results = results.where((r) => r['status'] == 'submitted').toList();
          }
          if (where.contains('auditor_id = ?') && whereArgs != null && argIdx < whereArgs.length) {
            final auditorId = whereArgs[argIdx++];
            results = results.where((r) => r['auditor_id'] == auditorId).toList();
          }
        }
      } else if (table == 'caps') {
        var argIdx = 0;
        if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['id'] == whereArgs[0]).toList();
        } else if (where == 'origin_audit_id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['origin_audit_id'] == whereArgs[0]).toList();
        } else if (where == 'origin_result_id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['origin_result_id'] == whereArgs[0]).toList();
        } else if (where.startsWith('id LIKE ?') && !where.contains('problem_statement') && whereArgs != null && whereArgs.isNotEmpty) {
          final prefix = (whereArgs[0] as String).replaceAll('%', '');
          results = results.where((r) => (r['id'] as String? ?? '').startsWith(prefix)).toList();
        } else {
          // SM role scoping
          if (where.contains('responsible_user_id = ? OR origin_audit_id IN') && whereArgs != null) {
            final smId = whereArgs[argIdx++];
            if (argIdx < whereArgs.length) argIdx++; // consume second arg for subquery
            final auditList = tables['audits'] ?? [];
            final authoredAuditIds = auditList
                .where((a) => a['auditor_id'] == smId)
                .map((a) => a['id'] as String)
                .toSet();
            results = results.where((r) {
              final resp = r['responsible_user_id'] as String?;
              final origAudit = r['origin_audit_id'] as String?;
              return resp == smId || (origAudit != null && authoredAuditIds.contains(origAudit));
            }).toList();
          }

          // Status filter
          if (where.contains("status IN ('open', 'reopened')")) {
            results = results
                .where((r) => r['status'] == 'open' || r['status'] == 'reopened')
                .toList();
          } else if (where.contains("status = 'done'")) {
            results = results.where((r) => r['status'] == 'done').toList();
          } else if (where.contains("status = 'aged'")) {
            final nowStr = (whereArgs != null && argIdx < whereArgs.length)
                ? (whereArgs[argIdx++] as String)
                : DateTime.now().toIso8601String().substring(0, 10);
            results = results.where((r) {
              final st = r['status'] as String? ?? '';
              final dl = r['deadline'] as String? ?? '';
              return st == 'aged' || ((st == 'open' || st == 'reopened') && dl.compareTo(nowStr) < 0);
            }).toList();
          } else if (where.contains("status IN ('closed', 'verified')")) {
            results = results
                .where((r) => r['status'] == 'closed' || r['status'] == 'verified')
                .toList();
          }

          // Search text
          if (where.contains('problem_statement LIKE ? OR id LIKE ?') && whereArgs != null && argIdx < whereArgs.length) {
            final pattern = (whereArgs[argIdx++] as String).replaceAll('%', '').toLowerCase();
            if (argIdx < whereArgs.length) argIdx++; // second arg
            results = results.where((r) {
              final ps = (r['problem_statement'] as String? ?? '').toLowerCase();
              final id = (r['id'] as String? ?? '').toLowerCase();
              return ps.contains(pattern) || id.contains(pattern);
            }).toList();
          }
        }
      } else {
        if (where == 'is_active = 1') {
          results = results
              .where((r) => r['is_active'] == 1 || r['is_active'] == true)
              .toList();
        } else if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['id'] == whereArgs[0]).toList();
        } else if (where == 'id = ? AND is_active = 1' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results
              .where(
                (r) =>
                    r['id'] == whereArgs[0] &&
                    (r['is_active'] == 1 || r['is_active'] == true),
              )
              .toList();
        } else if (where == 'cap_id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['cap_id'] == whereArgs[0]).toList();
        } else if (where == 'audit_id = ? AND checkpoint_id = ?' && whereArgs != null && whereArgs.length >= 2) {
          results = results
              .where(
                (r) =>
                    r['audit_id'] == whereArgs[0] &&
                    r['checkpoint_id'] == whereArgs[1],
              )
              .toList();
        } else if (where == 'audit_id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['audit_id'] == whereArgs[0]).toList();
        } else if (where == 'audit_result_id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
          results = results.where((r) => r['audit_result_id'] == whereArgs[0]).toList();
        }
      }
    }

    if (orderBy != null) {
      if (orderBy.contains('name')) {
        results.sort((a, b) {
          final na = (a['name'] as String? ?? '').toLowerCase();
          final nb = (b['name'] as String? ?? '').toLowerCase();
          return na.compareTo(nb);
        });
      } else if (orderBy.contains('sequence')) {
        results.sort((a, b) {
          final sa = a['sequence'] as int? ?? 0;
          final sb = b['sequence'] as int? ?? 0;
          return sa.compareTo(sb);
        });
      } else if (orderBy.contains('submitted_at DESC')) {
        results.sort((a, b) {
          final sa = a['submitted_at'] as String? ?? '';
          final sb = b['submitted_at'] as String? ?? '';
          return sb.compareTo(sa);
        });
      } else if (orderBy.contains('deadline ASC')) {
        results.sort((a, b) {
          final da = a['deadline'] as String? ?? '';
          final db = b['deadline'] as String? ?? '';
          return da.compareTo(db);
        });
      } else if (orderBy.contains('timestamp ASC')) {
        results.sort((a, b) {
          final ta = a['timestamp'] as String? ?? '';
          final tb = b['timestamp'] as String? ?? '';
          return ta.compareTo(tb);
        });
      }
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

    if (offset != null && offset > 0) {
      if (offset >= results.length) {
        results = [];
      } else {
        results = results.sublist(offset);
      }
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
