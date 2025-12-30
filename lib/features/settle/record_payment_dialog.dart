import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/repositories/settlements_repo.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/models/group.dart';
import '../../core/constants/currencies.dart';
import '../../core/supabase/supabase_client.dart' show currentUser;
import 'settle_page.dart' show groupBalancesProvider;

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final String groupId;
  final Group group;
  final List<Map<String, dynamic>> balances;

  const RecordPaymentDialog({
    super.key,
    required this.groupId,
    required this.group,
    required this.balances,
  });

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedPayerId;
  String? _selectedPayeeId;
  String? _selectedMethod;
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Credit Card',
    'Debit Card',
    'PayPal',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getCurrencySymbol(String currency) {
    return Currencies.getSymbol(currency);
  }

  String _formatCurrency(double amount, String currency) {
    return NumberFormat.currency(symbol: _getCurrencySymbol(currency))
        .format(amount);
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayerId == null || _selectedPayeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both payer and payee')),
      );
      return;
    }

    if (_selectedPayerId == _selectedPayeeId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer and payee must be different')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      final settlementsRepo = ref.read(settlementsRepoProvider);
      await settlementsRepo.recordSettlement(
        groupId: widget.groupId,
        fromUserId: _selectedPayerId!,
        toUserId: _selectedPayeeId!,
        amount: amount,
        currency: widget.group.currency,
        method: _selectedMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Invalidate balances to refresh
      ref.invalidate(groupBalancesProvider(widget.groupId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully!'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = currentUser()?.id;
    
    return AlertDialog(
      title: const Text('Record Payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payer dropdown
              DropdownButtonFormField<String>(
                value: _selectedPayerId,
                decoration: const InputDecoration(
                  labelText: 'Paid by',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: widget.balances.map((b) {
                  final userId = b['userId'] as String;
                  final name = b['name'] as String;
                  final isCurrentUser = userId == currentUserId;
                  return DropdownMenuItem<String>(
                    value: userId,
                    child: Row(
                      children: [
                        Text(name),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(You)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayerId = value;
                    // Clear payee if same as payer
                    if (_selectedPayeeId == value) {
                      _selectedPayeeId = null;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select who paid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Payee dropdown
              DropdownButtonFormField<String>(
                value: _selectedPayeeId,
                decoration: const InputDecoration(
                  labelText: 'Paid to',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: widget.balances
                    .where((b) => b['userId'] != _selectedPayerId)
                    .map((b) {
                  final userId = b['userId'] as String;
                  final name = b['name'] as String;
                  final isCurrentUser = userId == currentUserId;
                  return DropdownMenuItem<String>(
                    value: userId,
                    child: Row(
                      children: [
                        Text(name),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(You)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayeeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select who received payment';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Amount input
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${_getCurrencySymbol(widget.group.currency)} ',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Payment method dropdown (optional)
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method (Optional)',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Notes input (optional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _recordPayment,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}

