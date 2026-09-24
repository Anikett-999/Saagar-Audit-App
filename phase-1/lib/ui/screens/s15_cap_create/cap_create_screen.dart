import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/checkpoint.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S15 — Corrective Action Plan (CAP) Create.
///
/// Implements the 10-field template from Workbook Appendix A.3 & Spec §5 S15:
/// 1. CAP ID (auto-generated, read-only preview)
/// 2. Originating Finding (audit + checkpoint)
/// 3. Problem Statement (required)
/// 4. 5 Whys (Why 1 required, 2–5 optional)
/// 5. Root Cause (required)
/// 6. Action Steps (dynamic 3 to 5 steps, bounded)
/// 7. Responsible User / CAP Owner (SM, GM, Owner only)
/// 8. Deadline (date picker, defaults to +7 days)
/// 9. Verification Method (checkpoint dropdown or description)
/// 10. Create CAP Action (atomic multi-table commit via CapRepository)
class CapCreateScreen extends ConsumerStatefulWidget {
  const CapCreateScreen({
    super.key,
    this.originAuditId,
    this.originCheckpointId,
    this.originResultId,
    this.initialProblemStatement,
  });

  final String? originAuditId;
  final String? originCheckpointId;
  final String? originResultId;
  final String? initialProblemStatement;

  @override
  ConsumerState<CapCreateScreen> createState() => _CapCreateScreenState();
}

