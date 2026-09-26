import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S12 — Audit History (Own / All).
///
/// Displays role-scoped list of submitted and verified audits (Spec §5 S12):
/// - SM sees only audits they authored.
/// - GM and Owner see all store audits.
/// - Filter chips: All, Daily, Unverified (Weekly/Monthly disabled for Phase 2/3).
/// - Each audit card surfaces: date, type, auditor, compliance %, band color, fails count, status.
/// - Tap navigates to S13 (Audit Detail).
/// - Infinite scroll pagination (30 items per page) with pull-to-refresh.
class AuditHistoryScreen extends ConsumerStatefulWidget {
  const AuditHistoryScreen({super.key});

  @override
  ConsumerState<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends ConsumerState<AuditHistoryScreen> {
  final _scrollController = ScrollController();
  AuditHistoryFilter _selectedFilter = AuditHistoryFilter.all;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 30;

  List<Audit> _audits = [];
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreAudits();
      }
    }
  }

  Future<void> _loadInitialData() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    setState(() {
      _isLoading = true;
      _offset = 0;
      _hasMore = true;
    });

    try {
      final users = await UserRepository.instance.listAll();
      final userMap = {for (final User u in users) u.id: u.name};

      final audits = await AuditRepository.instance.listAudits(
        viewer: auth.user!,
        filter: _selectedFilter,
        limit: _limit,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _userNames = userMap;
          _audits = audits;
          _offset = audits.length;
          _hasMore = audits.length >= _limit;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreAudits() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreAudits = await AuditRepository.instance.listAudits(
        viewer: auth.user!,
        filter: _selectedFilter,
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          _audits.addAll(moreAudits);
          _offset += moreAudits.length;
          _hasMore = moreAudits.length >= _limit;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onFilterSelected(AuditHistoryFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    _loadInitialData();
  }

  String _formatAuditorName(String auditorId) {
    return _userNames[auditorId] ?? auditorId;
  }

  String _auditTypeLabel(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return l10n.s12TypeDaily;
      case 'weekly':
        return l10n.s12TypeWeekly;
      case 'monthly':
        return l10n.s12TypeMonthly;
      default:
        return type.toUpperCase();
    }
  }

  String _bandLabel(AppLocalizations l10n, String? band) {
    if (band == null) return l10n.s12BandPending;
    switch (band.toLowerCase()) {
      case 'excellent':
        return l10n.s12BandExcellent;
      case 'good':
        return l10n.s12BandGood;
      case 'fair':
        return l10n.s12BandFair;
      case 'poor':
        return l10n.s12BandPoor;
      case 'critical':
        return l10n.s12BandCritical;
      default:
        return band.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id) {
        _loadInitialData();
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);

    if (auth.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(l10n.s12Title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.s12RefreshTooltip,
            onPressed: _loadInitialData,
          ),
          const LanguageToggleButton(),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(l10n),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _audits.isEmpty
                    ? _buildEmptyState(l10n)
                    : _buildAuditList(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              key: const ValueKey('s12_filter_all'),
              label: l10n.s12FilterAll,
              isSelected: _selectedFilter == AuditHistoryFilter.all,
              onTap: () => _onFilterSelected(AuditHistoryFilter.all),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              key: const ValueKey('s12_filter_daily'),
              label: l10n.s12FilterDaily,
              isSelected: _selectedFilter == AuditHistoryFilter.daily,
              onTap: () => _onFilterSelected(AuditHistoryFilter.daily),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              key: const ValueKey('s12_filter_unverified'),
              label: l10n.s12FilterUnverified,
              isSelected: _selectedFilter == AuditHistoryFilter.unverified,
              onTap: () => _onFilterSelected(AuditHistoryFilter.unverified),
            ),
            const SizedBox(width: 8),
            _buildDisabledFilterChip(
              label: l10n.s12FilterWeekly,
              tooltip: l10n.s12FilterWeeklyTooltip,
            ),
            const SizedBox(width: 8),
            _buildDisabledFilterChip(
              label: l10n.s12FilterMonthly,
              tooltip: l10n.s12FilterMonthlyTooltip,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.navy,
      backgroundColor: AppColors.gray100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.gray800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.navy : AppColors.gray300,
        ),
      ),
    );
  }

  Widget _buildDisabledFilterChip({
    required String label,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: 0.5,
        child: Chip(
          label: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.gray600),
          ),
          backgroundColor: AppColors.gray100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.gray300),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == AuditHistoryFilter.all
                  ? l10n.s12NoAuditsFound
                  : l10n.s12NoAuditsMatchFilter,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.s12CompleteAuditPrompt,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditList(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _audits.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _audits.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final audit = _audits[index];
          return _buildAuditCard(context, l10n, audit);
        },
      ),
    );
  }

  Widget _buildAuditCard(
    BuildContext context,
    AppLocalizations l10n,
    Audit audit,
  ) {
    final pct = audit.compliancePct ?? 0.0;
    final color = bandColor(pct);
    final isVerified = audit.status == 'verified';

    return Card(
      key: ValueKey('audit_card_${audit.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.pushNamed(
            's13_audit_detail',
            pathParameters: {'id': audit.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Date & Status Badge
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event, size: 16, color: AppColors.navy),
                        const SizedBox(width: 6),
                        Text(
                          l10n.s12Date(audit.auditDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppColors.goldPale
                            : AppColors.greenPale,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isVerified
                              ? AppColors.gold
                              : AppColors.green,
                        ),
                      ),
                      child: Text(
                        isVerified
                            ? l10n.s12StatusVerified
                            : l10n.s12StatusSubmitted,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVerified
                              ? AppColors.gold
                              : AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Middle Row: Type badge + Auditor Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _auditTypeLabel(l10n, audit.auditType),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.s12Auditor(_formatAuditorName(audit.auditorId)),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Row: Compliance % Pill, Band Badge, and Fails count
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compliance percentage
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            l10n.s12ComplianceScore(pct.toStringAsFixed(1)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Band Name
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _bandLabel(l10n, audit.band),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Fails count badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          audit.failCount > 0
                              ? Icons.cancel_outlined
                              : Icons.check_circle_outline,
                          size: 16,
                          color: audit.failCount > 0
                              ? AppColors.red
                              : AppColors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.s12FailsCount(audit.failCount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: audit.failCount > 0
                                ? AppColors.red
                                : AppColors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.gray400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
