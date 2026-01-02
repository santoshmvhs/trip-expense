import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/expenses_repo.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/providers/expense_with_splits_provider.dart';
import '../../core/providers/activity_providers.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/models/expense.dart';
import '../../core/models/expense_split.dart';
import '../../core/utils/category_icons.dart';
import '../../widgets/momentra_logo_appbar.dart';
import '../../widgets/liquid_glass_card.dart';
import '../../theme/app_theme.dart';
import 'add_expense_page.dart';

final expenseDetailProvider = FutureProvider.family((ref, String expenseId) {
  return ref.watch(expensesRepoProvider).getExpense(expenseId);
});

final expenseSplitsProvider = FutureProvider.family((ref, String expenseId) async {
  final splitsRes = await supabase()
      .from('expense_splits')
      .select()
      .eq('expense_id', expenseId);

  return (splitsRes as List)
      .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ExpenseDetailPage extends ConsumerWidget {
  final String expenseId;

  const ExpenseDetailPage({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExpense = ref.watch(expenseDetailProvider(expenseId));
    final asyncSplits = ref.watch(expenseSplitsProvider(expenseId));
    final asyncMembers = ref.watch(groupMembersProvider('')); // Will get from expense

    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
        actions: [
          asyncExpense.when(
            data: (expense) => PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/shell/group/${expense.groupId}/expense/$expenseId/edit');
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Expense'),
                      content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref.read(expensesRepoProvider).deleteExpense(expenseId);
                      if (context.mounted) {
                        ref.invalidate(groupExpensesProvider(expense.groupId));
                        ref.invalidate(groupExpensesWithSplitsProvider(expense.groupId));
                        ref.invalidate(groupActivitiesProvider(expense.groupId));
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting expense: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: asyncExpense.when(
        data: (expense) {
          final asyncMembers = ref.watch(groupMembersProvider(expense.groupId));
          return asyncSplits.when(
            data: (splits) => asyncMembers.when(
              data: (members) => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Header Card
                    LiquidGlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Category Icon with gradient background
                              if (expense.category != null)
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        MomentraColors.warmOrange.withValues(alpha: 0.3),
                                        MomentraColors.warmOrange.withValues(alpha: 0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: MomentraColors.warmOrange.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    CategoryIcons.getIconForCategory(expense.category!),
                                    color: MomentraColors.warmOrange,
                                    size: 36,
                                  ),
                                ),
                              const SizedBox(width: 20),
                              // Title and Amount
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.title,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 24,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _formatCurrency(expense.amount, expense.currency),
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                            color: MomentraColors.warmOrange,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 32,
                                            letterSpacing: -1,
                                            height: 1.1,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Modern Details Section
                    LiquidGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 20,
                      child: Column(
                        children: [
                          _buildModernDetailRow(
                            context,
                            'Date',
                            DateFormat('MMM d, y').format(expense.expenseDate),
                            icon: Icons.calendar_today_rounded,
                            isFirst: true,
                          ),
                          if (expense.category != null)
                            _buildModernDetailRow(
                              context,
                              'Category',
                              expense.category!,
                              icon: CategoryIcons.getIconForCategory(expense.category!),
                              iconColor: CategoryIcons.getColorForCategory(expense.category!),
                            ),
                          if (expense.subcategory != null)
                            _buildModernDetailRow(
                              context,
                              'Subcategory',
                              expense.subcategory!,
                              icon: CategoryIcons.getIconForSubcategory(expense.subcategory!),
                              iconColor: expense.category != null
                                  ? CategoryIcons.getColorForCategory(expense.category!)
                                  : null,
                            ),
                          Builder(
                            builder: (context) {
                              String paidByName;
                              try {
                                final paidByMember = members.firstWhere(
                                  (m) => m['user_id'] == expense.paidBy,
                                );
                                paidByName = paidByMember['name'] as String;
                              } catch (e) {
                                paidByName = expense.paidBy.substring(0, 8) + '...';
                              }
                              return _buildModernDetailRow(
                                context,
                                'Paid by',
                                paidByName,
                                icon: Icons.person_rounded,
                              );
                            },
                          ),
                          if (expense.notes != null && expense.notes!.isNotEmpty)
                            _buildModernDetailRow(
                              context,
                              'Notes',
                              expense.notes!,
                              icon: Icons.note_rounded,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Modern Splits Section
                    LiquidGlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      MomentraColors.warmOrange.withValues(alpha: 0.2),
                                      MomentraColors.warmOrange.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: MomentraColors.warmOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Split Details',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (splits.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_outline_rounded,
                                      size: 56,
                                      color: MomentraColors.lightGray.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No splits found',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: MomentraColors.lightGray.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...splits.asMap().entries.map((entry) {
                              final index = entry.key;
                              final split = entry.value;
                              String userName = 'Unknown';
                              try {
                                final member = members.firstWhere(
                                  (m) => m['user_id'] == split.userId,
                                );
                                userName = member['name'] as String;
                              } catch (e) {
                                userName = split.userId.substring(0, 8) + '...';
                              }
                              return Container(
                                margin: EdgeInsets.only(bottom: index < splits.length - 1 ? 12 : 0),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      MomentraColors.warmOrange.withValues(alpha: 0.08),
                                      MomentraColors.warmOrange.withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: MomentraColors.warmOrange.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            MomentraColors.warmOrange,
                                            MomentraColors.warmOrange.withValues(alpha: 0.8),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: MomentraColors.warmOrange.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          userName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  letterSpacing: -0.2,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Share',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: MomentraColors.lightGray.withValues(alpha: 0.6),
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(split.share, expense.currency),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: MomentraColors.warmOrange,
                                            fontSize: 18,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Modern Receipt Section
                    if (expense.receiptPath != null)
                      LiquidGlassCard(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 20,
                        onTap: () {
                          // TODO: Open receipt image viewer
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withValues(alpha: 0.2),
                                    Colors.green.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.green,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receipt',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to view',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: MomentraColors.lightGray.withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: MomentraColors.lightGray.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading members')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading splits')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading expense'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: MomentraColors.divider.withValues(alpha: 0.1),
                  width: 1,
                ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isFirst ? 20 : 16,
        bottom: isLast ? 20 : 16,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (iconColor ?? MomentraColors.warmOrange).withValues(alpha: 0.2),
                    (iconColor ?? MomentraColors.warmOrange).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? MomentraColors.warmOrange,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MomentraColors.lightGray.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
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
}