class _CapCreateScreenState extends ConsumerState<CapCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _problemController = TextEditingController();
  final _why1Controller = TextEditingController();
  final _why2Controller = TextEditingController();
  final _why3Controller = TextEditingController();
  final _why4Controller = TextEditingController();
  final _why5Controller = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _verificationController = TextEditingController();

  final List<TextEditingController> _actionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  String? _capIdPreview;
  String? _selectedAuditId;
  String? _selectedCheckpointId;
  String? _selectedResponsibleUserId;
  late DateTime _selectedDeadline;

  List<Audit> _audits = [];
  List<Checkpoint> _checkpoints = [];
  List<User> _responsibleUsers = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDeadline = DateTime.now().add(const Duration(days: 7));
    if (widget.initialProblemStatement != null) {
      _problemController.text = widget.initialProblemStatement!;
    }
    _selectedAuditId = widget.originAuditId;
    _selectedCheckpointId = widget.originCheckpointId;
    _loadData();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _why1Controller.dispose();
    _why2Controller.dispose();
    _why3Controller.dispose();
    _why4Controller.dispose();
    _why5Controller.dispose();
    _rootCauseController.dispose();
    _verificationController.dispose();
    for (final c in _actionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Load active users (SM, GM, OWNER only)
      final allActive = await UserRepository.instance.listActive();
      final validUsers = allActive
          .where((u) => u.isSm || u.isGm || u.isOwner)
          .toList();

      // 2. Load daily checkpoints
      final checkpoints = await CheckpointRepository.instance
          .loadDailyCheckpointsInAuditOrder();

      // 3. Load audits
      final audits = await AuditRepository.instance.listAudits(
        viewer: auth.user!,
        limit: 20,
      );

      // 4. Generate CAP ID preview
      final capId = await CapRepository.instance.generateNextCapId(DateTime.now());

      if (mounted) {
        setState(() {
          _responsibleUsers = validUsers;
          _checkpoints = checkpoints;
          _audits = audits;
          _capIdPreview = capId;

          // Default selections
          if (_selectedAuditId == null && audits.isNotEmpty) {
            _selectedAuditId = audits.first.id;
          }

          if (_selectedCheckpointId == null && checkpoints.isNotEmpty) {
            _selectedCheckpointId = checkpoints.first.id;
          }

          if (_selectedResponsibleUserId == null && validUsers.isNotEmpty) {
            // Default to viewer if eligible, otherwise first valid user
            final viewerMatch = validUsers.any((u) => u.id == auth.user!.id);
            _selectedResponsibleUserId =
                viewerMatch ? auth.user!.id : validUsers.first.id;
          }

          // Pre-populate verification text if empty
          if (_verificationController.text.trim().isEmpty &&
              _selectedCheckpointId != null) {
            final cp = checkpoints.firstWhere(
              (c) => c.id == _selectedCheckpointId,
              orElse: () => checkpoints.first,
            );
            final locale = auth.user!.languagePref;
            _verificationController.text = cp.text(locale);
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addActionStep() {
    if (_actionControllers.length < 5) {
      setState(() {
        _actionControllers.add(TextEditingController());
      });
    }
  }

  void _removeActionStep(int index) {
    if (_actionControllers.length > 3) {
      setState(() {
        final removed = _actionControllers.removeAt(index);
        removed.dispose();
      });
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline.isBefore(now) ? now : _selectedDeadline,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (auth.user == null) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_actionControllers.length < 3 || _actionControllers.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.s15MinStepsNotice)),
      );
      return;
    }

    final emptyStep = _actionControllers.any((c) => c.text.trim().isEmpty);
    if (emptyStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.s15StepRequired)),
      );
      return;
    }

    if (_selectedAuditId == null && _audits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.s15NoAuditsFound)),
      );
      return;
    }

    final auditId = _selectedAuditId ?? '';
    final checkpointId = _selectedCheckpointId ?? '';
    final responsibleId = _selectedResponsibleUserId ?? auth.user!.id;

    setState(() => _isSubmitting = true);

    try {
      final deadlineStr = _selectedDeadline.toIso8601String().substring(0, 10);
      final steps = _actionControllers.map((c) => c.text.trim()).toList();

      final created = await CapRepository.instance.createCap(
        originAuditId: auditId,
        originCheckpointId: checkpointId,
        originResultId: widget.originResultId,
        problemStatement: _problemController.text.trim(),
        why1: _why1Controller.text.trim(),
        why2: _why2Controller.text.trim().isEmpty ? null : _why2Controller.text.trim(),
        why3: _why3Controller.text.trim().isEmpty ? null : _why3Controller.text.trim(),
        why4: _why4Controller.text.trim().isEmpty ? null : _why4Controller.text.trim(),
        why5: _why5Controller.text.trim().isEmpty ? null : _why5Controller.text.trim(),
        rootCause: _rootCauseController.text.trim(),
        responsibleUserId: responsibleId,
        deadline: deadlineStr,
        verificationMethod: _verificationController.text.trim().isEmpty
            ? 'Visual inspection'
            : _verificationController.text.trim(),
        actionSteps: steps,
        creatorUserId: auth.user!.id,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Navigate to S16 CAP Detail, then pop back to list upon return
      await context.pushNamed(
        's16_cap_detail',
        pathParameters: {'id': created.id},
      );
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final l10n = AppLocalizations.of(context);
      final errMsg = l10n != null ? l10n.s15ErrorPrefix(e.toString()) : 'Error: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.s15Title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              l10n.s15Subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.goldPale),
            ),
          ],
        ),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPreviewCard(l10n),
                    const SizedBox(height: 16),
                    _buildOriginCard(l10n, locale),
                    const SizedBox(height: 16),
                    _buildProblemAnd5WhysCard(l10n),
                    const SizedBox(height: 16),
                    _buildActionStepsCard(l10n),
                    const SizedBox(height: 16),
                    _buildOwnershipAndVerificationCard(l10n),
                    const SizedBox(height: 24),
                    _buildSubmitButton(l10n),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPreviewCard(AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: AppColors.goldPale,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.goldLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.s15CapIdPreview,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyMid,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _capIdPreview ?? 'CAP-YYYY-Wxx-01',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const Icon(Icons.assignment_outlined, color: AppColors.navy, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginCard(AppLocalizations l10n, String locale) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 20, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  l10n.s15SectionOrigin,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Checkpoint selector
            Text(
              l10n.s15OriginCheckpoint,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: const ValueKey('s15_checkpoint_dropdown'),
              initialValue: _selectedCheckpointId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _checkpoints.map((cp) {
                final text = '${cp.id} — ${cp.text(locale)}';
                return DropdownMenuItem<String>(
                  value: cp.id,
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCheckpointId = val;
                    final cp = _checkpoints.firstWhere((c) => c.id == val);
                    _verificationController.text = cp.text(locale);
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // Origin Audit
            Text(
              l10n.s15OriginAudit,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (_audits.isEmpty && widget.originAuditId == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.s15NoAuditsFound,
                  style: const TextStyle(fontSize: 12, color: AppColors.amber),
                ),
              )
            else
              DropdownButtonFormField<String>(
                key: const ValueKey('s15_audit_dropdown'),
                initialValue: _selectedAuditId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _audits.map((a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text(
                      l10n.s15AuditDropdownItem(a.auditDate, a.auditType.toUpperCase()),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAuditId = val);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemAnd5WhysCard(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.s15SectionProblem,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Problem Statement
            Text(
              l10n.s15ProblemStatement,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('s15_problem_field'),
              controller: _problemController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.s15ProblemStatementHint,
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? l10n.s15ProblemRequired : null,
            ),
            const SizedBox(height: 16),

            // Why 1 (Mandatory)
            Text(
              l10n.s15Why1,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('s15_why1_field'),
              controller: _why1Controller,
              decoration: InputDecoration(
                hintText: l10n.s15Why1Hint,
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? l10n.s15Why1Required : null,
            ),
            const SizedBox(height: 10),

            // Why 2 (Optional)
            _optionalWhyField(_why2Controller, l10n.s15Why2, l10n.s15Why2Hint, 's15_why2_field'),
            const SizedBox(height: 10),

            // Why 3 (Optional)
            _optionalWhyField(_why3Controller, l10n.s15Why3, l10n.s15Why3Hint, 's15_why3_field'),
            const SizedBox(height: 10),

            // Why 4 (Optional)
            _optionalWhyField(_why4Controller, l10n.s15Why4, l10n.s15Why4Hint, 's15_why4_field'),
            const SizedBox(height: 10),

            // Why 5 (Optional)
            _optionalWhyField(_why5Controller, l10n.s15Why5, l10n.s15Why5Hint, 's15_why5_field'),
            const SizedBox(height: 16),

            // Root Cause (Mandatory)
            Text(
              l10n.s15RootCause,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('s15_root_cause_field'),
              controller: _rootCauseController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.s15RootCauseHint,
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? l10n.s15RootCauseRequired : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionalWhyField(
    TextEditingController controller,
    String label,
    String hint,
    String keyStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: ValueKey(keyStr),
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.gray100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionStepsCard(AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.checklist, size: 20, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.s15SectionActions,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_actionControllers.length}/5',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyMid,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action steps dynamic rows (3 to 5 steps)
            for (var i = 0; i < _actionControllers.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('s15_step_field_$i'),
                        controller: _actionControllers[i],
                        decoration: InputDecoration(
                          hintText: l10n.s15StepLabel(i + 1),
                          filled: true,
                          fillColor: AppColors.gray100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? l10n.s15StepRequired
                            : null,
                      ),
                    ),
                    if (_actionControllers.length > 3)
                      IconButton(
                        key: ValueKey('s15_remove_step_$i'),
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.red),
                        onPressed: () => _removeActionStep(i),
                      )
                    else
                      const SizedBox(width: 48), // Spacing placeholder
                  ],
                ),
              ),
            ],

            if (_actionControllers.length < 5)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('s15_add_step_button'),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(l10n.s15AddStep),
                  onPressed: _addActionStep,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnershipAndVerificationCard(AppLocalizations l10n) {
    final deadlineFormatted = _selectedDeadline.toIso8601String().substring(0, 10);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.s15SectionOwnership,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Responsible User (CAP Owner)
            Text(
              l10n.s15ResponsibleUser,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: const ValueKey('s15_responsible_dropdown'),
              initialValue: _selectedResponsibleUserId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _responsibleUsers.map((u) {
                return DropdownMenuItem<String>(
                  value: u.id,
                  child: Text(
                    '${u.name} (${u.role})',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedResponsibleUserId = val);
                }
              },
              validator: (val) =>
                  (val == null || val.isEmpty) ? l10n.s15ResponsibleRequired : null,
            ),
            const SizedBox(height: 16),

            // Deadline date picker
            Text(
              l10n.s15Deadline,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: const ValueKey('s15_deadline_picker'),
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      deadlineFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.navy),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Verification Method
            Text(
              l10n.s15VerificationMethod,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('s15_verification_field'),
              controller: _verificationController,
              decoration: InputDecoration(
                hintText: l10n.s15VerificationMethodHint,
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? l10n.s15VerificationRequired
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return ElevatedButton(
      key: const ValueKey('s15_create_button'),
      onPressed: _isSubmitting ? null : _onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
            )
          : Text(
              l10n.s15CreateButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
