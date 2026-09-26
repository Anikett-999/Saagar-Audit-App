import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../data/backup_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S32 — Settings: Backup & Export.
///
/// Implements Spec §S32 and Sprint Design:
/// - Export entire 14-table SQLite database as a timestamped JSON file to Downloads.
/// - Graceful fallback to application documents directory if Downloads is unavailable.
/// - Displays security advisory regarding sensitive audit data and bcrypt hashes.
/// - Owner-only Firestore cloud sync section (disabled in Phase 1 with "Coming in Phase 4" badge).
/// - About section with app version, store information, and spec reference.
class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  bool _isExporting = false;

  Future<void> _exportDatabase(AppLocalizations l10n) async {
    setState(() => _isExporting = true);

    try {
      final result = await BackupService.instance.exportAndSaveToFile();
      if (!mounted) return;

      setState(() => _isExporting = false);

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.green, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.s32ExportSuccessTitle,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.s32ExportSuccessMessage(
              result.totalRecords,
              result.tableCount,
              result.fileName,
              result.filePath,
            ),
            style: const TextStyle(fontFamily: 'DMSans', height: 1.4),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.share, size: 16),
              label: Text(l10n.s32ShareFile),
              onPressed: () async {
                try {
                  final file = File(result.filePath);
                  if (await file.exists()) {
                    final bytes = await file.readAsBytes();
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: result.fileName,
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Could not share file: $e')),
                    );
                  }
                }
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l10n.s32CopyPath),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.s32PathCopied),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.s32OkButton,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s32ExportFailed(e.toString())),
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

    // Route guard: redirect unauthenticated users
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
    final isOwner = currentUser.role == 'OWNER';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s32Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                  Icons.cloud_download_outlined,
                  color: AppColors.navy,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.s32Subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.s32ExportCardDesc,
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
          const SizedBox(height: 24),

          // Local Database Export Card (All Roles)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.save_alt,
                          color: AppColors.navy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.s32ExportCardTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.s32ExportCardDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                      fontFamily: 'DMSans',
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Security Notice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldPale.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.security,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.s32ExportSecurityNotice,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.navy,
                              fontFamily: 'DMSans',
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Export Button
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportDatabase(l10n),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.file_download),
                    label: Text(
                      _isExporting ? l10n.s32Exporting : l10n.s32ExportButton,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cloud Sync Section (Owner-Only per Spec §S32)
          if (isOwner) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.gray200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_sync,
                            color: AppColors.gray600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.s32CloudSyncTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.navyLight.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.s32CloudSyncComingSoonBadge,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyLight,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.s32CloudSyncDesc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                        fontFamily: 'DMSans',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                color: AppColors.gray600,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.s32CloudSyncStatusLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.s32CloudSyncPhase4Notice,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              fontFamily: 'DMSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Disabled Force Sync Button with Phase 4 indicator
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.sync_disabled),
                      label: Text(
                        '${l10n.s32ForceSyncButton} (${l10n.s32CloudSyncComingSoonBadge})',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // About Card (All Roles per Spec §S32)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.navy,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.s32AboutCardTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    l10n.s32AboutVersion,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.s32AboutStore,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.s32AboutSpec,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.navyLight,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
