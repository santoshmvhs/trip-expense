class Settlement {
  final String id;
  final String groupId;
  final String fromUser;
  final String toUser;
  final double amount;
  final String currency;
  final String? method;
  final String? notes;
  final DateTime settledAt;

  Settlement({
    required this.id,
    required this.groupId,
    required this.fromUser,
    required this.toUser,
    required this.amount,
    required this.currency,
    this.method,
    this.notes,
    required this.settledAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        fromUser: json['from_user'] as String,
        toUser: json['to_user'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: (json['currency'] as String?) ?? 'INR',
        method: json['method'] as String?,
        notes: json['notes'] as String?,
        settledAt: DateTime.parse(json['settled_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'from_user': fromUser,
        'to_user': toUser,
        'amount': amount,
        'currency': currency,
        'method': method,
        'notes': notes,
        'settled_at': settledAt.toIso8601String(),
      };
}

