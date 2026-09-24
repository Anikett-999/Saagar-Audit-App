import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/cap.dart';
import '../../../data/models/cap_action.dart';
import '../../../data/models/user.dart';
import '../../../data/photo_service.dart';
import '../../../data/repositories/cap_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/language_toggle_button.dart';

/// Screen S17 — CAP Action — Mark Done Modal / Screen.
///
/// Spec §5 S17:
/// - Confirms all action steps are checked (must all have is_done = 1).
/// - Asks for optional "done notes" (reflection / completion description).
/// - Optional photo of completion evidence (context: 'cap_progress').
/// - On confirm:
///   - Updates caps.status = 'done', done_at = now.
///   - Inserts cap_log: event = 'marked_done'.
///   - Inserts photos (if provided): context = 'cap_progress'.
///   - // TODO(phase4): Push notification to GM.
class CapMarkDoneScreen extends ConsumerStatefulWidget {
  const CapMarkDoneScreen({
    super.key,
    required this.capId,
    this.onPickPhoto,
  });

  final String capId;
  final Future<String?> Function()? onPickPhoto;

  @override
  ConsumerState<CapMarkDoneScreen> createState() => _CapMarkDoneScreenState();
}

class _CapMarkDoneScreenState extends ConsumerState<CapMarkDoneScreen> {
  final _notesController = TextEditingController();

  Cap? _cap;
  List<CapAction> _actions = [];
  User? _responsibleUser;
  String? _photoPath;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cap = await CapRepository.instance.getById(widget.capId);
      if (cap != null) {
        final actions = await CapRepository.instance.actionsFor(widget.capId);
        final user = await UserRepository.instance.getById(cap.responsibleUserId);
        if (mounted) {
          setState(() {
            _cap = cap;
            _actions = actions;
            _responsibleUser = user;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
  }

  Future<void> _submitMarkDone() async {
    final cap = _cap;
    if (cap == null) return;

    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);

    try {
      final notesText = _notesController.text.trim();
      await CapRepository.instance.markDone(
        capId: cap.id,
        userId: user.id,
        doneNotes: notesText.isEmpty ? null : notesText,
        photoPath: _photoPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s17SuccessSnackbar(cap.id)),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.s17ErrorSnackbar(e.toString())),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(l10n.s17Title),
        actions: const [LanguageToggleButton()],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.s17Loading),
                ],
              ),
            )
          : _cap == null
              ? _buildNotFound(l10n)
              : _buildContent(l10n),
    );
  }

  Widget _buildNotFound(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(
              l10n.s17CapNotFound,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/caps');
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.s17CancelButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final cap = _cap!;
    final allActionsDone = _actions.isNotEmpty && _actions.every((a) => a.isDone);
    final isCapActionable = cap.isOpen;
    final canSubmit = isCapActionable && allActionsDone && !_isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Summary Card
          _buildSummaryCard(l10n, cap),
          const SizedBox(height: 16),

          // 2. Action Steps Confirmation
          _buildActionStepsCard(l10n, allActionsDone),
          const SizedBox(height: 16),

          // 3. Optional Done Notes
          _buildDoneNotesCard(l10n),
          const SizedBox(height: 16),

          // 4. Optional Evidence Photo
          _buildEvidencePhotoCard(l10n),
          const SizedBox(height: 16),

          // 5. Verification Advisory Card
          _buildAdvisoryCard(l10n),
          const SizedBox(height: 24),

          // 6. Action Buttons
          ElevatedButton.icon(
            key: const ValueKey('s17_confirm_button'),
            onPressed: canSubmit ? _submitMarkDone : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSubmitting ? l10n.s17Submitting : l10n.s17ConfirmButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: AppColors.gray300,
              disabledForegroundColor: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('s17_cancel_button'),
            onPressed: _isSubmitting
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop(false);
                    } else {
                      context.go('/caps/${cap.id}');
                    }
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.s17CancelButton),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n, Cap cap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cap.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                _statusBadge(l10n, cap.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.s17ProblemStatement,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.gray600,
              ),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.gray800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.gray600),
                const SizedBox(width: 6),
                Text(
                  '${l10n.s17Responsible}: ${_responsibleUser?.name ?? cap.responsibleUserId}${_responsibleUser != null ? ' (${_responsibleUser!.role.toUpperCase()})' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.gray600),
                const SizedBox(width: 6),
                Text(
                  l10n.s16DeadlineLabel(cap.deadline),
                  style: const TextStyle(fontSize: 13, color: AppColors.gray800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStepsCard(AppLocalizations l10n, bool allActionsDone) {
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
                const Icon(Icons.playlist_add_check, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  l10n.s17SectionCompletedSteps,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Verification Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: allActionsDone ? AppColors.greenPale : AppColors.amberPale,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: allActionsDone ? AppColors.greenMid : AppColors.amber,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    allActionsDone ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: allActionsDone ? AppColors.green : AppColors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      allActionsDone
                          ? l10n.s17AllStepsCompletedNotice(_actions.length)
                          : l10n.s17IncompleteStepsWarning,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: allActionsDone ? AppColors.green : AppColors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action list items
            ..._actions.map((action) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      action.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: action.isDone ? AppColors.green : AppColors.gray400,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.s17StepNumber(action.sequence)}: ${action.actionText}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: action.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: action.isDone
                                  ? AppColors.gray600
                                  : AppColors.gray800,
                            ),
                          ),
                          if (action.doneAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Done: ${action.doneAt!.substring(0, 10)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneNotesCard(AppLocalizations l10n) {
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
                const Icon(Icons.rate_review_outlined, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  l10n.s17SectionDoneNotes,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('s17_done_notes_input'),
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.s17DoneNotesHint,
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidencePhotoCard(AppLocalizations l10n) {
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
                Text(
                  l10n.s17SectionEvidencePhoto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_photoPath == null)
              OutlinedButton.icon(
                key: const ValueKey('s17_take_photo_button'),
                onPressed: _capturePhoto,
                icon: const Icon(Icons.add_a_photo),
                label: Text(l10n.s17TakePhoto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.s17PhotoAttached,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                key: const ValueKey('s17_retake_photo_button'),
                                onPressed: _capturePhoto,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: Text(l10n.s17RetakePhoto),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                key: const ValueKey('s17_remove_photo_button'),
                                onPressed: _removePhoto,
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: Text(l10n.s17RemovePhoto),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.red,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildAdvisoryCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navyLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.s17AdvisoryCard,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.navyMid,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(AppLocalizations l10n, String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'open':
        bg = AppColors.navy.withValues(alpha: 0.1);
        fg = AppColors.navy;
        label = l10n.s16StatusOpen;
        break;
      case 'done':
        bg = AppColors.greenPale;
        fg = AppColors.green;
        label = l10n.s16StatusDone;
        break;
      case 'verified':
        bg = AppColors.goldPale;
        fg = AppColors.gold;
        label = l10n.s16StatusVerified;
        break;
      case 'closed':
        bg = AppColors.gray200;
        fg = AppColors.gray800;
        label = l10n.s16StatusClosed;
        break;
      case 'aged':
        bg = AppColors.redPale;
        fg = AppColors.red;
        label = l10n.s16StatusAged;
        break;
      case 'reopened':
        bg = AppColors.amberPale;
        fg = AppColors.amber;
        label = l10n.s16StatusReopened;
        break;
      default:
        bg = AppColors.gray100;
        fg = AppColors.gray800;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
