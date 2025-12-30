import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment_template.dart';
import '../../theme/app_theme.dart';

class CreateMomentDialog extends ConsumerStatefulWidget {
  final String? groupId; // NULLABLE: moments can be standalone
  
  const CreateMomentDialog({
    super.key,
    this.groupId,
  });
  
  @override
  ConsumerState<CreateMomentDialog> createState() => _CreateMomentDialogState();
}

class _CreateMomentDialogState extends ConsumerState<CreateMomentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  
  String _selectedType = 'goal';
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  MomentTemplate? _selectedTemplate;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }
  
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }
  
  Future<void> _createMoment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final targetAmount = double.parse(_targetAmountController.text);
      
      await ref.read(momentsRepoProvider).createMoment(
        groupId: widget.groupId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        targetAmount: targetAmount,
        endDate: _selectedEndDate,
      );
      
      if (mounted) {
        // Invalidate moments list to refresh
        if (widget.groupId != null) {
          ref.invalidate(momentsProvider(widget.groupId));
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment created successfully!')),
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
                  'Create Moment',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                
                // Template selector
                Text(
                  'Template (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: MomentTemplates.getDefaultTemplates().length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Custom'),
                            selected: _selectedTemplate == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTemplate = null;
                              });
                            },
                          ),
                        );
                      }
                      final template = MomentTemplates.getDefaultTemplates()[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(template.name),
                          selected: _selectedTemplate?.id == template.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTemplate = selected ? template : null;
                              if (selected) {
                                _selectedType = template.type;
                                _titleController.text = template.name;
                                _descriptionController.text = template.description ?? '';
                                if (template.defaultTargetAmount != null) {
                                  _targetAmountController.text = template.defaultTargetAmount!.toStringAsFixed(0);
                                }
                                if (template.defaultDurationDays != null) {
                                  _selectedEndDate = DateTime.now().add(Duration(days: template.defaultDurationDays!));
                                }
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Type selector
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'trip', label: Text('Trip'), icon: Icon(Icons.flight)),
                    ButtonSegment(value: 'gift', label: Text('Gift'), icon: Icon(Icons.card_giftcard)),
                    ButtonSegment(value: 'goal', label: Text('Goal'), icon: Icon(Icons.flag)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
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
                        onPressed: _isLoading ? null : _createMoment,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create'),
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
}

