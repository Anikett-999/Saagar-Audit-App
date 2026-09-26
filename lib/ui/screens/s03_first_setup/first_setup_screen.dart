import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pin_numpad.dart';

/// S3 First-Time Setup. Only shown when the `users` table is empty.
///
/// Phase 1 minimal flow: Owner enters name, picks a 4-digit PIN, confirms it.
/// Adding GM/SM/CROs is deferred to Settings (S28/S29) — Decision Locked #1
/// says Owner can add team later without blocking the audit flow.
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onPinEntered(String pin) async {
    final l10n = AppLocalizations.of(context)!;
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

    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _error = l10n.s03NameTooShort);
      return;
    }

    await createUser(
      name: name,
      role: 'OWNER',
      pin: pin,
      languagePref:
          Localizations.localeOf(context).languageCode == 'mr' ? 'mr' : 'en',
    );

    if (!mounted) return;
    context.goNamed('s04_login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
