class ExpenseSplit {
  final String expenseId;
  final String userId;
  final double share;

  ExpenseSplit({
    required this.expenseId,
    required this.userId,
    required this.share,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) => ExpenseSplit(
        expenseId: json['expense_id'] as String,
        userId: json['user_id'] as String,
        // Handle both 'share' (new schema) and 'amount' (old schema)
        share: (json['share'] as num?)?.toDouble() ?? 
               (json['amount'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'expense_id': expenseId,
        'user_id': userId,
        'share': share,
      };
}

