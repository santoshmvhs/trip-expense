import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment_wishlist_item.dart';
import '../../theme/app_theme.dart';
import 'add_wishlist_item_dialog.dart';

class WishlistItemsSection extends ConsumerWidget {
  final String momentId;
  final bool canEdit;

  const WishlistItemsSection({
    super.key,
    required this.momentId,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(momentWishlistItemsProvider(momentId));

    return asyncItems.when(
      data: (items) {
        if (items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: MomentraColors.lightGray,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No wishlist items yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: MomentraColors.lightGray,
                    ),
                  ),
                  if (canEdit) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddWishlistItemDialog(momentId: momentId),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final wantedItems = items.where((i) => i.status == 'wanted').toList();
        final purchasedItems = items.where((i) => i.status == 'purchased').toList();
        final fulfilledItems = items.where((i) => i.status == 'fulfilled').toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AddWishlistItemDialog(momentId: momentId),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Wanted items
                if (wantedItems.isNotEmpty) ...[
                  _buildItemList(context, ref, wantedItems, 'Wanted', canEdit),
                  if (purchasedItems.isNotEmpty || fulfilledItems.isNotEmpty)
                    const SizedBox(height: 16),
                ],
                
                // Purchased items
                if (purchasedItems.isNotEmpty) ...[
                  _buildItemList(context, ref, purchasedItems, 'Purchased', canEdit),
                  if (fulfilledItems.isNotEmpty) const SizedBox(height: 16),
                ],
                
                // Fulfilled items
                if (fulfilledItems.isNotEmpty)
                  _buildItemList(context, ref, fulfilledItems, 'Fulfilled', canEdit),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildItemList(
    BuildContext context,
    WidgetRef ref,
    List<MomentWishlistItem> items,
    String sectionTitle,
    bool canEdit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: MomentraColors.lightGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _WishlistItemTile(
          item: item,
          canEdit: canEdit,
          onUpdated: () {
            ref.invalidate(momentWishlistItemsProvider(momentId));
          },
        )),
      ],
    );
  }
}

class _WishlistItemTile extends ConsumerWidget {
  final MomentWishlistItem item;
  final bool canEdit;
  final VoidCallback onUpdated;

  const _WishlistItemTile({
    required this.item,
    required this.canEdit,
    required this.onUpdated,
  });

  Future<void> _markPurchased(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(momentsRepoProvider).markWishlistItemPurchased(
        itemId: item.id,
      );
      onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marked as purchased')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markFulfilled(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(momentsRepoProvider).markWishlistItemFulfilled(item.id);
      onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marked as fulfilled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(momentsRepoProvider).deleteWishlistItem(item.id);
        onUpdated();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return MomentraColors.lightGray;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.shopping_bag,
                    color: MomentraColors.lightGray,
                  ),
                ),
              )
            : Icon(
                Icons.shopping_bag,
                color: MomentraColors.lightGray,
              ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty) ...[
              Text(item.description!),
              const SizedBox(height: 4),
            ],
            Wrap(
              spacing: 8,
              children: [
                if (item.price != null)
                  Chip(
                    label: Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  label: Text(
                    item.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getPriorityColor(item.priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: _getPriorityColor(item.priority)),
                ),
                if (item.quantity > 1)
                  Chip(
                    label: Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
        trailing: canEdit
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  if (item.link != null)
                    const PopupMenuItem(
                      value: 'open_link',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new, size: 18),
                          SizedBox(width: 8),
                          Text('Open Link'),
                        ],
                      ),
                    ),
                  if (item.status == 'wanted')
                    const PopupMenuItem(
                      value: 'mark_purchased',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Mark as Purchased'),
                        ],
                      ),
                    ),
                  if (item.status == 'purchased')
                    const PopupMenuItem(
                      value: 'mark_fulfilled',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 18),
                          SizedBox(width: 8),
                          Text('Mark as Fulfilled'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'open_link' && item.link != null) {
                    final uri = Uri.parse(item.link!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } else if (value == 'mark_purchased') {
                    _markPurchased(context, ref);
                  } else if (value == 'mark_fulfilled') {
                    _markFulfilled(context, ref);
                  } else if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) => AddWishlistItemDialog(
                        momentId: item.momentId,
                        item: item,
                      ),
                    );
                  } else if (value == 'delete') {
                    _deleteItem(context, ref);
                  }
                },
              )
            : item.link != null
                ? IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final uri = Uri.parse(item.link!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  )
                : null,
      ),
    );
  }
}

