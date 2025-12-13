import 'dart:math';

class Transfer {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const Transfer(this.fromUserId, this.toUserId, this.amount);
}

class SettleMath {
  /// balances: userId -> net balance
  /// positive = is owed, negative = owes
  static List<Transfer> simplify(Map<String, double> balances, {double eps = 0.01}) {
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final e in balances.entries) {
      final v = e.value;
      if (v > eps) creditors.add(MapEntry(e.key, v));
      else if (v < -eps) debtors.add(MapEntry(e.key, v));
    }

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => a.value.compareTo(b.value)); // most negative first

    int i = 0, j = 0;
    final transfers = <Transfer>[];

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];

      final owed = -debtor.value;
      final claim = creditor.value;
      final amt = min(owed, claim);

      if (amt > eps) {
        transfers.add(Transfer(debtor.key, creditor.key, _round2(amt)));
      }

      final newDebtor = debtor.value + amt;   // less negative
      final newCred = creditor.value - amt;  // less positive

      debtors[i] = MapEntry(debtor.key, newDebtor);
      creditors[j] = MapEntry(creditor.key, newCred);

      if (debtors[i].value > -eps) i++;
      if (creditors[j].value < eps) j++;
    }

    return transfers;
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100.0;
}

