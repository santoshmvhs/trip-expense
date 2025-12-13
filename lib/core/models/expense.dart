class Expense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String currency;
  final String paidBy;
  final String createdBy;
  final DateTime expenseDate;
  final String? receiptPath;
  final String? notes;
  final String? category;
  final String? subcategory;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime? recurringEndDate;

  Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.createdBy,
    required this.expenseDate,
    this.receiptPath,
    this.notes,
    this.category,
    this.subcategory,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringEndDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        // Handle both 'title' (new schema) and 'description' (old schema)
        title: (json['title'] as String?) ?? (json['description'] as String?) ?? '',
        amount: (json['amount'] as num).toDouble(),
        currency: (json['currency'] as String?) ?? 'INR',
        paidBy: json['paid_by'] as String,
        createdBy: json['created_by'] as String,
        expenseDate: DateTime.parse(json['expense_date'] as String),
        receiptPath: json['receipt_path'] as String?,
        notes: json['notes'] as String?,
        category: json['category'] as String?,
        subcategory: json['subcategory'] as String?,
        isRecurring: json['is_recurring'] as bool? ?? false,
        recurringFrequency: json['recurring_frequency'] as String?,
        recurringEndDate: json['recurring_end_date'] != null
            ? DateTime.parse(json['recurring_end_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'paid_by': paidBy,
        'created_by': createdBy,
        'expense_date': expenseDate.toIso8601String().substring(0, 10),
        'receipt_path': receiptPath,
        'notes': notes,
        'category': category,
        'subcategory': subcategory,
        'is_recurring': isRecurring,
        'recurring_frequency': recurringFrequency,
        'recurring_end_date': recurringEndDate?.toIso8601String().substring(0, 10),
      };
}

