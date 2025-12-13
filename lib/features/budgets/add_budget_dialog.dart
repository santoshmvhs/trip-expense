import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/budgets_repo.dart';
import '../../core/models/group_budget.dart';
import '../../core/models/user_budget.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/providers/budget_providers.dart';

class AddBudgetDialog extends ConsumerStatefulWidget {
  final String groupId;
  final String groupCurrency;
  final bool isGroupBudget;
  final GroupBudget? groupBudget;
  final UserBudget? userBudget;
  final VoidCallback onSaved;

  const AddBudgetDialog({
    super.key,
    required this.groupId,
    required this.groupCurrency,
    required this.isGroupBudget,
    this.groupBudget,
    this.userBudget,
    required this.onSaved,
  });

  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupBudget != null) {
      _amountController.text = widget.groupBudget!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.groupBudget!.description ?? '';
      _categoryController.text = widget.groupBudget!.category ?? '';
      _startDate = widget.groupBudget!.startDate;
      _endDate = widget.groupBudget!.endDate;
    } else if (widget.userBudget != null) {
      _amountController.text = widget.userBudget!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.userBudget!.description ?? '';
      _categoryController.text = widget.userBudget!.category ?? '';
      _startDate = widget.userBudget!.startDate;
      _endDate = widget.userBudget!.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final repo = ref.read(budgetsRepoProvider);
      final currentUserId = supabase().auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      if (widget.groupBudget != null) {
        // Update group budget
        await repo.updateGroupBudget(
          budgetId: widget.groupBudget!.id,
          amount: amount,
          category: _categoryController.text.isEmpty ? null : _categoryController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else if (widget.userBudget != null) {
        // Update user budget
        await repo.updateUserBudget(
          budgetId: widget.userBudget!.id,
          amount: amount,
          category: _categoryController.text.isEmpty ? null : _categoryController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else if (widget.isGroupBudget) {
        // Create group budget
        await repo.createGroupBudget(
          groupId: widget.groupId,
          createdBy: currentUserId,
          amount: amount,
          currency: widget.groupCurrency,
          category: _categoryController.text.isEmpty ? null : _categoryController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        // Create user budget
        await repo.createUserBudget(
          groupId: widget.groupId,
          userId: currentUserId,
          amount: amount,
          currency: widget.groupCurrency,
          category: _categoryController.text.isEmpty ? null : _categoryController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.groupBudget != null || widget.userBudget != null
                ? 'Budget updated'
                : 'Budget created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.groupBudget != null || widget.userBudget != null
            ? 'Edit Budget'
            : widget.isGroupBudget
                ? 'Add Trip Budget'
                : 'Add Personal Budget',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Budget Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter budget amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Food, Transport',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate != null
                            ? DateFormat('MMM d, y').format(_startDate!)
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate != null
                            ? DateFormat('MMM d, y').format(_endDate!)
                            : 'End Date',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

