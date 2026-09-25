import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S23 — Reference Rating Scale (Spec §5 S23 & §11.1).
///
/// Full implementation coming in Step 3.
class RatingScaleScreen extends StatelessWidget {
  const RatingScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s23Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: Center(
        child: Text(
          l10n.s23Title,
          key: const Key('s23_rating_scale_placeholder'),
        ),
      ),
    );
  }
}
