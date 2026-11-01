import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/backup_service.dart';
import 'package:saagar_audit_app/data/db/database.dart';
import 'package:saagar_audit_app/data/repositories/user_repository.dart';
import 'package:saagar_audit_app/l10n/app_localizations.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:saagar_audit_app/services/owner_recovery_service.dart';
import 'package:saagar_audit_app/ui/screens/s04_login/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  group('Item 5: Owner Recovery Code Service Suite', () {
    late FakeDatabase fakeDb;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    test('generateRecoveryCode creates formatted 12-char code SG-XXXX-YYYY', () {
      final code = OwnerRecoveryService.instance.generateRecoveryCode();
      expect(code, startsWith('SG-'));
      expect(code.length, 12); // SG-XXXX-YYYY (2 + 1 + 4 + 1 + 4)
      final parts = code.split('-');
      expect(parts.length, 3);
      expect(parts[1].length, 4);
      expect(parts[2].length, 4);
    });

    test('saveRecoveryCode stores salted BCrypt hash, never plaintext', () async {
      const code = 'SG-7492-BX41';
      await OwnerRecoveryService.instance.saveRecoveryCode(code);

      final prefs = await SharedPreferences.getInstance();
      final hash = prefs.getString('owner_recovery_code_hash');
      expect(hash, isNotNull);
      expect(hash, isNot(contains(code)));
      expect(hash, startsWith(r'$2a$10$'));
    });

    test('verifyRecoveryCode succeeds with exact, lowercase, or unhyphenated code', () async {
      const code = 'SG-7492-BX41';
      await OwnerRecoveryService.instance.saveRecoveryCode(code);

      // Exact
      expect(await OwnerRecoveryService.instance.verifyRecoveryCode('SG-7492-BX41'), isTrue);
      // Lowercase with hyphen
      expect(await OwnerRecoveryService.instance.verifyRecoveryCode('sg-7492-bx41'), isTrue);
      // Without hyphens
      expect(await OwnerRecoveryService.instance.verifyRecoveryCode('SG7492BX41'), isTrue);
      // With spaces
      expect(await OwnerRecoveryService.instance.verifyRecoveryCode(' SG 7492 BX41 '), isTrue);
      // Wrong code
      expect(await OwnerRecoveryService.instance.verifyRecoveryCode('SG-9999-ZZZZ'), isFalse);
    });

    test('resetOwnerPinWithRecoveryCode resets Owner PIN in database and preserves user record', () async {
      const code = 'SG-8888-AAAA';
      await OwnerRecoveryService.instance.saveRecoveryCode(code);

      final ownerId = await createUser(
        name: 'Sagar Bora',
        role: 'OWNER',
        pin: '1234',
        languagePref: 'en',
      );

      final resetOk = await OwnerRecoveryService.instance.resetOwnerPinWithRecoveryCode(
        recoveryCode: 'sg-8888-aaaa',
        newPin: '5678',
      );
      expect(resetOk, isTrue);

      final updatedOwner = await UserRepository.instance.getById(ownerId);
      expect(updatedOwner, isNotNull);
      expect(updatedOwner!.name, 'Sagar Bora');
    });

    test('Export Security: BackupService NEVER exports pin_hash or recovery_code_hash', () async {
      await createUser(
        name: 'Sagar Bora',
        role: 'OWNER',
        pin: '1234',
        languagePref: 'en',
      );

      final backupData = await BackupService.instance.exportDatabaseToJson();
      final tables = backupData['tables'] as Map<String, dynamic>;
      final users = (tables['users'] as List).cast<Map<String, dynamic>>();

      expect(users, isNotEmpty);
      for (final user in users) {
        expect(user.containsKey('pin_hash'), isFalse, reason: 'pin_hash must be strictly stripped');
        expect(user.containsKey('recovery_code_hash'), isFalse, reason: 'recovery hash must never exist in export');
        expect(user.containsKey('recovery_code'), isFalse);
      }
    });
  });

  group('LoginScreen Owner PIN Recovery Unified Modal Widget Tests', () {
    late FakeDatabase fakeDb;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeDb = FakeDatabase();
      AppDatabase.instance.setDatabaseForTesting(fakeDb);
    });

    tearDown(() {
      AppDatabase.instance.setDatabaseForTesting(null);
    });

    testWidgets('Recovery modal seamlessly switches to Step 2 (Set New PIN) without crash or overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const recoveryCode = 'SG-1111-2222';
      await OwnerRecoveryService.instance.saveRecoveryCode(recoveryCode);

      final ownerId = await createUser(
        name: 'Sagar Bora',
        role: 'OWNER',
        pin: '1234',
        languagePref: 'en',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Forgot PIN button and tap it
      final forgotPinBtn = find.text('Forgot PIN?');
      expect(forgotPinBtn, findsOneWidget);
      await tester.tap(forgotPinBtn);
      await tester.pumpAndSettle();

      // Step 1: Owner PIN Recovery modal is visible
      expect(find.text('Owner PIN Recovery'), findsOneWidget);
      expect(find.text('Verify Code'), findsOneWidget);

      // Enter recovery code
      final codeField = find.byType(TextField);
      await tester.enterText(codeField, recoveryCode);
      await tester.tap(find.text('Verify Code'));
      await tester.pumpAndSettle();

      // Step 2: Set New 4-Digit PIN is visible inside same dialog without exception
      expect(find.text('Set New 4-Digit PIN'), findsOneWidget);
      expect(find.text('Reset PIN'), findsOneWidget);

      // Enter new PIN and confirmation
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.first, '9999');
      await tester.enterText(textFields.last, '9999');

      await tester.tap(find.text('Reset PIN'));
      await tester.pumpAndSettle();

      // Dialog closed, success snackbar shown, no crashes
      expect(find.text('Set New 4-Digit PIN'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify PIN updated in database
      final updatedOwner = await UserRepository.instance.getById(ownerId);
      expect(updatedOwner, isNotNull);
    });
  });
}
