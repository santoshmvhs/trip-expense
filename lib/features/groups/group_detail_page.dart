import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;

import '../../core/repositories/groups_repo.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/services/export_service.dart';
import '../../core/models/group.dart';
import '../../core/models/expense.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/providers/activity_providers.dart';
import '../../core/models/group_activity.dart';
import '../../core/utils/category_icons.dart';
import 'invite_member_dialog.dart';
import 'groups_page.dart'; // Import to access groupsProvider
import '../budgets/budgets_tab.dart';

final groupsRepoProvider = Provider((_) => GroupsRepo());

final groupProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(groupsRepoProvider).getGroup(groupId);
});

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _touchedCategoryIndex;
  int? _touchedSubcategoryIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncGroup = ref.watch(groupProvider(widget.groupId));
    final asyncExpenses = ref.watch(groupExpensesProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: asyncGroup.when(
          data: (group) => Text(group.name),
          loading: () => const Text('Group'),
          error: (_, __) => const Text('Group'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Analysis'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Budgets'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
        ),
        actions: [
          // Export menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final group = await ref.read(groupProvider(widget.groupId).future);
              final expenses = await ref.read(groupExpensesProvider(widget.groupId).future);
              
              try {
                if (value == 'pdf') {
                  await ExportService.exportToPdf(group: group, expenses: expenses);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF exported successfully!')),
                    );
                  }
                } else if (value == 'csv') {
                  // Get member names for export
                  final members = await ref.read(groupMembersProvider(widget.groupId).future);
                  final memberNamesMap = <String, String>{};
                  for (final member in members) {
                    memberNamesMap[member['user_id'] as String] = member['name'] as String;
                  }
                  
                  await ExportService.exportToCsv(
                    group: group,
                    expenses: expenses,
                    memberNamesMap: memberNamesMap,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV exported successfully!')),
                    );
                  }
                } else if (value == 'qr') {
                  context.push('/shell/group/${widget.groupId}/qr-invite');
                } else if (value == 'settle') {
                  context.push('/shell/group/${widget.groupId}/settle');
                } else if (value == 'edit') {
                  _showEditGroupDialog(context, ref, group);
                } else if (value == 'delete') {
                  _confirmDeleteGroup(context, ref, widget.groupId);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            itemBuilder: (context) {
              return asyncGroup.when(
                data: (group) {
                  final currentUserId = currentUser()?.id;
                  final isCreator = group.createdBy == currentUserId;
                  
                  return [
                    const PopupMenuItem(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code),
                          SizedBox(width: 8),
                          Text('QR Invite'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settle',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance),
                          SizedBox(width: 8),
                          Text('Settle Up'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf),
                          SizedBox(width: 8),
                          Text('Export PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart),
                          SizedBox(width: 8),
                          Text('Export CSV'),
                        ],
                      ),
                    ),
                    if (isCreator) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Group'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Group', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ];
                },
                loading: () => [
                  const PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 8),
                        Text('QR Invite'),
                      ],
                    ),
                  ),
                ],
                error: (_, __) => [
                  const PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 8),
                        Text('QR Invite'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              debugPrint('👆 Invite button clicked in GroupDetailPage');
              debugPrint('📋 Opening dialog for group: ${widget.groupId}');
              showDialog(
                context: context,
                builder: (context) {
                  debugPrint('🔨 Building InviteMemberDialog');
                  return InviteMemberDialog(groupId: widget.groupId);
                },
              ).then((value) {
                debugPrint('🔚 Dialog closed with value: $value');
              });
            },
            tooltip: 'Invite Member',
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: 'add_expense_fab_${widget.groupId}', // Unique hero tag per group
              onPressed: () {
                context.push('/shell/group/${widget.groupId}/add-expense');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Expenses Tab
          _buildExpensesTab(context, ref, asyncExpenses, asyncGroup),
          // Analysis Tab
          _buildAnalysisTab(context, ref, asyncExpenses, asyncGroup),
          // Budgets Tab
          asyncGroup.when(
            data: (group) => BudgetsTab(
              groupId: widget.groupId,
              groupCurrency: group.currency,
              groupCreatedBy: group.createdBy,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading group')),
          ),
          // Timeline Tab
          _buildTimelineTab(context, ref),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(BuildContext context, WidgetRef ref, AsyncValue<List<Expense>> asyncExpenses, AsyncValue<Group> asyncGroup) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: asyncExpenses.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to add your first expense',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            // Calculate statistics
            final totalSpent = items.fold(0.0, (sum, e) => sum + e.amount);
            final avgExpense = items.isNotEmpty ? totalSpent / items.length : 0.0;
            final categoryTotals = <String, double>{};
            for (var expense in items) {
              final category = expense.category ?? 'Uncategorized';
              categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(groupExpensesProvider(widget.groupId));
                ref.invalidate(groupProvider(widget.groupId));
              },
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to add your first expense',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final e = items[i];
                        return _buildExpenseCard(context, ref, e, widget.groupId);
                      },
                    ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stackTrace) {
            debugPrint('Error loading expenses: $e');
            debugPrint('Stack trace: $stackTrace');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(groupExpensesProvider(widget.groupId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }

  Widget _buildAnalysisTab(BuildContext context, WidgetRef ref, AsyncValue<List<Expense>> asyncExpenses, AsyncValue<Group> asyncGroup) {
    return asyncExpenses.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add expenses to see analysis',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        // Calculate detailed statistics
        final totalSpent = items.fold(0.0, (sum, e) => sum + e.amount);
        final avgExpense = items.isNotEmpty ? totalSpent / items.length : 0.0;
        final categoryTotals = <String, double>{};
        final subcategoryTotals = <String, double>{};
        final monthlyTotals = <String, double>{};
        final memberTotals = <String, double>{};
        final dailyTotals = <String, double>{};
        
        for (var expense in items) {
          // Category totals
          final category = expense.category ?? 'Uncategorized';
          categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
          
          // Subcategory totals
          if (expense.subcategory != null && expense.subcategory!.isNotEmpty) {
            final subcategoryKey = '$category - ${expense.subcategory}';
            subcategoryTotals[subcategoryKey] = (subcategoryTotals[subcategoryKey] ?? 0) + expense.amount;
          }
          
          // Monthly totals
          final month = DateFormat('MMM y').format(expense.expenseDate);
          monthlyTotals[month] = (monthlyTotals[month] ?? 0) + expense.amount;
          
          // Daily totals (for cash flow chart)
          final day = DateFormat('MMM d').format(expense.expenseDate);
          dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
          
          // Member totals (who paid)
          memberTotals[expense.paidBy] = (memberTotals[expense.paidBy] ?? 0) + expense.amount;
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupExpensesProvider(widget.groupId));
            ref.invalidate(groupProvider(widget.groupId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: asyncGroup.when(
              data: (group) => _buildDetailedAnalysisSection(
                context,
                ref,
                group,
                items,
                totalSpent,
                items.length,
                avgExpense,
                categoryTotals,
                subcategoryTotals,
                monthlyTotals,
                memberTotals,
                dailyTotals,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading group')),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading expenses'),
            const SizedBox(height: 8),
            Text(e.toString(), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab(BuildContext context, WidgetRef ref) {
    final asyncActivities = ref.watch(groupActivitiesProvider(widget.groupId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupActivitiesProvider(widget.groupId));
      },
      child: asyncActivities.when(
        data: (activities) {
          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activities will appear here as members make changes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group activities by date
          final groupedActivities = <String, List<GroupActivity>>{};
          for (var activity in activities) {
            final dateKey = DateFormat('yyyy-MM-dd').format(activity.createdAt);
            groupedActivities.putIfAbsent(dateKey, () => []).add(activity);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedActivities.keys.length,
            itemBuilder: (context, index) {
              final dateKey = groupedActivities.keys.elementAt(index);
              final dateActivities = groupedActivities[dateKey]!;
              final date = DateTime.parse(dateKey);
              final isToday = dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());
              final isYesterday = dateKey ==
                  DateFormat('yyyy-MM-dd')
                      .format(DateTime.now().subtract(const Duration(days: 1)));

              String dateLabel;
              if (isToday) {
                dateLabel = 'Today';
              } else if (isYesterday) {
                dateLabel = 'Yesterday';
              } else {
                dateLabel = DateFormat('MMM d, y').format(date);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ...dateActivities.map((activity) => _buildActivityItem(
                        context,
                        ref,
                        activity,
                        isFirst: dateActivities.indexOf(activity) == 0,
                        isLast: dateActivities.indexOf(activity) == dateActivities.length - 1,
                      )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading timeline'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    WidgetRef ref,
    GroupActivity activity, {
    required bool isFirst,
    required bool isLast,
  }) {
    final asyncMembers = ref.watch(groupMembersProvider(activity.groupId));
    String userName = activity.userId.substring(0, 8) + '...';
    
    return asyncMembers.when(
      data: (members) {
        try {
          final member = members.firstWhere(
            (m) => m['user_id'] == activity.userId,
            orElse: () => <String, dynamic>{'name': userName},
          );
          userName = member['name'] as String;
        } catch (e) {
          // Use default userName
        }

        return Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Activity content
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(activity.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activity.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(activity.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        if (activity.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            activity.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                userName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        // Action buttons for expense activities
                        if (activity.isExpenseActivity && activity.entityId != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              context.push(
                                  '/shell/group/${activity.groupId}/expense/${activity.entityId}');
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Expense'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildDetailedAnalysisSection(
    BuildContext context,
    WidgetRef ref,
    Group group,
    List<Expense> expenses,
    double totalSpent,
    int expenseCount,
    double avgExpense,
    Map<String, double> categoryTotals,
    Map<String, double> subcategoryTotals,
    Map<String, double> monthlyTotals,
    Map<String, double> memberTotals,
    Map<String, double> dailyTotals,
  ) {
    // Get member names
    final asyncMembers = ref.watch(groupMembersProvider(widget.groupId));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Spent',
                value: _formatCurrency(totalSpent, group.currency),
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Expenses',
                value: '$expenseCount',
                icon: Icons.receipt_long,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Average',
                value: _formatCurrency(avgExpense, group.currency),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Categories',
                value: '${categoryTotals.length}',
                icon: Icons.category,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Category Pie Chart
        if (categoryTotals.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses by Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        // Donut chart on the left with center text
                        Expanded(
                          flex: 2,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    enabled: true,
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedCategoryIndex = null;
                                          return;
                                        }
                                        final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                        if (index >= 0 && index < categoryTotals.length) {
                                          _touchedCategoryIndex = index;
                                        } else {
                                          _touchedCategoryIndex = null;
                                        }
                                      });
                                    },
                                  ),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50, // Prominent center hole
                                  sections: categoryTotals.entries.toList().asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final categoryEntry = entry.value;
                                    final percentage = totalSpent > 0 ? (categoryEntry.value / totalSpent) * 100 : 0.0;
                                    final isTouched = index == _touchedCategoryIndex;
                                    final baseRadius = 70.0;
                                    final radius = isTouched ? baseRadius + 8.0 : baseRadius;
                                    final categoryColor = _getColorForCategory(categoryEntry.key);
                                    
                                    return PieChartSectionData(
                                      value: categoryEntry.value,
                                      title: percentage > 3 ? '${percentage.toStringAsFixed(0)}%' : '',
                                      color: categoryColor,
                                      radius: radius,
                                      titleStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.5),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Center widget with animation
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _touchedCategoryIndex != null &&
                                            _touchedCategoryIndex! >= 0 &&
                                            _touchedCategoryIndex! < categoryTotals.length
                                        ? Column(
                                            key: ValueKey('category_${_touchedCategoryIndex}'),
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CategoryIcons.getIconForCategory(
                                                  categoryTotals.entries.toList()[_touchedCategoryIndex!].key,
                                                ),
                                                size: 24,
                                                color: _getColorForCategory(
                                                  categoryTotals.entries.toList()[_touchedCategoryIndex!].key,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                child: Text(
                                                  categoryTotals.entries.toList()[_touchedCategoryIndex!].key,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: _getColorForCategory(
                                                          categoryTotals.entries.toList()[_touchedCategoryIndex!].key,
                                                        ),
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatCurrency(
                                                  categoryTotals.entries.toList()[_touchedCategoryIndex!].value,
                                                  group.currency,
                                                ),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '${((categoryTotals.entries.toList()[_touchedCategoryIndex!].value / totalSpent) * 100).toStringAsFixed(1)}%',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          )
                                        : Column(
                                            key: const ValueKey('total'),
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.pie_chart_outline,
                                                size: 24,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Total',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatCurrency(totalSpent, group.currency),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '${categoryTotals.length} categories',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Legend on the right
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (categoryTotals.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value)))
                              .map((entry) {
                                final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
                                final categoryColor = _getColorForCategory(entry.key);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: categoryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Subcategory Pie Chart
        if (subcategoryTotals.isNotEmpty && subcategoryTotals.length > 1) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses by Subcategory',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        // Donut chart on the left with center text
                        Expanded(
                          flex: 2,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    enabled: true,
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedSubcategoryIndex = null;
                                          return;
                                        }
                                        final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                        final sortedSubcategories = (subcategoryTotals.entries.toList()
                                          ..sort((a, b) => b.value.compareTo(a.value)))
                                          .take(8)
                                          .toList();
                                        if (index >= 0 && index < sortedSubcategories.length) {
                                          _touchedSubcategoryIndex = index;
                                        } else {
                                          _touchedSubcategoryIndex = null;
                                        }
                                      });
                                    },
                                  ),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50, // Prominent center hole
                                  sections: (subcategoryTotals.entries.toList()
                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                    .take(8)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final subcategoryEntry = entry.value;
                                      final percentage = totalSpent > 0 ? (subcategoryEntry.value / totalSpent) * 100 : 0.0;
                                      final isTouched = index == _touchedSubcategoryIndex;
                                      final baseRadius = 70.0;
                                      final radius = isTouched ? baseRadius + 8.0 : baseRadius;
                                      final subcategoryColor = _getColorForCategory(subcategoryEntry.key + 'sub');
                                      
                                      return PieChartSectionData(
                                        value: subcategoryEntry.value,
                                        title: percentage > 3 ? '${percentage.toStringAsFixed(0)}%' : '',
                                        color: subcategoryColor,
                                        radius: radius,
                                        titleStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.5),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ),
                              ),
                              // Center widget with animation
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _touchedSubcategoryIndex != null &&
                                            _touchedSubcategoryIndex! >= 0 &&
                                            _touchedSubcategoryIndex! <
                                                (subcategoryTotals.entries.toList()
                                                  ..sort((a, b) => b.value.compareTo(a.value)))
                                                  .take(8)
                                                  .length
                                        ? Column(
                                            key: ValueKey('subcategory_${_touchedSubcategoryIndex}'),
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CategoryIcons.getIconForSubcategory(
                                                  (subcategoryTotals.entries.toList()
                                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                                    .take(8)
                                                    .toList()[_touchedSubcategoryIndex!]
                                                    .key,
                                                ),
                                                size: 24,
                                                color: _getColorForCategory(
                                                  (subcategoryTotals.entries.toList()
                                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                                    .take(8)
                                                    .toList()[_touchedSubcategoryIndex!]
                                                    .key +
                                                    'sub',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                child: Text(
                                                  (subcategoryTotals.entries.toList()
                                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                                    .take(8)
                                                    .toList()[_touchedSubcategoryIndex!]
                                                    .key,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: _getColorForCategory(
                                                          (subcategoryTotals.entries.toList()
                                                            ..sort((a, b) => b.value.compareTo(a.value)))
                                                            .take(8)
                                                            .toList()[_touchedSubcategoryIndex!]
                                                            .key +
                                                            'sub',
                                                        ),
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatCurrency(
                                                  (subcategoryTotals.entries.toList()
                                                    ..sort((a, b) => b.value.compareTo(a.value)))
                                                    .take(8)
                                                    .toList()[_touchedSubcategoryIndex!]
                                                    .value,
                                                  group.currency,
                                                ),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '${(((subcategoryTotals.entries.toList()
                                                  ..sort((a, b) => b.value.compareTo(a.value)))
                                                  .take(8)
                                                  .toList()[_touchedSubcategoryIndex!]
                                                  .value /
                                                  totalSpent) *
                                                  100)
                                                  .toStringAsFixed(1)}%',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          )
                                        : Column(
                                            key: const ValueKey('total_subcategories'),
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.category_outlined,
                                                size: 24,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Top Subcategories',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatCurrency(totalSpent, group.currency),
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '${(subcategoryTotals.entries.toList()
                                                  ..sort((a, b) => b.value.compareTo(a.value)))
                                                  .take(8)
                                                  .length} shown',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Legend on the right
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (subcategoryTotals.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value)))
                              .take(8)
                              .map((entry) {
                                final subcategoryColor = _getColorForCategory(entry.key + 'sub');
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: subcategoryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Cash Flow Per Day Chart
        if (dailyTotals.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash Flow Per Day',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItem: (barGroup, groupIndex, rod, rodIndex) {
                              final sortedDays = dailyTotals.entries.toList()
                                ..sort((a, b) {
                                  try {
                                    final dateA = DateFormat('MMM d').parse(a.key);
                                    final dateB = DateFormat('MMM d').parse(b.key);
                                    return dateA.compareTo(dateB);
                                  } catch (e) {
                                    return a.key.compareTo(b.key);
                                  }
                                });
                              final day = sortedDays[barGroup.x.toInt()].key;
                              final amount = sortedDays[barGroup.x.toInt()].value;
                              return BarTooltipItem(
                                '${day}\n${_formatCurrency(amount, group.currency)}',
                                TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final sortedDays = dailyTotals.entries.toList()
                                  ..sort((a, b) {
                                    try {
                                      final dateA = DateFormat('MMM d').parse(a.key);
                                      final dateB = DateFormat('MMM d').parse(b.key);
                                      return dateA.compareTo(dateB);
                                    } catch (e) {
                                      return a.key.compareTo(b.key);
                                    }
                                  });
                                final index = value.toInt();
                                if (index >= 0 && index < sortedDays.length) {
                                  final day = sortedDays[index].key;
                                  // Show abbreviated day format
                                  final parts = day.split(' ');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      parts.length > 1 ? '${parts[0]}\n${parts[1]}' : day,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 40,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                // Format without symbol for Y-axis
                                final formatted = NumberFormat('#,###').format(value);
                                return Text(
                                  formatted,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                        ),
                        barGroups: () {
                          final sortedDays = dailyTotals.entries.toList()
                            ..sort((a, b) {
                              // Sort by date (parse the date string)
                              try {
                                final dateA = DateFormat('MMM d').parse(a.key);
                                final dateB = DateFormat('MMM d').parse(b.key);
                                return dateA.compareTo(dateB);
                              } catch (e) {
                                return a.key.compareTo(b.key);
                              }
                            });
                          return sortedDays.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value,
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        }(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Monthly Spending Chart
        if (monthlyTotals.length > 1) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Spending',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: monthlyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < monthlyTotals.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      monthlyTotals.keys.elementAt(index),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: monthlyTotals.entries.toList().asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value,
                                color: Theme.of(context).colorScheme.primary,
                                width: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Member Spending Breakdown
        if (memberTotals.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by Member',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  asyncMembers.when(
                    data: (members) {
                      final memberMap = <String, String>{};
                      for (final member in members) {
                        memberMap[member['user_id'] as String] = member['name'] as String;
                      }
                      
                      return Column(
                        children: (memberTotals.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                          .map((entry) {
                            final memberName = memberMap[entry.key] ?? entry.key.substring(0, 8) + '...';
                            final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      memberName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          memberName,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}% of total',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(entry.value, group.currency),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Top Expenses
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Expenses',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...(expenses.toList()
                  ..sort((a, b) => b.amount.compareTo(a.amount)))
                  .take(5)
                  .map((expense) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.receipt,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(expense.title),
                      subtitle: Text(
                        '${expense.category ?? 'Uncategorized'}${expense.subcategory != null ? ' • ${expense.subcategory}' : ''}',
                      ),
                      trailing: Text(
                        _formatCurrency(expense.amount, expense.currency),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      onTap: () {
                        context.push('/shell/group/${widget.groupId}/expense/${expense.id}');
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[category.hashCode % colors.length];
  }

  Widget _buildAnalysisSection(
    BuildContext context,
    Group group,
    double totalSpent,
    int expenseCount,
    double avgExpense,
    int categoryCount,
    Map<String, double> categoryTotals,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Group Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Spent',
                    value: _formatCurrency(totalSpent, group.currency),
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Expenses',
                    value: '$expenseCount',
                    icon: Icons.receipt_long,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Average',
                    value: _formatCurrency(avgExpense, group.currency),
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Categories',
                    value: '$categoryCount',
                    icon: Icons.category,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            // Category Breakdown
            if (categoryTotals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'By Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...(categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                .take(5)
                .map((entry) {
                  final percentage = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(entry.value, group.currency),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref, Expense e, String groupId) {
    final asyncMembers = ref.watch(groupMembersProvider(groupId));
    return asyncMembers.when(
      data: (members) {
        String paidByName = e.paidBy.substring(0, 8) + '...';
        try {
          final member = members.firstWhere(
            (m) => m['user_id'] == e.paidBy,
          );
          paidByName = member['name'] as String;
        } catch (_) {
          // Use default if member not found
        }
        
        final categoryName = e.category ?? 'Uncategorized';
        final subcategoryName = e.subcategory;
        final categoryIcon = CategoryIcons.getIconForCategory(categoryName);
        final categoryColor = CategoryIcons.getColorForCategory(categoryName);
        // Use subcategory icon if available, otherwise use category icon
        final displayIcon = subcategoryName != null
            ? CategoryIcons.getIconForSubcategory(subcategoryName)
            : categoryIcon;
        final dateFormat = DateFormat('MMM d, y');
        final timeFormat = DateFormat('h:mm a');
        final isToday = e.expenseDate.year == DateTime.now().year &&
            e.expenseDate.month == DateTime.now().month &&
            e.expenseDate.day == DateTime.now().day;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              context.push('/shell/group/$groupId/expense/${e.id}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      displayIcon,
                      color: categoryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Expense Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isToday ? 'Today' : dateFormat.format(e.expenseDate),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (e.category != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                displayIcon,
                                size: 14,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  subcategoryName ?? categoryName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: categoryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Paid by $paidByName',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Show category badge only if we have category but no subcategory (to avoid duplication)
                            // Or show subcategory badge if we have both
                            if (e.category != null && e.subcategory == null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        categoryIcon,
                                        size: 12,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          categoryName,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(e.amount, e.currency),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: const CircularProgressIndicator(strokeWidth: 2),
          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${DateFormat('MMM d, y').format(e.expenseDate)} • Loading...'),
          trailing: Text('${e.currency} ${e.amount.toStringAsFixed(2)}'),
          onTap: () {
            context.push('/shell/group/$groupId/expense/${e.id}');
          },
        ),
      ),
      error: (_, __) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${DateFormat('MMM d, y').format(e.expenseDate)} • Paid by ${e.paidBy.substring(0, 8)}...'),
          trailing: Text('${e.currency} ${e.amount.toStringAsFixed(2)}'),
          onTap: () {
            context.push('/shell/group/$groupId/expense/${e.id}');
          },
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    return NumberFormat.currency(symbol: _getCurrencySymbol(currency)).format(amount);
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

  static void _showEditGroupDialog(BuildContext context, WidgetRef ref, Group group) {
    final nameController = TextEditingController(text: group.name);
    final currencyController = TextEditingController(text: group.currency);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: 'Currency (e.g., INR, USD)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newCurrency = currencyController.text.trim().toUpperCase();
              
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group name cannot be empty')),
                );
                return;
              }
              
              try {
                await ref.read(groupsRepoProvider).updateGroup(
                      groupId: group.id,
                      name: newName,
                      currency: newCurrency.isNotEmpty ? newCurrency : null,
                    );
                
                if (context.mounted) {
                  ref.invalidate(groupProvider(group.id));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _confirmDeleteGroup(BuildContext context, WidgetRef ref, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone. All expenses and data associated with this group will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(groupsRepoProvider).deleteGroup(groupId);
                
                // Invalidate providers to refresh the UI
                ref.invalidate(groupsProvider);
                ref.invalidate(groupProvider(groupId));
                ref.invalidate(groupExpensesProvider(groupId));
                ref.invalidate(groupMembersProvider(groupId));
                ref.invalidate(groupActivitiesProvider(groupId));
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  context.go('/shell'); // Navigate back to home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditGroupDialog(BuildContext context, WidgetRef ref, Group group) {
    final nameController = TextEditingController(text: group.name);
    final currencyController = TextEditingController(text: group.currency);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: 'Currency (e.g., INR, USD)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newCurrency = currencyController.text.trim().toUpperCase();
              
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group name cannot be empty')),
                );
                return;
              }
              
              try {
                await ref.read(groupsRepoProvider).updateGroup(
                      groupId: group.id,
                      name: newName,
                      currency: newCurrency.isNotEmpty ? newCurrency : null,
                    );
                
                if (context.mounted) {
                  ref.invalidate(groupProvider(group.id));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _confirmDeleteGroup(BuildContext context, WidgetRef ref, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone. All expenses and data associated with this group will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(groupsRepoProvider).deleteGroup(groupId);
                
                // Invalidate providers to refresh the UI
                ref.invalidate(groupsProvider);
                ref.invalidate(groupProvider(groupId));
                ref.invalidate(groupExpensesProvider(groupId));
                ref.invalidate(groupMembersProvider(groupId));
                ref.invalidate(groupActivitiesProvider(groupId));
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  context.go('/shell'); // Navigate back to home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

