import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/cap.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S14 — Corrective Action Plans (CAP) List.
///
/// Displays filterable, searchable list of CAPs visible to the authenticated user.
/// SM sees own + assigned. GM and Owner see all.
///
/// Follows Spec §5 Screen S14.
class CapListScreen extends ConsumerStatefulWidget {
  const CapListScreen({super.key});

  @override
  ConsumerState<CapListScreen> createState() => _CapListScreenState();
}

class _CapListScreenState extends ConsumerState<CapListScreen> {
  final _searchController = TextEditingController();
  CapFilter _selectedFilter = CapFilter.all;
  bool _isLoading = true;
  List<Cap> _caps = [];
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load users for responsible name display
      final users = await UserRepository.instance.listAll();
      final userMap = {for (final User u in users) u.id: u.name};

      final caps = await CapRepository.instance.listCaps(
        viewer: auth.user!,
        filter: _selectedFilter,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _userNames = userMap;
          _caps = caps;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFilterChanged(CapFilter filter) {
    setState(() => _selectedFilter = filter);
    _loadData();
  }

  void _onSearchChanged(String _) {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id) {
        _loadData();
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.s14Title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              l10n.s14Subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.goldPale),
            ),
          ],
        ),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('s14_create_fab'),
        onPressed: () async {
          await context.pushNamed('s15_cap_create');
          _loadData();
        },
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.s14NewCapButton,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildSearchAndFilters(l10n),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _caps.isEmpty
                      ? _buildEmptyState(l10n)
                      : _buildCapList(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          TextField(
            key: const ValueKey('s14_search_field'),
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.s14SearchHint,
              prefixIcon: const Icon(Icons.search, color: AppColors.gray600),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadData();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.gray100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(CapFilter.all, l10n.s14FilterAll),
                const SizedBox(width: 8),
                _filterChip(CapFilter.open, l10n.s14FilterOpen),
                const SizedBox(width: 8),
                _filterChip(CapFilter.done, l10n.s14FilterDone),
                const SizedBox(width: 8),
                _filterChip(CapFilter.aged, l10n.s14FilterAged),
                const SizedBox(width: 8),
                _filterChip(CapFilter.closed, l10n.s14FilterClosed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(CapFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      key: ValueKey('filter_${filter.name}'),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(filter),
      selectedColor: AppColors.navy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.gray800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.gray100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.s14EmptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.s14EmptyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.gray600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await context.pushNamed('s15_cap_create');
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.s14NewCapButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapList(AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _caps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cap = _caps[index];
        return _buildCapCard(context, l10n, cap);
      },
    );
  }

  Widget _buildCapCard(BuildContext context, AppLocalizations l10n, Cap cap) {
    final responsibleName = _userNames[cap.responsibleUserId] ?? cap.responsibleUserId;
    final deadlineStatus = cap.deadlineStatus();

    return Card(
      key: ValueKey('cap_item_${cap.id}'),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: deadlineStatus == CapDeadlineStatus.overdue
              ? AppColors.red.withValues(alpha: 0.4)
              : AppColors.gray200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.pushNamed(
            's16_cap_detail',
            pathParameters: {'id': cap.id},
          );
          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: CAP ID + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cap.id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                  ),
                  _statusBadge(l10n, cap.status),
                ],
              ),
              const SizedBox(height: 8),

              // Problem Statement (truncated)
              Text(
                cap.problemStatement,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyMid,
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Row: Responsible User + Deadline badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.s14ResponsiblePrefix(responsibleName),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _deadlineToWidget(l10n, cap.deadline, deadlineStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(AppLocalizations l10n, String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'open':
        bg = AppColors.navyLight.withValues(alpha: 0.12);
        fg = AppColors.navyLight;
        label = l10n.s14StatusOpen;
        break;
      case 'done':
        bg = Colors.purple.withValues(alpha: 0.12);
        fg = Colors.purple.shade800;
        label = l10n.s14StatusDone;
        break;
      case 'verified':
        bg = AppColors.greenPale;
        fg = AppColors.green;
        label = l10n.s14StatusVerified;
        break;
      case 'closed':
        bg = AppColors.gray200;
        fg = AppColors.gray800;
        label = l10n.s14StatusClosed;
        break;
      case 'aged':
        bg = AppColors.redPale;
        fg = AppColors.red;
        label = l10n.s14StatusAged;
        break;
      case 'reopened':
        bg = AppColors.amberPale;
        fg = AppColors.amber;
        label = l10n.s14StatusReopened;
        break;
      default:
        bg = AppColors.gray100;
        fg = AppColors.gray600;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _deadlineToWidget(
    AppLocalizations l10n,
    String deadline,
    CapDeadlineStatus status,
  ) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case CapDeadlineStatus.overdue:
        bg = AppColors.redPale;
        fg = AppColors.red;
        text = l10n.s14DeadlineOverdue(deadline);
        break;
      case CapDeadlineStatus.dueSoon:
        bg = AppColors.amberPale;
        fg = AppColors.amber;
        text = l10n.s14DeadlineDueSoon(deadline);
        break;
      case CapDeadlineStatus.ok:
        bg = AppColors.greenPale;
        fg = AppColors.green;
        text = l10n.s14DeadlineOk(deadline);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
