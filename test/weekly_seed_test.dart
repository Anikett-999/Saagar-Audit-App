import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P2-1 Weekly Seed Integrity Tests', () {
    late List<Map<String, dynamic>> allCheckpoints;
    late List<Map<String, dynamic>> weeklyCheckpoints;
    late List<Map<String, dynamic>> allSops;

    setUpAll(() {
      final cpFile = File('assets/seed/checkpoints.json');
      final rawCp = jsonDecode(cpFile.readAsStringSync()) as List<dynamic>;
      allCheckpoints = rawCp
          .whereType<Map<String, dynamic>>()
          .where((m) => m['id'] != null)
          .toList();
      weeklyCheckpoints =
          allCheckpoints.where((m) => m['frequency'] == 'weekly').toList();

      final sopsFile = File('assets/seed/sops.json');
      final rawSops = jsonDecode(sopsFile.readAsStringSync()) as List<dynamic>;
      allSops = rawSops
          .whereType<Map<String, dynamic>>()
          .where((m) => m['id'] != null)
          .toList();
    });

    test('Total checkpoints is exactly 104 (68 daily + 36 weekly)', () {
      expect(allCheckpoints.length, 104);
      final dailyCount =
          allCheckpoints.where((m) => m['frequency'] == 'daily').length;
      expect(dailyCount, 68);
      expect(weeklyCheckpoints.length, 36);
    });

    test('SOP9 Operations is present in sops.json', () {
      final sop9 = allSops.firstWhere((s) => s['id'] == 'SOP9');
      expect(sop9['number'], 9);
      expect(sop9['name_en'], 'Operations');
      expect(sop9['name_mr'], 'कार्यात्मक कामकाज');
      expect(sop9['weight'], 1);
      expect(sop9['is_critical'], 0);
      expect(sop9['display_order'], 9);
    });

    test('All 36 weekly checkpoints have real Marathi (R3 Hard Stop — no duplicates/placeholders)', () {
      for (final cp in weeklyCheckpoints) {
        final id = cp['id'] as String;
        final textEn = cp['text_en'] as String?;
        final textMr = cp['text_mr'] as String?;
        final evidenceEn = cp['evidence_en'] as String?;
        final evidenceMr = cp['evidence_mr'] as String?;

        expect(textEn, isNotNull, reason: '$id text_en missing');
        expect(textEn!.isNotEmpty, isTrue, reason: '$id text_en empty');

        expect(textMr, isNotNull, reason: '$id text_mr missing');
        expect(textMr!.isNotEmpty, isTrue, reason: '$id text_mr empty');
        expect(textMr, isNot(contains('[MR TODO]')), reason: '$id contains placeholder');
        expect(textMr, isNot(equals(textEn)), reason: '$id text_mr must NOT duplicate text_en');

        expect(evidenceEn, isNotNull, reason: '$id evidence_en missing');
        expect(evidenceMr, isNotNull, reason: '$id evidence_mr missing');
      }
    });

    test('Component breakdown and weights match Appendix A.2 exact specification (56 wt total)', () {
      final ops = weeklyCheckpoints.where((c) => (c['id'] as String).startsWith('O.')).toList();
      final cash = weeklyCheckpoints.where((c) => (c['id'] as String).startsWith('CW.')).toList();
      final rs = weeklyCheckpoints.where((c) => (c['id'] as String).startsWith('RS.')).toList();
      final inv = weeklyCheckpoints.where((c) => (c['id'] as String).startsWith('IW.')).toList();

      expect(ops.length, 10, reason: '10 Operations checkpoints (O.1–O.10)');
      expect(cash.length, 8, reason: '8 Cash Weekly checkpoints (CW.1–CW.8)');
      expect(rs.length, 6, reason: '6 Reporting & Service checkpoints (RS.1–RS.6)');
      expect(inv.length, 12, reason: '12 Inventory Weekly checkpoints (IW.1–IW.12)');

      // Weight checks
      for (final c in ops) {
        expect(c['weight'], 1, reason: '${c['id']} weight must be 1');
        expect(c['sop_id'], 'SOP9', reason: '${c['id']} sop_id must be SOP9');
        expect(c['requires_photo_on_fail'], 0);
      }
      for (final c in cash) {
        expect(c['weight'], 2, reason: '${c['id']} weight must be 2');
        expect(c['sop_id'], 'SOP6', reason: '${c['id']} sop_id must be SOP6');
        expect(c['requires_photo_on_fail'], 1, reason: 'Cash fail requires photo');
      }
      for (final c in rs) {
        expect(c['weight'], 1, reason: '${c['id']} weight must be 1');
        expect(c['sop_id'], 'SOP8', reason: '${c['id']} sop_id must be SOP8');
        expect(c['requires_photo_on_fail'], 0);
      }
      for (final c in inv) {
        expect(c['weight'], 2, reason: '${c['id']} weight must be 2');
        expect(c['sop_id'], 'SOP7', reason: '${c['id']} sop_id must be SOP7');
        expect(c['requires_photo_on_fail'], 1, reason: 'Inventory fail requires photo');
      }

      final totalWeeklyWeight = weeklyCheckpoints.fold<int>(
        0,
        (sum, cp) => sum + (cp['weight'] as int),
      );
      expect(totalWeeklyWeight, 56, reason: 'Weekly-only weighted total must be exactly 56');
    });
  });
}
