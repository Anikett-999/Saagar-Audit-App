/// Single action step within a Corrective Action Plan.
///
/// Mapped 1:1 from Spec §4.10 `cap_actions` table.
class CapAction {
  const CapAction({
    required this.id,
    required this.capId,
    required this.sequence,
    required this.actionText,
    this.isDone = false,
    this.doneAt,
    this.doneBy,
    this.doneNotes,
  });

  factory CapAction.fromMap(Map<String, Object?> m) => CapAction(
        id: m['id']! as String,
        capId: m['cap_id']! as String,
        sequence: m['sequence']! as int,
        actionText: m['action_text']! as String,
        isDone: (m['is_done'] as int? ?? 0) == 1,
        doneAt: m['done_at'] as String?,
        doneBy: m['done_by'] as String?,
        doneNotes: m['done_notes'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'cap_id': capId,
        'sequence': sequence,
        'action_text': actionText,
        'is_done': isDone ? 1 : 0,
        'done_at': doneAt,
        'done_by': doneBy,
        'done_notes': doneNotes,
      };

  final String id;
  final String capId;
  final int sequence; // 1..n
  final String actionText;
  final bool isDone;
  final String? doneAt; // ISO-8601 UTC
  final String? doneBy; // user ID
  final String? doneNotes;

  CapAction copyWith({
    String? id,
    String? capId,
    int? sequence,
    String? actionText,
    bool? isDone,
    String? doneAt,
    String? doneBy,
    String? doneNotes,
  }) {
    return CapAction(
      id: id ?? this.id,
      capId: capId ?? this.capId,
      sequence: sequence ?? this.sequence,
      actionText: actionText ?? this.actionText,
      isDone: isDone ?? this.isDone,
      doneAt: doneAt ?? this.doneAt,
      doneBy: doneBy ?? this.doneBy,
      doneNotes: doneNotes ?? this.doneNotes,
    );
  }
}
