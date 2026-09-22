import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';
import '../../widgets/pin_numpad.dart';

/// S4 Login.
///
/// Per Spec §5 S4:
///   * Name dropdown sorted with Owner first, then GM, then SM (alpha within).
///   * 4-digit PIN via custom in-app numpad (no OS keyboard).
///   * 5 wrong attempts in 60s → 60-second lockout with countdown + shake.
///
/// On success, navigates to S5 Home.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  List<Map<String, Object?>> _users = const [];
  String? _selectedUserId;
  bool _shakeNumpad = false;
  String? _error;
  bool _loading = true;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    ref.read(authProvider.notifier).loadPersistedState().then((_) {
      if (mounted) {
        _syncLockoutTimer(ref.read(authProvider));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncLockoutTimer(ref.read(authProvider));
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _syncLockoutTimer(AuthState auth) {
    if (auth.isLockedOut) {
      if (_lockoutTimer == null || !_lockoutTimer!.isActive) {
        _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final currentAuth = ref.read(authProvider);
          if (!currentAuth.isLockedOut) {
            timer.cancel();
            _lockoutTimer = null;
            setState(() {
              _error = null;
            });
          } else {
            final l10n = AppLocalizations.of(context);
            setState(() {
              _error = l10n != null
                  ? l10n.s04TooManyAttempts(currentAuth.lockoutRemaining.inSeconds)
                  : 'Too many wrong attempts. Try again in ${currentAuth.lockoutRemaining.inSeconds}s.';
            });
          }
        });
      }
    } else {
      _lockoutTimer?.cancel();
      _lockoutTimer = null;
    }
  }

  Future<void> _loadUsers() async {
    final db = AppDatabase.instance.db;
    // Owner first, then GM, then SM. Alphabetical within role.
    final rows = await db.rawQuery('''
      SELECT id, name, role FROM users
      WHERE is_active = 1
      ORDER BY
        CASE role
          WHEN 'OWNER' THEN 0
          WHEN 'GM'    THEN 1
          WHEN 'SM'    THEN 2
        END,
        name COLLATE NOCASE
    ''');
    setState(() {
      _users = rows;
      _selectedUserId = rows.isNotEmpty ? rows.first['id'] as String : null;
      _loading = false;
    });
  }

  Future<void> _onPin(String pin) async {
    final uid = _selectedUserId;
    if (uid == null) return;

    final ok =
        await ref.read(authProvider.notifier).tryLogin(userId: uid, pin: pin);
    if (!mounted) return;

    if (ok) {
      _lockoutTimer?.cancel();
      final user = ref.read(authProvider).user;
      if (user != null && (user.languagePref == 'en' || user.languagePref == 'mr')) {
        await ref.read(localeProvider.notifier).set(Locale(user.languagePref));
      }
      if (!mounted) return;
      try {
        context.goNamed('s05_home');
      } catch (_) {
        // GoRouter not present in ancestor tree (e.g. isolated unit widget tests)
      }
      return;
    }

    final auth = ref.read(authProvider);
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _shakeNumpad = !_shakeNumpad;
      if (auth.isLockedOut) {
        _error = l10n.s04TooManyAttempts(auth.lockoutRemaining.inSeconds);
        _syncLockoutTimer(auth);
      } else {
        _error = l10n.s04WrongPinAttemptsLeft(5 - auth.failedAttempts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final locked = auth.isLockedOut;
    _syncLockoutTimer(auth);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.s04SelectName,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                items: [
                  for (final u in _users)
                    DropdownMenuItem(
                      value: u['id'] as String,
                      child: Text('${u['name']}  ·  ${u['role']}'),
                    ),
                ],
                onChanged: locked
                    ? null
                    : (v) => setState(() => _selectedUserId = v),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.s04EnterPin,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'DMSans', fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: locked
                      ? _buildLockout(l10n, auth.lockoutRemaining)
                      : PinNumpad(
                          onPinComplete: _onPin,
                          shake: _shakeNumpad,
                        ),
                ),
              ),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockout(AppLocalizations l10n, Duration remaining) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_clock_outlined,
          size: 48,
          color: AppColors.red,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.s04LockedCountdown(remaining.inSeconds),
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 16,
            color: AppColors.red,
          ),
        ),
      ],
    );
  }
}
