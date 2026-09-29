/// Escalation model corresponding to SQLite `escalations` table (Spec §7 & §4.13).
class Escalation {
  const Escalation({
    required this.id,
    required this.triggerNumber,
    required this.triggerLabel,
    required this.sourceType,
    this.sourceAuditId,
    this.sourceCapId,
    this.raisedByUserId,
    required this.raisedToUserId,
    required this.urgency,
    required this.whatHappened,
    this.evidence,
    this.impact,
    this.requestedAction,
    this.status = 'open',
    required this.raisedAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.whatsappSent = false,
  });

  factory Escalation.fromMap(Map<String, dynamic> map) {
    return Escalation(
      id: map['id'] as String,
      triggerNumber: (map['trigger_number'] as num).toInt(),
      triggerLabel: map['trigger_label'] as String,
      sourceType: map['source_type'] as String,
      sourceAuditId: map['source_audit_id'] as String?,
      sourceCapId: map['source_cap_id'] as String?,
      raisedByUserId: map['raised_by_user_id'] as String?,
      raisedToUserId: map['raised_to_user_id'] as String,
      urgency: map['urgency'] as String,
      whatHappened: map['what_happened'] as String,
      evidence: map['evidence'] as String?,
      impact: map['impact'] as String?,
      requestedAction: map['requested_action'] as String?,
      status: (map['status'] as String?) ?? 'open',
      raisedAt: map['raised_at'] as String,
      acknowledgedAt: map['acknowledged_at'] as String?,
      resolvedAt: map['resolved_at'] as String?,
      resolutionNotes: map['resolution_notes'] as String?,
      whatsappSent: (map['whatsapp_sent'] as num?) == 1,
    );
  }

  final String id;
  final int triggerNumber;
  final String triggerLabel;
  final String sourceType; // 'audit' | 'cap' | 'trend' | 'manual'
  final String? sourceAuditId;
  final String? sourceCapId;
  final String? raisedByUserId;
  final String raisedToUserId;
  final String urgency; // 'immediate' | 'same_day' | 'same_night' | 'next_audit'
  final String whatHappened;
  final String? evidence;
  final String? impact;
  final String? requestedAction;
  final String status; // 'open' | 'acknowledged' | 'resolved'
  final String raisedAt; // ISO8601 UTC
  final String? acknowledgedAt;
  final String? resolvedAt;
  final String? resolutionNotes;
  final bool whatsappSent;

  bool get isOpen => status == 'open';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isResolved => status == 'resolved';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trigger_number': triggerNumber,
      'trigger_label': triggerLabel,
      'source_type': sourceType,
      'source_audit_id': sourceAuditId,
      'source_cap_id': sourceCapId,
      'raised_by_user_id': raisedByUserId,
      'raised_to_user_id': raisedToUserId,
      'urgency': urgency,
      'what_happened': whatHappened,
      'evidence': evidence,
      'impact': impact,
      'requested_action': requestedAction,
      'status': status,
      'raised_at': raisedAt,
      'acknowledged_at': acknowledgedAt,
      'resolved_at': resolvedAt,
      'resolution_notes': resolutionNotes,
      'whatsapp_sent': whatsappSent ? 1 : 0,
    };
  }

  Escalation copyWith({
    String? id,
    int? triggerNumber,
    String? triggerLabel,
    String? sourceType,
    String? sourceAuditId,
    String? sourceCapId,
    String? raisedByUserId,
    String? raisedToUserId,
    String? urgency,
    String? whatHappened,
    String? evidence,
    String? impact,
    String? requestedAction,
    String? status,
    String? raisedAt,
    String? acknowledgedAt,
    String? resolvedAt,
    String? resolutionNotes,
    bool? whatsappSent,
  }) {
    return Escalation(
      id: id ?? this.id,
      triggerNumber: triggerNumber ?? this.triggerNumber,
      triggerLabel: triggerLabel ?? this.triggerLabel,
      sourceType: sourceType ?? this.sourceType,
      sourceAuditId: sourceAuditId ?? this.sourceAuditId,
      sourceCapId: sourceCapId ?? this.sourceCapId,
      raisedByUserId: raisedByUserId ?? this.raisedByUserId,
      raisedToUserId: raisedToUserId ?? this.raisedToUserId,
      urgency: urgency ?? this.urgency,
      whatHappened: whatHappened ?? this.whatHappened,
      evidence: evidence ?? this.evidence,
      impact: impact ?? this.impact,
      requestedAction: requestedAction ?? this.requestedAction,
      status: status ?? this.status,
      raisedAt: raisedAt ?? this.raisedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      whatsappSent: whatsappSent ?? this.whatsappSent,
    );
  }
}
