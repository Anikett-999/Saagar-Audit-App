import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// Loads JSON seed data into the database on first launch.
///
/// Seeds the immutable reference rows (SOPs, checkpoints) — never user data.
/// The `users` table starts empty so S3 First-Time Setup is triggered.
class SeedLoader {
  SeedLoader._();

  static Future<void> loadAll(Database db) async {
    await loadSops(db);
    await loadCheckpoints(db);
  }

  static Future<void> loadSops(Database db) async {
    final raw = await rootBundle.loadString('assets/seed/sops.json');
    final List<dynamic> rows = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (final row in rows.cast<Map<String, dynamic>>()) {
      // Seed JSON allows comment-rows (keys prefixed with `_`) for human notes.
      // Skip them; only real data rows have `id`.
      if (row['id'] == null) continue;
      batch.insert(
        'sops',
        {
          'id': row['id'],
          'number': row['number'],
          'name_en': row['name_en'],
          'name_mr': row['name_mr'],
          'weight': row['weight'],
          'is_critical': row['is_critical'],
          'display_order': row['display_order'],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> loadCheckpoints(Database db) async {
    final raw = await rootBundle.loadString('assets/seed/checkpoints.json');
    final List<dynamic> rows = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (final row in rows.cast<Map<String, dynamic>>()) {
      if (row['id'] == null) continue;
      batch.rawInsert(
        '''
        INSERT INTO checkpoints (
          id, sop_id, frequency, sequence, text_en, text_mr,
          evidence_en, evidence_mr, weight, allows_na,
          requires_photo_on_fail, display_order
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          sop_id = excluded.sop_id,
          frequency = excluded.frequency,
          sequence = excluded.sequence,
          text_en = excluded.text_en,
          text_mr = excluded.text_mr,
          evidence_en = excluded.evidence_en,
          evidence_mr = excluded.evidence_mr,
          weight = excluded.weight,
          allows_na = excluded.allows_na,
          requires_photo_on_fail = excluded.requires_photo_on_fail,
          display_order = excluded.display_order
        ''',
        [
          row['id'],
          row['sop_id'],
          row['frequency'],
          row['sequence'],
          row['text_en'],
          row['text_mr'],
          row['evidence_en'],
          row['evidence_mr'],
          row['weight'],
          row['allows_na'],
          row['requires_photo_on_fail'],
          row['display_order'],
        ],
      );
    }
    await batch.commit(noResult: true);
  }
}
