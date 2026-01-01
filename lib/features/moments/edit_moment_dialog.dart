import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment.dart';
import '../../theme/app_theme.dart';

class EditMomentDialog extends ConsumerStatefulWidget {
  final Moment moment;
  final String? groupId;
  
  const EditMomentDialog({
    super.key,
    required this.moment,
    this.groupId,
  });
  
  @override
  ConsumerState<EditMomentDialog> createState() => _EditMomentDialogState();
}

class _EditMomentDialogState extends ConsumerState<EditMomentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  
  DateTime? _selectedStartDate;
  DateTime _selectedEndDate = DateTime.now();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _titleController.text = widget.moment.title;
    _descriptionController.text = widget.moment.description ?? '';
    _targetAmountController.text = widget.moment.targetAmount.toStringAsFixed(0);
    _selectedStartDate = widget.moment.startDate;
    _selectedEndDate = widget.moment.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        if (_selectedEndDate.isBefore(picked)) {
          _selectedEndDate = picked.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final firstDate = _selectedStartDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }
  
  Future<void> _updateMoment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final targetAmount = double.parse(_targetAmountController.text);
      
      await ref.read(momentsRepoProvider).updateMoment(
        widget.moment.id,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          'target_amount': targetAmount,
          'start_date': _selectedStartDate?.toIso8601String(),
          'end_date': _selectedEndDate.toIso8601String(),
        },
      );
      
      if (mounted) {
        ref.invalidate(momentProvider(widget.moment.id));
        if (widget.groupId != null) {
          ref.invalidate(momentsProvider(widget.groupId));
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment updated successfully!')),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Moment',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                
                // Type (read-only)
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(widget.moment.type.toUpperCase()),
                  avatar: Icon(_getTypeIcon(widget.moment.type)),
                ),
                const SizedBox(height: 24),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Japan Trip 2024',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add a note about this moment',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Target amount
                TextFormField(
                  controller: _targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    hintText: '10000',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter target amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Start date (optional)
                InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Start Date (optional)',
                      hintText: 'Defaults to today',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedStartDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedStartDate = null;
                                });
                              },
                              tooltip: 'Clear start date',
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                    child: Text(
                      _selectedStartDate != null
                          ? DateFormat('MMM d, y').format(_selectedStartDate!)
                          : 'Today',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _selectedStartDate != null
                            ? null
                            : MomentraColors.lightGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // End date
                InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('MMM d, y').format(_selectedEndDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Actions
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateMoment,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'trip':
        return Icons.flight;
      case 'gift':
        return Icons.card_giftcard;
      case 'goal':
        return Icons.flag;
      case 'wishlist':
        return Icons.shopping_cart;
      default:
        return Icons.flag;
    }
  }
}


