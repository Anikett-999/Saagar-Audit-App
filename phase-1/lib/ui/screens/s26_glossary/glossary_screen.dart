import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S26 — Reference Bilingual Glossary (Spec §5 S26 & §11.4).
///
/// Full implementation coming in Step 6.
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s26Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: Center(
        child: Text(
          l10n.s26Title,
          key: const Key('s26_glossary_placeholder'),
        ),
      ),
    );
  }
}
