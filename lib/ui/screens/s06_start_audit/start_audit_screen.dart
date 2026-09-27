import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/cro.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/cro_repository.dart';
import '../../../domain/iso_week.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/draft_audit_provider.dart';
import '../../theme/app_colors.dart';

/// S6 Start Audit — date + CROs on duty, then routes to S7.
/// Parameterized by [auditType] ('daily' | 'weekly').
///
/// Per Spec §5 S6:
///   * Default date = today. Backdate allowed up to 30 days; future blocked.
///   * CROs on duty: multi-select, minimum 1.
///   * If an audit already exists for this date/week, warn and allow supersession.
class StartAuditScreen extends ConsumerStatefulWidget {
  const StartAuditScreen({
    super.key,
    this.auditType = 'daily',
  });

  final String auditType;

  @override
  ConsumerState<StartAuditScreen> createState() => _StartAuditScreenState();
}

class _StartAuditScreenState extends ConsumerState<StartAuditScreen> {
  DateTime _date = DateTime.now();
  List<Cro> _allCros = const [];
  final Set<String> _selectedCroIds = {};
  Audit? _existingAudit;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final cros = await CroRepository.instance.listActive();
    final Audit? existing;
    if (widget.auditType == 'weekly') {
      existing = await AuditRepository.instance.findByWeek(
        weekNumber: isoWeek(_date),
        year: _date.year,
        auditType: 'weekly',
      );
    } else {
      existing = await AuditRepository.instance.findByDate(
        date: DateFormat('yyyy-MM-dd').format(_date),
        auditType: 'daily',
      );
    }
    if (!mounted) return;
    setState(() {
      _allCros = cros;
      _existingAudit = existing;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date) {
      setState(() => _date = picked);
      await _refresh();
    }
  }

  Future<void> _addCroInline() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var counter = 'Titan';
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add CRO'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'CRO name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: counter,
                decoration: const InputDecoration(labelText: 'Counter'),
                items: const [
                  DropdownMenuItem(value: 'Titan', child: Text('Titan World')),
                  DropdownMenuItem(value: 'Helios', child: Text('Helios')),
                ],
                onChanged: (v) => setSt(() => counter = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.btnCancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.length < 2) return;
                await CroRepository.instance.add(name: name, counter: counter);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(true);
              },
              child: Text(l10n.btnAdd),
            ),
          ],
        ),
      ),
    );
    if (added == true) await _refresh();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCroIds.isEmpty) {
      setState(() => _error = l10n.s06SelectAtLeastOneCro);
      return;
    }
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final selectedCros =
        _allCros.where((c) => _selectedCroIds.contains(c.id)).toList();

    await ref.read(draftAuditProvider.notifier).startAudit(
          date: DateFormat('yyyy-MM-dd').format(_date),
          auditType: widget.auditType,
          auditorId: user.id,
          cros: selectedCros,
          supersedesAuditId:
              _existingAudit?.isSubmitted == true ? _existingAudit!.id : null,
        );

    if (!mounted) return;
    context.goNamed('s07_checkpoint');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final isWeekly = widget.auditType == 'weekly';
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(_date);
    final isToday =
        DateFormat('yyyy-MM-dd').format(_date) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());

    final calendarSubtitle = isWeekly
        ? '${l10n.s05WeekNumberLabel(isoWeek(_date), _date.year)}  ·  $dateLabel'
        : dateLabel + (isToday ? '  ·  today' : '');

    return Scaffold(
      appBar: AppBar(
        title: Text(isWeekly ? l10n.s06WeeklyTitle : l10n.s06Title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.navy),
              title: Text(l10n.s06AuditDate),
              subtitle: Text(calendarSubtitle),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
          ),
          if (_existingAudit != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amberPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _existingAudit!.isSubmitted
                          ? (isWeekly
                              ? 'A submitted weekly audit exists for Week ${isoWeek(_date)}, ${_date.year}. Starting a new one will supersede it.'
                              : 'A submitted audit exists for this date. Starting a new one will supersede it (history preserved).')
                          : (isWeekly
                              ? 'A draft weekly audit exists for Week ${isoWeek(_date)}, ${_date.year}. Starting a new one will replace it.'
                              : 'A draft audit exists for this date. Starting a new one will replace it.'),
                      style: const TextStyle(color: AppColors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.s06CrosOnDuty,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 18,
                  color: AppColors.navy,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add CRO'),
                onPressed: _addCroInline,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_allCros.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No CROs added yet'),
                subtitle: Text(
                  'Use "Add CRO" above to add staff before starting the audit.',
                ),
              ),
            )
          else
            ..._allCros.map((c) {
              final selected = _selectedCroIds.contains(c.id);
              return CheckboxListTile(
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedCroIds.add(c.id);
                    } else {
                      _selectedCroIds.remove(c.id);
                    }
                  });
                },
                title: Text(c.name),
                subtitle: Text('${c.counter}  ·  ${c.shift}'),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.red),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_busy || _allCros.isEmpty) ? null : _confirm,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.s06BeginAudit),
          ),
        ],
      ),
    );
  }
}
