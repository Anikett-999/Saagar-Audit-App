import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/audit_repository.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Hard Rule #6: Audit Immutability Test (Spec §14.1 & TC8)', () {
    late FakeDatabase fakeDb;
    const auditId = 'test-audit-uuid-1234';

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed an audit in draft status
      fakeDb.tables['audits']!.add({
        'id': auditId,
        'audit_type': 'daily',
        'audit_date': '2026-09-21',
        'week_number': 39,
        'month_number': 9,
        'year': 2026,
        'auditor_id': 'user-1',
        'device_id': 'device-1',
        'status': 'draft',
        'fail_count': 0,
        'pass_count': 0,
        'na_count': 0,
        'draft_started_at': DateTime.now().toUtc().toIso8601String(),
      });
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('saveResult succeeds when audit is in draft status', () async {
      final res = await AuditRepository.instance.saveResult(
        auditId: auditId,
        checkpointId: '1.1',
        result: 'P',
        weight: 2,
      );

      expect(res.auditId, auditId);
      expect(res.checkpointId, '1.1');
      expect(res.result, 'P');
      expect(fakeDb.tables['audit_results']!.length, 1);
    });

    test('submitAudit transitions audit status to submitted', () async {
      await AuditRepository.instance.submitAudit(
        auditId: auditId,
        rawScore: 90.0,
        maxScore: 100.0,
        compliancePct: 90.0,
        band: 'good',
        passCount: 45,
        failCount: 5,
        naCount: 18,
      );

      final audit = fakeDb.tables['audits']!.first;
      expect(audit['status'], 'submitted');
      expect(audit['compliance_pct'], 90.0);
      expect(audit['band'], 'good');
    });

    test('saveResult throws StateError when audit is in submitted status', () async {
      // First submit the audit
      await AuditRepository.instance.submitAudit(
        auditId: auditId,
        rawScore: 90.0,
        maxScore: 100.0,
        compliancePct: 90.0,
        band: 'good',
        passCount: 45,
        failCount: 5,
        naCount: 18,
      );

      // Attempting to modify a submitted audit MUST throw StateError
      expect(
        () => AuditRepository.instance.saveResult(
          auditId: auditId,
          checkpointId: '1.2',
          result: 'F',
          weight: 3,
          findingText: 'Unauthorized post-submit edit attempt',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Cannot modify audit $auditId: status is submitted'),
          ),
        ),
      );
    });

    test('submitAudit throws StateError when audit is already submitted', () async {
      // First submit
      await AuditRepository.instance.submitAudit(
        auditId: auditId,
        rawScore: 90.0,
        maxScore: 100.0,
        compliancePct: 90.0,
        band: 'good',
        passCount: 45,
        failCount: 5,
        naCount: 18,
      );

      // Attempting to submit again MUST throw StateError
      expect(
        () => AuditRepository.instance.submitAudit(
          auditId: auditId,
          rawScore: 90.0,
          maxScore: 100.0,
          compliancePct: 90.0,
          band: 'good',
          passCount: 45,
          failCount: 5,
          naCount: 18,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Cannot submit audit $auditId: not found or not in draft status'),
          ),
        ),
      );
    });
  });
}
