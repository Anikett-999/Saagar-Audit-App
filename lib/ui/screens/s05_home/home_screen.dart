import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/audit.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../domain/iso_week.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/draft_audit_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// S5 Home / Dashboard — role-aware landing after login.
///
/// SM sees a big "Start Daily Audit" CTA and today's audit status.
/// GM/Owner see audit overview cards + "Start Weekly Audit" card.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Audit? _todayAudit;
  Audit? _thisWeekAudit;
  Audit? _thisMonthAudit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final todayAudit = await AuditRepository.instance.findByDate(
      date: today,
      auditType: 'daily',
    );
    final weekAudit = await AuditRepository.instance.findByWeek(
      weekNumber: isoWeek(now),
      year: now.year,
      auditType: 'weekly',
    );
    final monthAudit = await AuditRepository.instance.findByMonth(
      monthNumber: now.month,
      year: now.year,
      auditType: 'monthly',
    );
    if (!mounted) return;
    setState(() {
      _todayAudit = todayAudit;
      _thisWeekAudit = weekAudit;
      _thisMonthAudit = monthAudit;
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
    final canStartDaily = user.role == 'SM' || user.role == 'OWNER';
    final canStartWeekly = user.role == 'GM' || user.role == 'OWNER';
    final canStartMonthly = user.role == 'OWNER';
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
              onRefresh: _loadAudits,
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
                  _todayCard(l10n, canStartDaily),
                  if (canStartWeekly) ...[
                    const SizedBox(height: 12),
                    _weeklyCard(context, l10n),
                  ],
                  if (canStartMonthly) ...[
                    const SizedBox(height: 12),
                    _monthlyCard(context, l10n),
                  ],
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
                    await _loadAudits();
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

  Widget _weeklyCard(BuildContext context, AppLocalizations l10n) {
    final audit = _thisWeekAudit;
    final now = DateTime.now();
    final weekNumber = isoWeek(now);
    final year = now.year;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.s05ThisWeekWeeklyAudit,
                        style: const TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 20,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.s05WeekNumberLabel(weekNumber, year),
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(l10n, audit),
              ],
            ),
            const SizedBox(height: 16),
            if (audit == null) ...[
              Text(
                l10n.s05WeeklyNotStartedYet,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.s05StartWeeklyAudit),
                onPressed: () async {
                  await context.push('/audit/start?type=weekly');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(l10n.s05SevenDayReview),
                onPressed: () async {
                  await context.push('/audit/7-day-review?week=$weekNumber&year=$year');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
            ] else if (audit.isDraft) ...[
              Text(
                l10n.s05WeeklyDraftInProgress,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.s05ResumeWeeklyDraft),
                onPressed: () async {
                  await ref.read(draftAuditProvider.notifier).resumeDraft(
                        audit: audit,
                        cros: const [],
                      );
                  if (!context.mounted) return;
                  await context.pushNamed('s07_checkpoint');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(l10n.s05SevenDayReview),
                onPressed: () async {
                  await context.push('/audit/7-day-review?week=$weekNumber&year=$year');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
            ] else ...[
              Text(
                '${l10n.s05SubmittedStatus} • ${audit.compliancePct?.toStringAsFixed(1) ?? "—"}% (${audit.band ?? "—"})',
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.assessment_outlined, size: 18),
                label: Text(l10n.s05ViewWeeklyReport),
                onPressed: () async {
                  final existing = await ReportRepository.instance.getByAuditId(audit.id);
                  if (existing != null) {
                    if (context.mounted) {
                      context.pushNamed('s21_report_detail', pathParameters: {'id': existing.id});
                    }
                  } else {
                    final newRep = await ReportRepository.instance.generateWeeklyReport(
                      weeklyAuditId: audit.id,
                      authorUserId: audit.auditorId,
                    );
                    if (context.mounted) {
                      context.pushNamed('s21_report_detail', pathParameters: {'id': newRep.id});
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Weekly Audit'),
                onPressed: () => context.pushNamed(
                  's13_audit_detail',
                  pathParameters: {'id': audit.id},
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(l10n.s05SevenDayReview),
                onPressed: () async {
                  await context.push('/audit/7-day-review?week=$weekNumber&year=$year');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthlyCard(BuildContext context, AppLocalizations l10n) {
    final audit = _thisMonthAudit;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final year = now.year;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.s05ThisMonthMonthlyAudit,
                        style: const TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 20,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.s05MonthYearLabel(monthName, year),
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(l10n, audit),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.s05MonthlySubtitle,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (audit == null) ...[
              Text(
                l10n.s05MonthlyNotStartedYet,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.s05StartMonthlyAudit),
                onPressed: () async {
                  await context.push('/audit/start?type=monthly');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
            ] else if (audit.isDraft) ...[
              Text(
                l10n.s05MonthlyDraftInProgress,
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.s05ResumeMonthlyDraft),
                onPressed: () async {
                  await ref.read(draftAuditProvider.notifier).resumeDraft(
                        audit: audit,
                        cros: const [],
                      );
                  if (!context.mounted) return;
                  await context.pushNamed('s07_checkpoint');
                  if (!mounted) return;
                  await _loadAudits();
                },
              ),
            ] else ...[
              Text(
                '${l10n.s05SubmittedStatus} • ${audit.compliancePct?.toStringAsFixed(1) ?? "—"}% (${audit.band ?? "—"})',
                style: const TextStyle(color: AppColors.gray600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(l10n.s12Title),
                onPressed: () => context.pushNamed(
                  's13_audit_detail',
                  pathParameters: {'id': audit.id},
                ),
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

  Widget _navTiles(BuildContext context, AppLocalizations l10n, String role) {
    return Column(
      children: [
        _navTile(
          icon: Icons.history_outlined,
          title: l10n.s05AuditHistoryTitle,
          subtitle: l10n.s05AuditHistorySubtitle,
          enabled: true,
          onTap: () => context.pushNamed('s12_audit_history'),
        ),
        _navTile(
          icon: Icons.fact_check_outlined,
          title: l10n.s05CapsTitle,
          subtitle: l10n.s05CapsSubtitle,
          enabled: true,
          onTap: () => context.pushNamed('s14_cap_list'),
        ),
        if (role == 'GM' || role == 'OWNER')
          _navTile(
            icon: Icons.dashboard_customize_outlined,
            title: l10n.capOversightTitle,
            subtitle: l10n.capOversightSubtitle,
            enabled: true,
            onTap: () => context.push('/caps/oversight'),
          ),
        _navTile(
          icon: Icons.assessment_outlined,
          title: l10n.s20ScreenTitle,
          subtitle: l10n.s20ScreenSubtitle,
          enabled: true,
          onTap: () => context.pushNamed('s20_reports_list'),
        ),
        _navTile(
          icon: Icons.menu_book_outlined,
          title: l10n.s05ReferenceTitle,
          subtitle: l10n.s05ReferenceSubtitle,
          enabled: true,
          onTap: () => context.pushNamed('s22_reference_index'),
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
