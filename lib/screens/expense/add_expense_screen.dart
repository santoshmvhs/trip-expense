import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _splitType = 'equal'; // 'equal', 'unequal', 'percentage'
  Map<String, double> _splits = {};
  bool _isLoading = false;
  bool _isRecurring = false;
  String? _recurringFrequency;
  DateTime? _recurringEndDate;
  String? _receiptUrl;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Travel',
    'Other',
  ];

  final List<String> _recurringFrequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  Future<void> _pickReceipt() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Upload to Supabase Storage
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final userId = context.read<AuthProvider>().currentUser?.id ?? '';

        await Supabase.instance.client.storage
            .from('receipts')
            .uploadBinary('$userId/$fileName', bytes);

        final url = Supabase.instance.client.storage
            .from('receipts')
            .getPublicUrl('$userId/$fileName');

        setState(() {
          _receiptUrl = url;
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

  Future<void> _selectRecurringEndDate() async {
    final DateTime? picked = await showDatePicker(
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
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSplits();
    });
  }

  void _initializeSplits() {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.getGroupMembers(widget.groupId);
    
    if (_splitType == 'equal' && members.isNotEmpty) {
      setState(() {
        _splits = {};
        for (var member in members) {
          _splits[member.id] = 0.0; // Will be calculated when amount is entered
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateEqualSplits() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.getGroupMembers(widget.groupId);
    
    if (members.isEmpty) return;

    final splitAmount = amount / members.length;
    setState(() {
      _splits = {};
      for (var member in members) {
        _splits[member.id] = splitAmount;
      }
    });
  }

  Future<void> _createExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_splits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one person to split')),
      );
      return;
    }

    final totalSplit = _splits.values.fold(0.0, (sum, value) => sum + value);
    if ((totalSplit - amount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Split total (${totalSplit.toStringAsFixed(2)}) must equal amount (${amount.toStringAsFixed(2)})',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final authProvider = context.read<AuthProvider>();
      final groupProvider = context.read<GroupProvider>();
      final group = groupProvider.groups.firstWhere((g) => g.id == widget.groupId);

      await expenseProvider.createExpense(
        groupId: widget.groupId,
        paidBy: authProvider.currentUser!.id,
        amount: amount,
        description: _descriptionController.text.trim(),
        currency: group.currency,
        category: _selectedCategory,
        receiptUrl: _receiptUrl,
        isRecurring: _isRecurring,
        recurringFrequency: _recurringFrequency,
        recurringEndDate: _recurringEndDate,
        splits: _splits,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully!')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, _) {
          final group = groupProvider.groups.firstWhere((g) => g.id == widget.groupId);
          final members = groupProvider.getGroupMembers(widget.groupId);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: group.currency,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      if (_splitType == 'equal') {
                        _updateEqualSplits();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Receipt Upload
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt),
                      title: const Text('Receipt'),
                      subtitle: _receiptUrl != null
                          ? const Text('Receipt uploaded', style: TextStyle(color: Colors.green))
                          : const Text('Tap to upload receipt'),
                      trailing: _receiptUrl != null
                          ? IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _receiptUrl = null;
                                });
                              },
                            )
                          : const Icon(Icons.upload),
                      onTap: _pickReceipt,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Recurring Expense Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Recurring Expense'),
                      subtitle: const Text('Repeat this expense automatically'),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _recurringFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: _recurringFrequencies.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(freq[0].toUpperCase() + freq.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _recurringFrequency = value;
                        });
                      },
                      validator: (value) {
                        if (_isRecurring && value == null) {
                          return 'Please select a frequency';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _recurringEndDate == null
                            ? 'End Date (Optional)'
                            : 'End Date: ${_recurringEndDate!.toString().split(' ')[0]}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectRecurringEndDate,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Split Between',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'equal', label: Text('Equal')),
                      ButtonSegment(value: 'unequal', label: Text('Custom')),
                    ],
                    selected: {_splitType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _splitType = newSelection.first;
                        _initializeSplits();
                        if (_splitType == 'equal') {
                          _updateEqualSplits();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ...members.map((member) {
                    final amount = _splits[member.id] ?? 0.0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            ((member.fullName ?? member.email).isNotEmpty
                                ? (member.fullName ?? member.email)[0]
                                : '?').toUpperCase(),
                          ),
                        ),
                        title: Text(member.fullName ?? member.email),
                        trailing: SizedBox(
                          width: 120,
                          child: _splitType == 'equal'
                              ? Text(
                                  amount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : TextFormField(
                                  initialValue: amount > 0 ? amount.toStringAsFixed(2) : '',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    suffixText: group.currency,
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _splits[member.id] =
                                          double.tryParse(value) ?? 0.0;
                                    });
                                  },
                                ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add Expense'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

