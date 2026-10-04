import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../data/backup_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cloud_sync_provider.dart';
import '../../../services/cloud_sync_service.dart';
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
                              Consumer(
                                builder: (context, ref, _) {
                                  final syncState = ref.watch(cloudSyncProvider);
                                  final isOk = syncState.status == CloudSyncStatus.success;
                                  final badgeColor = isOk ? AppColors.green : AppColors.navyLight;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l10n.s32CloudSyncComingSoonBadge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: badgeColor,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  );
                                },
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

                    // Live Status Indicator Card
                    Builder(
                      builder: (context) {
                        final syncState = ref.watch(cloudSyncProvider);
                        IconData statusIcon;
                        Color statusColor;
                        String statusText;

                        switch (syncState.status) {
                          case CloudSyncStatus.syncing:
                            statusIcon = Icons.sync;
                            statusColor = AppColors.gold;
                            statusText = l10n.s32CloudSyncStatusSyncing;
                            break;
                          case CloudSyncStatus.success:
                            statusIcon = Icons.cloud_done;
                            statusColor = AppColors.green;
                            statusText = l10n.s32CloudSyncStatusSuccess;
                            break;
                          case CloudSyncStatus.error:
                            statusIcon = Icons.sync_problem;
                            statusColor = AppColors.red;
                            statusText = l10n.s32CloudSyncStatusError(
                              syncState.errorMessage ?? 'Unknown',
                            );
                            break;
                          case CloudSyncStatus.offline:
                            statusIcon = Icons.cloud_off;
                            statusColor = AppColors.gray600;
                            statusText = l10n.s32CloudSyncStatusOffline;
                            break;
                          case CloudSyncStatus.unconfigured:
                            statusIcon = Icons.cloud_queue;
                            statusColor = AppColors.navyLight;
                            statusText = l10n.s32CloudSyncStatusUnconfigured;
                            break;
                          case CloudSyncStatus.idle:
                            statusIcon = Icons.cloud_sync;
                            statusColor = AppColors.navy;
                            statusText = l10n.s32CloudSyncStatusIdle;
                            break;
                        }

                        final lastSyncText = syncState.lastSyncAt != null
                            ? l10n.s32CloudSyncLastSync(
                                '${syncState.lastSyncAt!.day}/${syncState.lastSyncAt!.month}/${syncState.lastSyncAt!.year} '
                                '${syncState.lastSyncAt!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncAt!.minute.toString().padLeft(2, '0')}',
                              )
                            : l10n.s32CloudSyncLastSync(l10n.s32CloudSyncNever);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                        fontFamily: 'DMSans',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lastSyncText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray600,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.s32CloudSyncPending(syncState.pendingCount),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'DMSans',
                                ),
                              ),
                              if (syncState.status == CloudSyncStatus.syncing) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: syncState.progress > 0
                                        ? syncState.progress
                                        : null,
                                    backgroundColor: AppColors.gray200,
                                    color: AppColors.gold,
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Active Force Sync Button
                    Consumer(
                      builder: (context, ref, _) {
                        final syncState = ref.watch(cloudSyncProvider);
                        final isSyncing =
                            syncState.status == CloudSyncStatus.syncing;

                        return ElevatedButton.icon(
                          onPressed: isSyncing
                              ? null
                              : () async {
                                  final res = await ref
                                      .read(cloudSyncProvider.notifier)
                                      .syncNow(force: true);
                                  if (context.mounted) {
                                    if (res.success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.s32SyncSuccessNotice(
                                              res.pushedRecords +
                                                  res.pulledRecords +
                                                  res.uploadedPhotos,
                                            ),
                                          ),
                                          backgroundColor: AppColors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (res.status == CloudSyncStatus.unconfigured) {
                                      showDialog<void>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: Row(
                                            children: [
                                              const Icon(Icons.cloud_queue, color: AppColors.navy),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.s32CloudSyncTitle,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            res.message ?? l10n.s32CloudSyncPhase4Notice,
                                            style: const TextStyle(fontSize: 14, height: 1.4),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (res.status == CloudSyncStatus.offline) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.s32CloudSyncStatusOffline),
                                          backgroundColor: AppColors.amber,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            res.message ??
                                                l10n.s32CloudSyncStatusError(
                                                  'Failed',
                                                ),
                                          ),
                                          backgroundColor: AppColors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isSyncing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            isSyncing
                                ? l10n.s32CloudSyncStatusSyncing
                                : l10n.s32ForceSyncButton,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
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
