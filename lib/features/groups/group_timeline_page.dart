import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/activity_providers.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/models/group_activity.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/momentra_logo_appbar.dart';

class GroupTimelinePage extends ConsumerWidget {
  final String groupId;

  const GroupTimelinePage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActivities = ref.watch(groupActivitiesProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(groupActivitiesProvider(groupId));
            },
          ),
        ],
      ),
      body: asyncActivities.when(
        data: (activities) {
          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activities will appear here as members make changes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group activities by date
          final groupedActivities = <String, List<GroupActivity>>{};
          for (final activity in activities) {
            final dateKey = DateFormat('yyyy-MM-dd').format(activity.createdAt);
            groupedActivities.putIfAbsent(dateKey, () => []).add(activity);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupActivitiesProvider(groupId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedActivities.length,
              itemBuilder: (context, index) {
                final dateKey = groupedActivities.keys.elementAt(index);
                final dateActivities = groupedActivities[dateKey]!;
                final date = DateTime.parse(dateKey);
                final isToday = dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());
                final isYesterday = dateKey ==
                    DateFormat('yyyy-MM-dd')
                        .format(DateTime.now().subtract(const Duration(days: 1)));

                String dateLabel;
                if (isToday) {
                  dateLabel = 'Today';
                } else if (isYesterday) {
                  dateLabel = 'Yesterday';
                } else {
                  dateLabel = DateFormat('MMM d, y').format(date);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateLabel,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ...dateActivities.map((activity) => _buildActivityItem(
                          context,
                          ref,
                          activity,
                          isFirst: dateActivities.indexOf(activity) == 0,
                          isLast: dateActivities.indexOf(activity) ==
                              dateActivities.length - 1,
                        )),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Error loading timeline'),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    WidgetRef ref,
    GroupActivity activity, {
    required bool isFirst,
    required bool isLast,
  }) {
    return Builder(
      builder: (context) {
        // Get user name
        final asyncMembers = ref.watch(groupMembersProvider(activity.groupId));
        String userName = activity.userId.substring(0, 8) + '...';
        try {
          final members = asyncMembers.value;
          if (members != null) {
            final member = members.firstWhere(
              (m) => m['user_id'] == activity.userId,
              orElse: () => <String, dynamic>{'name': userName},
            );
            userName = member['name'] as String;
          }
        } catch (e) {
          // Use default userName
        }

        return Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Activity content
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activity.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activity.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Text(
                              DateFormat('h:mm a').format(activity.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        if (activity.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            activity.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                userName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        // Action buttons for expense activities
                        if (activity.isExpenseActivity && activity.entityId != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              context.push(
                                  '/shell/group/${activity.groupId}/expense/${activity.entityId}');
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Expense'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

