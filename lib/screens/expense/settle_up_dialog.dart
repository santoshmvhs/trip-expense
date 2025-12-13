import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/balance_model.dart';

class SettleUpDialog extends StatefulWidget {
  final String groupId;
  final List<BalanceModel> balances;

  const SettleUpDialog({
    super.key,
    required this.groupId,
    required this.balances,
  });

  @override
  State<SettleUpDialog> createState() => _SettleUpDialogState();
}

class _SettleUpDialogState extends State<SettleUpDialog> {
  bool _isLoading = false;

  List<Map<String, dynamic>> _calculateSettlements() {
    // Simplified settlement algorithm
    // In a real app, you'd want a more sophisticated algorithm
    final settlements = <Map<String, dynamic>>[];
    final balances = List<BalanceModel>.from(widget.balances);

    // Separate those who owe and those who are owed
    final debtors = balances.where((b) => b.owes).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final creditors = balances.where((b) => b.isOwed).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance));

    int debtorIndex = 0;
    int creditorIndex = 0;

    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];

      final debt = debtor.balance;
      final credit = creditor.balance.abs();

      final settlementAmount = debt < credit ? debt : credit;

      settlements.add({
        'payerId': debtor.userId,
        'payerName': debtor.userName,
        'payeeId': creditor.userId,
        'payeeName': creditor.userName,
        'amount': settlementAmount,
      });

      if (debt < credit) {
        debtorIndex++;
        creditors[creditorIndex] = BalanceModel(
          userId: creditor.userId,
          userName: creditor.userName,
          balance: creditor.balance + settlementAmount,
        );
      } else if (debt > credit) {
        creditorIndex++;
        debtors[debtorIndex] = BalanceModel(
          userId: debtor.userId,
          userName: debtor.userName,
          balance: debtor.balance - settlementAmount,
        );
      } else {
        debtorIndex++;
        creditorIndex++;
      }
    }

    return settlements;
  }

  Future<void> _recordPayment({
    required String payerId,
    required String payeeId,
    required double amount,
  }) async {
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final groupProvider = context.read<GroupProvider>();
      final group = groupProvider.groups.firstWhere((g) => g.id == widget.groupId);

      await expenseProvider.recordPayment(
        groupId: widget.groupId,
        payerId: payerId,
        payeeId: payeeId,
        amount: amount,
        currency: group.currency,
      );
    } catch (e) {
      rethrow;
    }
  }

  String _formatCurrency(double amount, String currency) {
    return NumberFormat.currency(symbol: _getCurrencySymbol(currency))
        .format(amount);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.read<GroupProvider>();
    final group = groupProvider.groups.firstWhere((g) => g.id == widget.groupId);
    final settlements = _calculateSettlements();

    return AlertDialog(
      title: const Text('Settle Up'),
      content: SizedBox(
        width: double.maxFinite,
        child: settlements.isEmpty
            ? const Text('All balances are settled!')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: settlements.length,
                itemBuilder: (context, index) {
                  final settlement = settlements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.payment, color: Colors.green),
                      title: Text(
                        '${settlement['payerName']} pays ${settlement['payeeName']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _formatCurrency(
                          settlement['amount'] as double,
                          group.currency,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (settlements.isNotEmpty)
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      for (var settlement in settlements) {
                        await _recordPayment(
                          payerId: settlement['payerId'] as String,
                          payeeId: settlement['payeeId'] as String,
                          amount: settlement['amount'] as double,
                        );
                      }

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payments recorded successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Record Payments'),
          ),
      ],
    );
  }
}

