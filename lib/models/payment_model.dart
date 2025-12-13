class PaymentModel {
  final String id;
  final String groupId;
  final String payerId;
  final String payeeId;
  final double amount;
  final String currency;
  final String? description;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    this.currency = 'USD',
    this.description,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'payee_id': payeeId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

