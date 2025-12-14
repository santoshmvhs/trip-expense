import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/repositories/expenses_repo.dart';
import '../../core/repositories/groups_repo.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/providers/expense_with_splits_provider.dart';
import '../../core/providers/category_providers.dart';
import '../../core/providers/activity_providers.dart';
import '../../core/models/category.dart';
import '../../core/models/expense_split.dart';
import '../../core/utils/category_icons.dart';
import 'expense_detail_page.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final String groupId;
  final String? expenseId; // If provided, edit mode

  const AddExpensePage({super.key, required this.groupId, this.expenseId});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategoryId; // Store category ID
  String? _selectedCategoryName; // Store category name for display and saving
  String? _selectedSubcategoryId; // Store subcategory ID
  String? _selectedSubcategoryName; // Store subcategory name for display and saving
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaidBy;
  final Map<String, bool> _selectedMembers = {};
  String _splitType = 'equal'; // 'equal', 'percentage', 'amount', 'shares'
  final Map<String, TextEditingController> _splitControllers = {};
  bool _isLoading = false;
  bool _isLoadingExpense = false;
  bool _hasInvalidatedMembers = false;
  bool _hasPrefetchedCategories = false;
  
  // Receipt upload
  final ImagePicker _imagePicker = ImagePicker();
  String? _receiptPath;
  File? _receiptFile;
  
  // Recurring expenses
  bool _isRecurring = false;
  String? _recurringFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  DateTime? _recurringEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _loadExpenseForEdit();
    }
  }

  Future<void> _loadExpenseForEdit() async {
    setState(() => _isLoadingExpense = true);
    try {
      final expense = await ref.read(expensesRepoProvider).getExpense(widget.expenseId!);
      
      // Load splits
      final splitsRes = await supabase()
          .from('expense_splits')
          .select()
          .eq('expense_id', widget.expenseId!);
      
      final splits = (splitsRes as List)
          .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
          .toList();

      // Populate form
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedDate = expense.expenseDate;
      _selectedPaidBy = expense.paidBy;
      // Load category and subcategory by name (backward compatibility)
      _selectedCategoryName = expense.category;
      _selectedSubcategoryName = expense.subcategory;
      
      // Try to find category ID from name
      if (_selectedCategoryName != null) {
        final categories = await ref.read(categoriesProvider.future);
        try {
          final category = categories.firstWhere(
            (c) => c.name == _selectedCategoryName,
          );
          _selectedCategoryId = category.id;
          
          // Try to find subcategory ID from name
          if (_selectedSubcategoryName != null) {
            final subcategories = await ref.read(subcategoriesProvider(category.id).future);
            try {
              final subcategory = subcategories.firstWhere(
                (s) => s.name == _selectedSubcategoryName,
              );
              _selectedSubcategoryId = subcategory.id;
            } catch (e) {
              // Subcategory not found, keep name only
            }
          }
        } catch (e) {
          // Category not found, keep name only
        }
      }
      _notesController.text = expense.notes ?? '';
      _receiptPath = expense.receiptPath;
      _isRecurring = expense.isRecurring;
      _recurringFrequency = expense.recurringFrequency;
      _recurringEndDate = expense.recurringEndDate;

      // Populate splits
      for (final split in splits) {
        _selectedMembers[split.userId] = true;
        if (!_splitControllers.containsKey(split.userId)) {
          _splitControllers[split.userId] = TextEditingController();
        }
        // Determine split type based on splits
        // For now, default to 'amount' if editing
        _splitType = 'amount';
        _splitControllers[split.userId]!.text = split.share.toStringAsFixed(2);
      }
    } catch (e) {
      debugPrint('Error loading expense for edit: $e');
    } finally {
      setState(() => _isLoadingExpense = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeSplitControllers(List<Map<String, dynamic>> members) {
    for (final member in members) {
      final userId = member['user_id'] as String;
      if (!_splitControllers.containsKey(userId)) {
        _splitControllers[userId] = TextEditingController();
      }
    }
  }

  Future<void> _pickReceipt() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Receipt Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Upload to Supabase Storage
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final userId = currentUser()!.id;

        await supabase().storage
            .from('receipts')
            .uploadBinary('$userId/$fileName', bytes);

        final url = supabase().storage
            .from('receipts')
            .getPublicUrl('$userId/$fileName');

        setState(() {
          _receiptPath = url;
          _receiptFile = File(image.path);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading receipt: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // Allow dates up to 10 years in the future
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid')),
      );
      return;
    }

    final selectedUserIds = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // Allow personal expenses (no splits) - user can choose to not split
    // If no members selected, it's a personal expense visible only to the creator
    final isPersonalExpense = selectedUserIds.isEmpty;

    setState(() => _isLoading = true);

    try {
    final amount = double.parse(_amountController.text);
    final splits = <String, double>{};

    // Handle personal expense (no splits)
    if (!isPersonalExpense) {
      // Shared expense - calculate splits
      switch (_splitType) {
        case 'equal':
        final sharePerPerson = amount / selectedUserIds.length;
        for (final userId in selectedUserIds) {
          splits[userId] = sharePerPerson;
        }
        break;

      case 'percentage':
        double totalPercentage = 0;
        for (final userId in selectedUserIds) {
          final controller = _splitControllers[userId];
          if (controller == null || controller.text.isEmpty) {
            throw Exception('Please enter percentage for all selected members');
          }
          final percentage = double.tryParse(controller.text);
          if (percentage == null || percentage < 0 || percentage > 100) {
            throw Exception('Please enter valid percentages (0-100)');
          }
          totalPercentage += percentage;
        }
        if ((totalPercentage - 100).abs() > 0.01) {
          throw Exception('Percentages must add up to 100%');
        }
        for (final userId in selectedUserIds) {
          final percentage = double.parse(_splitControllers[userId]!.text);
          splits[userId] = (amount * percentage) / 100;
        }
        break;

      case 'amount':
        double totalAmount = 0;
        for (final userId in selectedUserIds) {
          final controller = _splitControllers[userId];
          if (controller == null || controller.text.isEmpty) {
            throw Exception('Please enter amount for all selected members');
          }
          final splitAmount = double.tryParse(controller.text);
          if (splitAmount == null || splitAmount < 0) {
            throw Exception('Please enter valid amounts');
          }
          totalAmount += splitAmount;
        }
        if ((totalAmount - amount).abs() > 0.01) {
          throw Exception('Amounts must add up to ₹${amount.toStringAsFixed(2)}');
        }
        for (final userId in selectedUserIds) {
          splits[userId] = double.parse(_splitControllers[userId]!.text);
        }
        break;

      case 'shares':
        double totalShares = 0;
        for (final userId in selectedUserIds) {
          final controller = _splitControllers[userId];
          if (controller == null || controller.text.isEmpty) {
            throw Exception('Please enter shares for all selected members');
          }
          final shares = double.tryParse(controller.text);
          if (shares == null || shares <= 0) {
            throw Exception('Please enter valid shares (greater than 0)');
          }
          totalShares += shares;
        }
        if (totalShares == 0) {
          throw Exception('Total shares cannot be zero');
        }
        for (final userId in selectedUserIds) {
          final shares = double.parse(_splitControllers[userId]!.text);
          splits[userId] = (amount * shares) / totalShares;
        }
        break;
      }
    }

      if (widget.expenseId != null) {
        // Update existing expense
        await ref.read(expensesRepoProvider).updateExpense(
              expenseId: widget.expenseId!,
              title: _titleController.text.trim(),
              amount: amount,
              currency: 'INR', // TODO: Get from group
              paidBy: _selectedPaidBy!,
              expenseDate: _selectedDate,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              category: _selectedCategoryName,
              subcategory: _selectedSubcategoryName,
              receiptPath: _receiptPath,
              isRecurring: _isRecurring,
              recurringFrequency: _recurringFrequency,
              recurringEndDate: _recurringEndDate,
              splitsByUserId: splits,
            );

        if (mounted) {
          ref.invalidate(groupExpensesProvider(widget.groupId));
          ref.invalidate(groupExpensesWithSplitsProvider(widget.groupId));
          ref.invalidate(groupActivitiesProvider(widget.groupId));
          ref.invalidate(expenseDetailProvider(widget.expenseId!));
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new expense
        await ref.read(expensesRepoProvider).createExpense(
              groupId: widget.groupId,
              title: _titleController.text.trim(),
              amount: amount,
              currency: 'INR', // TODO: Get from group
              paidBy: _selectedPaidBy!,
              expenseDate: _selectedDate,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              category: _selectedCategoryName,
              subcategory: _selectedSubcategoryName,
              receiptPath: _receiptPath,
              isRecurring: _isRecurring,
              recurringFrequency: _recurringFrequency,
              recurringEndDate: _recurringEndDate,
              splitsByUserId: splits,
            );

        if (mounted) {
          // Invalidate providers to refresh the list
          ref.invalidate(groupExpensesProvider(widget.groupId));
          ref.invalidate(groupExpensesWithSplitsProvider(widget.groupId));
          ref.invalidate(groupActivitiesProvider(widget.groupId));
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    // Pre-fetch categories immediately to avoid delay when opening dropdown
    if (!_hasPrefetchedCategories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(categoriesProvider.future);
        setState(() {
          _hasPrefetchedCategories = true;
        });
      });
    }
    
    // Invalidate members provider on first build to ensure fresh data
    if (!_hasInvalidatedMembers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(groupMembersProvider(widget.groupId));
        setState(() {
          _hasInvalidatedMembers = true;
        });
      });
    }
    
    final asyncMembers = ref.watch(groupMembersProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Dinner at restaurant',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.currency_rupee),
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            ref.watch(categoriesProvider).when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'Select category',
                  prefixIcon: _selectedCategoryId != null
                      ? Icon(
                          CategoryIcons.getIconForCategory(
                            categories.firstWhere((c) => c.id == _selectedCategoryId).name,
                          ),
                          color: CategoryIcons.getColorForCategory(
                            categories.firstWhere((c) => c.id == _selectedCategoryId).name,
                          ),
                        )
                      : const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: categories.map((category) {
                  final icon = CategoryIcons.getIconForCategory(category.name);
                  final color = CategoryIcons.getColorForCategory(category.name);
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    final selectedCategory = categories.firstWhere((c) => c.id == value);
                    _selectedCategoryName = selectedCategory.name;
                    _selectedSubcategoryId = null;
                    _selectedSubcategoryName = null; // Reset subcategory when category changes
                  });
                },
              ),
              loading: () => DropdownButtonFormField<String>(
                value: null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Loading...',
                ),
                items: const [],
                onChanged: (_) {}, // No-op for loading state
              ),
              error: (_, __) => DropdownButtonFormField<String>(
                value: null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Error loading categories',
                ),
                items: const [],
                onChanged: (_) {}, // No-op for error state
              ),
            ),
            const SizedBox(height: 16),

            // Subcategory
            if (_selectedCategoryId != null)
              ref.watch(categoriesProvider).when(
                data: (allCategories) {
                  final selectedCategory = allCategories.firstWhere((c) => c.id == _selectedCategoryId);
                  return ref.watch(subcategoriesProvider(_selectedCategoryId!)).when(
                    data: (subcategories) => DropdownButtonFormField<String>(
                      value: _selectedSubcategoryId,
                      decoration: InputDecoration(
                        labelText: 'Subcategory',
                        hintText: 'Select subcategory',
                        prefixIcon: _selectedSubcategoryId != null
                            ? Icon(
                                CategoryIcons.getIconForSubcategory(
                                  subcategories.firstWhere((s) => s.id == _selectedSubcategoryId).name,
                                ),
                                color: CategoryIcons.getColorForCategory(selectedCategory.name),
                              )
                            : const Icon(Icons.label_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: subcategories.map((subcategory) {
                        final icon = CategoryIcons.getIconForSubcategory(subcategory.name);
                        final categoryColor = CategoryIcons.getColorForCategory(selectedCategory.name);
                        return DropdownMenuItem(
                          value: subcategory.id,
                          child: Row(
                            children: [
                              Icon(icon, color: categoryColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(subcategory.name)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategoryId = value;
                          final selectedSubcategory = subcategories.firstWhere((s) => s.id == value);
                          _selectedSubcategoryName = selectedSubcategory.name;
                        });
                      },
                    ),
                    loading: () => DropdownButtonFormField<String>(
                      value: null,
                      decoration: InputDecoration(
                        labelText: 'Subcategory',
                        hintText: 'Loading...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: const [],
                      onChanged: (_) {},
                    ),
                    error: (_, __) => DropdownButtonFormField<String>(
                      value: null,
                      decoration: InputDecoration(
                        labelText: 'Subcategory',
                        hintText: 'Error loading subcategories',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: const [],
                      onChanged: (_) {},
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            if (_selectedCategoryId != null) const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.chevron_right),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  DateFormat('MMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Paid by
            asyncMembers.when(
              data: (members) {
                if (_selectedPaidBy == null && members.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedPaidBy = members[0]['user_id'] as String;
                    });
                  });
                }
                return DropdownButtonFormField<String>(
                  value: _selectedPaidBy,
                  decoration: InputDecoration(
                    labelText: 'Paid by',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  items: members.map((member) {
                    final userId = member['user_id'] as String;
                    final name = member['name'] as String;
                    return DropdownMenuItem(
                      value: userId,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaidBy = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select who paid';
                    }
                    return null;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading members: $e'),
            ),
            const SizedBox(height: 24),

            // Split options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split between',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    // Split type selector
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'equal', label: Text('Equal')),
                        ButtonSegment(value: 'percentage', label: Text('%')),
                        ButtonSegment(value: 'amount', label: Text('Amount')),
                        ButtonSegment(value: 'shares', label: Text('Shares')),
                      ],
                      selected: {_splitType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _splitType = newSelection.first;
                          // Clear controllers when switching types
                          for (final controller in _splitControllers.values) {
                            controller.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Member selection and split inputs
                    asyncMembers.when(
                      data: (members) {
                        _initializeSplitControllers(members);
                        return Column(
                          children: members.map((member) {
                            final userId = member['user_id'] as String;
                            final name = member['name'] as String;
                            if (!_selectedMembers.containsKey(userId)) {
                              _selectedMembers[userId] = true;
                            }
                            final isSelected = _selectedMembers[userId] ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    title: Text(name),
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMembers[userId] = value ?? false;
                                        if (!(value ?? false)) {
                                          _splitControllers[userId]?.clear();
                                        }
                                      });
                                    },
                                  ),
                                  if (isSelected && _splitType != 'equal')
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: TextFormField(
                                        controller: _splitControllers[userId],
                                        decoration: InputDecoration(
                                          labelText: _splitType == 'percentage'
                                              ? 'Percentage (%)'
                                              : _splitType == 'amount'
                                                  ? 'Amount (₹)'
                                                  : 'Shares',
                                          hintText: _splitType == 'percentage'
                                              ? '0'
                                              : _splitType == 'amount'
                                                  ? '0.00'
                                                  : '1',
                                          border: const OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.numberWithOptions(decimal: _splitType != 'shares'),
                                        enabled: isSelected,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox(),
                    ),
                    // Split preview
                    Builder(
                      builder: (context) {
                        if (_amountController.text.isEmpty) return const SizedBox();
                        try {
                          final amount = double.tryParse(_amountController.text) ?? 0;
                          if (amount <= 0) return const SizedBox();
                          
                          final selectedIds = _selectedMembers.entries
                              .where((e) => e.value)
                              .map((e) => e.key)
                              .toList();
                          
                          if (selectedIds.isEmpty) return const SizedBox();
                          
                          Map<String, double> preview = {};
                          String? errorMessage;
                          
                          switch (_splitType) {
                            case 'equal':
                              final perPerson = amount / selectedIds.length;
                              for (final id in selectedIds) {
                                preview[id] = perPerson;
                              }
                              break;
                            case 'percentage':
                              double totalPct = 0;
                              for (final id in selectedIds) {
                                final pct = double.tryParse(_splitControllers[id]?.text ?? '0') ?? 0;
                                totalPct += pct;
                                preview[id] = (amount * pct) / 100;
                              }
                              if ((totalPct - 100).abs() > 0.01) {
                                errorMessage = 'Total: ${totalPct.toStringAsFixed(1)}% (should be 100%)';
                              }
                              break;
                            case 'amount':
                              double total = 0;
                              for (final id in selectedIds) {
                                final amt = double.tryParse(_splitControllers[id]?.text ?? '0') ?? 0;
                                total += amt;
                                preview[id] = amt;
                              }
                              if ((total - amount).abs() > 0.01) {
                                errorMessage = 'Total: ₹${total.toStringAsFixed(2)} (should be ₹${amount.toStringAsFixed(2)})';
                              }
                              break;
                            case 'shares':
                              double totalShares = 0;
                              for (final id in selectedIds) {
                                final shares = double.tryParse(_splitControllers[id]?.text ?? '0') ?? 0;
                                totalShares += shares;
                              }
                              if (totalShares > 0) {
                                for (final id in selectedIds) {
                                  final shares = double.tryParse(_splitControllers[id]?.text ?? '0') ?? 0;
                                  preview[id] = (amount * shares) / totalShares;
                                }
                              }
                              break;
                          }
                          
                          if (errorMessage != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                errorMessage,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            );
                          }
                          
                          return asyncMembers.when(
                            data: (members) {
                              final memberMap = <String, String>{};
                              for (final m in members) {
                                memberMap[m['user_id'] as String] = m['name'] as String;
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Split Preview:',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    ...preview.entries.map((e) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(memberMap[e.key] ?? 'Unknown'),
                                            Text(
                                              '₹${e.value.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          );
                        } catch (e) {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional notes...',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Receipt Upload
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _pickReceipt,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _receiptPath != null
                              ? Colors.green.withOpacity(0.1)
                              : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _receiptPath != null ? Icons.receipt_long : Icons.add_photo_alternate,
                          color: _receiptPath != null
                              ? Colors.green
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _receiptPath != null
                                  ? 'Receipt uploaded'
                                  : 'Tap to upload receipt',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _receiptPath != null
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_receiptPath != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _receiptPath = null;
                              _receiptFile = null;
                            });
                          },
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_receiptFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _receiptFile!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Recurring Expense Toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 20,
                      color: _isRecurring
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    const Text('Recurring Expense'),
                  ],
                ),
                subtitle: _isRecurring
                    ? Text(_recurringFrequency != null
                        ? 'Repeats ${_recurringFrequency}'
                        : 'Select frequency')
                    : const Text('Make this expense repeat automatically'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringFrequency = null;
                      _recurringEndDate = null;
                    }
                  });
                },
              ),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _recurringFrequency,
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  hintText: 'Select frequency',
                  prefixIcon: const Icon(Icons.schedule),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Row(
                      children: [
                        Icon(Icons.today, size: 20),
                        SizedBox(width: 8),
                        Text('Daily'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 20),
                        SizedBox(width: 8),
                        Text('Weekly'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 20),
                        SizedBox(width: 8),
                        Text('Monthly'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'yearly',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20),
                        SizedBox(width: 8),
                        Text('Yearly'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurringFrequency = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('End Date (Optional)'),
                subtitle: Text(_recurringEndDate != null
                    ? DateFormat('MMM d, y').format(_recurringEndDate!)
                    : 'No end date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() {
                      _recurringEndDate = picked;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 24),

                        // Submit button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitExpense,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.expenseId != null ? 'Update Expense' : 'Add Expense'),
                        ),
          ],
        ),
      ),
    );
  }
}

