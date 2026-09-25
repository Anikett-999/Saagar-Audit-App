import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S25 — Reference Strong vs Weak Evidence (Spec §5 S25 & §11.3).
///
/// Full implementation coming in Step 5.
class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s25Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: Center(
        child: Text(
          l10n.s25Title,
          key: const Key('s25_evidence_placeholder'),
        ),
      ),
    );
  }
}
