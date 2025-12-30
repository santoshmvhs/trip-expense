class Moment {
  final String id;
  final String? groupId; // NULLABLE: moments can be standalone or group-linked
  final String type;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? startDate;
  final DateTime endDate;
  final String lifecycleState;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool funded;
  final bool overdue;
  
  Moment({
    required this.id,
    this.groupId,
    required this.type,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.startDate,
    required this.endDate,
    required this.lifecycleState,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.funded,
    required this.overdue,
  });
  
  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] as String,
      groupId: json['group_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: DateTime.parse(json['end_date'] as String),
      lifecycleState: json['lifecycle_state'] as String? ?? 'ACTIVE',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      funded: json['funded'] as bool? ?? false,
      overdue: json['overdue'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'type': type,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'end_date': endDate.toIso8601String(),
    };
  }
  
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }
}

