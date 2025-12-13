class GroupInvitation {
  final String id;
  final String groupId;
  final String email;
  final String invitedBy;
  final String status; // 'pending', 'accepted', 'declined'
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;

  GroupInvitation({
    required this.id,
    required this.groupId,
    required this.email,
    required this.invitedBy,
    required this.status,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      email: json['email'] as String,
      invitedBy: json['invited_by'] as String,
      status: json['status'] as String,
      token: json['token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'email': email,
      'invited_by': invitedBy,
      'status': status,
      'token': token,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

