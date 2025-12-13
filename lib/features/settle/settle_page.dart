import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/repositories/groups_repo.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/models/expense.dart';
import '../../core/models/expense_split.dart';
import '../../core/models/settlement.dart';
import '../../core/models/group.dart';
import 'settle_math.dart';

final groupsRepoProvider = Provider((_) => GroupsRepo());

final groupProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(groupsRepoProvider).getGroup(groupId);
});

final groupBalancesProvider = FutureProvider.family((ref, String groupId) async {
  final expenses = await ref.watch(groupExpensesProvider(groupId).future);
  final members = await ref.watch(groupMembersProvider(groupId).future);
  
  // Calculate balances
  final balances = <String, double>{}; // userId -> balance (positive = owed, negative = owes)
  
  // Fetch all splits at once to avoid N+1 query issue
  final expenseIds = expenses.map((e) => e.id).toList();
  final allSplitsRes = expenseIds.isNotEmpty
      ? await supabase()
          .from('expense_splits')
          .select()
          .or(expenseIds.map((id) => 'expense_id.eq.$id').join(','))
      : <dynamic>[];
  
  // Group splits by expense_id
  final splitsByExpenseId = <String, List<ExpenseSplit>>{};
  for (final splitJson in (allSplitsRes as List)) {
    final split = ExpenseSplit.fromJson(splitJson as Map<String, dynamic>);
    splitsByExpenseId.putIfAbsent(split.expenseId, () => []).add(split);
  }
  
  // Process expenses with pre-fetched splits
  for (final expense in expenses) {
    final splits = splitsByExpenseId[expense.id] ?? [];
    
    // Paid by gets positive balance
    balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;
    
    // Split among participants
    for (final split in splits) {
      balances[split.userId] = (balances[split.userId] ?? 0) - split.share;
    }
  }
  
  // Get member names
  final memberMap = <String, String>{};
  for (final member in members) {
    memberMap[member['user_id'] as String] = member['name'] as String;
  }
  
  // Convert to list with names
  return balances.entries.map((e) => {
    'userId': e.key,
    'name': memberMap[e.key] ?? 'Unknown',
    'balance': e.value,
  }).toList();
});

class SettlePage extends ConsumerWidget {
  final String groupId;

  const SettlePage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroup = ref.watch(groupProvider(groupId));
    final asyncBalances = ref.watch(groupBalancesProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
      ),
      body: asyncGroup.when(
        data: (group) => asyncBalances.when(
          data: (balances) {
            // Calculate simplified transfers
            final balanceMap = <String, double>{};
            for (final b in balances) {
              balanceMap[b['userId'] as String] = (b['balance'] as num).toDouble();
            }
            
            final transfers = SettleMath.simplify(balanceMap);
            
            if (transfers.isEmpty && balances.every((b) => (b['balance'] as num).abs() < 0.01)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All settled!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No outstanding balances',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Balances
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Balances',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...balances.map((b) {
                            final balance = (b['balance'] as num).toDouble();
                            final name = b['name'] as String;
                            final isOwed = balance > 0.01;
                            final isOwes = balance < -0.01;
                            
                            if (!isOwed && !isOwes) return const SizedBox();
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOwed
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                child: Icon(
                                  isOwed ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isOwed ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                              title: Text(name),
                              trailing: Text(
                                isOwed
                                    ? 'Gets back ${_formatCurrency(balance.abs(), group.currency)}'
                                    : 'Owes ${_formatCurrency(balance.abs(), group.currency)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOwed ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Simplified Transfers
                  if (transfers.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simplified Transfers',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To settle all balances, make these transfers:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ...transfers.map((transfer) {
                              final fromName = balances.firstWhere(
                                (b) => b['userId'] == transfer.fromUserId,
                                orElse: () => {'name': 'Unknown'},
                              )['name'] as String;
                              final toName = balances.firstWhere(
                                (b) => b['userId'] == transfer.toUserId,
                                orElse: () => {'name': 'Unknown'},
                              )['name'] as String;
                              
                              return Card(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: ListTile(
                                  leading: const Icon(Icons.swap_horiz),
                                  title: Text('$fromName → $toName'),
                                  trailing: Text(
                                    _formatCurrency(transfer.amount, group.currency),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Record Payment Button
                  FilledButton.icon(
                    onPressed: () => _showRecordPaymentDialog(context, ref, group, balances),
                    icon: const Icon(Icons.payment),
                    label: const Text('Record Payment'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading group')),
      ),
    );
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

  void _showRecordPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    Group group,
    List<Map<String, dynamic>> balances,
  ) {
    // TODO: Implement payment recording
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: const Text('Payment recording feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

