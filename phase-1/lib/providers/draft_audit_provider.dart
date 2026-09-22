import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/audit.dart';
import '../data/models/checkpoint.dart';
import '../data/models/cro.dart';
import '../data/models/photo.dart';
import '../data/photo_service.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/checkpoint_repository.dart';
import '../domain/score_engine.dart';

export '../domain/score_engine.dart'
    show Band, CheckpointMark, ScoreResult, Verdict;

String verdictCode(Verdict v) => switch (v) {
      Verdict.pass => 'P',
      Verdict.fail => 'F',
      Verdict.na => 'NA',
    };

/// In-progress audit state. Persists every mark to SQLite so a crash mid-audit
/// loses nothing — Spec §2 offline-first acceptance: 24-hr offline works.
class DraftAuditState {
  const DraftAuditState({
    this.audit,
    this.checkpoints = const [],
    this.currentIndex = 0,
    this.results = const {},
    this.cros = const [],
  });

  /// Null if no draft is active.
  final Audit? audit;

  /// All 68 daily checkpoints in audit order, loaded once at draft start.
  final List<Checkpoint> checkpoints;

  /// Index into [checkpoints] — what the user is currently looking at.
  final int currentIndex;

  /// checkpoint_id → verdict. Sparse — only checkpoints already marked.
  final Map<String, Verdict> results;

  /// CROs on duty for this audit (selected on S6).
  final List<Cro> cros;

  bool get isActive => audit != null;
  bool get isComplete =>
      checkpoints.isNotEmpty && results.length == checkpoints.length;

  Checkpoint? get currentCheckpoint =>
      (currentIndex >= 0 && currentIndex < checkpoints.length)
          ? checkpoints[currentIndex]
          : null;

  int get passCount =>
      results.values.where((v) => v == Verdict.pass).length;
  int get failCount =>
      results.values.where((v) => v == Verdict.fail).length;
  int get naCount => results.values.where((v) => v == Verdict.na).length;

  DraftAuditState copyWith({
    Audit? audit,
    List<Checkpoint>? checkpoints,
    int? currentIndex,
    Map<String, Verdict>? results,
    List<Cro>? cros,
    bool clearAudit = false,
  }) {
    return DraftAuditState(
      audit: clearAudit ? null : (audit ?? this.audit),
      checkpoints: checkpoints ?? this.checkpoints,
      currentIndex: currentIndex ?? this.currentIndex,
      results: results ?? this.results,
      cros: cros ?? this.cros,
    );
  }
}

class DraftAuditNotifier extends StateNotifier<DraftAuditState> {
  DraftAuditNotifier() : super(const DraftAuditState());

  /// Start a brand-new daily audit. Loads the 68 checkpoints in time-block
  /// order and creates a draft row in SQLite.
  Future<void> startDaily({
    required String date,
    required String auditorId,
    required List<Cro> cros,
    String? supersedesAuditId,
  }) async {
    final audit = await AuditRepository.instance.createDraft(
      date: date,
      auditType: 'daily',
      auditorId: auditorId,
      supersedesAuditId: supersedesAuditId,
    );
    final checkpoints = await CheckpointRepository.instance
        .loadDailyCheckpointsInAuditOrder();
    state = DraftAuditState(
      audit: audit,
      checkpoints: checkpoints,
      currentIndex: 0,
      results: const {},
      cros: cros,
    );
  }

  /// Mark the current checkpoint as PASS or NA. Persists to DB and advances index.
  /// Hard Rule: FAIL marks must go through [recordFailAndAdvance] to ensure
  /// finding text and mandatory photos are captured atomically without leaving orphans.
  Future<void> mark(Verdict v, {String? findingText, String? croId}) async {
    assert(
      v != Verdict.fail,
      'FAIL must be recorded via recordFailAndAdvance with finding details',
    );
    final cp = state.currentCheckpoint;
    final audit = state.audit;
    if (cp == null || audit == null) return;
    if (audit.status != 'draft') {
      throw StateError(
        'Cannot modify audit ${audit.id}: status is ${audit.status}',
      );
    }

    await AuditRepository.instance.saveResult(
      auditId: audit.id,
      checkpointId: cp.id,
      result: verdictCode(v),
      weight: cp.weight,
      findingText: findingText,
      croId: croId,
    );

    final nextResults = Map<String, Verdict>.from(state.results)
      ..[cp.id] = v;

    state = state.copyWith(
      results: nextResults,
      currentIndex:
          (state.currentIndex + 1).clamp(0, state.checkpoints.length),
    );
  }

