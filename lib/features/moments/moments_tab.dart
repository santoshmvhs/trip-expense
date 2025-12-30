import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment.dart';
import '../../widgets/moment_health_badge.dart';
import '../../widgets/moment_progress_card.dart';
import '../../theme/app_theme.dart';
import 'create_moment_dialog.dart';
import 'moment_detail_page.dart';

class MomentsTab extends ConsumerStatefulWidget {
  final String groupId;
  
  const MomentsTab({
    super.key,
    required this.groupId,
  });
  
  @override
  ConsumerState<MomentsTab> createState() => _MomentsTabState();
}

class _MomentsTabState extends ConsumerState<MomentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedType; // 'trip', 'gift', 'goal', or null for all
  String? _selectedStatus; // 'active', 'completed', or null for all
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  List<Moment> _filterMoments(List<Moment> moments) {
    return moments.where((moment) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = moment.title.toLowerCase().contains(query);
        final matchesDescription = (moment.description ?? '').toLowerCase().contains(query);
        if (!matchesTitle && !matchesDescription) return false;
      }
      
      // Type filter
      if (_selectedType != null && moment.type != _selectedType) {
        return false;
      }
      
      // Status filter
      if (_selectedStatus != null) {
        if (_selectedStatus == 'active' && moment.lifecycleState == 'COMPLETED') {
          return false;
        }
        if (_selectedStatus == 'completed' && moment.lifecycleState != 'COMPLETED') {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final asyncMoments = ref.watch(momentsProvider(widget.groupId));
    
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: MomentraColors.surface,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search moments...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: MomentraColors.charcoal,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Type Filters
                    FilterChip(
                      label: const Text('All Types'),
                      selected: _selectedType == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Trip'),
                      selected: _selectedType == 'trip',
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? 'trip' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Gift'),
                      selected: _selectedType == 'gift',
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? 'gift' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Goal'),
                      selected: _selectedType == 'goal',
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? 'goal' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    // Status Filters
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Active'),
                      selected: _selectedStatus == 'active',
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? 'active' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: _selectedStatus == 'completed',
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? 'completed' : null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Moments List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(momentsProvider(widget.groupId));
            },
            child: asyncMoments.when(
              data: (moments) {
                final filteredMoments = _filterMoments(moments);
                
                if (filteredMoments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: MomentraColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchQuery.isNotEmpty || _selectedType != null || _selectedStatus != null
                                  ? Icons.search_off
                                  : Icons.flag_outlined,
                              size: 64,
                              color: MomentraColors.warmOrange,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty || _selectedType != null || _selectedStatus != null
                                ? 'No moments match your filters'
                                : 'No moments yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: MomentraColors.lightGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty || _selectedType != null || _selectedStatus != null
                                ? 'Try adjusting your search or filters'
                                : 'Create your first moment to start tracking goals, trips, or gifts',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: MomentraColors.lightGray.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          if (_searchQuery.isNotEmpty || _selectedType != null || _selectedStatus != null) ...[
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _selectedType = null;
                                  _selectedStatus = null;
                                });
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => CreateMomentDialog(groupId: widget.groupId),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create Moment'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                
                final activeMoments = filteredMoments.where((m) => m.lifecycleState != 'COMPLETED').toList();
                final completedMoments = filteredMoments.where((m) => m.lifecycleState == 'COMPLETED').toList();
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (activeMoments.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'Active Moments',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activeMoments.map((moment) => _MomentCard(
                        moment: moment,
                        groupId: widget.groupId,
                        onTap: () {
                          context.push('/shell/group/${widget.groupId}/moment/${moment.id}');
                        },
                      )),
                      const SizedBox(height: 24),
                    ],
                    if (completedMoments.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'Completed',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: MomentraColors.lightGray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...completedMoments.map((moment) => _MomentCard(
                        moment: moment,
                        groupId: widget.groupId,
                        onTap: () {
                          context.push('/shell/group/${widget.groupId}/moment/${moment.id}');
                        },
                      )),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $error', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(momentsProvider(widget.groupId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends ConsumerWidget {
  final Moment moment;
  final String groupId;
  final VoidCallback onTap;
  
  const _MomentCard({
    required this.moment,
    required this.groupId,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHealth = ref.watch(momentHealthProvider(moment.id));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: MomentraColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            moment.type.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MomentraColors.warmOrange,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (moment.lifecycleState != 'COMPLETED')
                        asyncHealth.when(
                          data: (health) => MomentHealthBadge(
                            status: health.status,
                            label: health.label,
                          ),
                          loading: () => const SizedBox(width: 80),
                          error: (_, __) => const SizedBox(),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'share') {
                            context.push('/shell/group/$groupId/moment/${moment.id}/share');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: moment.progressPercentage / 100,
                  minHeight: 8,
                  backgroundColor: MomentraColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    moment.progressPercentage >= 100 
                        ? HealthColors.green 
                        : MomentraColors.warmOrange,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${moment.progressPercentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MomentraColors.warmOrange,
                    ),
                  ),
                  Text(
                    '₹${moment.currentAmount.toStringAsFixed(0)} / ₹${moment.targetAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
