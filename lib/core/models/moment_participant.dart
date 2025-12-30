class MomentParticipant {
  final String id;
  final String momentId;
  final String? userId;
  final String email;
  final String? displayName;
  final String role;
  final DateTime joinedAt;
  
  MomentParticipant({
    required this.id,
    required this.momentId,
    this.userId,
    required this.email,
    this.displayName,
    required this.role,
    required this.joinedAt,
  });
  
  factory MomentParticipant.fromJson(Map<String, dynamic> json) {
    return MomentParticipant(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String?,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] as String? ?? 'contributor',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
  
  String get displayNameOrEmail => displayName ?? email;
}

