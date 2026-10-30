import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/audit_result.dart';
import 'package:saagar_audit_app/data/models/checkpoint.dart';
import 'package:saagar_audit_app/data/models/cro.dart';
import 'package:saagar_audit_app/data/models/sop.dart';
import 'package:saagar_audit_app/services/daily_audit_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testAudit = Audit(
    id: 'audit-daily-01',
    auditType: 'daily',
    auditDate: '2026-10-30',
    weekNumber: 44,
    year: 2026,
    auditorId: 'user-sm-1',
    deviceId: 'dev-1',
    status: 'submitted',
    rawScore: 81.0,
    maxScore: 90.0,
    compliancePct: 90.0,
    band: 'good',
    failCount: 1,
    passCount: 9,
    naCount: 0,
    submittedAt: '2026-10-30T19:00:00Z',
    notes: 'Morning shift had power fluctuation.',
  );

  final testSops = [
    const Sop(
      id: 'SOP1',
      number: 1,
      nameEn: 'Cash Management',
      nameMr: 'रोख व्यवस्थापन',
      weight: 2,
      isCritical: true,
      displayOrder: 1,
    ),
    const Sop(
      id: 'SOP2',
      number: 2,
      nameEn: 'Opening Procedure',
      nameMr: 'दुकान उघडण्याची प्रक्रिया',
      weight: 1,
      isCritical: false,
      displayOrder: 2,
    ),
  ];

  final testCheckpoints = {
    '1.1': const Checkpoint(
      id: '1.1',
      sopId: 'SOP1',
      frequency: 'daily',
      sequence: 1,
      textEn: 'Petty cash physical count matches register',
      textMr: 'किरकोळ रोख मोजणी नोंदवहीशी जुळते',
      weight: 2,
      allowsNa: false,
      requiresPhotoOnFail: true,
      displayOrder: 1,
    ),
    '1.4': const Checkpoint(
      id: '1.4',
      sopId: 'SOP1',
      frequency: 'daily',
      sequence: 4,
      textEn: 'Closing cash variance recorded',
      textMr: 'दिवसाअखेर रोख तफावत नोंदवली',
      weight: 2,
      allowsNa: false,
      requiresPhotoOnFail: true,
      displayOrder: 4,
    ),
  };

  final testResults = [
    const AuditResult(
      id: 'res-1',
      auditId: 'audit-daily-01',
      checkpointId: '1.1',
      result: 'pass',
      weightedPoints: 2.0,
      createdAt: '2026-10-30T18:15:00Z',
    ),
    const AuditResult(
      id: 'res-2',
      auditId: 'audit-daily-01',
      checkpointId: '1.4',
      result: 'fail',
      weightedPoints: 0.0,
      findingText: '₹600 cash variance observed at cash counter till',
      croId: 'cro-1',
      createdAt: '2026-10-30T18:30:00Z',
    ),
  ];

  final Map<String, Cro> testCros = {
    'cro-1': Cro(
      id: 'cro-1',
      name: 'Rahul Shinde',
      counter: 'Titan R1',
      shift: 'morning',
      isActive: true,
      joinedAt: DateTime(2026, 1, 1),
    ),
  };

  group('DailyAuditPdfService Tests (Spec §5 S13 & Section 10)', () {
    test('Builds valid PDF bytes for daily audit with fail and notes', () async {
      final bytes = await DailyAuditPdfService.instance.buildPdfBytes(
        audit: testAudit,
        auditorName: 'Sagar Bora',
        verifierName: 'Amit GM',
        sops: testSops,
        checkpointsById: testCheckpoints,
        results: testResults,
        crosById: testCros,
        storeName: 'Titan World (WLMHW) - Latur',
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      // Validate PDF signature header %PDF-
      final headerStr = String.fromCharCodes(bytes.take(5));
      expect(headerStr, startsWith('%PDF'));
    });

    test('Builds valid PDF bytes for 100% compliant audit with 0 fails', () async {
      const perfectAudit = Audit(
        id: 'audit-daily-perfect',
        auditType: 'daily',
        auditDate: '2026-10-30',
        weekNumber: 44,
        year: 2026,
        auditorId: 'user-sm-1',
        deviceId: 'dev-1',
        status: 'verified',
        rawScore: 90.0,
        maxScore: 90.0,
        compliancePct: 100.0,
        band: 'excellent',
        failCount: 0,
        passCount: 10,
        naCount: 0,
        submittedAt: '2026-10-30T19:00:00Z',
        verifiedAt: '2026-10-30T19:30:00Z',
        verifierId: 'user-owner-1',
      );

      final perfectResults = [
        const AuditResult(
          id: 'res-p1',
          auditId: 'audit-daily-perfect',
          checkpointId: '1.1',
          result: 'pass',
          weightedPoints: 2.0,
          createdAt: '2026-10-30T18:15:00Z',
        ),
      ];

      final bytes = await DailyAuditPdfService.instance.buildPdfBytes(
        audit: perfectAudit,
        auditorName: 'Sagar Bora',
        verifierName: 'Sagar Owner',
        sops: testSops,
        checkpointsById: testCheckpoints,
        results: perfectResults,
        crosById: testCros,
      );

      expect(bytes.isNotEmpty, isTrue);
      final headerStr = String.fromCharCodes(bytes.take(5));
      expect(headerStr, startsWith('%PDF'));
    });
  });
}
