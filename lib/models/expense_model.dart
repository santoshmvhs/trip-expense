class ExpenseModel {
  final String id;
  final String groupId;
  final String paidBy;
  final double amount;
  final String currency;
  final String description;
  final String? category;
  final String? receiptUrl;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime? recurringEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseSplit> splits;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.amount,
    this.currency = 'USD',
    required this.description,
    this.category,
    this.receiptUrl,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringEndDate,
    required this.createdAt,
    required this.updatedAt,
    this.splits = const [],
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      paidBy: json['paid_by'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String,
      category: json['category'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
      recurringEndDate: json['recurring_end_date'] != null
          ? DateTime.parse(json['recurring_end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      splits: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'paid_by': paidBy,
      'amount': amount,
      'currency': currency,
      'description': description,
      'category': category,
      'receipt_url': receiptUrl,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'recurring_end_date': recurringEndDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final bool isPaid;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.amount,
    this.isPaid = false,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['is_paid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'amount': amount,
      'is_paid': isPaid,
    };
  }
}

