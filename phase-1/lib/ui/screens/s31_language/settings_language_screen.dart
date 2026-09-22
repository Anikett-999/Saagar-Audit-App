import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S31 — Settings: Language.
///
/// Implements Spec §S31 and Sprint design:
/// - Dedicated language settings screen displaying English and Marathi.
/// - Live instant UI language switch via [localeProvider].
/// - Persists selection to the logged-in user's [users.language_pref] column
///   in SQLite via [UserRepository.updateLanguagePref].
/// - Synchronizes with [authProvider] memory state and [SharedPreferences]
///   so user preference survives restarts and next logins.
class SettingsLanguageScreen extends ConsumerWidget {
  const SettingsLanguageScreen({super.key});

  Future<void> _selectLanguage({
    required BuildContext context,
    required WidgetRef ref,
    required String code,
    required String? userId,
  }) async {
    // 1. Live instant switch in UI + SharedPreferences
    await ref.read(localeProvider.notifier).set(Locale(code));

    // 2. Persist to SQLite users.language_pref for logged-in user
    if (userId != null) {
      await UserRepository.instance.updateLanguagePref(userId, code);
      ref.read(authProvider.notifier).updateUserLanguagePref(code);
    }

    if (!context.mounted) return;

    final l10n = lookupAppLocalizations(Locale(code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.s31LanguageUpdatedSuccess),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;

    // Route guard: if user is not logged in, redirect to settings/login
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
    final currentLocale = ref.watch(localeProvider);
    final isMarathi = currentLocale?.languageCode == 'mr';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s31Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header Info Card
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
                  Icons.translate,
                  color: AppColors.navy,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.s31Subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontFamily: 'DMSans',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.s31Instruction,
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

          // English Selection Tile
          _buildLanguageCard(
            context: context,
            title: l10n.s31EnglishTitle,
            subtitle: l10n.s31EnglishSubtitle,
            isSelected: !isMarathi,
            currentBadgeText: l10n.s31CurrentLanguageBadge,
            onTap: () => _selectLanguage(
              context: context,
              ref: ref,
              code: 'en',
              userId: currentUser.id,
            ),
          ),
          const SizedBox(height: 16),

          // Marathi Selection Tile
          _buildLanguageCard(
            context: context,
            title: l10n.s31MarathiTitle,
            subtitle: l10n.s31MarathiSubtitle,
            isSelected: isMarathi,
            currentBadgeText: l10n.s31CurrentLanguageBadge,
            onTap: () => _selectLanguage(
              context: context,
              ref: ref,
              code: 'mr',
              userId: currentUser.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required String currentBadgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.navy : AppColors.gray300,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? AppColors.cream : AppColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navy : AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language,
                  color: isSelected ? AppColors.goldLight : AppColors.gray600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? AppColors.navy : AppColors.gray800,
                        fontFamily: 'DMSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                        fontFamily: 'DMSans',
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentBadgeText,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.navy,
                  size: 24,
                ),
              ] else
                const Icon(
                  Icons.radio_button_unchecked,
                  color: AppColors.gray400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
