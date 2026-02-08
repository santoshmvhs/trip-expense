class Participant {
  final String id;
  final String momentId;
  final String? userId;
  final String email;
  final String? displayName;
  final String role;
  final DateTime joinedAt;
  
  Participant({
    required this.id,
    required this.momentId,
    this.userId,
    required this.email,
    this.displayName,
    required this.role,
    required this.joinedAt,
  });
  
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['_id'] ?? json['id'],
      momentId: json['momentId'],
      userId: json['userId'],
      email: json['email'],
      displayName: json['displayName'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
  
  String get displayNameOrEmail => displayName ?? email;
}

