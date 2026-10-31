import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/owner_recovery_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pin_numpad.dart';

/// S3 First-Time Setup. Only shown when the `users` table is empty.
///
/// Phase 1 flow: Owner enters name, picks a 4-digit PIN, confirms it.
/// Generates Master Recovery Code (F16), displays it to Owner, and auto-logs in (F-UX).
class FirstSetupScreen extends ConsumerStatefulWidget {
  const FirstSetupScreen({super.key});

  @override
  ConsumerState<FirstSetupScreen> createState() => _FirstSetupScreenState();
}

class _FirstSetupScreenState extends ConsumerState<FirstSetupScreen> {
  final _nameController = TextEditingController();
  String? _firstPin;
  bool _confirming = false;
  bool _shakeNumpad = false;
  String? _error;
  String? _generatedRecoveryCode;
  String? _createdUserId;
  String? _createdName;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onPinEntered(String pin) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    // Validate name upfront before proceeding with PIN confirmation (Client Ref: §F / ¶364)
    if (name.length < 2) {
      setState(() {
        _error = l10n.s03NameTooShort;
        _firstPin = null;
        _confirming = false;
        _shakeNumpad = !_shakeNumpad;
      });
      return;
    }

    if (!_confirming) {
      setState(() {
        _firstPin = pin;
        _confirming = true;
        _error = null;
      });
      return;
    }

    if (pin != _firstPin) {
      setState(() {
        _shakeNumpad = !_shakeNumpad;
        _error = l10n.s03PinsMismatch;
        _firstPin = null;
        _confirming = false;
      });
      return;
    }

    final lang = Localizations.localeOf(context).languageCode == 'mr' ? 'mr' : 'en';
    final userId = await createUser(
      name: name,
      role: 'OWNER',
      pin: pin,
      languagePref: lang,
    );

    // Generate and cryptographically store Master Recovery Code (Client Ref: F16)
    final recoveryCode = OwnerRecoveryService.instance.generateRecoveryCode();
    await OwnerRecoveryService.instance.saveRecoveryCode(recoveryCode);

    if (!mounted) return;
    setState(() {
      _generatedRecoveryCode = recoveryCode;
      _createdUserId = userId;
      _createdName = name;
    });
  }

  void _onContinueToApp() {
    final lang = Localizations.localeOf(context).languageCode == 'mr' ? 'mr' : 'en';
    if (_createdUserId != null && _createdName != null) {
      // Auto-authenticate directly to Home (eliminates redundant 3rd PIN prompt, Client Ref: §F / ¶364)
      ref.read(authProvider.notifier).setCurrentUser(
        AuthUser(
          id: _createdUserId!,
          name: _createdName!,
          role: 'OWNER',
          languagePref: lang,
        ),
      );
    }
    context.goNamed('s05_home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_generatedRecoveryCode != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.goldPale,
                    child: Icon(Icons.key_rounded, size: 40, color: AppColors.goldDark),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.s03RecoveryCodeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 26,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.s03RecoveryCodeSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _generatedRecoveryCode!,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppColors.navy),
                        tooltip: 'Copy Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedRecoveryCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.s03RecoveryCodeCopied)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.gold,
                    ),
                    onPressed: _onContinueToApp,
                    child: Text(
                      l10n.btnContinueToApp,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.s03Title,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 28,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.s03Subtitle,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  enabled: !_confirming,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: l10n.s03OwnerName,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _confirming ? l10n.s03ReenterPin : l10n.s03OwnerPin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: PinNumpad(
                      key: ValueKey(_confirming),
                      onPinComplete: (pin) {
                        FocusScope.of(context).unfocus();
                        _onPinEntered(pin);
                      },
                      shake: _shakeNumpad,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
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
      ),
    );
  }
}
