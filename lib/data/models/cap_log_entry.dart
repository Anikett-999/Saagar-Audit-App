/// Event log entry tracking the immutable lifecycle timeline of a CAP.
///
/// Mapped 1:1 from Spec §4.11 `cap_log` table.
class CapLogEntry {
  const CapLogEntry({
    required this.id,
    required this.capId,
    required this.event,
    this.fromStatus,
    this.toStatus,
    this.actorUserId,
    this.deviceId,
    required this.timestamp,
    this.note,
  });

  factory CapLogEntry.fromMap(Map<String, Object?> m) => CapLogEntry(
        id: m['id']! as String,
        capId: m['cap_id']! as String,
        event: m['event']! as String,
        fromStatus: m['from_status'] as String?,
        toStatus: m['to_status'] as String?,
        actorUserId: m['actor_user_id'] as String?,
        deviceId: m['device_id'] as String?,
        timestamp: m['timestamp']! as String,
        note: m['note'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'cap_id': capId,
        'event': event,
        'from_status': fromStatus,
        'to_status': toStatus,
        'actor_user_id': actorUserId,
        'device_id': deviceId,
        'timestamp': timestamp,
        'note': note,
      };

  final String id;
  final String capId;
  final String event; // 'created' | 'action_done' | 'marked_done' | 'verified' | 'closed' | 'extended' | 'aged' | 'reopened'
  final String? fromStatus;
  final String? toStatus;
  final String? actorUserId;
  final String? deviceId;
  final String timestamp; // ISO-8601 UTC
  final String? note;
}
