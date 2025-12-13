import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/balance_model.dart';
import '../../models/group_model.dart';
import '../expense/add_expense_screen.dart';
import '../expense/settle_up_dialog.dart';
import '../analytics/analytics_screen.dart';
import 'group_settings_screen.dart';
import 'invite_member_dialog.dart';
import 'qr_invite_screen.dart';
import 'scan_qr_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GroupProvider>(
          builder: (context, groupProvider, _) {
            final group = groupProvider.groups
                .firstWhere((g) => g.id == widget.groupId);
            return Text(group.name);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsScreen(groupId: widget.groupId),
                ),
              );
            },
            tooltip: 'Analytics',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite Member',
            onSelected: (value) {
              if (value == 'email') {
                showDialog(
                  context: context,
                  builder: (context) => InviteMemberDialog(groupId: widget.groupId),
                );
              } else if (value == 'qr') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrInviteScreen(groupId: widget.groupId),
                  ),
                );
              } else if (value == 'scan') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanQrScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'email',
                child: Row(
                  children: [
                    Icon(Icons.email),
                    SizedBox(width: 12),
                    Text('Invite by Email'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code),
                    SizedBox(width: 12),
                    Text('Show QR Code'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner),
                    SizedBox(width: 12),
                    Text('Scan QR Code'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupSettingsScreen(groupId: widget.groupId),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, GroupProvider>(
        builder: (context, expenseProvider, groupProvider, _) {
          final group = groupProvider.groups
              .firstWhere(
                (g) => g.id == widget.groupId,
                orElse: () => GroupModel(
                  id: widget.groupId,
                  name: 'Loading...',
                  createdBy: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
          final expenses = expenseProvider.getExpensesForGroup(widget.groupId);
          final balances = expenseProvider.getBalancesForGroup(widget.groupId);

          return Column(
            children: [
              // Balances Summary Card
              if (balances.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balances',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...balances.map((balance) {
                        if (balance.absoluteBalance < 0.01) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  balance.userName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                balance.isOwed
                                    ? 'Gets back ${_formatCurrency(balance.absoluteBalance, group.currency)}'
                                    : 'Owes ${_formatCurrency(balance.absoluteBalance, group.currency)}',
                                style: TextStyle(
                                  color: balance.isOwed ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (balances.any((b) => b.absoluteBalance > 0.01))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => SettleUpDialog(
                                    groupId: widget.groupId,
                                    balances: balances,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.payment),
                              label: const Text('Settle Up'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Expenses List
              Expanded(
                child: expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add an expense to get started',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            expenseProvider.loadExpenses(widget.groupId),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    expense.description[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  expense.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Paid by ${_getUserName(expense.paidBy, groupProvider)}',
                                    ),
                                    Text(
                                      DateFormat('MMM d, y').format(expense.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  _formatCurrency(expense.amount, expense.currency),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/expense/add/${widget.groupId}');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
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

  String _getUserName(String userId, GroupProvider groupProvider) {
    final members = groupProvider.getGroupMembers(widget.groupId);
    final user = members.firstWhere(
      (m) => m.id == userId,
      orElse: () => members.first,
    );
    return user.fullName ?? user.email;
  }
}

