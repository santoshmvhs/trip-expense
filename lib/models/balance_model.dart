class BalanceModel {
  final String userId;
  final String userName;
  final double balance; // Positive = owes, Negative = is owed

  BalanceModel({
    required this.userId,
    required this.userName,
    required this.balance,
  });

  bool get isOwed => balance < 0;
  bool get owes => balance > 0;
  double get absoluteBalance => balance.abs();
}

