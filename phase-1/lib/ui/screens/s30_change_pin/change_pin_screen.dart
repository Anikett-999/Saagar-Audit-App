import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S30 — Settings: Change PIN.
///
/// Implements Spec §S30 and Sprint design:
/// - Accessible to all roles (Owner, GM, SM).
/// - 3 fields: Current PIN, New PIN, Confirm New PIN.
/// - Verifies Current PIN with [BCrypt.checkpw] against stored hash in SQLite.
/// - Validates 4-digit format and matching confirmation.
/// - Enforces that new PIN must differ from current PIN.
/// - Hashes the new PIN via [hashPin] (bcrypt cost 10) before calling [UserRepository.changePin].
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _currentPinError;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n, String userId) async {
    setState(() => _currentPinError = null);
    if (!_formKey.currentState!.validate()) return;

    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();

    setState(() => _submitting = true);

    try {
      // 1. Fetch user to verify current PIN hash
      final user = await UserRepository.instance.getById(userId);
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _currentPinError = l10n.s30CurrentPinIncorrect;
        });
        return;
      }

      // 2. Verify current PIN using BCrypt.checkpw
      final isMatch = BCrypt.checkpw(currentPin, user.pinHash);
      if (!isMatch) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _currentPinError = l10n.s30CurrentPinIncorrect;
        });
        return;
      }

      // 3. Hash new PIN via hashPin() (bcrypt cost 10)
      final newHash = hashPin(newPin);

      // 4. Update repository
      await UserRepository.instance.changePin(userId, newHash);

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s30PinChangedSuccess),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.goNamed('s27_settings');
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;

    // Route guard: if user is not logged in, redirect to settings/login
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            context.goNamed('s27_settings');
          } catch (_) {}
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s30Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.navyLight.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.navy,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                              fontFamily: 'DMSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.s30InstructionText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray600,
                              fontFamily: 'DMSans',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Field 1: Current PIN
              TextFormField(
                controller: _currentPinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureCurrent,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.s30CurrentPinLabel,
                  hintText: l10n.s30CurrentPinHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  counterText: '',
                  errorText: _currentPinError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    },
                  ),
                ),
                onChanged: (_) {
                  if (_currentPinError != null) {
                    setState(() => _currentPinError = null);
                  }
                },
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.length != 4 || !RegExp(r'^\d{4}$').hasMatch(trimmed)) {
                    return l10n.s30CurrentPinRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Field 2: New PIN
              TextFormField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureNew,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.s30NewPinLabel,
                  hintText: l10n.s30NewPinHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                ),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.length != 4 || !RegExp(r'^\d{4}$').hasMatch(trimmed)) {
                    return l10n.s30NewPinRequired;
                  }
                  if (trimmed == _currentPinController.text.trim()) {
                    return l10n.s30NewPinSameAsCurrent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Field 3: Confirm New PIN
              TextFormField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirm,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: l10n.s30ConfirmPinLabel,
                  hintText: l10n.s30ConfirmPinHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed != _newPinController.text.trim()) {
                    return l10n.s30PinMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  l10n.s30SaveButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _submitting ? null : () => _submit(l10n, currentUser.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
