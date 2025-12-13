class TripBudget {
  final String id;
  final String groupId;
  final String createdBy;
  final double totalAmount;
  final String currency;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripBudget({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.totalAmount,
    required this.currency,
    this.description,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripBudget.fromJson(Map<String, dynamic> json) => TripBudget(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        createdBy: json['created_by'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'INR',
        description: json['description'] as String?,
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : null,
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'created_by': createdBy,
        'total_amount': totalAmount,
        'currency': currency,
        'description': description,
        'start_date': startDate?.toIso8601String().substring(0, 10),
        'end_date': endDate?.toIso8601String().substring(0, 10),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

