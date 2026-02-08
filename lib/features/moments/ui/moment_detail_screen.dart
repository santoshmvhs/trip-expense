import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/health_badge.dart';
import '../../../../widgets/progress_card.dart';
import '../../../../widgets/guidance_card.dart';
import '../../../../widgets/participant_list.dart';
import '../../../../app/theme.dart';
import '../state/moment_detail_provider.dart';
import '../data/repo/moments_repo.dart';
import '../state/moments_list_provider.dart';
import 'invite_screen.dart';
import 'add_contribution_screen.dart';
import 'close_moment_screen.dart';
import 'package:intl/intl.dart';

class MomentDetailScreen extends ConsumerWidget {
  final String momentId;
  
  const MomentDetailScreen({super.key, required this.momentId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(momentDetailProvider(momentId));
    
    return Scaffold(
      backgroundColor: MomentraColors.charcoal,
      appBar: AppBar(
        title: const Text('Moment Details'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'close',
                child: Text('Close Moment'),
              ),
            ],
            onSelected: (value) {
              if (value == 'close') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CloseMomentScreen(momentId: momentId),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          final moment = detail.moment;
          final health = detail.health;
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(momentDetailProvider(momentId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moment.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            moment.type.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (health != null)
                      HealthBadge(
                        status: health.status,
                        label: health.label,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Progress Card
                ProgressCard(
                  currentAmount: moment.currentAmount,
                  targetAmount: moment.targetAmount,
                  endDate: moment.endDate,
                ),
                const SizedBox(height: 16),
                
                // Health Details
                if (health != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Funding: ${(health.fundingRatio * 100).toStringAsFixed(0)}%'),
                          Text('Expected: ${(health.expectedFundingRatio * 100).toStringAsFixed(0)}%'),
                          Text('Gap: ${(health.gap * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Guidance
                GuidanceCard(guidance: detail.guidance),
                const SizedBox(height: 16),
                
                // Participants
                ParticipantList(
                  participants: detail.participants,
                  participantTotals: _calculateParticipantTotals(detail),
                ),
                const SizedBox(height: 16),
                
                // Contributions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (detail.contributions.isEmpty)
                          const Text('No contributions yet'),
                        ...detail.contributions.take(5).map((contribution) {
                          final participant = detail.participants.firstWhere(
                            (p) => p.id == contribution.participantId,
                            orElse: () => detail.participants.first,
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(participant.displayNameOrEmail[0].toUpperCase()),
                            ),
                            title: Text(participant.displayNameOrEmail),
                            subtitle: Text(contribution.note ?? 'Contribution'),
                            trailing: Text(
                              '₹${contribution.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            dense: true,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
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
                  ref.invalidate(momentDetailProvider(momentId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InviteScreen(momentId: momentId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddContributionScreen(momentId: momentId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Contribute'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Map<String, double> _calculateParticipantTotals(detail) {
    final Map<String, double> totals = {};
    for (final contribution in detail.contributions) {
      totals[contribution.participantId] = 
          (totals[contribution.participantId] ?? 0.0) + contribution.amount;
    }
    return totals;
  }
}

