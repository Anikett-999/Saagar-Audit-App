import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cro.dart';
import '../../../data/repositories/cro_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S28 — Settings: Manage CROs.
///
/// Available to all roles (SM, GM, Owner) per Spec §S28 and role matrix.
/// Displays all active and inactive CROs.
/// Deactivated CROs disappear from new audit pickers (listActive)
/// but remain attributed in past audit history.
class ManageCrosScreen extends ConsumerStatefulWidget {
  const ManageCrosScreen({super.key});

  @override
  ConsumerState<ManageCrosScreen> createState() => _ManageCrosScreenState();
}

class _ManageCrosScreenState extends ConsumerState<ManageCrosScreen> {
  List<Cro> _cros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCros();
  }

  Future<void> _loadCros() async {
    setState(() => _loading = true);
    final list = await CroRepository.instance.listAll();
    if (!mounted) return;
    setState(() {
      _cros = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s28Title),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.s28AddCroTitle),
        onPressed: () => _openCroDialog(context, l10n),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCros,
              child: _cros.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 96,
                      ),
                      itemCount: _cros.length,
                      itemBuilder: (context, index) {
                        final cro = _cros[index];
                        return _buildCroCard(context, l10n, cro);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.s28EmptyState,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.gray600,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.s28AddCroTitle),
                  onPressed: () => _openCroDialog(context, l10n),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCroCard(BuildContext context, AppLocalizations l10n, Cro cro) {
    final isActive = cro.isActive;

    final counterText = switch (cro.counter) {
      'Titan' => l10n.s28CounterTitan,
      'Helios' => l10n.s28CounterHelios,
      _ => cro.counter,
    };

    final shiftText = switch (cro.shift) {
      'morning' => l10n.s28ShiftMorning,
      'afternoon' => l10n.s28ShiftAfternoon,
      _ => l10n.s28ShiftFlexible,
    };

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? AppColors.gray200 : AppColors.gray300,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isActive ? AppColors.navy : AppColors.gray400,
                    child: Text(
                      cro.name.isNotEmpty ? cro.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cro.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.navy : AppColors.gray800,
                            fontFamily: 'DMSans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$counterText • $shiftText',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray600,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(l10n, isActive),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.s28EditAction),
                    onPressed: () => _openCroDialog(context, l10n, existing: cro),
                  ),
                  const SizedBox(width: 8),
                  if (isActive)
                    TextButton.icon(
                      icon: const Icon(Icons.person_off_outlined, size: 18, color: AppColors.red),
                      label: Text(
                        l10n.s28DeactivateAction,
                        style: const TextStyle(color: AppColors.red),
                      ),
                      onPressed: () => _confirmDeactivate(l10n, cro),
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18, color: AppColors.green),
                      label: Text(
                        l10n.s28ReactivateAction,
                        style: const TextStyle(color: AppColors.green),
                      ),
                      onPressed: () => _reactivateCro(cro, l10n),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AppLocalizations l10n, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.greenPale : AppColors.gray200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.green.withValues(alpha: 0.3) : AppColors.gray400,
        ),
      ),
      child: Text(
        isActive ? l10n.s28StatusActive : l10n.s28StatusInactive,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.green : AppColors.gray600,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate(
    AppLocalizations l10n,
    Cro cro,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.s28DeactivateConfirmTitle,
          style: const TextStyle(fontFamily: 'DMSerifDisplay', color: AppColors.navy),
        ),
        content: Text(
          l10n.s28DeactivateConfirmBody,
          style: const TextStyle(fontFamily: 'DMSans', color: AppColors.gray800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.s28CancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.s28DeactivateAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CroRepository.instance.deactivate(cro.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s28CroDeactivatedSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadCros();
    }
  }

  Future<void> _reactivateCro(Cro cro, AppLocalizations l10n) async {
    await CroRepository.instance.reactivate(cro.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.s28CroReactivatedSuccess),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _loadCros();
  }

  void _openCroDialog(
    BuildContext context,
    AppLocalizations l10n, {
    Cro? existing,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CroFormDialog(
        existing: existing,
        onSaved: () async {
          await _loadCros();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  existing == null
                      ? l10n.s28CroAddedSuccess
                      : l10n.s28CroUpdatedSuccess,
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

class _CroFormDialog extends StatefulWidget {
  const _CroFormDialog({
    this.existing,
    required this.onSaved,
  });

  final Cro? existing;
  final VoidCallback onSaved;

  @override
  State<_CroFormDialog> createState() => _CroFormDialogState();
}

class _CroFormDialogState extends State<_CroFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _counter;
  late String _shift;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _counter = e?.counter ?? 'Titan';
    _shift = e?.shift ?? 'morning';
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();

    try {
      final e = widget.existing;
      if (e == null) {
        final id = await CroRepository.instance.add(
          name: name,
          counter: _counter,
          shift: _shift,
        );
        if (!_isActive) {
          await CroRepository.instance.deactivate(id);
        }
      } else {
        await CroRepository.instance.update(
          id: e.id,
          name: name,
          counter: _counter,
          shift: _shift,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? l10n.s28EditCroTitle : l10n.s28AddCroTitle,
        style: const TextStyle(fontFamily: 'DMSerifDisplay', color: AppColors.navy),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.s28NameLabel,
                  hintText: l10n.s28NameHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return l10n.s28NameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.s28CounterLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.gray800,
                  fontFamily: 'DMSans',
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'Titan',
                    label: Text(l10n.s28CounterTitan),
                    icon: const Icon(Icons.watch_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 'Helios',
                    label: Text(l10n.s28CounterHelios),
                    icon: const Icon(Icons.storefront_outlined, size: 16),
                  ),
                ],
                selected: {_counter},
                onSelectionChanged: (val) {
                  setState(() => _counter = val.first);
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.s28ShiftLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.gray800,
                  fontFamily: 'DMSans',
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _shift,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  DropdownMenuItem(value: 'morning', child: Text(l10n.s28ShiftMorning)),
                  DropdownMenuItem(value: 'afternoon', child: Text(l10n.s28ShiftAfternoon)),
                  DropdownMenuItem(value: 'flexible', child: Text(l10n.s28ShiftFlexible)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _shift = val);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.s28StatusLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.s28ActiveHelp,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                ),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.s28CancelButton),
        ),
        ElevatedButton(
          onPressed: _saving ? null : () => _submit(l10n),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                )
              : Text(l10n.s28SaveButton),
        ),
      ],
    );
  }
}
