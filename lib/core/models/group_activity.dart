class GroupActivity {
  final String id;
  final String groupId;
  final String userId;
  final String activityType;
  final String entityType;
  final String? entityId;
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  GroupActivity({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.activityType,
    required this.entityType,
    this.entityId,
    required this.title,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory GroupActivity.fromJson(Map<String, dynamic> json) {
    // Handle both old schema (description, related_id) and new schema (entity_type, entity_id, title)
    final activityType = json['activity_type'] as String;
    String entityType = 'expense';
    if (activityType.startsWith('member_')) {
      entityType = 'member';
    } else if (activityType.startsWith('payment_') || activityType == 'settlement_recorded') {
      entityType = 'payment';
    }
    
    final description = json['description'] as String? ?? '';
    final title = json['title'] as String? ?? (description.length > 50 ? '${description.substring(0, 50)}...' : description);
    final entityId = json['entity_id'] as String? ?? json['related_id'] as String?;
    
    return GroupActivity(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      activityType: activityType,
      entityType: json['entity_type'] as String? ?? entityType,
      entityId: entityId,
      title: title,
      description: description,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'user_id': userId,
        'activity_type': activityType,
        'entity_type': entityType,
        'entity_id': entityId,
        'title': title,
        'description': description,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  // Helper getters
  String get icon {
    switch (activityType) {
      case 'expense_added':
        return '💰';
      case 'expense_updated':
        return '✏️';
      case 'expense_deleted':
        return '🗑️';
      case 'member_added':
        return '👤';
      case 'member_removed':
        return '👋';
      case 'payment_added':
        return '💳';
      case 'settlement_recorded':
        return '✅';
      default:
        return '📝';
    }
  }

  bool get isExpenseActivity =>
      activityType.startsWith('expense_') || entityType == 'expense';
  bool get isMemberActivity =>
      activityType.startsWith('member_') || entityType == 'member';
  bool get isPaymentActivity =>
      activityType.startsWith('payment_') ||
      activityType == 'settlement_recorded' ||
      entityType == 'payment' ||
      entityType == 'settlement';
}

