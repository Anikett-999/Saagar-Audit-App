import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/checkpoint.dart';
import 'package:saagar_audit_app/providers/draft_audit_provider.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Hard Rule #6: Mandatory Photo Gate on Fail (Spec §5 S8/S10)', () {
    late FakeDatabase fakeDb;
    late DraftAuditNotifier notifier;

    const cpWithPhotoRequired = Checkpoint(
      id: '1.1',
      sopId: 'SOP_1',
      frequency: 'daily',
      sequence: 1,
      textEn: 'Store facade and entrance clean and illuminated',
      textMr: 'दुकानाचे दर्शनी भाग स्वच्छ आणि प्रकाशित',
      weight: 2,
      allowsNa: false,
      requiresPhotoOnFail: true,
      displayOrder: 1,
    );

    const cpWithoutPhotoRequired = Checkpoint(
      id: '1.2',
      sopId: 'SOP_1',
      frequency: 'daily',
      sequence: 2,
      textEn: 'Music playlist active and appropriate volume',
      textMr: 'संगीताची प्लेलिस्ट सक्रिय आणि योग्य आवाजात',
      weight: 1,
      allowsNa: true,
      requiresPhotoOnFail: false,
      displayOrder: 2,
    );

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      notifier = DraftAuditNotifier();

      final audit = Audit(
        id: 'audit-test-photo-gate',
        auditType: 'daily',
        auditDate: '2026-09-21',
        weekNumber: 39,
        monthNumber: 9,
        year: 2026,
        auditorId: 'user-1',
        deviceId: 'device-1',
        status: 'draft',
        failCount: 0,
        passCount: 0,
        naCount: 0,
        draftStartedAt: DateTime.now().toUtc().toIso8601String(),
      );

      fakeDb.tables['audits']!.add(audit.toMap());

      notifier.state = DraftAuditState(
        audit: audit,
        checkpoints: const [cpWithPhotoRequired, cpWithoutPhotoRequired],
        currentIndex: 0,
        results: const {},
        cros: const [],
      );
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test(
        'recordFailAndAdvance throws ArgumentError when requiresPhotoOnFail=true and photoPaths is empty',
        () async {
      expect(notifier.state.currentCheckpoint?.id, '1.1');
      expect(notifier.state.currentCheckpoint?.requiresPhotoOnFail, isTrue);

      expect(
        () => notifier.recordFailAndAdvance(
          findingText: 'Store facade signboard lights broken',
          photoPaths: const [],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('requires at least one photo on FAIL'),
          ),
        ),
      );
    });

    test(
        'recordFailAndAdvance succeeds when requiresPhotoOnFail=true and photoPaths has at least 1 photo',
        () async {
      await notifier.recordFailAndAdvance(
        findingText: 'Store facade signboard lights broken',
        photoPaths: ['/test/path/facade_broken.jpg'],
      );

      expect(notifier.state.results['1.1'], Verdict.fail);
      expect(notifier.state.currentIndex, 1);
      expect(fakeDb.tables['photos']!.length, 1);
      expect(
        fakeDb.tables['photos']!.first['local_path'],
        '/test/path/facade_broken.jpg',
      );
    });

    test(
        'recordFailAndAdvance succeeds when requiresPhotoOnFail=false even with 0 photos',
        () async {
      notifier.jumpTo(1);
      expect(notifier.state.currentCheckpoint?.id, '1.2');
      expect(notifier.state.currentCheckpoint?.requiresPhotoOnFail, isFalse);

      await notifier.recordFailAndAdvance(
        findingText: 'Music player disconnected',
        photoPaths: const [],
      );

      expect(notifier.state.results['1.2'], Verdict.fail);
    });

    test(
        'submitAudit blocks submission with StateError if any requiresPhotoOnFail checkpoint is FAIL without photo',
        () async {
      final now = DateTime.now().toUtc().toIso8601String();
      fakeDb.tables['audit_results']!.add({
        'id': 'res-1',
        'audit_id': 'audit-test-photo-gate',
        'checkpoint_id': '1.1',
        'result': 'F',
        'weighted_points': 0.0,
        'finding_text': 'Facade dirty',
        'created_at': now,
      });

      fakeDb.tables['audit_results']!.add({
        'id': 'res-2',
        'audit_id': 'audit-test-photo-gate',
        'checkpoint_id': '1.2',
        'result': 'P',
        'weighted_points': 1.0,
        'created_at': now,
      });

      notifier.state = notifier.state.copyWith(
        results: {
          '1.1': Verdict.fail,
          '1.2': Verdict.pass,
        },
      );

      expect(notifier.state.isComplete, isTrue);

      expect(
        () => notifier.submitAudit(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('requires photo evidence on FAIL'),
          ),
        ),
      );
    });

    test(
        'submitAudit succeeds when all FAIL checkpoints with requiresPhotoOnFail have attached photos',
        () async {
      final now = DateTime.now().toUtc().toIso8601String();
      fakeDb.tables['audit_results']!.add({
        'id': 'res-1',
        'audit_id': 'audit-test-photo-gate',
        'checkpoint_id': '1.1',
        'result': 'F',
        'weighted_points': 0.0,
        'finding_text': 'Facade dirty',
        'created_at': now,
      });

      fakeDb.tables['photos']!.add({
        'id': 'photo-1',
        'audit_result_id': 'res-1',
        'context': 'fail_evidence',
        'local_path': '/path/facade.jpg',
        'upload_status': 'pending',
        'captured_at': now,
      });

      fakeDb.tables['audit_results']!.add({
        'id': 'res-2',
        'audit_id': 'audit-test-photo-gate',
        'checkpoint_id': '1.2',
        'result': 'P',
        'weighted_points': 1.0,
        'created_at': now,
      });

      notifier.state = notifier.state.copyWith(
        results: {
          '1.1': Verdict.fail,
          '1.2': Verdict.pass,
        },
      );

      final score = await notifier.submitAudit();
      expect(score.passCount, 1);
      expect(score.failCount, 1);
      expect(notifier.state.audit?.status, 'submitted');
    });
  });
}
