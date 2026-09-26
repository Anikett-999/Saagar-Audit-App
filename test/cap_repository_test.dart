import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/models/audit.dart';
import 'package:saagar_audit_app/data/models/cap.dart';
import 'package:saagar_audit_app/data/models/cap_action.dart';
import 'package:saagar_audit_app/data/models/cap_log_entry.dart';
import 'package:saagar_audit_app/data/repositories/audit_repository.dart';
import 'package:saagar_audit_app/data/repositories/cap_repository.dart';
import 'package:saagar_audit_app/domain/iso_week.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  late FakeDatabase fakeDb;
  late CapRepository repo;
  late AuditRepository auditRepo;

  const ownerUser = AuthUser(
    id: 'user-owner-1',
    name: 'Owner Admin',
    role: 'OWNER',
    languagePref: 'en',
  );

  const gmUser = AuthUser(
    id: 'user-gm-1',
    name: 'General Manager',
    role: 'GM',
    languagePref: 'en',
  );

  const smUser1 = AuthUser(
    id: 'user-sm-1',
    name: 'Store Manager 1',
    role: 'SM',
    languagePref: 'en',
  );

  const smUser2 = AuthUser(
    id: 'user-sm-2',
    name: 'Store Manager 2',
    role: 'SM',
    languagePref: 'en',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeDatabase();
    AppDatabase.instance.setDatabaseForTesting(fakeDb);
    repo = CapRepository.instance;
    auditRepo = AuditRepository.instance;

    // Seed users into fakeDb
    fakeDb.tables['users'] = [
      {
        'id': 'user-owner-1',
        'name': 'Owner Admin',
        'role': 'OWNER',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-01-01T00:00:00Z',
      },
      {
        'id': 'user-gm-1',
        'name': 'General Manager',
        'role': 'GM',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-01-01T00:00:00Z',
      },
      {
        'id': 'user-sm-1',
        'name': 'Store Manager 1',
        'role': 'SM',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-01-01T00:00:00Z',
      },
      {
        'id': 'user-sm-2',
        'name': 'Store Manager 2',
        'role': 'SM',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-01-01T00:00:00Z',
      },
      {
        'id': 'user-cro-1',
        'name': 'Staff Member',
        'role': 'STAFF',
        'pin_hash': 'hash',
        'language_pref': 'en',
        'is_active': 1,
        'created_at': '2026-01-01T00:00:00Z',
      },
    ];
  });

  tearDown(() {
    AppDatabase.instance.setDatabaseForTesting(null);
  });

  group('ISO Week & CAP ID Generation (Spec §15.5 & S15)', () {
    test('isoWeek calculates expected week numbers', () {
      expect(isoWeek(DateTime(2026, 1, 1)), 1);
      expect(isoWeek(DateTime(2026, 9, 22)), 39);
    });

    test('generateNextCapId formats as CAP-YYYY-Wxx-01 for first CAP', () async {
      final id = await repo.generateNextCapId(DateTime(2026, 9, 22));
      expect(id, 'CAP-2026-W39-01');
    });

    test('generateNextCapId increments sequence within the same week', () async {
      fakeDb.tables['caps']!.add({
        'id': 'CAP-2026-W39-01',
      });
      final id = await repo.generateNextCapId(DateTime(2026, 9, 22));
      expect(id, 'CAP-2026-W39-02');
    });

    test('Cap deadlineStatus and convenience getters work as expected', () {
      final now = DateTime(2026, 9, 22);

      const overdueCap = Cap(
        id: 'CAP-1',
        originAuditId: 'a1',
        originCheckpointId: 'cp1',
        problemStatement: 'Problem',
        why1: 'Why',
        rootCause: 'Root',
        responsibleUserId: 'u1',
        deadline: '2026-09-20', // past
        verificationMethod: 'Check',
        openedAt: '2026-09-15T00:00:00Z',
      );
      expect(overdueCap.deadlineStatus(now), CapDeadlineStatus.overdue);
      expect(overdueCap.isOpen, isTrue);

      const dueSoonCap = Cap(
        id: 'CAP-2',
        originAuditId: 'a1',
        originCheckpointId: 'cp1',
        problemStatement: 'Problem',
        why1: 'Why',
        rootCause: 'Root',
        responsibleUserId: 'u1',
        deadline: '2026-09-23', // tomorrow
        verificationMethod: 'Check',
        openedAt: '2026-09-15T00:00:00Z',
      );
      expect(dueSoonCap.deadlineStatus(now), CapDeadlineStatus.dueSoon);

      const okCap = Cap(
        id: 'CAP-3',
        originAuditId: 'a1',
        originCheckpointId: 'cp1',
        problemStatement: 'Problem',
        why1: 'Why',
        rootCause: 'Root',
        responsibleUserId: 'u1',
        deadline: '2026-09-30', // +8 days
        verificationMethod: 'Check',
        openedAt: '2026-09-15T00:00:00Z',
        status: 'done',
      );
      expect(okCap.deadlineStatus(now), CapDeadlineStatus.ok);
      expect(okCap.isDone, isTrue);
      expect(okCap.isOpen, isFalse);
    });
  });

  group('CapRepository - Validation & Creation (Spec §5 S15)', () {
    test('createCap validates mandatory fields', () async {
      final validSteps = ['Step 1', 'Step 2', 'Step 3'];

      expect(
        () => repo.createCap(
          originAuditId: 'audit-1',
          originCheckpointId: 'cp-1',
          problemStatement: '',
          why1: 'Why 1',
          rootCause: 'Root Cause',
          responsibleUserId: 'user-sm-1',
          deadline: '2026-09-30',
          verificationMethod: 'Check ticket',
          actionSteps: validSteps,
        ),
        throwsArgumentError,
      );

      expect(
        () => repo.createCap(
          originAuditId: 'audit-1',
          originCheckpointId: 'cp-1',
          problemStatement: 'Problem',
          why1: '',
          rootCause: 'Root Cause',
          responsibleUserId: 'user-sm-1',
          deadline: '2026-09-30',
          verificationMethod: 'Check ticket',
          actionSteps: validSteps,
        ),
        throwsArgumentError,
      );

      expect(
        () => repo.createCap(
          originAuditId: 'audit-1',
          originCheckpointId: 'cp-1',
          problemStatement: 'Problem',
          why1: 'Why 1',
          rootCause: '',
          responsibleUserId: 'user-sm-1',
          deadline: '2026-09-30',
          verificationMethod: 'Check ticket',
          actionSteps: validSteps,
        ),
        throwsArgumentError,
      );
    });

    test('createCap enforces 3–5 action steps', () async {
      expect(
        () => repo.createCap(
          originAuditId: 'audit-1',
          originCheckpointId: 'cp-1',
          problemStatement: 'Problem',
          why1: 'Why 1',
          rootCause: 'Root Cause',
          responsibleUserId: 'user-sm-1',
          deadline: '2026-09-30',
          verificationMethod: 'Check ticket',
          actionSteps: ['Only Step 1', 'Only Step 2'], // < 3
        ),
        throwsArgumentError,
      );

      expect(
        () => repo.createCap(
          originAuditId: 'audit-1',
          originCheckpointId: 'cp-1',
          problemStatement: 'Problem',
          why1: 'Why 1',
          rootCause: 'Root Cause',
          responsibleUserId: 'user-sm-1',
          deadline: '2026-09-30',
          verificationMethod: 'Check ticket',
          actionSteps: ['1', '2', '3', '4', '5', '6'], // > 5
        ),
        throwsArgumentError,
      );
    });

    test('createCap rejects non-management responsible user', () async {
      expect(
        () => repo.createCap(
          originAuditId: 'audit-1',
          originCheckpointId: 'cp-1',
          problemStatement: 'Problem',
          why1: 'Why 1',
          rootCause: 'Root Cause',
          responsibleUserId: 'user-cro-1', // Role is STAFF, not SM/GM/OWNER
          deadline: '2026-09-30',
          verificationMethod: 'Check ticket',
          actionSteps: ['Step 1', 'Step 2', 'Step 3'],
        ),
        throwsArgumentError,
      );
    });

    test('createCap inserts cap, actions, and cap_log atomically', () async {
      final cap = await repo.createCap(
        originAuditId: 'audit-1',
        originResultId: 'res-1',
        originCheckpointId: 'cp-1',
        problemStatement: 'Stock mismatch at counter 2',
        why1: 'Labels not scanned at intake',
        why2: 'Scanner battery died',
        rootCause: 'Lack of dock charging discipline',
        responsibleUserId: 'user-sm-1',
        deadline: '2026-09-30',
        verificationMethod: 'Daily scanner inspection',
        actionSteps: [
          'Charge all scanners overnight',
          'Post charging checklist on desk',
          'Perform morning battery check',
        ],
        creatorUserId: 'user-gm-1',
        originDate: DateTime(2026, 9, 22),
      );

      expect(cap.id, 'CAP-2026-W39-01');
      expect(cap.status, 'open');
      expect(cap.isOpen, isTrue);
      expect(cap.isDone, isFalse);

      // Verify actions inserted
      final actions = await repo.actionsFor(cap.id);
      expect(actions.length, 3);
      expect(actions[0].sequence, 1);
      expect(actions[0].actionText, 'Charge all scanners overnight');
      expect(actions[0].isDone, isFalse);

      // Verify log entry inserted
      final logs = await repo.logFor(cap.id);
      expect(logs.length, 1);
      expect(logs.first.event, 'created');
      expect(logs.first.toStatus, 'open');
      expect(logs.first.actorUserId, 'user-gm-1');
    });
  });

  group('CapRepository - Action Step Checklist & Mark Done (Spec §5 S16/S17)', () {
    late String capId;
    late List<String> actionIds;

    setUp(() async {
      final cap = await repo.createCap(
        originAuditId: 'audit-1',
        originCheckpointId: 'cp-1',
        problemStatement: 'Defective display light',
        why1: 'LED strip burned out',
        rootCause: 'Power surge without spike guard',
        responsibleUserId: 'user-sm-1',
        deadline: '2026-09-30',
        verificationMethod: 'Visual inspection',
        actionSteps: [
          'Replace LED strip',
          'Install surge protector',
          'Test illumination',
        ],
        originDate: DateTime(2026, 9, 22),
      );
      capId = cap.id;
      final actions = await repo.actionsFor(capId);
      actionIds = actions.map((CapAction a) => a.id).toList();
    });

    test('toggleAction marks action done and logs event', () async {
      await repo.toggleAction(
        actionId: actionIds[0],
        done: true,
        userId: 'user-sm-1',
        notes: 'Installed new 12V strip',
      );

      final actions = await repo.actionsFor(capId);
      expect(actions[0].isDone, isTrue);
      expect(actions[0].doneBy, 'user-sm-1');
      expect(actions[0].doneNotes, 'Installed new 12V strip');

      final logs = await repo.logFor(capId);
      expect(logs.any((CapLogEntry l) => l.event == 'action_done'), isTrue);
    });

    test('markDone throws StateError if any action step is incomplete', () async {
      // Mark step 1 done, but leave steps 2 and 3 incomplete
      await repo.toggleAction(
        actionId: actionIds[0],
        done: true,
        userId: 'user-sm-1',
      );

      expect(
        () => repo.markDone(capId: capId, userId: 'user-sm-1'),
        throwsStateError,
      );
    });

    test('markDone transitions status to done and writes cap_log', () async {
      // Mark all 3 steps done
      for (final id in actionIds) {
        await repo.toggleAction(
          actionId: id,
          done: true,
          userId: 'user-sm-1',
        );
      }

      await repo.markDone(
        capId: capId,
        userId: 'user-sm-1',
        doneNotes: 'All physical replacements completed.',
      );

      final cap = await repo.getById(capId);
      expect(cap, isNotNull);
      expect(cap!.status, 'done');
      expect(cap.isDone, isTrue);
      expect(cap.doneAt, isNotNull);

      final logs = await repo.logFor(capId);
      final markDoneLog = logs.firstWhere((CapLogEntry l) => l.event == 'marked_done');
      expect(markDoneLog.fromStatus, 'open');
      expect(markDoneLog.toStatus, 'done');
      expect(markDoneLog.note, 'All physical replacements completed.');
    });

    test('markDone throws StateError if CAP is already done', () async {
      for (final id in actionIds) {
        await repo.toggleAction(actionId: id, done: true, userId: 'user-sm-1');
      }
      await repo.markDone(capId: capId, userId: 'user-sm-1');

      // Attempt second markDone
      expect(
        () => repo.markDone(capId: capId, userId: 'user-sm-1'),
        throwsStateError,
      );
    });

    test('markDone persists optional photo with context=cap_progress', () async {
      for (final id in actionIds) {
        await repo.toggleAction(actionId: id, done: true, userId: 'user-sm-1');
      }

      await repo.markDone(
        capId: capId,
        userId: 'user-sm-1',
        doneNotes: 'Replaced with photo proof',
        photoPath: '/mock/evidence/photo_01.jpg',
      );

      final cap = await repo.getById(capId);
      expect(cap!.status, 'done');

      final photos = fakeDb.tables['photos']!;
      final capPhotos = photos.where((p) => p['cap_id'] == capId).toList();
      expect(capPhotos.length, 1);
      expect(capPhotos.first['context'], 'cap_progress');
      expect(capPhotos.first['local_path'], '/mock/evidence/photo_01.jpg');
      expect(capPhotos.first['uploaded_by'], 'user-sm-1');
      expect(capPhotos.first['audit_result_id'], isNull);

      final repoPhotos = await repo.photosForCap(capId);
      expect(repoPhotos.length, 1);
      expect(repoPhotos.first['local_path'], '/mock/evidence/photo_01.jpg');
    });
  });

  group('CapRepository - Role Scoping & Filters (Spec §5 S14)', () {
    setUp(() async {
      // Seed audits for SM1 and SM2
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-sm1',
          'auditor_id': 'user-sm-1',
          'audit_date': '2026-09-20',
          'audit_type': 'daily',
          'week_number': 38,
          'year': 2026,
          'device_id': 'dev-1',
          'status': 'submitted',
          'submitted_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'audit-sm2',
          'auditor_id': 'user-sm-2',
          'audit_date': '2026-09-21',
          'audit_type': 'daily',
          'week_number': 38,
          'year': 2026,
          'device_id': 'dev-1',
          'status': 'submitted',
          'submitted_at': '2026-09-21T10:00:00Z',
        },
      ];

      // CAP 1: Assigned to SM1, from SM1 audit
      await repo.createCap(
        id: 'CAP-2026-W38-01',
        originAuditId: 'audit-sm1',
        originCheckpointId: 'cp-1',
        problemStatement: 'Cash desk dust',
        why1: 'No morning wipe',
        rootCause: 'Missing microfiber cloths',
        responsibleUserId: 'user-sm-1',
        deadline: '2026-09-28',
        verificationMethod: 'Inspection',
        actionSteps: ['Step 1', 'Step 2', 'Step 3'],
      );

      // CAP 2: Assigned to SM2, from SM2 audit
      await repo.createCap(
        id: 'CAP-2026-W38-02',
        originAuditId: 'audit-sm2',
        originCheckpointId: 'cp-2',
        problemStatement: 'Price tag missing',
        why1: 'Tag fell off',
        rootCause: 'Low adhesive',
        responsibleUserId: 'user-sm-2',
        deadline: '2026-09-29',
        verificationMethod: 'Inspection',
        actionSteps: ['Step A', 'Step B', 'Step C'],
      );
    });

    test('SM viewer only sees own/assigned CAPs', () async {
      final sm1Caps = await repo.listCaps(viewer: smUser1);
      expect(sm1Caps.length, 1);
      expect(sm1Caps.first.id, 'CAP-2026-W38-01');

      final sm2Caps = await repo.listCaps(viewer: smUser2);
      expect(sm2Caps.length, 1);
      expect(sm2Caps.first.id, 'CAP-2026-W38-02');
    });

    test('GM and OWNER see all CAPs', () async {
      final gmCaps = await repo.listCaps(viewer: gmUser);
      expect(gmCaps.length, 2);

      final ownerCaps = await repo.listCaps(viewer: ownerUser);
      expect(ownerCaps.length, 2);
    });

    test('listCaps search filters by problem statement or CAP ID', () async {
      final searchResult = await repo.listCaps(
        viewer: ownerUser,
        search: 'dust',
      );
      expect(searchResult.length, 1);
      expect(searchResult.first.id, 'CAP-2026-W38-01');

      final idResult = await repo.listCaps(
        viewer: ownerUser,
        search: 'W38-02',
      );
      expect(idResult.length, 1);
      expect(idResult.first.id, 'CAP-2026-W38-02');
    });
  });

  group('CapRepository - S13 Link Helpers', () {
    test('capsForAudit and capForResult return linked CAPs', () async {
      await repo.createCap(
        originAuditId: 'audit-spec-1',
        originResultId: 'res-fail-1',
        originCheckpointId: 'cp-10',
        problemStatement: 'Missing fire extinguisher tag',
        why1: 'Expired last month',
        rootCause: 'Vendor delay',
        responsibleUserId: 'user-sm-1',
        deadline: '2026-10-01',
        verificationMethod: 'Check tag',
        actionSteps: ['Step 1', 'Step 2', 'Step 3'],
        originDate: DateTime(2026, 9, 22),
      );

      final auditCaps = await repo.capsForAudit('audit-spec-1');
      expect(auditCaps.length, 1);

      final resultCap = await repo.capForResult('res-fail-1');
      expect(resultCap, isNotNull);
      expect(resultCap!.originCheckpointId, 'cp-10');

      final emptyCap = await repo.capForResult('res-nonexistent');
      expect(emptyCap, isNull);
    });
  });

  group('AuditRepository - listAudits (Spec §5 S12)', () {
    setUp(() {
      fakeDb.tables['audits'] = [
        {
          'id': 'audit-sm1-submitted',
          'auditor_id': 'user-sm-1',
          'audit_date': '2026-09-20',
          'audit_type': 'daily',
          'week_number': 38,
          'year': 2026,
          'device_id': 'dev-1',
          'status': 'submitted',
          'submitted_at': '2026-09-20T10:00:00Z',
        },
        {
          'id': 'audit-sm1-draft',
          'auditor_id': 'user-sm-1',
          'audit_date': '2026-09-21',
          'audit_type': 'daily',
          'week_number': 38,
          'year': 2026,
          'device_id': 'dev-1',
          'status': 'draft',
          'draft_started_at': '2026-09-21T09:00:00Z',
        },
        {
          'id': 'audit-sm2-submitted',
          'auditor_id': 'user-sm-2',
          'audit_date': '2026-09-21',
          'audit_type': 'daily',
          'week_number': 38,
          'year': 2026,
          'device_id': 'dev-1',
          'status': 'submitted',
          'submitted_at': '2026-09-21T12:00:00Z',
        },
        {
          'id': 'audit-owner-verified',
          'auditor_id': 'user-owner-1',
          'audit_date': '2026-09-22',
          'audit_type': 'daily',
          'week_number': 38,
          'year': 2026,
          'device_id': 'dev-1',
          'status': 'verified',
          'submitted_at': '2026-09-22T15:00:00Z',
        },
      ];
    });

    test('listAudits excludes drafts and returns submitted/verified only', () async {
      final audits = await auditRepo.listAudits(viewer: ownerUser);
      expect(audits.any((Audit a) => a.status == 'draft'), isFalse);
      expect(audits.length, 3);
    });

    test('listAudits role scoping limits SM to own authored audits', () async {
      final smAudits = await auditRepo.listAudits(viewer: smUser1);
      expect(smAudits.length, 1);
      expect(smAudits.first.id, 'audit-sm1-submitted');

      final ownerAudits = await auditRepo.listAudits(viewer: ownerUser);
      expect(ownerAudits.length, 3);
    });

    test('listAudits honors pagination limit and offset', () async {
      final page1 = await auditRepo.listAudits(
        viewer: ownerUser,
        limit: 2,
        offset: 0,
      );
      expect(page1.length, 2);

      final page2 = await auditRepo.listAudits(
        viewer: ownerUser,
        limit: 2,
        offset: 2,
      );
      expect(page2.length, 1);
    });
  });
}
