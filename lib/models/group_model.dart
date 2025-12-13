class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String currency;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? memberIds;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.currency = 'USD',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberIds,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currency': currency,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