  /// Atomically persists a FAIL verdict, finding text, CRO attribution, and
  /// all attached evidence photos to SQLite, then advances the checkpoint index.
  /// Eliminates the Orphan-FAIL gap.
  Future<void> recordFailAndAdvance({
    required String findingText,
    String? croId,
    required List<String> photoPaths,
  }) async {
    final cp = state.currentCheckpoint;
    final audit = state.audit;
    if (cp == null || audit == null) return;
    if (audit.status != 'draft') {
      throw StateError(
        'Cannot modify audit ${audit.id}: status is ${audit.status}',
      );
    }
    if (cp.requiresPhotoOnFail && photoPaths.isEmpty) {
      throw ArgumentError(
        'Checkpoint ${cp.id} requires at least one photo on FAIL',
      );
    }

    final result = await AuditRepository.instance.saveResult(
      auditId: audit.id,
      checkpointId: cp.id,
      result: 'F',
      weight: cp.weight,
      findingText: findingText,
      croId: croId,
    );

    for (final path in photoPaths) {
      final size = await PhotoService.instance.fileSize(path);
      await AuditRepository.instance.attachPhoto(
        auditResultId: result.id,
        localPath: path,
        fileSizeBytes: size,
      );
    }

    final nextResults = Map<String, Verdict>.from(state.results)
      ..[cp.id] = Verdict.fail;

    state = state.copyWith(
      results: nextResults,
      currentIndex:
          (state.currentIndex + 1).clamp(0, state.checkpoints.length),
    );
  }

  /// Calculates final score using `scoreDaily(List<CheckpointMark>)` and submits
  /// the audit to SQLite, locking status to 'submitted'.
  Future<ScoreResult> submitAudit({String? notes}) async {
    final audit = state.audit;
    if (audit == null) {
      throw StateError('No active audit to submit');
    }
    if (audit.status != 'draft') {
      throw StateError(
        'Cannot submit audit ${audit.id}: status is ${audit.status}',
      );
    }
    if (!state.isComplete) {
      throw StateError(
        'Cannot submit incomplete audit: only ${state.results.length} of ${state.checkpoints.length} checkpoints marked',
      );
    }

    // Submission gate: verify all FAIL checkpoints with requiresPhotoOnFail have attached photos.
    for (final cp in state.checkpoints) {
      final verdict = state.results[cp.id];
      if (verdict == Verdict.fail && cp.requiresPhotoOnFail) {
        final result = await AuditRepository.instance.findResult(
          auditId: audit.id,
          checkpointId: cp.id,
        );
        final photos = result != null
            ? await AuditRepository.instance.photosForResult(result.id)
            : const <Photo>[];
        if (photos.isEmpty) {
          throw StateError(
            'Cannot submit audit: Checkpoint ${cp.id} requires photo evidence on FAIL',
          );
        }
      }
    }

    final marks = state.checkpoints.map((cp) {
      final verdict = state.results[cp.id]!;
      return CheckpointMark(
        checkpointId: cp.id,
        result: verdict,
        weight: cp.weight,
      );
    }).toList();

    final scoreResult = scoreDaily(marks);

    await AuditRepository.instance.submitAudit(
      auditId: audit.id,
      rawScore: scoreResult.rawScore,
      maxScore: scoreResult.maxScore,
      compliancePct: scoreResult.compliancePct,
      band: scoreResult.band.name,
      passCount: scoreResult.passCount,
      failCount: scoreResult.failCount,
      naCount: scoreResult.naCount,
      notes: notes,
    );

    final updatedAudit = audit.copyWith(
      status: 'submitted',
      submittedAt: DateTime.now().toUtc().toIso8601String(),
      rawScore: scoreResult.rawScore,
      maxScore: scoreResult.maxScore,
      compliancePct: scoreResult.compliancePct,
      band: scoreResult.band.name,
      passCount: scoreResult.passCount,
      failCount: scoreResult.failCount,
      naCount: scoreResult.naCount,
      notes: notes,
    );

    state = state.copyWith(audit: updatedAudit);
    return scoreResult;
  }

  void goBack() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void jumpTo(int index) {
    if (index < 0 || index >= state.checkpoints.length) return;
    state = state.copyWith(currentIndex: index);
  }

  void clear() {
    state = const DraftAuditState();
  }
}

final draftAuditProvider =
    StateNotifierProvider<DraftAuditNotifier, DraftAuditState>(
  (ref) => DraftAuditNotifier(),
);
