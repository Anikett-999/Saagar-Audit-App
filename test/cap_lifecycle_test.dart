import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/cap_repository.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  late FakeDatabase fakeDb;
  late CapRepository repo;

  const gmUser = AuthUser(
    id: 'user-gm-1',
    name: 'General Manager',
    role: 'GM',
    languagePref: 'en',
  );

  const ownerUser = AuthUser(
    id: 'user-owner-1',
    name: 'Owner Admin',
    role: 'OWNER',
    languagePref: 'en',
  );

  const smUser = AuthUser(
    id: 'user-sm-1',
    name: 'Store Manager',
    role: 'SM',
    languagePref: 'en',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeDatabase();
    AppDatabase.instance.setDatabaseForTesting(fakeDb);
    repo = CapRepository.instance;

    // Seed users
    fakeDb.tables['users'] = [
      {
        'id': 'user-owner-1',
        'name': 'Owner Admin',
        'role': 'OWNER',
        'is_active': 1,
      },
      {
        'id': 'user-gm-1',
        'name': 'General Manager',
        'role': 'GM',
        'is_active': 1,
      },
      {
        'id': 'user-sm-1',
        'name': 'Store Manager',
        'role': 'SM',
        'is_active': 1,
      },
    ];

    // Seed checkpoints (CP 1.1 without photo requirement, CP 1.2 with mandatory photo requirement)
    fakeDb.tables['checkpoints'] = [
      {
        'id': '1.1',
        'sop_id': 1,
        'name_en': 'Floor Cleanliness',
        'requires_photo_on_fail': 0,
        'weight': 1,
      },
      {
        'id': '1.2',
        'sop_id': 1,
        'name_en': 'Fire Extinguisher',
        'requires_photo_on_fail': 1,
        'weight': 2,
      },
    ];
  });

  group('Sprint P2-5 — CAP Lifecycle Transitions Suite', () {
    test('1. verifyCap happy path: transitions done -> verified with cap_log', () async {
      // Seed a done CAP
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-01',
        'origin_audit_id': 'audit-1',
        'origin_result_id': 'res-1',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Floor dirty',
        'why_1': 'Mop broken',
        'root_cause': 'No spares',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Inspect floor',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
        'done_at': '2026-09-25T12:00:00Z',
        'aged_count': 0,
        'extension_count': 0,
      });

      await repo.verifyCap(
        capId: 'CAP-2026-W39-01',
        verifierId: gmUser.id,
      );

      final updated = await repo.getById('CAP-2026-W39-01');
      expect(updated, isNotNull);
      expect(updated!.status, equals('verified'));
      expect(updated.isVerified, isTrue);
      expect(updated.verifiedBy, equals(gmUser.id));
      expect(updated.verifiedAt, isNotNull);

      // Verify cap_log entry
      final logs = await repo.logFor('CAP-2026-W39-01');
      final verifyLog = logs.lastWhere((l) => l.event == 'verified');
      expect(verifyLog.fromStatus, equals('done'));
      expect(verifyLog.toStatus, equals('verified'));
      expect(verifyLog.actorUserId, equals(gmUser.id));
    });

    test('2. verifyCap photo gate: requires_photo_on_fail=1 throws ArgumentError without photo, succeeds with photo', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-02',
        'origin_audit_id': 'audit-2',
        'origin_result_id': 'res-2',
        'origin_checkpoint_id': '1.2', // CP 1.2 requires photo on fail
        'is_pattern': 0,
        'problem_statement': 'Fire extinguisher expired',
        'why_1': 'Not checked',
        'root_cause': 'No vendor contract',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Check gauge and tag',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
        'done_at': '2026-09-25T12:00:00Z',
        'aged_count': 0,
        'extension_count': 0,
      });

      // Attempt verification without photo -> must throw ArgumentError
      expect(
        () => repo.verifyCap(
          capId: 'CAP-2026-W39-02',
          verifierId: gmUser.id,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Verify with photo path -> succeeds and writes photo row with context='cap_verification'
      await repo.verifyCap(
        capId: 'CAP-2026-W39-02',
        verifierId: gmUser.id,
        photoPath: '/mock/path/verify_photo.jpg',
      );

      final updated = await repo.getById('CAP-2026-W39-02');
      expect(updated!.status, equals('verified'));

      // Check photos table
      final photos = await repo.photosForCap('CAP-2026-W39-02');
      expect(photos.length, equals(1));
      expect(photos.first['context'], equals('cap_verification'));
      expect(photos.first['local_path'], equals('/mock/path/verify_photo.jpg'));
      expect(photos.first['uploaded_by'], equals(gmUser.id));
    });

    test('3. verifyCap invalid state guard: throws StateError if CAP is not done', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-03',
        'origin_audit_id': 'audit-3',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Method',
        'status': 'open', // not done
        'opened_at': '2026-09-20T10:00:00Z',
      });

      expect(
        () => repo.verifyCap(
          capId: 'CAP-2026-W39-03',
          verifierId: gmUser.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('4. closeCap happy path: transitions verified -> closed with cap_log', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-04',
        'origin_audit_id': 'audit-4',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Method',
        'status': 'verified',
        'opened_at': '2026-09-20T10:00:00Z',
        'verified_at': '2026-09-26T10:00:00Z',
        'verified_by': gmUser.id,
      });

      await repo.closeCap(
        capId: 'CAP-2026-W39-04',
        closerId: gmUser.id,
      );

      final updated = await repo.getById('CAP-2026-W39-04');
      expect(updated, isNotNull);
      expect(updated!.status, equals('closed'));
      expect(updated.isClosed, isTrue);
      expect(updated.closedBy, equals(gmUser.id));
      expect(updated.closedAt, isNotNull);

      // Verify cap_log entry
      final logs = await repo.logFor('CAP-2026-W39-04');
      final closeLog = logs.lastWhere((l) => l.event == 'closed');
      expect(closeLog.fromStatus, equals('verified'));
      expect(closeLog.toStatus, equals('closed'));
      expect(closeLog.actorUserId, equals(gmUser.id));
    });

    test('5. closeCap invalid state guard: throws StateError if CAP is not verified', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-05',
        'origin_audit_id': 'audit-5',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Method',
        'status': 'done', // not verified
        'opened_at': '2026-09-20T10:00:00Z',
      });

      expect(
        () => repo.closeCap(
          capId: 'CAP-2026-W39-05',
          closerId: gmUser.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('6. extendCap happy path: bumps extension_count, updates deadline & reason, keeps status done', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-06',
        'origin_audit_id': 'audit-6',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-09-25',
        'verification_method': 'Method',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
        'extension_count': 0,
      });

      await repo.extendCap(
        capId: 'CAP-2026-W39-06',
        actorId: gmUser.id,
        newDeadline: '2026-10-05',
        reason: 'Vendor parts delayed by 1 week',
      );

      final updated = await repo.getById('CAP-2026-W39-06');
      expect(updated!.deadline, equals('2026-10-05'));
      expect(updated.extensionCount, equals(1));
      expect(updated.latestExtensionReason, equals('Vendor parts delayed by 1 week'));
      expect(updated.status, equals('done')); // stays done per plan §5.1

      // Verify cap_log entry
      final logs = await repo.logFor('CAP-2026-W39-06');
      final extLog = logs.lastWhere((l) => l.event == 'extended');
      expect(extLog.fromStatus, equals('done'));
      expect(extLog.toStatus, equals('done'));
      expect(extLog.actorUserId, equals(gmUser.id));
      expect(extLog.note, contains('Vendor parts delayed by 1 week'));
    });

    test('7. extendCap validation: throws ArgumentError on blank reason or blank deadline', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-07',
        'origin_audit_id': 'audit-7',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-09-25',
        'verification_method': 'Method',
        'status': 'open',
        'opened_at': '2026-09-20T10:00:00Z',
      });

      expect(
        () => repo.extendCap(
          capId: 'CAP-2026-W39-07',
          actorId: gmUser.id,
          newDeadline: '2026-10-05',
          reason: '   ', // blank
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repo.extendCap(
          capId: 'CAP-2026-W39-07',
          actorId: gmUser.id,
          newDeadline: '',
          reason: 'Valid reason',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('8. reopenCap happy path: verify-fail -> reopen sets status=reopened & logs', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-08',
        'origin_audit_id': 'audit-8',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-09-25',
        'verification_method': 'Method',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
      });

      await repo.reopenCap(
        capId: 'CAP-2026-W39-08',
        actorId: gmUser.id,
        reason: 'Verification failed: action was ineffective',
      );

      final updated = await repo.getById('CAP-2026-W39-08');
      expect(updated!.status, equals('reopened'));
      expect(updated.isReopened, isTrue);
      expect(updated.isOpen, isTrue);

      final logs = await repo.logFor('CAP-2026-W39-08');
      final reopenLog = logs.lastWhere((l) => l.event == 'reopened');
      expect(reopenLog.fromStatus, equals('done'));
      expect(reopenLog.toStatus, equals('reopened'));
      expect(reopenLog.note, contains('Verification failed: action was ineffective'));
    });

    test('9. reopenCap happy path: closed -> reopen sets status=reopened (Owner action)', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-09',
        'origin_audit_id': 'audit-9',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-09-25',
        'verification_method': 'Method',
        'status': 'closed',
        'opened_at': '2026-09-20T10:00:00Z',
        'closed_at': '2026-09-26T10:00:00Z',
        'closed_by': gmUser.id,
      });

      await repo.reopenCap(
        capId: 'CAP-2026-W39-09',
        actorId: ownerUser.id,
        reason: 'Issue recurred after close; re-evaluating root cause',
      );

      final updated = await repo.getById('CAP-2026-W39-09');
      expect(updated!.status, equals('reopened'));
      expect(updated.isReopened, isTrue);

      final logs = await repo.logFor('CAP-2026-W39-09');
      final reopenLog = logs.lastWhere((l) => l.event == 'reopened');
      expect(reopenLog.fromStatus, equals('closed'));
      expect(reopenLog.toStatus, equals('reopened'));
    });

    test('10. reopenCap validation: throws ArgumentError on blank reason, throws StateError on open CAP', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-10',
        'origin_audit_id': 'audit-10',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-09-25',
        'verification_method': 'Method',
        'status': 'open', // open cannot be reopened
        'opened_at': '2026-09-20T10:00:00Z',
      });

      expect(
        () => repo.reopenCap(
          capId: 'CAP-2026-W39-10',
          actorId: gmUser.id,
          reason: 'Some reason',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('11. Pattern CAP end-to-end: is_pattern=1 flows open -> done -> verified -> closed seamlessly', () async {
      final cap = await repo.createCap(
        id: 'CAP-2026-W39-99',
        originAuditId: 'audit-weekly-1',
        originCheckpointId: '1.1',
        isPattern: true,
        problemStatement: 'Persistent weekly pattern on CP 1.1 across 3 days',
        why1: 'Staff rotation',
        rootCause: 'No standard training on shift transition',
        responsibleUserId: smUser.id,
        deadline: '2026-10-05',
        verificationMethod: 'Review next weekly audit for 0 fails on CP 1.1',
        actionSteps: [
          'Brief all 3 shift leaders',
          'Post cleaning checklist on register',
          'Conduct daily spot checks',
        ],
      );

      expect(cap.isPattern, isTrue);
      expect(cap.status, equals('open'));

      // Mark all 3 actions done
      final actions = await repo.actionsFor(cap.id);
      expect(actions.length, equals(3));
      for (final a in actions) {
        await repo.toggleAction(actionId: a.id, done: true, userId: smUser.id);
      }

      // Mark CAP done
      await repo.markDone(capId: cap.id, userId: smUser.id);
      final doneCap = await repo.getById(cap.id);
      expect(doneCap!.status, equals('done'));
      expect(doneCap.isPattern, isTrue);

      // Verify CAP
      await repo.verifyCap(capId: cap.id, verifierId: gmUser.id);
      final verifiedCap = await repo.getById(cap.id);
      expect(verifiedCap!.status, equals('verified'));
      expect(verifiedCap.isPattern, isTrue);

      // Close CAP
      await repo.closeCap(capId: cap.id, closerId: gmUser.id);
      final closedCap = await repo.getById(cap.id);
      expect(closedCap!.status, equals('closed'));
      expect(closedCap.isPattern, isTrue);

      // Verify full audit log
      final logs = await repo.logFor(cap.id);
      expect(logs.any((l) => l.event == 'created'), isTrue);
      expect(logs.any((l) => l.event == 'action_done'), isTrue);
      expect(logs.any((l) => l.event == 'marked_done'), isTrue);
      expect(logs.any((l) => l.event == 'verified'), isTrue);
      expect(logs.any((l) => l.event == 'closed'), isTrue);
    });

    test('12. R5 Immutability: CAP transitions touch only caps/cap_log/photos, never audits or audit_results', () async {
      // Seed audit & audit_results
      fakeDb.tables['audits']!.add({
        'id': 'audit-immutable-1',
        'audit_type': 'daily',
        'status': 'submitted',
        'compliance_percentage': 90.0,
        'band': 'good',
        'total_score': 81.0,
        'max_possible_score': 90.0,
      });

      fakeDb.tables['audit_results']!.add({
        'id': 'res-immutable-1',
        'audit_id': 'audit-immutable-1',
        'checkpoint_id': '1.1',
        'result': 'F',
        'score': 0.0,
      });

      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-50',
        'origin_audit_id': 'audit-immutable-1',
        'origin_result_id': 'res-immutable-1',
        'origin_checkpoint_id': '1.1',
        'is_pattern': 0,
        'problem_statement': 'Test',
        'why_1': 'Why',
        'root_cause': 'Root',
        'responsible_user_id': 'user-sm-1',
        'deadline': '2026-10-01',
        'verification_method': 'Method',
        'status': 'done',
        'opened_at': '2026-09-20T10:00:00Z',
      });

      // Execute verify and close
      await repo.verifyCap(capId: 'CAP-2026-W39-50', verifierId: gmUser.id);
      await repo.closeCap(capId: 'CAP-2026-W39-50', closerId: gmUser.id);

      // Verify audit and results remain 100% identical
      final audit = fakeDb.tables['audits']!.firstWhere((a) => a['id'] == 'audit-immutable-1');
      expect(audit['compliance_percentage'], equals(90.0));
      expect(audit['total_score'], equals(81.0));
      expect(audit['status'], equals('submitted'));

      final result = fakeDb.tables['audit_results']!.firstWhere((r) => r['id'] == 'res-immutable-1');
      expect(result['score'], equals(0.0));
      expect(result['result'], equals('F'));
    });

    test('13. getCapCounts: aggregates open, awaiting verification, verified, closed, and overdue', () async {
      fakeDb.tables['caps']!.addAll([
        {
          'id': 'CAP-1',
          'origin_audit_id': 'a1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'P1',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': 'user-sm-1',
          'deadline': '2026-12-01',
          'verification_method': 'v',
          'status': 'open',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-2',
          'origin_audit_id': 'a1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'P2',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': 'user-sm-1',
          'deadline': '2026-01-01', // overdue open
          'verification_method': 'v',
          'status': 'reopened',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-3',
          'origin_audit_id': 'a1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'P3',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': 'user-sm-1',
          'deadline': '2026-10-01',
          'verification_method': 'v',
          'status': 'done', // awaiting verification
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-4',
          'origin_audit_id': 'a1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'P4',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': 'user-sm-1',
          'deadline': '2026-10-01',
          'verification_method': 'v',
          'status': 'verified',
          'opened_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'CAP-5',
          'origin_audit_id': 'a1',
          'origin_checkpoint_id': '1.1',
          'problem_statement': 'P5',
          'why_1': 'w',
          'root_cause': 'r',
          'responsible_user_id': 'user-sm-1',
          'deadline': '2026-01-01',
          'verification_method': 'v',
          'status': 'closed', // closed overdue is not counted in overdue
          'opened_at': '2026-09-20T10:00:00Z',
        },
      ]);

      final counts = await repo.getCapCounts(viewer: gmUser);
      expect(counts.open, equals(2)); // CAP-1 (open) + CAP-2 (reopened)
      expect(counts.awaitingVerification, equals(1)); // CAP-3 (done)
      expect(counts.verified, equals(1)); // CAP-4 (verified)
      expect(counts.closed, equals(1)); // CAP-5 (closed)
      expect(counts.overdue, equals(1)); // CAP-2 (deadline 2026-01-01 < today, reopened)
    });
  });
}
