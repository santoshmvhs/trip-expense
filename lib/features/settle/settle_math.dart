import 'dart:math';

class Transfer {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const Transfer(this.fromUserId, this.toUserId, this.amount);
}

class SettleMath {
  /// balances: userId -> net balance
  /// positive = is owed (should receive), negative = owes (should pay)
  /// 
  /// This implements the SettleUp algorithm:
  /// 1. Separate people into debtors (negative balance) and creditors (positive balance)
  /// 2. Sort debtors by amount owed (most negative first)
  /// 3. Sort creditors by amount owed (most positive first)
  /// 4. Greedily match largest debtor with largest creditor
  /// 5. Create transfer for minimum of the two amounts
  /// 6. Update balances and continue until all settled
  static List<Transfer> simplify(Map<String, double> balances, {double eps = 0.01}) {
    // Filter out zero balances and create separate lists
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    for (final entry in balances.entries) {
      final balance = entry.value;
      if (balance > eps) {
        creditors[entry.key] = balance;
      } else if (balance < -eps) {
        debtors[entry.key] = balance;
      }
    }

    // Convert to sorted lists (largest first for creditors, most negative first for debtors)
    final creditorList = creditors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtorList = debtors.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final transfers = <Transfer>[];
    int debtorIndex = 0;
    int creditorIndex = 0;

    // Greedy matching: always match largest debtor with largest creditor
    while (debtorIndex < debtorList.length && creditorIndex < creditorList.length) {
      final debtor = debtorList[debtorIndex];
      final creditor = creditorList[creditorIndex];

      // Amount debtor owes (positive)
      final debtAmount = -debtor.value;
      // Amount creditor is owed (positive)
      final creditAmount = creditor.value;

      // Transfer the minimum of what's owed and what's claimed
      final transferAmount = min(debtAmount, creditAmount);

      if (transferAmount > eps) {
        transfers.add(Transfer(
          debtor.key,
          creditor.key,
          _round2(transferAmount),
        ));
      }

      // Update balances
      final newDebtBalance = debtor.value + transferAmount;
      final newCreditBalance = creditor.value - transferAmount;

      debtorList[debtorIndex] = MapEntry(debtor.key, newDebtBalance);
      creditorList[creditorIndex] = MapEntry(creditor.key, newCreditBalance);

      // Move to next debtor if this one is settled (balance >= -eps)
      if (newDebtBalance.abs() < eps) {
        debtorIndex++;
      }
      // Move to next creditor if this one is settled (balance <= eps)
      if (newCreditBalance.abs() < eps) {
        creditorIndex++;
      }
    }

    return transfers;
  }

  /// Round to 2 decimal places to avoid floating point precision issues
  static double _round2(double v) {
    return (v * 100).roundToDouble() / 100.0;
  }
}
