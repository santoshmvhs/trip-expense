import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/momentra_logo_appbar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      await _loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
        actions: [
          if (_notifications.any((n) => !n['is_read']))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] as bool? ?? false;

                      return Dismissible(
                        key: Key(notification['id'] as String),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await _supabase
                              .from('notifications')
                              .delete()
                              .eq('id', notification['id']);
                          _loadNotifications();
                        },
                        child: Card(
                          color: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Icon(
                                _getNotificationIcon(notification['type'] as String?),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notification['title'] as String? ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['message'] as String? ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, y • h:mm a').format(
                                    DateTime.parse(notification['created_at'] as String),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: isRead
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.circle, size: 12),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () => _markAsRead(notification['id'] as String),
                                  ),
                            onTap: () {
                              _markAsRead(notification['id'] as String);
                              // Navigate to relevant screen based on notification type
                              final metadata = notification['metadata'] as Map<String, dynamic>?;
                              if (metadata != null) {
                                final groupId = metadata['group_id'] as String?;
                                final entityType = metadata['entity_type'] as String?;
                                final entityId = metadata['entity_id'] as String?;
                                
                                if (groupId != null) {
                                  if (entityType == 'expense' && entityId != null) {
                                    context.push('/shell/group/$groupId/expense/$entityId');
                                  } else {
                                    context.push('/shell/group/$groupId/timeline');
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

      IconData _getNotificationIcon(String? type) {
        switch (type) {
          case 'expense_added':
            return Icons.receipt;
          case 'expense_updated':
            return Icons.edit;
          case 'expense_deleted':
            return Icons.delete;
          case 'payment_received':
            return Icons.payment;
          case 'group_invite':
            return Icons.group_add;
          case 'member_added':
            return Icons.person_add;
          case 'member_removed':
            return Icons.person_remove;
          case 'group_activity':
            return Icons.timeline;
          default:
            return Icons.notifications;
        }
      }
}

