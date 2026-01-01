import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment_template.dart';
import '../../core/models/moment_wishlist_item.dart';
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
  DateTime? _selectedStartDate; // NULLABLE: defaults to NOW() if not set
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  MomentTemplate? _selectedTemplate;
  
  // Wishlist items (only for wishlist type)
  final List<_WishlistItemFormData> _wishlistItems = [];
  
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past dates
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        // Ensure end date is after start date
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
  
  Future<void> _createMoment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final targetAmount = double.parse(_targetAmountController.text);
      
      // Create the moment first
      final moment = await ref.read(momentsRepoProvider).createMoment(
        groupId: widget.groupId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        targetAmount: targetAmount,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
      
      // If wishlist type, create all wishlist items
      if (_selectedType == 'wishlist' && _wishlistItems.isNotEmpty) {
        for (final item in _wishlistItems) {
          try {
            await ref.read(momentsRepoProvider).addWishlistItem(
              momentId: moment.id,
              name: item.name,
              description: item.description?.isEmpty ?? true ? null : item.description,
              price: item.price,
              link: item.link?.isEmpty ?? true ? null : item.link,
              imageUrl: item.imageUrl?.isEmpty ?? true ? null : item.imageUrl,
              quantity: item.quantity,
              priority: item.priority,
            );
          } catch (e) {
            developer.log('Error adding wishlist item: $e');
            // Continue with other items even if one fails
          }
        }
      }
      
      if (mounted) {
        // Invalidate moments list to refresh
        if (widget.groupId != null) {
          ref.invalidate(momentsProvider(widget.groupId));
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedType == 'wishlist' && _wishlistItems.isNotEmpty
                ? 'Moment created with ${_wishlistItems.length} item(s)!'
                : 'Moment created successfully!'),
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
                                  _selectedStartDate = DateTime.now();
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
                    ButtonSegment(value: 'wishlist', label: Text('Wishlist'), icon: Icon(Icons.shopping_cart)),
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
                
                // Wishlist Items Section (only for wishlist type)
                if (_selectedType == 'wishlist') ...[
                  const SizedBox(height: 24),
                  _buildWishlistItemsSection(),
                ],
                
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
  
  Widget _buildWishlistItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wishlist Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _wishlistItems.add(_WishlistItemFormData());
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_wishlistItems.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No items added yet. Click "Add Item" to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MomentraColors.lightGray,
                  ),
                ),
              ),
            ),
          )
        else
          ...List.generate(_wishlistItems.length, (index) {
            return _WishlistItemForm(
              key: ValueKey(index),
              item: _wishlistItems[index],
              index: index,
              onChanged: (item) {
                setState(() {
                  _wishlistItems[index] = item;
                });
              },
              onDelete: () {
                setState(() {
                  _wishlistItems.removeAt(index);
                });
              },
            );
          }),
      ],
    );
  }
}

// Data class for wishlist item form data
class _WishlistItemFormData {
  String name;
  String? description;
  double? price;
  String? link;
  String? imageUrl;
  int quantity;
  String priority;

  _WishlistItemFormData({
    this.name = '',
    this.description,
    this.price,
    this.link,
    this.imageUrl,
    this.quantity = 1,
    this.priority = 'medium',
  });
}

// Widget for editing a single wishlist item in the form
class _WishlistItemForm extends StatefulWidget {
  final _WishlistItemFormData item;
  final int index;
  final ValueChanged<_WishlistItemFormData> onChanged;
  final VoidCallback onDelete;

  const _WishlistItemForm({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_WishlistItemForm> createState() => __WishlistItemFormState();
}

class __WishlistItemFormState extends State<_WishlistItemForm> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _linkController;
  late TextEditingController _imageUrlController;
  late TextEditingController _quantityController;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _priceController = TextEditingController(text: widget.item.price?.toStringAsFixed(0) ?? '');
    _linkController = TextEditingController(text: widget.item.link ?? '');
    _imageUrlController = TextEditingController(text: widget.item.imageUrl ?? '');
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _priority = widget.item.priority;
    
    // Add listeners to update parent
    _nameController.addListener(_updateItem);
    _descriptionController.addListener(_updateItem);
    _priceController.addListener(_updateItem);
    _linkController.addListener(_updateItem);
    _imageUrlController.addListener(_updateItem);
    _quantityController.addListener(_updateItem);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateItem() {
    widget.onChanged(_WishlistItemFormData(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      price: _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim()),
      link: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
      priority: _priority,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          widget.item.name.isEmpty ? 'Item ${widget.index + 1}' : widget.item.name,
          style: TextStyle(
            fontWeight: widget.item.name.isEmpty ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: widget.item.price != null
            ? Text('₹${(widget.item.price! * widget.item.quantity).toStringAsFixed(0)}')
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: widget.onDelete,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., iPhone 15 Pro',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add details about this item',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Price and Quantity Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (optional)',
                          hintText: '0',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: '1',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Priority
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'low', label: Text('Low')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _priority = newSelection.first;
                      _updateItem();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Link
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link (optional)',
                    hintText: 'https://example.com/product',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                
                // Image URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.image),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

