import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/domain/pattern_detection.dart';

void main() {
  group('Sprint P2-4 — Pattern-Detection Engine Tests (Spec §5 T2.4 & Workbook Day 3 §3.6)', () {
    test('1. T2.4 Canonical — Checkpoint 1.4 failing on days 1,2,3 triggers single pattern and single CAP', () {
      final failPoints = [
        const DailyFailPoint(
          checkpointId: '1.4',
          auditDate: '2026-09-21', // Monday
          findingText: 'Dust on upper shelf display',
        ),
        const DailyFailPoint(
          checkpointId: '1.4',
          auditDate: '2026-09-22', // Tuesday
          findingText: 'Dust on counter edge',
        ),
        const DailyFailPoint(
          checkpointId: '1.4',
          auditDate: '2026-09-23', // Wednesday
          findingText: 'Glass smudge and dust on shelf',
        ),
        // Checkpoint 2.1 failing on only 2 days (NOT a pattern)
        const DailyFailPoint(
          checkpointId: '2.1',
          auditDate: '2026-09-21',
          findingText: 'Name badge missing',
        ),
        const DailyFailPoint(
          checkpointId: '2.1',
          auditDate: '2026-09-22',
          findingText: 'Name badge unpinned',
        ),
      ];

      final patterns = detectWeeklyPatterns(failPoints);

      // Expect exactly 1 pattern detected (CP 1.4)
      expect(patterns.length, 1);
      final p1 = patterns.first;

      expect(p1.checkpointId, '1.4');
      expect(p1.failCount, 3);
      expect(p1.dates, ['2026-09-21', '2026-09-22', '2026-09-23']);
      expect(p1.weekdaysEn, ['Mon', 'Tue', 'Wed']);
      expect(p1.weekdaysMr, ['सोम', 'मंगळ', 'बुध']);

      // Canonical description format
      expect(
        p1.formattedDescription('en'),
        'Checkpoint 1.4 failed on 3 days (Mon, Tue, Wed) — pattern',
      );
      expect(
        p1.formattedDescription('mr'),
        'तपासणी बिंदू 1.4 3 दिवस अयशस्वी (सोम, मंगळ, बुध) — पॅटर्न',
      );

      // Single-CAP rule: maps to exactly ONE suggested Pattern CAP
      final suggestedCap = p1.toSuggestedCap();
      expect(suggestedCap.checkpointId, '1.4');
      expect(suggestedCap.failCount, 3);
      expect(
        suggestedCap.problemStatementEn,
        contains('Recurring pattern: Checkpoint 1.4 failed on 3 days (Mon, Tue, Wed)'),
      );
      expect(
        suggestedCap.problemStatementMr,
        contains('वारंवार आढळणारा पॅटर्न: तपासणी बिंदू 1.4 3 दिवस अयशस्वी'),
      );
    });

    test('2. Multiple failures on the same day for a checkpoint count as 1 distinct fail-day', () {
      final failPoints = [
        const DailyFailPoint(
          checkpointId: '4.2',
          auditDate: '2026-09-21',
          findingText: 'Morning shift fail',
        ),
        const DailyFailPoint(
          checkpointId: '4.2',
          auditDate: '2026-09-21', // Duplicate date
          findingText: 'Evening re-check fail',
        ),
        const DailyFailPoint(
          checkpointId: '4.2',
          auditDate: '2026-09-22',
          findingText: 'Next day fail',
        ),
      ];

      // Only 2 distinct days -> NOT a pattern (>= 3 required)
      final patterns = detectWeeklyPatterns(failPoints);
      expect(patterns, isEmpty);
    });

    test('3. Checkpoint failing on 4 days is ordered before checkpoint failing on 3 days', () {
      final failPoints = [
        // CP 1.4 on 3 days
        const DailyFailPoint(checkpointId: '1.4', auditDate: '2026-09-21'),
        const DailyFailPoint(checkpointId: '1.4', auditDate: '2026-09-22'),
        const DailyFailPoint(checkpointId: '1.4', auditDate: '2026-09-23'),

        // CP 6.1 on 4 days
        const DailyFailPoint(checkpointId: '6.1', auditDate: '2026-09-21'),
        const DailyFailPoint(checkpointId: '6.1', auditDate: '2026-09-22'),
        const DailyFailPoint(checkpointId: '6.1', auditDate: '2026-09-24'),
        const DailyFailPoint(checkpointId: '6.1', auditDate: '2026-09-25'),
      ];

      final patterns = detectWeeklyPatterns(failPoints);
      expect(patterns.length, 2);
      expect(patterns[0].checkpointId, '6.1');
      expect(patterns[0].failCount, 4);
      expect(patterns[1].checkpointId, '1.4');
      expect(patterns[1].failCount, 3);
    });

    test('4. JSON serialization round-trips correctly', () {
      const pattern = PatternFinding(
        checkpointId: '3.1',
        failCount: 3,
        dates: ['2026-09-21', '2026-09-23', '2026-09-25'],
        weekdaysEn: ['Mon', 'Wed', 'Fri'],
        weekdaysMr: ['सोम', 'बुध', 'शुक्र'],
        findings: ['f1', 'f2', 'f3'],
      );

      final json = pattern.toJson();
      final roundTrip = PatternFinding.fromJson(json);

      expect(roundTrip.checkpointId, pattern.checkpointId);
      expect(roundTrip.failCount, pattern.failCount);
      expect(roundTrip.dates, pattern.dates);
      expect(roundTrip.weekdaysEn, pattern.weekdaysEn);
      expect(roundTrip.weekdaysMr, pattern.weekdaysMr);
      expect(roundTrip.findings, pattern.findings);
    });
  });
}
