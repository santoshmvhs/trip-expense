class Moment {
  final String id;
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
  final List<String> participants;
  
  Moment({
    required this.id,
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
    required this.participants,
  });
  
  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['_id'] ?? json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      targetAmount: (json['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0.0).toDouble(),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: DateTime.parse(json['endDate']),
      lifecycleState: json['lifecycleState'] ?? 'ACTIVE',
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      funded: json['funded'] ?? false,
      overdue: json['overdue'] ?? false,
      participants: List<String>.from(json['participants'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'endDate': endDate.toIso8601String(),
    };
  }
  
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }
}

