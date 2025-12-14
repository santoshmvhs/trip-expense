import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/trip_budget.dart';
import '../../core/models/trip_budget_allocation.dart';
import '../../core/providers/budget_providers.dart';
import '../../core/providers/category_providers.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/category_icons.dart';

class TripBudgetDialog extends ConsumerStatefulWidget {
  final String groupId;
  final String groupCurrency;
  final TripBudget? tripBudget;
  final bool showAllocations;

  const TripBudgetDialog({
    super.key,
    required this.groupId,
    required this.groupCurrency,
    this.tripBudget,
    this.showAllocations = false,
  });

  @override
  ConsumerState<TripBudgetDialog> createState() => _TripBudgetDialogState();
}

class _TripBudgetDialogState extends ConsumerState<TripBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _totalAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Allocation management
  final List<TripBudgetAllocation> _allocations = [];
  double _totalAllocated = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.tripBudget != null) {
      _totalAmountController.text = widget.tripBudget!.totalAmount.toStringAsFixed(2);
      _descriptionController.text = widget.tripBudget!.description ?? '';
      _startDate = widget.tripBudget!.startDate;
      _endDate = widget.tripBudget!.endDate;
    }

    if (widget.showAllocations && widget.tripBudget != null) {
      _loadAllocations();
    }
  }

  Future<void> _loadAllocations() async {
    if (widget.tripBudget == null) return;
    final allocations = await ref.read(budgetsRepoProvider).getTripBudgetAllocations(widget.tripBudget!.id);
    setState(() {
      _allocations.clear();
      _allocations.addAll(allocations);
      _updateTotalAllocated();
    });
  }

  void _updateTotalAllocated() {
    _totalAllocated = _allocations.fold<double>(0.0, (sum, a) => sum + a.amount);
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTripBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = double.tryParse(_totalAmountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid total amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase().auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final budgetsRepo = ref.read(budgetsRepoProvider);
      TripBudget tripBudget;

      if (widget.tripBudget == null) {
        // Create new trip budget
        tripBudget = await budgetsRepo.createTripBudget(
          groupId: widget.groupId,
          createdBy: userId,
          totalAmount: totalAmount,
          currency: widget.groupCurrency,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        // Update existing trip budget
        tripBudget = await budgetsRepo.updateTripBudget(
          budgetId: widget.tripBudget!.id,
          totalAmount: totalAmount,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      // Save allocations if any
      if (_allocations.isNotEmpty) {
        // Delete existing allocations
        await budgetsRepo.deleteAllTripBudgetAllocations(tripBudget.id);

        // Create new allocations
        for (var allocation in _allocations) {
          await budgetsRepo.createTripBudgetAllocation(
            tripBudgetId: tripBudget.id,
            category: allocation.category,
            subcategory: allocation.subcategory,
            amount: allocation.amount,
            description: allocation.description,
            sortOrder: allocation.sortOrder,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip budget saved successfully'),
            backgroundColor: Colors.green,
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.tripBudget != null;
    final showAllocationsSection = widget.showAllocations || _allocations.isNotEmpty;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Edit Trip Budget' : 'Create Trip Budget',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Amount
                      TextFormField(
                        controller: _totalAmountController,
                        decoration: InputDecoration(
                          labelText: 'Total Budget',
                          prefixText: _getCurrencySymbol(widget.groupCurrency),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total budget';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                                );
                                if (date != null) {
                                  setState(() => _startDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_startDate == null
                                  ? 'Start Date'
                                  : DateFormat('MMM d, y').format(_startDate!)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                                  firstDate: _startDate ?? DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                                );
                                if (date != null) {
                                  setState(() => _endDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_endDate == null
                                  ? 'End Date'
                                  : DateFormat('MMM d, y').format(_endDate!)),
                            ),
                          ),
                        ],
                      ),

                      if (showAllocationsSection) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Allocations',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAddAllocationDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Allocations Summary
                        if (_allocations.isNotEmpty) ...[
                          Card(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Allocated:',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${_getCurrencySymbol(widget.groupCurrency)}${_totalAllocated.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Allocations List
                        ..._allocations.asMap().entries.map((entry) {
                          final index = entry.key;
                          final allocation = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                CategoryIcons.getIconForCategory(allocation.category ?? ''),
                              ),
                              title: Text(allocation.displayName),
                              subtitle: Text(
                                '${_getCurrencySymbol(widget.groupCurrency)}${allocation.amount.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _allocations.removeAt(index);
                                    _updateTotalAllocated();
                                  });
                                },
                              ),
                              onTap: () => _showEditAllocationDialog(index),
                            ),
                          );
                        }),

                        // Remaining Budget
                        if (_allocations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            color: _totalAllocated > (double.tryParse(_totalAmountController.text) ?? 0)
                                ? Colors.red[50]
                                : Colors.green[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining:',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${_getCurrencySymbol(widget.groupCurrency)}${((double.tryParse(_totalAmountController.text) ?? 0) - _totalAllocated).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _totalAllocated > (double.tryParse(_totalAmountController.text) ?? 0)
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTripBudget,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAllocationDialog() async {
    await _showAllocationDialog();
  }

  Future<void> _showEditAllocationDialog(int index) async {
    await _showAllocationDialog(allocation: _allocations[index], index: index);
  }

  Future<void> _showAllocationDialog({TripBudgetAllocation? allocation, int? index}) async {
    final categories = ref.read(categoriesProvider);

    String? selectedCategory;
    String? selectedSubcategory;
    final amountController = TextEditingController(
      text: allocation?.amount.toStringAsFixed(2) ?? '',
    );
    final descriptionController = TextEditingController(
      text: allocation?.description ?? '',
    );

    if (allocation != null) {
      selectedCategory = allocation.category;
      selectedSubcategory = allocation.subcategory;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(index == null ? 'Add Allocation' : 'Edit Allocation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...categories.map((cat) => DropdownMenuItem(
                            value: cat.name,
                            child: Text(cat.name),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                        selectedSubcategory = null; // Reset subcategory when category changes
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subcategory
                  if (selectedCategory != null)
                    Builder(
                      builder: (context) {
                        final selectedCat = categories.firstWhere(
                          (c) => c.name == selectedCategory,
                          orElse: () => throw Exception('Category not found'),
                        );
                        final subcategories = ref.watch(subcategoriesProvider(selectedCat.id));
                        
                        return DropdownButtonFormField<String>(
                          value: selectedSubcategory,
                          decoration: InputDecoration(
                            labelText: 'Subcategory',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ...subcategories.map((sub) => DropdownMenuItem(
                                  value: sub.name,
                                  child: Text(sub.name),
                                )),
                          ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedSubcategory = value;
                                });
                              },
                            );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: _getCurrencySymbol(widget.groupCurrency),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                    return;
                  }

                  Navigator.of(context).pop({
                    'category': selectedCategory,
                    'subcategory': selectedSubcategory,
                    'amount': amount,
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          // Update existing
          _allocations[index] = TripBudgetAllocation(
            id: _allocations[index].id,
            tripBudgetId: _allocations[index].tripBudgetId,
            category: result['category'] as String?,
            subcategory: result['subcategory'] as String?,
            amount: result['amount'] as double,
            description: result['description'] as String?,
            sortOrder: _allocations[index].sortOrder,
            createdAt: _allocations[index].createdAt,
            updatedAt: DateTime.now(),
          );
        } else {
          // Add new
          _allocations.add(TripBudgetAllocation(
            id: '', // Will be generated by database
            tripBudgetId: widget.tripBudget?.id ?? '',
            category: result['category'] as String?,
            subcategory: result['subcategory'] as String?,
            amount: result['amount'] as double,
            description: result['description'] as String?,
            sortOrder: _allocations.length,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
        _updateTotalAllocated();
      });
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }
}

