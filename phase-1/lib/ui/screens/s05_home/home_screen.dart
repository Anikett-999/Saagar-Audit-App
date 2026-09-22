import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/audit.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// S5 Home / Dashboard — role-aware landing after login.
///
/// SM sees a big "Start Daily Audit" CTA and today's audit status.
/// GM/Owner see audit overview cards (deeper functionality lands in W3+).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Audit? _todayAudit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayAudit();
  }

  Future<void> _loadTodayAudit() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final audit = await AuditRepository.instance.findByDate(
      date: today,
      auditType: 'daily',
    );
    if (!mounted) return;
    setState(() {
      _todayAudit = audit;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    if (user == null) {
      // Defensive — shouldn't happen post-login.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.goNamed('s04_login'),
      );
      return const Scaffold(body: SizedBox.shrink());
    }

    final l10n = AppLocalizations.of(context)!;
    final canStartAudit = user.role == 'SM' || user.role == 'OWNER';
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.goldLight),
            tooltip: l10n.btnLogout,
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.goNamed('s04_login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayAudit,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  _greetingBlock(l10n, user.name, user.role),
                  const SizedBox(height: 8),
                  Text(
                    today,
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _todayCard(l10n, canStartAudit),
                  const SizedBox(height: 12),
                  _navTiles(context, l10n, user.role),
                ],
              ),
            ),
    );
  }

  Widget _greetingBlock(AppLocalizations l10n, String name, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.s05Hello(name),
          style: const TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 26,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _roleLabel(l10n, role),
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            color: AppColors.gold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _todayCard(AppLocalizations l10n, bool canStartAudit) {
    final audit = _todayAudit;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.s05TodayDailyAudit,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 20,
                    color: AppColors.navy,
                  ),
                ),
                _statusChip(l10n, audit),
              ],
            ),
            const SizedBox(height: 16),
            if (audit == null) ...[
              Text(
                canStartAudit
                    ? l10n.s05NotStartedYet
                    : l10n.s05NotStartedAdmin,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              if (canStartAudit)
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.s05StartDailyAudit),
                  onPressed: () async {
                    await context.pushNamed('s06_start_audit');
                    if (!mounted) return;
                    await _loadTodayAudit();
                  },
                )
              else
                Text(
                  l10n.s05DailyAuditsRunBySm,
                  style: const TextStyle(color: AppColors.gray600),
                ),
            ] else if (audit.isDraft) ...[
              Text(
                l10n.s05DraftInProgress,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.s05ResumeDraft),
                onPressed: () => context.pushNamed('s07_checkpoint'),
              ),
            ] else ...[
              Text(
                '${l10n.s05SubmittedStatus} • ${audit.compliancePct?.toStringAsFixed(1) ?? "—"}% (${audit.band ?? "—"})',
                style: const TextStyle(color: AppColors.gray600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(AppLocalizations l10n, Audit? audit) {
    if (audit == null) {
      return _chip(l10n.s05StatusNotStarted, AppColors.gray200, AppColors.gray800);
    }
    if (audit.isDraft) {
      return _chip(l10n.s05StatusInProgress, AppColors.amberPale, AppColors.amber);
    }
    if (audit.isSubmitted) {
      return _chip(l10n.s05StatusSubmitted, AppColors.greenPale, AppColors.green);
    }
    return _chip(audit.status, AppColors.gray200, AppColors.gray800);
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n, String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.s05ComingSoon(feature)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _navTiles(BuildContext context, AppLocalizations l10n, String role) {
    return Column(
      children: [
        _navTile(
          icon: Icons.history_outlined,
          title: l10n.s05AuditHistoryTitle,
          subtitle: l10n.s05AuditHistorySubtitle,
          enabled: false,
          onTap: () => _showComingSoon(context, l10n, l10n.s05AuditHistoryTitle),
        ),
        _navTile(
          icon: Icons.fact_check_outlined,
          title: l10n.s05CapsTitle,
          subtitle: l10n.s05CapsSubtitle,
          enabled: false,
          onTap: () => _showComingSoon(context, l10n, l10n.s05CapsTitle),
        ),
        _navTile(
          icon: Icons.menu_book_outlined,
          title: l10n.s05ReferenceTitle,
          subtitle: l10n.s05ReferenceSubtitle,
          enabled: false,
          onTap: () => _showComingSoon(context, l10n, l10n.s05ReferenceTitle),
        ),
        _navTile(
          icon: Icons.settings_outlined,
          title: l10n.s05SettingsTitle,
          subtitle: l10n.s05SettingsSubtitle,
          enabled: true,
          onTap: () => context.pushNamed('s27_settings'),
        ),
      ],
    );
  }



  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.7,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(icon, color: AppColors.navy),
          title: Text(title),
          subtitle: Text(
            enabled ? subtitle : '$subtitle  ·  coming in week 3+',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: enabled
              ? const Icon(Icons.chevron_right, color: AppColors.gray400)
              : const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.gray400,
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    return switch (role) {
      'SM' => l10n.s05RoleSm,
      'GM' => l10n.s05RoleGm,
      'OWNER' => l10n.s05RoleOwner,
      _ => role.toUpperCase(),
    };
  }
}
