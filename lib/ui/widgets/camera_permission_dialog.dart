import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Shows an explanation dialog when camera permission is denied, with an
/// actionable button to open the device application settings.
Future<void> showCameraPermissionDeniedDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final title = l10n?.cameraPermissionRequiredTitle ?? 'Camera Permission Required';
  final message = l10n?.cameraPermissionRequiredMessage ??
      'Camera permission is required to capture evidence photos. Please open Settings and enable camera access.';
  final btnSettings = l10n?.btnOpenSettings ?? 'Open Settings';
  final btnCancel = l10n?.btnCancel ?? 'Cancel';

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.no_photography_outlined, color: AppColors.red, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 18,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          color: AppColors.gray800,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            btnCancel,
            style: const TextStyle(color: AppColors.gray600),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.gold,
          ),
          onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              await Geolocator.openAppSettings();
            } catch (_) {
              // Best-effort platform settings launch
            }
          },
          icon: const Icon(Icons.settings, size: 16),
          label: Text(btnSettings),
        ),
      ],
    ),
  );
}
