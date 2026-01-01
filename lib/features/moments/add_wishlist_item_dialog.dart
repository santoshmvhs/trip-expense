import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment_wishlist_item.dart';
import '../../theme/app_theme.dart';

class AddWishlistItemDialog extends ConsumerStatefulWidget {
  final String momentId;
  final MomentWishlistItem? item; // If provided, edit mode

  const AddWishlistItemDialog({
    super.key,
    required this.momentId,
    this.item,
  });

  @override
  ConsumerState<AddWishlistItemDialog> createState() => _AddWishlistItemDialogState();
}

class _AddWishlistItemDialogState extends ConsumerState<AddWishlistItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _quantityController = TextEditingController();
  
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description ?? '';
      _priceController.text = widget.item!.price?.toStringAsFixed(0) ?? '';
      _linkController.text = widget.item!.link ?? '';
      _imageUrlController.text = widget.item!.imageUrl ?? '';
      _quantityController.text = widget.item!.quantity.toString();
      _selectedPriority = widget.item!.priority;
    } else {
      _quantityController.text = '1';
    }
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      
      if (widget.item != null) {
        // Update existing item
        await ref.read(momentsRepoProvider).updateWishlistItem(
          widget.item!.id,
          {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            'price': price,
            'link': _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
            'image_url': _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
            'quantity': quantity,
            'priority': _selectedPriority,
          },
        );
      } else {
        // Create new item
        await ref.read(momentsRepoProvider).addWishlistItem(
          momentId: widget.momentId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          link: _linkController.text.trim().isEmpty
              ? null
              : _linkController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          quantity: quantity,
          priority: _selectedPriority,
        );
      }
      
      if (mounted) {
        ref.invalidate(momentWishlistItemsProvider(widget.momentId));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item != null
                ? 'Wishlist item updated'
                : 'Wishlist item added'),
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
                  widget.item != null ? 'Edit Wishlist Item' : 'Add Wishlist Item',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., iPhone 15 Pro',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name';
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
                    hintText: 'Add details about this item',
                  ),
                  maxLines: 3,
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
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Invalid price';
                            }
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty < 1) {
                            return 'Must be at least 1';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Priority
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'low', label: Text('Low')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {_selectedPriority},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedPriority = newSelection.first;
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
                        onPressed: _isLoading ? null : _saveItem,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.item != null ? 'Update' : 'Add'),
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

