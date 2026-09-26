import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S27 — Settings Hub.
///
/// Role-filtered settings hub per Spec §S27 and Claude sprint design:
/// - Manage CROs (All roles)
/// - Manage Users (Owner ONLY — hidden entirely for SM/GM)
/// - Change PIN (All roles)
/// - Language (All roles)
/// - Backup & Export (All roles)
/// - About (All roles)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.goNamed('s04_login');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context)!;
    final isOwner = user.role == 'OWNER';
    final roleBadgeText = switch (user.role) {
      'OWNER' => l10n.s27OwnerBadge,
      'GM' => l10n.s27GmBadge,
      _ => l10n.s27SmBadge,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s27Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildUserProfileCard(context, l10n, user, roleBadgeText),
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.s27ManagementSection),
          const SizedBox(height: 8),
          _buildTile(
            context: context,
            icon: Icons.badge_outlined,
            title: l10n.s27ManageCrosTitle,
            subtitle: l10n.s27ManageCrosSubtitle,
            onTap: () => context.pushNamed('s28_manage_cros'),
          ),
          // Manage Users is strictly Owner-only. Hidden entirely for SM/GM per Spec §S27/§S29.
          if (isOwner)
            _buildTile(
              context: context,
              icon: Icons.people_outline,
              title: l10n.s27ManageUsersTitle,
              subtitle: l10n.s27ManageUsersSubtitle,
              onTap: () => context.pushNamed('s29_manage_users'),
            ),
          const SizedBox(height: 20),
          _buildSectionHeader(l10n.s27PreferencesSection),
          const SizedBox(height: 8),
          _buildTile(
            context: context,
            icon: Icons.lock_outline,
            title: l10n.s27ChangePinTitle,
            subtitle: l10n.s27ChangePinSubtitle,
            onTap: () => context.pushNamed('s30_change_pin'),
          ),
          _buildTile(
            context: context,
            icon: Icons.translate,
            title: l10n.s27LanguageTitle,
            subtitle: l10n.s27LanguageSubtitle,
            onTap: () => context.pushNamed('s31_language'),
          ),
          _buildTile(
            context: context,
            icon: Icons.cloud_download_outlined,
            title: l10n.s27BackupExportTitle,
            subtitle: l10n.s27BackupExportSubtitle,
            onTap: () => context.pushNamed('s32_backup_export'),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(l10n.s27AccountSection),
          const SizedBox(height: 8),
          _buildTile(
            context: context,
            icon: Icons.info_outline,
            title: l10n.s27AboutTitle,
            subtitle: l10n.s27AboutSubtitle,
            onTap: () => _showAboutDialog(context, l10n),
          ),
          _buildTile(
            context: context,
            icon: Icons.logout,
            title: l10n.btnLogout,
            iconColor: AppColors.red,
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.goNamed('s04_login');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(
    BuildContext context,
    AppLocalizations l10n,
    AuthUser user,
    String roleBadgeText,
  ) {
    final badgeBg = switch (user.role) {
      'OWNER' => AppColors.goldPale,
      'GM' => AppColors.navyLight.withValues(alpha: 0.15),
      _ => AppColors.greenPale,
    };

    final badgeFg = switch (user.role) {
      'OWNER' => AppColors.gold,
      'GM' => AppColors.navy,
      _ => AppColors.green,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.navy,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DMSerifDisplay',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleBadgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.gray600,
          letterSpacing: 1.2,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.navy).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.navy,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontFamily: 'DMSans',
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                  fontFamily: 'DMSans',
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.gray400,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.s27AboutDialogTitle,
          style: const TextStyle(
            fontFamily: 'DMSerifDisplay',
            color: AppColors.navy,
          ),
        ),
        content: Text(
          l10n.s27AboutDialogBody,
          style: const TextStyle(
            height: 1.5,
            color: AppColors.gray800,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.s27CloseDialog,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
