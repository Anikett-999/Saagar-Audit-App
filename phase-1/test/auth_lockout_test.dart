import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthNotifier Rolling 60s PIN Lockout (Spec §5 S4 & Hard Rule #4)', () {
    late AuthNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = AuthNotifier();
    });

    test('Initial state is not locked out and has 0 failed attempts', () {
      expect(notifier.state.isLockedOut, isFalse);
      expect(notifier.state.failedAttempts, 0);
    });

    test('Fewer than 5 attempts within 60s does not trigger lockout', () {
      final base = DateTime(2026, 9, 20, 10, 0, 0);
      notifier.registerFailure(at: base);
      notifier.registerFailure(at: base.add(const Duration(seconds: 10)));
      notifier.registerFailure(at: base.add(const Duration(seconds: 20)));
      notifier.registerFailure(at: base.add(const Duration(seconds: 30)));

      expect(notifier.state.failureTimestamps.length, 4);
      expect(notifier.state.isLockedOut, isFalse);
    });

    test('5 failed attempts within 60s triggers strict 60s lockout', () {
      for (var i = 0; i < 5; i++) {
        notifier.registerFailure();
      }

      expect(notifier.state.isLockedOut, isTrue);
      expect(notifier.state.lockoutRemaining.inSeconds, inInclusiveRange(55, 60));
    });

    test('Attempts spaced > 60s decay and do not accumulate to trigger lockout', () {
      final base = DateTime(2026, 9, 20, 10, 0, 0);
      // First attempt at 10:00:00
      notifier.registerFailure(at: base);
      // Second attempt at 10:00:15
      notifier.registerFailure(at: base.add(const Duration(seconds: 15)));
      // Third attempt at 10:00:30
      notifier.registerFailure(at: base.add(const Duration(seconds: 30)));
      // Fourth attempt at 10:00:45
      notifier.registerFailure(at: base.add(const Duration(seconds: 45)));

      // 5th attempt arrives at 10:01:05 (65 seconds after base).
      // The first attempt at 10:00:00 has decayed (>60s ago).
      notifier.registerFailure(at: base.add(const Duration(seconds: 65)));

      // Total recent attempts in the 60s window should be 4, NOT 5, so NOT locked out!
      expect(notifier.state.isLockedOut, isFalse);
      expect(notifier.state.failureTimestamps.length, 4);
    });
  });

  group('AuthNotifier Lockout Persistence across app reboots (DEF-01)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Lockout persists to SharedPreferences and rehydrates in new AuthNotifier', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier1 = AuthNotifier(prefs: prefs);

      // Trigger 5 failures
      for (var i = 0; i < 5; i++) {
        notifier1.registerFailure();
      }
      await notifier1.lastPersistOperation;
      expect(notifier1.state.isLockedOut, isTrue);

      // Verify written to prefs
      final storedUntil = prefs.getString('auth_lockout_until');
      expect(storedUntil, isNotNull);

      // Simulate app kill & restart: construct a brand-new AuthNotifier with same prefs
      final notifier2 = AuthNotifier(prefs: prefs);
      await notifier2.loadPersistedState(prefs: prefs);

      // Must still be locked out
      expect(notifier2.state.isLockedOut, isTrue);
      expect(notifier2.state.lockoutRemaining.inSeconds, inInclusiveRange(50, 60));
    });

    test('Expired lockout in SharedPreferences is cleaned up and does not lock out', () async {
      final pastLockout = DateTime.now().subtract(const Duration(seconds: 10));
      SharedPreferences.setMockInitialValues({
        'auth_lockout_until': pastLockout.toIso8601String(),
      });
      final prefs = await SharedPreferences.getInstance();

      final notifier = AuthNotifier(prefs: prefs);
      await notifier.loadPersistedState(prefs: prefs);

      expect(notifier.state.isLockedOut, isFalse);
      expect(prefs.getString('auth_lockout_until'), isNull);
    });

    test('Recent failures persist and count towards lockout in new session', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier1 = AuthNotifier(prefs: prefs);

      // 3 failures
      notifier1.registerFailure();
      notifier1.registerFailure();
      notifier1.registerFailure();
      await notifier1.lastPersistOperation;
      expect(notifier1.state.isLockedOut, isFalse);
      expect(notifier1.state.failedAttempts, 3);

      // Reboot app
      final notifier2 = AuthNotifier(prefs: prefs);
      await notifier2.loadPersistedState(prefs: prefs);
      expect(notifier2.state.failedAttempts, 3);

      // 2 more failures in new session triggers lockout!
      notifier2.registerFailure();
      notifier2.registerFailure();
      await notifier2.lastPersistOperation;
      expect(notifier2.state.isLockedOut, isTrue);
    });
  });
}

