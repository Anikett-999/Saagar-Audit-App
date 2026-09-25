import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S24 — Reference Escalation Triggers (Spec §5 S24 & §11.2).
///
/// Full implementation coming in Step 4.
class EscalationTriggersScreen extends StatelessWidget {
  const EscalationTriggersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s24Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: Center(
        child: Text(
          l10n.s24Title,
          key: const Key('s24_escalation_triggers_placeholder'),
        ),
      ),
    );
  }
}
