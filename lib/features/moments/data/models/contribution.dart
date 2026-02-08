class Contribution {
  final String id;
  final String momentId;
  final String participantId;
  final double amount;
  final String? note;
  final DateTime createdAt;
  
  Contribution({
    required this.id,
    required this.momentId,
    required this.participantId,
    required this.amount,
    this.note,
    required this.createdAt,
  });
  
  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['_id'] ?? json['id'],
      momentId: json['momentId'],
      participantId: json['participantId'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'note': note,
    };
  }
}

