import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/audit.dart';
import '../../../data/models/cap.dart';
import '../../../data/models/checkpoint.dart';
import '../../../data/models/user.dart';
import '../../../data/photo_service.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../data/repositories/checkpoint_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S18 — CAP Verification Screen (GM / Owner only).
///
/// Implements Spec §5 S18 and Workbook Day 4 §4.3:
/// - GM/Owner inspects resolved CAP and re-evaluates verification method.
/// - Mandatory photo evidence enforcement if origin checkpoint has `requires_photo_on_fail == 1`.
/// - On Pass: updates CAP to `verified` via `CapRepository.verifyCap`.
/// - On Fail: presents choices to either Extend deadline or Reopen at Plan phase.
class S18CapVerifyScreen extends ConsumerStatefulWidget {
  const S18CapVerifyScreen({
    super.key,
    required this.capId,
    this.onPickPhoto,
  });

  final String capId;
  final Future<String?> Function()? onPickPhoto;

  @override
  ConsumerState<S18CapVerifyScreen> createState() => _S18CapVerifyScreenState();
}

class _S18CapVerifyScreenState extends ConsumerState<S18CapVerifyScreen> {
  Cap? _cap;
  Checkpoint? _checkpoint;
  Audit? _originAudit;
  User? _responsibleUser;
  String? _photoPath;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _requiresPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cap = await CapRepository.instance.getById(widget.capId);
      if (cap != null) {
        final cp = await CheckpointRepository.instance.getById(cap.originCheckpointId);
        final audit = await AuditRepository.instance.getById(cap.originAuditId);
        final user = await UserRepository.instance.getById(cap.responsibleUserId);

        if (mounted) {
          setState(() {
            _cap = cap;
            _checkpoint = cp;
            _originAudit = audit;
            _responsibleUser = user;
            _requiresPhoto = cp != null && cp.requiresPhotoOnFail;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cap = null;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final picker = widget.onPickPhoto ??
          () => PhotoService.instance.captureAndStore(auditId: widget.capId);
      final path = await picker();
      if (path != null && mounted) {
        setState(() => _photoPath = path);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s18PhotoCaptureError(e.toString())),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _onPassAndVerify() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || (!user.isGm && !user.isOwner)) {
      return;
    }

    if (_requiresPhoto && (_photoPath == null || _photoPath!.trim().isEmpty)) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s18PhotoRequiredError),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await CapRepository.instance.verifyCap(
        capId: widget.capId,
        verifierId: user.id,
        photoPath: _photoPath,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s18VerifySuccess),
            backgroundColor: AppColors.green,
          ),
        );
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/caps/${widget.capId}');
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s18VerifyError(e.toString())),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onVerificationFailed() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.s18FailDialogTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(l10n.s18FailDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.weeklyReviewCancel),
          ),
          OutlinedButton(
            key: const ValueKey('s18_fail_extend_choice'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showExtendDialog();
            },
            child: Text(l10n.s18ActionExtend),
          ),
          FilledButton(
            key: const ValueKey('s18_fail_reopen_choice'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showReopenDialog();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text(l10n.s18ActionReopen),
          ),
        ],
      ),
    );
  }

  void _showExtendDialog() {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateStr = selectedDate.toIso8601String().substring(0, 10);
          return AlertDialog(
            title: Text(l10n.s18ExtendTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.s18ExtendNewDeadline,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray300),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.gray100,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.navy),
                          const SizedBox(width: 8),
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.s18ExtendReason,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('s18_extend_reason_input'),
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.s18ExtendReasonHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.weeklyReviewCancel),
              ),
              FilledButton(
                key: const ValueKey('s18_confirm_extend_button'),
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(l10n.s18MissingReasonError)),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  _handleExtend(dateStr, reason);
                },
                child: Text(l10n.s18ConfirmExtend),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleExtend(String dateStr, String reason) async {
    final authUser = ref.read(authProvider).user;
    if (authUser == null) return;

    setState(() => _isSubmitting = true);
    try {
      await CapRepository.instance.extendCap(
        capId: widget.capId,
        actorId: authUser.id,
        newDeadline: dateStr,
        reason: reason,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s18ExtendSuccess),
          backgroundColor: AppColors.green,
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/caps/${widget.capId}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showReopenDialog() {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.s18ReopenTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.s18ReopenReason,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const ValueKey('s18_reopen_reason_input'),
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.s18ReopenReasonHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.weeklyReviewCancel),
          ),
          FilledButton(
            key: const ValueKey('s18_confirm_reopen_button'),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.s18MissingReasonError)),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _handleReopen(reason);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text(l10n.s18ConfirmReopen),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReopen(String reason) async {
    final authUser = ref.read(authProvider).user;
    if (authUser == null) return;

    setState(() => _isSubmitting = true);
    try {
      await CapRepository.instance.reopenCap(
        capId: widget.capId,
        actorId: authUser.id,
        reason: reason,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.s18ReopenSuccess),
          backgroundColor: Colors.deepOrange,
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/caps/${widget.capId}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Role Guard: GM/Owner only
    if (user != null && !user.isGm && !user.isOwner) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s18CapVerifyTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                l10n.s18AccessDenied,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.s18Back),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s18CapVerifyTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cap == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.s18CapVerifyTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text(l10n.s16NotFound),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.s16BackToCaps),
              ),
            ],
          ),
        ),
      );
    }

    final cap = _cap!;
    final cpText = _checkpoint != null
        ? '${cap.originCheckpointId} — ${_checkpoint!.text(locale)}'
        : cap.originCheckpointId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.s18CapVerifyTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            _buildHeaderCard(l10n, cap),
            const SizedBox(height: 16),

            // Origin Checkpoint Card
            _buildOriginCard(l10n, cpText),
            const SizedBox(height: 16),

            // Verification Method Card (Hero Card)
            _buildVerificationMethodCard(l10n, cap),
            const SizedBox(height: 16),

            // Photo Evidence Section
            _buildPhotoCard(l10n),
            const SizedBox(height: 24),

            // Verification Decision Buttons
            _buildDecisionButtons(l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n, Cap cap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cap.id,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (cap.isPattern) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.amber),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.repeat, size: 14, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Text(
                          l10n.s18PatternMarker,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: Text(
                    cap.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.s18ProblemStatement,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gray600),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.navy, width: 4),
                ),
              ),
              child: Text(
                cap.problemStatement,
                style: const TextStyle(fontSize: 14, color: AppColors.gray800),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.gray600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.s17Responsible}: ${_responsibleUser?.name ?? cap.responsibleUserId}',
                    style: const TextStyle(fontSize: 13, color: AppColors.gray800),
                  ),
                ),
                const Icon(Icons.event, size: 16, color: AppColors.gray600),
                const SizedBox(width: 6),
                Text(
                  '${l10n.s18Deadline}: ${cap.deadline}',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginCard(AppLocalizations l10n, String cpText) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: AppColors.navy, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.s18OriginCheckpoint,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              cpText,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray800),
            ),
            if (_originAudit != null) ...[
              const SizedBox(height: 6),
              Text(
                'Audit: ${_originAudit!.auditDate} (${_originAudit!.auditType.toUpperCase()})',
                style: const TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationMethodCard(AppLocalizations l10n, Cap cap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.navy, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s18VerificationMethod,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldPale,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Text(
                cap.verificationMethod,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: AppColors.navy, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.s18QuestionAffirmation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
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

  Widget _buildPhotoCard(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: AppColors.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.s17SectionEvidencePhoto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (_requiresPhoto)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.red),
                    ),
                    child: Text(
                      l10n.s18PhotoRequiredBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                  ),
              ],
            ),
            if (_requiresPhoto && _photoPath == null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.s18PhotoRequiredNotice,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_photoPath == null)
              OutlinedButton.icon(
                key: const ValueKey('s18_take_photo_button'),
                onPressed: _capturePhoto,
                icon: const Icon(Icons.add_a_photo),
                label: Text(l10n.s18TakePhoto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: AppColors.gray300,
                        child: Image.file(
                          File(_photoPath!),
                          fit: BoxFit.cover,
                          cacheWidth: 150,
                          cacheHeight: 150,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.broken_image,
                            size: 32,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: AppColors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  l10n.s18PhotoAttached,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _photoPath!.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontSize: 11, color: AppColors.gray600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.s17RemovePhoto,
                      icon: const Icon(Icons.delete_outline, color: AppColors.red),
                      onPressed: () => setState(() => _photoPath = null),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButtons(AppLocalizations l10n) {
    final canPass = !_requiresPhoto || (_photoPath != null && _photoPath!.trim().isNotEmpty);

    return Column(
      children: [
        // Pass & Verify Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            key: const ValueKey('s18_pass_verify_button'),
            onPressed: (_isSubmitting || !canPass) ? null : _onPassAndVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.gray300,
              disabledForegroundColor: AppColors.gray600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : const Icon(Icons.verified),
            label: Text(
              l10n.s18PassAndVerify,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Verification Failed Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey('s18_fail_verify_button'),
            onPressed: _isSubmitting ? null : _onVerificationFailed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.close),
            label: Text(
              l10n.s18VerificationFailed,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
