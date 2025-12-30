class MomentTemplate {
  final String id;
  final String name;
  final String type;
  final String? description;
  final double? defaultTargetAmount;
  final int? defaultDurationDays;
  final Map<String, dynamic>? metadata;
  
  MomentTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.defaultTargetAmount,
    this.defaultDurationDays,
    this.metadata,
  });
  
  factory MomentTemplate.fromJson(Map<String, dynamic> json) {
    return MomentTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      defaultTargetAmount: json['default_target_amount'] != null 
          ? (json['default_target_amount'] as num).toDouble()
          : null,
      defaultDurationDays: json['default_duration_days'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'default_target_amount': defaultTargetAmount,
      'default_duration_days': defaultDurationDays,
      'metadata': metadata,
    };
  }
}

// Predefined templates
class MomentTemplates {
  static List<MomentTemplate> getDefaultTemplates() {
    return [
      MomentTemplate(
        id: 'template_trip_weekend',
        name: 'Weekend Trip',
        type: 'trip',
        description: 'A short weekend getaway with friends',
        defaultTargetAmount: 10000,
        defaultDurationDays: 30,
        metadata: {'category': 'travel'},
      ),
      MomentTemplate(
        id: 'template_trip_international',
        name: 'International Trip',
        type: 'trip',
        description: 'Save for an international vacation',
        defaultTargetAmount: 100000,
        defaultDurationDays: 180,
        metadata: {'category': 'travel'},
      ),
      MomentTemplate(
        id: 'template_gift_birthday',
        name: 'Birthday Gift',
        type: 'gift',
        description: 'Collect money for a birthday gift',
        defaultTargetAmount: 5000,
        defaultDurationDays: 14,
        metadata: {'category': 'celebration'},
      ),
      MomentTemplate(
        id: 'template_gift_wedding',
        name: 'Wedding Gift',
        type: 'gift',
        description: 'Group gift for a wedding',
        defaultTargetAmount: 25000,
        defaultDurationDays: 30,
        metadata: {'category': 'celebration'},
      ),
      MomentTemplate(
        id: 'template_goal_emergency',
        name: 'Emergency Fund',
        type: 'goal',
        description: 'Build an emergency fund',
        defaultTargetAmount: 50000,
        defaultDurationDays: 365,
        metadata: {'category': 'savings'},
      ),
      MomentTemplate(
        id: 'template_goal_purchase',
        name: 'Big Purchase',
        type: 'goal',
        description: 'Save for a specific purchase',
        defaultTargetAmount: 50000,
        defaultDurationDays: 180,
        metadata: {'category': 'savings'},
      ),
    ];
  }
}

