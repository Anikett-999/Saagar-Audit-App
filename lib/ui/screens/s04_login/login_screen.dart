import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cloud_sync_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/owner_recovery_service.dart';
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
  int _errorCount = 0;
  String? _error;
  bool _loading = true;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authProvider.notifier).loadPersistedState().then((_) {
          if (mounted) {
            _syncLockoutTimer(ref.read(authProvider));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _syncLockoutTimer(AuthState auth) {
    final uid = _selectedUserId;
    if (uid != null && auth.isUserLockedOut(uid)) {
      if (_lockoutTimer == null || !_lockoutTimer!.isActive) {
        _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final currentAuth = ref.read(authProvider);
          if (!currentAuth.isUserLockedOut(_selectedUserId)) {
            timer.cancel();
            _lockoutTimer = null;
            setState(() {
              _error = null;
            });
          } else {
            final l10n = AppLocalizations.of(context);
            final rem = currentAuth.userLockoutRemaining(_selectedUserId);
            setState(() {
              _error = l10n != null
                  ? l10n.s04TooManyAttempts(rem.inSeconds)
                  : 'Too many wrong attempts. Try again in ${rem.inSeconds}s.';
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
      // Auto-trigger role-based background sync upon successful login
      unawaited(ref.read(cloudSyncProvider.notifier).syncNow());
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
    final userLocked = auth.isUserLockedOut(uid);
    final attemptsLeft = 5 - auth.userFailedAttempts(uid);

    setState(() {
      _errorCount++;
      _shakeNumpad = !_shakeNumpad;
      if (userLocked) {
        final rem = auth.userLockoutRemaining(uid);
        _error = l10n.s04TooManyAttempts(rem.inSeconds);
        _syncLockoutTimer(auth);
      } else {
        if (attemptsLeft == 1) {
          _error = l10n.s04WrongPinOneAttemptLeft;
        } else {
          _error = l10n.s04WrongPinAttemptsLeft(attemptsLeft);
        }
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
    final userLocked = auth.isUserLockedOut(_selectedUserId);
    final userRemaining = auth.userLockoutRemaining(_selectedUserId);
    _syncLockoutTimer(auth);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                onChanged: (v) {
                  setState(() {
                    _selectedUserId = v;
                    _error = null;
                  });
                },
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: userLocked
                        ? _buildLockout(l10n, userRemaining)
                        : PinNumpad(
                            key: ValueKey(_selectedUserId),
                            onPinComplete: _onPin,
                            shake: _shakeNumpad,
                            errorCount: _errorCount,
                          ),
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
              if (_isOwnerSelected) ...[
                TextButton(
                  onPressed: _showForgotPinDialog,
                  child: Text(
                    l10n.s04ForgotPin,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
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

  bool get _isOwnerSelected {
    if (_selectedUserId == null) return false;
    final user = _users.firstWhere(
      (u) => u['id'] == _selectedUserId,
      orElse: () => {},
    );
    return user['role'] == 'OWNER';
  }

  Future<void> _showForgotPinDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OwnerRecoveryDialog(
        l10n: l10n,
        onSuccess: () async {
          if (_selectedUserId != null) {
            await ref.read(authProvider.notifier).unlockUser(_selectedUserId!);
          }
        },
      ),
    );

    if (success == true && mounted) {
      setState(() {
        _error = null;
        _errorCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s04PinResetSuccess),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

class _OwnerRecoveryDialog extends StatefulWidget {
  const _OwnerRecoveryDialog({
    required this.l10n,
    required this.onSuccess,
  });

  final AppLocalizations l10n;
  final VoidCallback onSuccess;

  @override
  State<_OwnerRecoveryDialog> createState() => _OwnerRecoveryDialogState();
}

class _OwnerRecoveryDialogState extends State<_OwnerRecoveryDialog> {
  int _step = 1;
  String? _verifiedCode;

  late final TextEditingController _codeController;
  late final TextEditingController _pinController;
  late final TextEditingController _confirmController;

  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _pinController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final ok = await OwnerRecoveryService.instance.verifyRecoveryCode(code);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _isLoading = false;
        _verifiedCode = code;
        _step = 2;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = widget.l10n.s04RecoveryInvalid;
      });
    }
  }

  Future<void> _resetPin() async {
    final p1 = _pinController.text.trim();
    final p2 = _confirmController.text.trim();

    if (p1.length != 4 || int.tryParse(p1) == null) {
      setState(() {
        _error = 'PIN must be exactly 4 digits.';
      });
      return;
    }

    if (p1 != p2) {
      setState(() {
        _error = widget.l10n.s03PinsMismatch;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ok = await OwnerRecoveryService.instance.resetOwnerPinWithRecoveryCode(
        recoveryCode: _verifiedCode!,
        newPin: p1,
      );

      if (!mounted) return;

      if (ok) {
        widget.onSuccess();
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _error = widget.l10n.s04RecoveryInvalid;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to reset PIN: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _step == 1 ? Icons.vpn_key_outlined : Icons.lock_reset,
            color: AppColors.gold,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _step == 1
                  ? widget.l10n.s04RecoveryTitle
                  : widget.l10n.s04ResetPinTitle,
              style: const TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == 1) ...[
              Text(
                widget.l10n.s04RecoveryPrompt,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppColors.gray800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                autofocus: true,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. SG-7492-BX41',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) => _verifyCode(),
              ),
            ] else ...[
              const Text(
                'Enter a new 4-digit PIN for your Owner account:',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppColors.gray800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                autofocus: true,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.l10n.s03OwnerPin,
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.l10n.s04ConfirmNewPin,
                  counterText: '',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (_) => _resetPin(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(widget.l10n.btnCancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.gold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isLoading ? null : (_step == 1 ? _verifyCode : _resetPin),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                )
              : Text(_step == 1 ? widget.l10n.btnVerifyCode : widget.l10n.btnResetPin),
        ),
      ],
    );
  }
}
