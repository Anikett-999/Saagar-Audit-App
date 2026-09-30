/// A single P/F/NA mark on one checkpoint within an audit.
class AuditResult {
  const AuditResult({
    required this.id,
    required this.auditId,
    required this.checkpointId,
    required this.result,
    this.weightedPoints,
    this.findingText,
    this.croId,
    this.flagSecurityConcern = false,
    required this.createdAt,
  });

  factory AuditResult.fromMap(Map<String, Object?> m) => AuditResult(
        id: m['id']! as String,
        auditId: m['audit_id']! as String,
        checkpointId: m['checkpoint_id']! as String,
        result: m['result']! as String,
        weightedPoints: (m['weighted_points'] as num?)?.toDouble(),
        findingText: m['finding_text'] as String?,
        croId: m['cro_id'] as String?,
        flagSecurityConcern: (m['flag_security_concern'] as int? ?? 0) == 1,
        createdAt: m['created_at']! as String,
      );

  final String id;
  final String auditId;
  final String checkpointId;
  final String result; // 'P' | 'F' | 'NA'
  final double? weightedPoints; // null for NA
  final String? findingText;
  final String? croId;
  final bool flagSecurityConcern;
  final String createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'audit_id': auditId,
        'checkpoint_id': checkpointId,
        'result': result,
        'weighted_points': weightedPoints,
        'finding_text': findingText,
        'cro_id': croId,
        'flag_security_concern': flagSecurityConcern ? 1 : 0,
        'created_at': createdAt,
      };

  AuditResult copyWith({
    String? id,
    String? auditId,
    String? checkpointId,
    String? result,
    double? weightedPoints,
    String? findingText,
    String? croId,
    bool? flagSecurityConcern,
    String? createdAt,
  }) =>
      AuditResult(
        id: id ?? this.id,
        auditId: auditId ?? this.auditId,
        checkpointId: checkpointId ?? this.checkpointId,
        result: result ?? this.result,
        weightedPoints: weightedPoints ?? this.weightedPoints,
        findingText: findingText ?? this.findingText,
        croId: croId ?? this.croId,
        flagSecurityConcern: flagSecurityConcern ?? this.flagSecurityConcern,
        createdAt: createdAt ?? this.createdAt,
      );
}
