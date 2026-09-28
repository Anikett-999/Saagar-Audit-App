import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/cap.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen — GM / Owner CAP Oversight Dashboard (Phase-2 finale).
///
/// Implements Spec §5.5 & Plan §5.5:
/// - Summary cards of CAP status counts (Open, Awaiting Verification, Verified, Closed, Overdue)
/// - "Awaiting My Verification" list as primary call-to-action deep-linking to S18
/// - Pattern marker on Pattern CAPs
class GmDashboardScreen extends ConsumerStatefulWidget {
  const GmDashboardScreen({super.key});

  @override
  ConsumerState<GmDashboardScreen> createState() => _GmDashboardScreenState();
}

class _GmDashboardScreenState extends ConsumerState<GmDashboardScreen> {
  CapDashboardCounts? _counts;
  List<Cap> _awaitingCaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).user;
      final counts = await CapRepository.instance.getCapCounts(viewer: user);
      final awaiting = await CapRepository.instance.listCaps(
        viewer: user ?? const AuthUser(id: 'gm', name: 'GM', role: 'GM', languagePref: 'en'),
        filter: CapFilter.done,
      );

      if (mounted) {
        setState(() {
          _counts = counts;
          _awaitingCaps = awaiting;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.capOversightTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Subtitle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.capOversightTitle,
                          style: const TextStyle(
                            fontFamily: 'DMSerifDisplay',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cream,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.capOversightSubtitle,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Counts Grid
                  if (_counts != null) _buildCountsGrid(l10n, _counts!),
                  const SizedBox(height: 20),

                  // Awaiting My Verification Section
                  Row(
                    children: [
                      const Icon(Icons.pending_actions, color: AppColors.navy, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.capOversightAwaitingSection,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _awaitingCaps.isNotEmpty ? Colors.purple.withValues(alpha: 0.15) : AppColors.gray200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_awaitingCaps.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _awaitingCaps.isNotEmpty ? Colors.purple : AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_awaitingCaps.isEmpty)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 40, color: AppColors.green),
                              const SizedBox(height: 8),
                              Text(
                                l10n.capOversightNoAwaiting,
                                style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._awaitingCaps.map((cap) => _buildAwaitingCard(l10n, cap)),

                  const SizedBox(height: 20),

                  // Nav to All CAPs
                  OutlinedButton.icon(
                    key: const ValueKey('gm_view_all_caps_button'),
                    onPressed: () => context.push('/caps'),
                    icon: const Icon(Icons.list_alt),
                    label: Text(l10n.s14Title),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCountsGrid(AppLocalizations l10n, CapDashboardCounts counts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard(
              title: l10n.capOversightCountOpen,
              count: counts.open,
              color: AppColors.navy,
              icon: Icons.folder_open,
              width: cardWidth,
            ),
            _metricCard(
              title: l10n.capOversightCountAwaiting,
              count: counts.awaitingVerification,
              color: Colors.purple,
              icon: Icons.task_alt,
              width: cardWidth,
            ),
            _metricCard(
              title: l10n.capOversightCountVerified,
              count: counts.verified,
              color: AppColors.green,
              icon: Icons.verified_outlined,
              width: cardWidth,
            ),
            _metricCard(
              title: l10n.capOversightCountClosed,
              count: counts.closed,
              color: AppColors.gray600,
              icon: Icons.lock_outline,
              width: cardWidth,
            ),
            if (counts.overdue > 0)
              _metricCard(
                title: l10n.capOversightCountOverdue,
                count: counts.overdue,
                color: AppColors.red,
                icon: Icons.warning_amber_rounded,
                width: constraints.maxWidth,
              ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwaitingCard(AppLocalizations l10n, Cap cap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cap.id,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy),
                  ),
                ),
                if (cap.isPattern) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: Text(
                      l10n.s18PatternMarker,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amber),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cap.status.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cap.problemStatement,
              style: const TextStyle(fontSize: 13, color: AppColors.gray800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.gray600),
                const SizedBox(width: 4),
                Text(
                  '${l10n.s18Deadline}: ${cap.deadline}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
                const Spacer(),
                FilledButton.icon(
                  key: ValueKey('verify_now_${cap.id}'),
                  onPressed: () async {
                    final res = await context.push<bool>('/caps/${cap.id}/verify');
                    if (res == true) {
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.verified, size: 16),
                  label: Text(l10n.capOversightVerifyNow),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
