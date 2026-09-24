/// Status of a CAP deadline relative to the current date.
enum CapDeadlineStatus {
  overdue,
  dueSoon,
  ok,
}

/// Filter groups for the CAP list view (Spec §5 S14).
enum CapFilter {
  all,
  open,
  done,
  aged,
  closed,
}

/// Corrective Action Plan (CAP) model.
///
/// Mapped 1:1 from Spec §4.9 `caps` table.
class Cap {
  const Cap({
    required this.id,
    required this.originAuditId,
    this.originResultId,
    required this.originCheckpointId,
    this.isPattern = false,
    required this.problemStatement,
    required this.why1,
    this.why2,
    this.why3,
    this.why4,
    this.why5,
    required this.rootCause,
    required this.responsibleUserId,
    required this.deadline,
    required this.verificationMethod,
    this.status = 'open',
    required this.openedAt,
    this.doneAt,
    this.verifiedAt,
    this.closedAt,
    this.verifiedBy,
    this.closedBy,
    this.agedCount = 0,
    this.extensionCount = 0,
    this.latestExtensionReason,
  });

  factory Cap.fromMap(Map<String, Object?> m) => Cap(
        id: m['id']! as String,
        originAuditId: m['origin_audit_id']! as String,
        originResultId: m['origin_result_id'] as String?,
        originCheckpointId: m['origin_checkpoint_id']! as String,
        isPattern: (m['is_pattern'] as int? ?? 0) == 1,
        problemStatement: m['problem_statement']! as String,
        why1: m['why_1']! as String,
        why2: m['why_2'] as String?,
        why3: m['why_3'] as String?,
        why4: m['why_4'] as String?,
        why5: m['why_5'] as String?,
        rootCause: m['root_cause']! as String,
        responsibleUserId: m['responsible_user_id']! as String,
        deadline: m['deadline']! as String,
        verificationMethod: m['verification_method']! as String,
        status: (m['status'] as String?) ?? 'open',
        openedAt: m['opened_at']! as String,
        doneAt: m['done_at'] as String?,
        verifiedAt: m['verified_at'] as String?,
        closedAt: m['closed_at'] as String?,
        verifiedBy: m['verified_by'] as String?,
        closedBy: m['closed_by'] as String?,
        agedCount: (m['aged_count'] as int?) ?? 0,
        extensionCount: (m['extension_count'] as int?) ?? 0,
        latestExtensionReason: m['latest_extension_reason'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'origin_audit_id': originAuditId,
        'origin_result_id': originResultId,
        'origin_checkpoint_id': originCheckpointId,
        'is_pattern': isPattern ? 1 : 0,
        'problem_statement': problemStatement,
        'why_1': why1,
        'why_2': why2,
        'why_3': why3,
        'why_4': why4,
        'why_5': why5,
        'root_cause': rootCause,
        'responsible_user_id': responsibleUserId,
        'deadline': deadline,
        'verification_method': verificationMethod,
        'status': status,
        'opened_at': openedAt,
        'done_at': doneAt,
        'verified_at': verifiedAt,
        'closed_at': closedAt,
        'verified_by': verifiedBy,
        'closed_by': closedBy,
        'aged_count': agedCount,
        'extension_count': extensionCount,
        'latest_extension_reason': latestExtensionReason,
      };

  final String id;
  final String originAuditId;
  final String? originResultId;
  final String originCheckpointId;
  final bool isPattern;
  final String problemStatement;
  final String why1;
  final String? why2;
  final String? why3;
  final String? why4;
  final String? why5;
  final String rootCause;
  final String responsibleUserId;
  final String deadline; // YYYY-MM-DD
  final String verificationMethod;
  final String status; // 'open' | 'done' | 'verified' | 'closed' | 'aged' | 'reopened'
  final String openedAt; // ISO-8601 UTC
  final String? doneAt;
  final String? verifiedAt;
  final String? closedAt;
  final String? verifiedBy;
  final String? closedBy;
  final int agedCount;
  final int extensionCount;
  final String? latestExtensionReason;

  bool get isOpen => status == 'open' || status == 'reopened';
  bool get isDone => status == 'done';
  bool get isVerified => status == 'verified';
  bool get isClosed => status == 'closed';
  bool get isAged => status == 'aged';

  /// Computes deadline status relative to [now]:
  /// - overdue: deadline is strictly before today
  /// - dueSoon: deadline is today or tomorrow (difference <= 1 day)
  /// - ok: deadline is 2 or more days in future
  CapDeadlineStatus deadlineStatus([DateTime? now]) {
    final diffDays = daysUntilDeadline(now);
    if (diffDays == null) return CapDeadlineStatus.ok;
    if (diffDays < 0) return CapDeadlineStatus.overdue;
    if (diffDays <= 1) return CapDeadlineStatus.dueSoon;
    return CapDeadlineStatus.ok;
  }

  /// Returns the number of days until the deadline relative to [now]:
  /// - Negative value if overdue (e.g. -2 = overdue by 2 days)
  /// - 0 if due today
  /// - Positive value if due in future (e.g. 1 = due tomorrow)
  int? daysUntilDeadline([DateTime? now]) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final parsed = DateTime.tryParse(deadline);
    if (parsed == null) return null;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    return d.difference(today).inDays;
  }

  Cap copyWith({
    String? id,
    String? originAuditId,
    String? originResultId,
    String? originCheckpointId,
    bool? isPattern,
    String? problemStatement,
    String? why1,
    String? why2,
    String? why3,
    String? why4,
    String? why5,
    String? rootCause,
    String? responsibleUserId,
    String? deadline,
    String? verificationMethod,
    String? status,
    String? openedAt,
    String? doneAt,
    String? verifiedAt,
    String? closedAt,
    String? verifiedBy,
    String? closedBy,
    int? agedCount,
    int? extensionCount,
    String? latestExtensionReason,
  }) {
    return Cap(
      id: id ?? this.id,
      originAuditId: originAuditId ?? this.originAuditId,
      originResultId: originResultId ?? this.originResultId,
      originCheckpointId: originCheckpointId ?? this.originCheckpointId,
      isPattern: isPattern ?? this.isPattern,
      problemStatement: problemStatement ?? this.problemStatement,
      why1: why1 ?? this.why1,
      why2: why2 ?? this.why2,
      why3: why3 ?? this.why3,
      why4: why4 ?? this.why4,
      why5: why5 ?? this.why5,
      rootCause: rootCause ?? this.rootCause,
      responsibleUserId: responsibleUserId ?? this.responsibleUserId,
      deadline: deadline ?? this.deadline,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      doneAt: doneAt ?? this.doneAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      closedAt: closedAt ?? this.closedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      closedBy: closedBy ?? this.closedBy,
      agedCount: agedCount ?? this.agedCount,
      extensionCount: extensionCount ?? this.extensionCount,
      latestExtensionReason:
          latestExtensionReason ?? this.latestExtensionReason,
    );
  }
}
