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

  group('Per-User Lockout & Progressive Back-Off (Item 8 / Client Ref F23)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Wrong attempts for User A (SM) lock out User A only, leaving User B (Owner) unlocked', () {
      final notifier = AuthNotifier();
      const smId = 'user-sm-001';
      const ownerId = 'user-owner-001';

      // SM fails 5 times
      for (var i = 0; i < 5; i++) {
        notifier.registerFailureForUser(smId);
      }

      // SM is locked out
      expect(notifier.state.isUserLockedOut(smId), isTrue);
      expect(notifier.state.userLockoutRemaining(smId).inSeconds, inInclusiveRange(55, 60));
      expect(notifier.state.userFailedAttempts(smId), 0); // reset upon lockout trigger

      // Owner is completely unlocked
      expect(notifier.state.isUserLockedOut(ownerId), isFalse);
      expect(notifier.state.userLockoutRemaining(ownerId), Duration.zero);
      expect(notifier.state.userFailedAttempts(ownerId), 0);
    });

    test('Progressive lockout increases penalty: 60s -> 300s (5m) -> 900s (15m)', () {
      final notifier = AuthNotifier();
      const gmId = 'user-gm-001';
      final now = DateTime.now();

      // Lockout 1: 5 fails -> 60s
      for (var i = 0; i < 5; i++) {
        notifier.registerFailureForUser(gmId, at: now.add(Duration(seconds: i)));
      }
      expect(notifier.state.isUserLockedOut(gmId), isTrue);
      final info1 = notifier.state.userLockouts[gmId]!;
      expect(info1.consecutiveLockouts, 1);
      expect(info1.lockoutUntil!.difference(now.add(const Duration(seconds: 4))).inSeconds, 60);

      // Fast-forward after 60s: Lockout 2 -> 5 fails -> 300s (5 minutes)
      final afterLockout1 = now.add(const Duration(seconds: 65));
      for (var i = 0; i < 5; i++) {
        notifier.registerFailureForUser(gmId, at: afterLockout1.add(Duration(seconds: i)));
      }
      expect(notifier.state.isUserLockedOut(gmId), isTrue);
      final info2 = notifier.state.userLockouts[gmId]!;
      expect(info2.consecutiveLockouts, 2);
      expect(info2.lockoutUntil!.difference(afterLockout1.add(const Duration(seconds: 4))).inSeconds, 300);

      // Fast-forward after 300s: Lockout 3 -> 5 fails -> 900s (15 minutes)
      final afterLockout2 = afterLockout1.add(const Duration(seconds: 305));
      for (var i = 0; i < 5; i++) {
        notifier.registerFailureForUser(gmId, at: afterLockout2.add(Duration(seconds: i)));
      }
      expect(notifier.state.isUserLockedOut(gmId), isTrue);
      final info3 = notifier.state.userLockouts[gmId]!;
      expect(info3.consecutiveLockouts, 3);
      expect(info3.lockoutUntil!.difference(afterLockout2.add(const Duration(seconds: 4))).inSeconds, 900);
    });

    test('Per-user lockout persists and rehydrates across app restarts', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier1 = AuthNotifier(prefs: prefs);
      const smId = 'user-sm-persisted';
      const ownerId = 'user-owner-persisted';

      // SM fails 5 times
      for (var i = 0; i < 5; i++) {
        notifier1.registerFailureForUser(smId);
      }
      await notifier1.lastPersistOperation;

      // Verify stored in prefs under auth_user_lockouts_v2
      expect(prefs.getString('auth_user_lockouts_v2'), isNotNull);

      // Rehydrate in new notifier instance
      final notifier2 = AuthNotifier(prefs: prefs);
      await notifier2.loadPersistedState(prefs: prefs);

      expect(notifier2.state.isUserLockedOut(smId), isTrue);
      expect(notifier2.state.isUserLockedOut(ownerId), isFalse);
    });
  });
}

