class TripBudgetAllocation {
  final String id;
  final String tripBudgetId;
  final String? category;
  final String? subcategory;
  final double amount;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripBudgetAllocation({
    required this.id,
    required this.tripBudgetId,
    this.category,
    this.subcategory,
    required this.amount,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripBudgetAllocation.fromJson(Map<String, dynamic> json) =>
      TripBudgetAllocation(
        id: json['id'] as String,
        tripBudgetId: json['trip_budget_id'] as String,
        category: json['category'] as String?,
        subcategory: json['subcategory'] as String?,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String?,
        sortOrder: (json['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_budget_id': tripBudgetId,
        'category': category,
        'subcategory': subcategory,
        'amount': amount,
        'description': description,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  // Helper to get display name
  String get displayName {
    if (subcategory != null && subcategory!.isNotEmpty) {
      return subcategory!;
    }
    if (category != null && category!.isNotEmpty) {
      return category!;
    }
    return 'Uncategorized';
  }
}

