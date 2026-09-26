import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/cro_repository.dart';
import 'package:saagar_audit_app/data/repositories/user_repository.dart';

import 'helpers/fake_database.dart';

void main() {
  group('UserRepository & CroRepository Data Layer Tests (Sprint S27-S32)', () {
    late FakeDatabase fakeDb;

    setUp(() {
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);

      // Seed initial Owner (created at S03 First-Time Setup)
      fakeDb.tables['users']!.add({
        'id': 'owner-uuid-001',
        'name': 'Aniket Owner',
        'role': 'OWNER',
        'pin_hash': r'$2a$10$dummyOwnerHashForTestingPurposesOnly',
        'language_pref': 'en',
        'phone': '9876543210',
        'is_active': 1,
        'created_at': '2026-09-01T08:00:00.000Z',
        'last_login_at': null,
        'created_by': null,
      });

      // Seed initial CROs
      fakeDb.tables['cros']!.add({
        'id': 'cro-uuid-001',
        'name': 'Rahul Shinde',
        'counter': 'Titan',
        'shift': 'morning',
        'is_active': 1,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });
      fakeDb.tables['cros']!.add({
        'id': 'cro-uuid-002',
        'name': 'Pooja Patil',
        'counter': 'Helios',
        'shift': 'afternoon',
        'is_active': 0,
        'joined_at': '2026-09-01T08:00:00.000Z',
      });
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    group('UserRepository - Single Owner Rule & Validation', () {
      test('addUser with role OWNER throws ArgumentError per Spec §S29', () async {
        expect(
          () => UserRepository.instance.addUser(
            name: 'Second Owner',
            role: 'OWNER',
            pinHash: 'hash123',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Cannot create user with role OWNER'),
            ),
          ),
        );
      });

      test('addUser with invalid role throws ArgumentError', () async {
        expect(
          () => UserRepository.instance.addUser(
            name: 'Cashier Staff',
            role: 'CASHIER',
            pinHash: 'hash123',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid role'),
            ),
          ),
        );
      });

      test('addUser with short name (< 2 chars) throws ArgumentError', () async {
        expect(
          () => UserRepository.instance.addUser(
            name: 'A',
            role: 'SM',
            pinHash: 'hash123',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('addUser creates SM user successfully and returns UUID', () async {
        final id = await UserRepository.instance.addUser(
          name: 'Sunil SM',
          role: 'SM',
          pinHash: 'smHash123',
          phone: '9988776655',
          createdBy: 'owner-uuid-001',
        );

        expect(id, isNotEmpty);
        final created = await UserRepository.instance.getById(id);
        expect(created, isNotNull);
        expect(created!.name, 'Sunil SM');
        expect(created.role, 'SM');
        expect(created.isSm, isTrue);
        expect(created.isOwner, isFalse);
        expect(created.isActive, isTrue);
        expect(created.phone, '9988776655');
        expect(created.createdBy, 'owner-uuid-001');
      });

      test('addUser creates GM user successfully', () async {
        final id = await UserRepository.instance.addUser(
          name: 'Ganesh GM',
          role: 'GM',
          pinHash: 'gmHash123',
        );

        final created = await UserRepository.instance.getById(id);
        expect(created, isNotNull);
        expect(created!.role, 'GM');
        expect(created.isGm, isTrue);
      });
    });

    group('UserRepository - Immutability, Deactivation & Lifecycle', () {
      test('deactivate keeps the user row but marks isActive=false', () async {
        final smId = await UserRepository.instance.addUser(
          name: 'Temp SM',
          role: 'SM',
          pinHash: 'hashTemp',
        );

        await UserRepository.instance.deactivate(smId);

        // Row must NOT be deleted (audit-trail integrity per spec §S29)
        final user = await UserRepository.instance.getById(smId);
        expect(user, isNotNull);
        expect(user!.isActive, isFalse);

        // listAll includes the deactivated user
        final all = await UserRepository.instance.listAll();
        expect(all.any((u) => u.id == smId), isTrue);

        // listActive excludes the deactivated user
        final active = await UserRepository.instance.listActive();
        expect(active.any((u) => u.id == smId), isFalse);
      });

      test('deactivate on OWNER throws StateError to safeguard system', () async {
        expect(
          () => UserRepository.instance.deactivate('owner-uuid-001'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Cannot deactivate the Owner'),
            ),
          ),
        );
      });

      test('reactivate marks user isActive=true again', () async {
        final smId = await UserRepository.instance.addUser(
          name: 'Reactivated SM',
          role: 'SM',
          pinHash: 'hash123',
        );

        await UserRepository.instance.deactivate(smId);
        expect((await UserRepository.instance.getById(smId))!.isActive, isFalse);

        await UserRepository.instance.reactivate(smId);
        expect((await UserRepository.instance.getById(smId))!.isActive, isTrue);
      });

      test('resetPin updates pin_hash', () async {
        final smId = await UserRepository.instance.addUser(
          name: 'Reset PIN SM',
          role: 'SM',
          pinHash: 'oldHash',
        );

        await UserRepository.instance.resetPin(smId, 'newResetHash');
        final user = await UserRepository.instance.getById(smId);
        expect(user!.pinHash, 'newResetHash');
      });

      test('changePin updates pin_hash', () async {
        await UserRepository.instance.changePin('owner-uuid-001', 'newOwnerPinHash');
        final owner = await UserRepository.instance.getById('owner-uuid-001');
        expect(owner!.pinHash, 'newOwnerPinHash');
      });

      test('updateLanguagePref updates language preference with validation', () async {
        await UserRepository.instance.updateLanguagePref('owner-uuid-001', 'mr');
        final owner = await UserRepository.instance.getById('owner-uuid-001');
        expect(owner!.languagePref, 'mr');

        expect(
          () => UserRepository.instance.updateLanguagePref('owner-uuid-001', 'fr'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('listAll orders users alphabetically by name', () async {
        await UserRepository.instance.addUser(name: 'Zara SM', role: 'SM', pinHash: 'h1');
        await UserRepository.instance.addUser(name: 'Amit GM', role: 'GM', pinHash: 'h2');

        final all = await UserRepository.instance.listAll();
        final names = all.map((u) => u.name).toList();
        expect(names, ['Amit GM', 'Aniket Owner', 'Zara SM']);
      });
    });

    group('CroRepository Extensions (listAll, update, reactivate)', () {
      test('listAll returns both active and inactive CROs sorted by name', () async {
        final all = await CroRepository.instance.listAll();
        expect(all.length, 2);
        // Pooja Patil (inactive) and Rahul Shinde (active)
        expect(all[0].name, 'Pooja Patil');
        expect(all[1].name, 'Rahul Shinde');
      });

      test('listActive returns only active CROs', () async {
        final active = await CroRepository.instance.listActive();
        expect(active.length, 1);
        expect(active.first.name, 'Rahul Shinde');
      });

      test('update modifies CRO details', () async {
        await CroRepository.instance.update(
          id: 'cro-uuid-001',
          name: 'Rahul S. Shinde',
          counter: 'Helios',
          shift: 'afternoon',
        );

        final cro = await CroRepository.instance.getById('cro-uuid-001');
        expect(cro, isNotNull);
        expect(cro!.name, 'Rahul S. Shinde');
        expect(cro.counter, 'Helios');
        expect(cro.shift, 'afternoon');
      });

      test('reactivate marks inactive CRO as active', () async {
        var cro = await CroRepository.instance.getById('cro-uuid-002');
        expect(cro!.isActive, isFalse);

        await CroRepository.instance.reactivate('cro-uuid-002');
        cro = await CroRepository.instance.getById('cro-uuid-002');
        expect(cro!.isActive, isTrue);

        final active = await CroRepository.instance.listActive();
        expect(active.length, 2);
      });
    });
  });
}
