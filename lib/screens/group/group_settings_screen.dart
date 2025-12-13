import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/group_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../services/csv_export_service.dart';
import '../../models/group_model.dart';

class GroupSettingsScreen extends StatelessWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  Future<void> _generateReport(BuildContext context) async {
    try {
      final groupProvider = context.read<GroupProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      
      final group = groupProvider.groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => GroupModel(
          id: groupId,
          name: 'Unknown',
          createdBy: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final expenses = expenseProvider.getExpensesForGroup(groupId);
      final balances = expenseProvider.getBalancesForGroup(groupId);

      await ReportService.generateExpenseReport(
        group: group,
        expenses: expenses,
        balances: balances,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCsv(BuildContext context) async {
    try {
      final groupProvider = context.read<GroupProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      
      final group = groupProvider.groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => GroupModel(
          id: groupId,
          name: 'Unknown',
          createdBy: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final expenses = expenseProvider.getExpensesForGroup(groupId);

      await CsvExportService.exportToCsv(
        group: group,
        expenses: expenses,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final groupProvider = context.read<GroupProvider>();
        await groupProvider.deleteGroup(groupId);
        
        if (context.mounted) {
          // Navigate back to home screen
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.read<GroupProvider>();
    final group = groupProvider.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => GroupModel(
        id: groupId,
        name: 'Loading...',
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final authProvider = context.read<AuthProvider>();
    final isCreator = group.createdBy == authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Group Name'),
            subtitle: Text(group.name),
          ),
          if (group.description != null)
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Description'),
              subtitle: Text(group.description!),
            ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text(group.currency),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Generate Expense Report'),
            subtitle: const Text('Export expenses as PDF'),
            onTap: () => _generateReport(context),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export to CSV'),
            subtitle: const Text('Export expenses as CSV file'),
            onTap: () => _exportToCsv(context),
          ),
          if (isCreator) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Group',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Permanently delete this group'),
              onTap: () => _deleteGroup(context),
            ),
          ],
        ],
      ),
    );
  }
}

