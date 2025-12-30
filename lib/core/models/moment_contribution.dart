class MomentContribution {
  final String id;
  final String momentId;
  final String participantId;
  final double amount;
  final String? note;
  final String? expenseId; // NULLABLE: link to expense if applicable
  final DateTime createdAt;
  
  MomentContribution({
    required this.id,
    required this.momentId,
    required this.participantId,
    required this.amount,
    this.note,
    this.expenseId,
    required this.createdAt,
  });
  
  factory MomentContribution.fromJson(Map<String, dynamic> json) {
    return MomentContribution(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      participantId: json['participant_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      expenseId: json['expense_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'moment_id': momentId,
      'participant_id': participantId,
      'amount': amount,
      'note': note,
      'expense_id': expenseId,
    };
  }
}

