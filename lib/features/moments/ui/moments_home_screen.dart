import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_store.dart';
import '../../../../widgets/health_badge.dart';
import '../../../../widgets/momentra_logo.dart';
import '../../../../app/theme.dart';
import '../data/models/moment.dart';
import '../state/moments_list_provider.dart';
import 'create_moment_screen.dart';
import 'moment_detail_screen.dart';

class MomentsHomeScreen extends ConsumerWidget {
  const MomentsHomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(momentsListProvider);
    
    return Scaffold(
      backgroundColor: MomentraColors.charcoal,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MomentraLogoSmall(size: 28),
            const SizedBox(width: 12),
            const Text('Momentra'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await LocalStore.clear();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: momentsAsync.when(
        data: (moments) {
          if (moments.isEmpty) {
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
                      child: const MomentraLogo(size: 80, showText: false),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No moments yet',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MomentraColors.lightGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first moment to get started',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateMomentScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Your First Moment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final activeMoments = moments.where((m) => m.lifecycleState != 'COMPLETED').toList();
          final completedMoments = moments.where((m) => m.lifecycleState == 'COMPLETED').toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(momentsListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeMoments.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Active Moments',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activeMoments.map((moment) => _MomentCard(moment: moment)),
                  const SizedBox(height: 32),
                ],
                if (completedMoments.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Completed',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MomentraColors.lightGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...completedMoments.map((moment) => _MomentCard(moment: moment)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(momentsListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateMomentScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Moment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: MomentraColors.warmOrange,
        foregroundColor: MomentraColors.black,
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final Moment moment;
  
  const _MomentCard({required this.moment});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MomentDetailScreen(momentId: moment.id),
            ),
          );
        },
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
                  if (moment.lifecycleState != 'COMPLETED')
                    HealthBadge(
                      status: 'green',
                      label: moment.lifecycleState == 'COMPLETED' ? 'Completed' : 'Active',
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

