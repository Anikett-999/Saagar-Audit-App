/// Application user (Owner, General Manager, Store Manager).
///
/// Mapped 1:1 from Spec §4.1 `users` table.
class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.pinHash,
    required this.languagePref,
    this.phone,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
    this.createdBy,
  });

  factory User.fromMap(Map<String, Object?> m) => User(
        id: m['id']! as String,
        name: m['name']! as String,
        role: m['role']! as String,
        pinHash: m['pin_hash']! as String,
        languagePref: (m['language_pref'] as String?) ?? 'en',
        phone: m['phone'] as String?,
        isActive: (m['is_active']! as int) == 1,
        createdAt: DateTime.parse(m['created_at']! as String),
        lastLoginAt: m['last_login_at'] != null
            ? DateTime.parse(m['last_login_at']! as String)
            : null,
        createdBy: m['created_by'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'pin_hash': pinHash,
        'language_pref': languagePref,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toUtc().toIso8601String(),
        'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
        'created_by': createdBy,
      };

  final String id;
  final String name;
  final String role; // 'SM' | 'GM' | 'OWNER'
  final String pinHash;
  final String languagePref; // 'en' | 'mr'
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? createdBy;

  bool get isOwner => role == 'OWNER';
  bool get isGm => role == 'GM';
  bool get isSm => role == 'SM';
}
