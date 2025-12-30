import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/moment_providers.dart';
import '../../core/models/moment.dart';
import '../../widgets/moment_health_badge.dart';
import '../../widgets/moment_progress_card.dart';
import '../../widgets/moment_guidance_card.dart';
import '../../theme/app_theme.dart';
import 'add_participant_dialog.dart';
import 'add_contribution_dialog.dart';
import 'moment_notifications_settings.dart';

class MomentDetailPage extends ConsumerWidget {
  final String momentId;
  final String? groupId; // For navigation back
  
  const MomentDetailPage({
    super.key,
    required this.momentId,
    this.groupId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMoment = ref.watch(momentProvider(momentId));
    final asyncHealth = ref.watch(momentHealthProvider(momentId));
    final asyncGuidance = ref.watch(momentGuidanceProvider(momentId));
    final asyncParticipants = ref.watch(momentParticipantsProvider(momentId));
    final asyncContributions = ref.watch(momentContributionsProvider(momentId));
    
    return Scaffold(
      appBar: AppBar(
        title: asyncMoment.when(
          data: (moment) => Text(moment.title),
          loading: () => const Text('Moment'),
          error: (_, __) => const Text('Moment'),
        ),
        actions: [
          asyncMoment.when(
            data: (moment) {
              return PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share Moment'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'notifications',
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined),
                        SizedBox(width: 8),
                        Text('Notification Settings'),
                      ],
                    ),
                  ),
                  if (moment.lifecycleState != 'COMPLETED')
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('Close Moment'),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) async {
                  if (value == 'share') {
                    context.push('/shell/group/${groupId ?? 'none'}/moment/$momentId/share');
                  } else if (value == 'notifications') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MomentNotificationsSettings(momentId: momentId),
                      ),
                    );
                  } else if (value == 'close') {
                    try {
                      await ref.read(momentsRepoProvider).closeMoment(momentId);
                      if (context.mounted) {
                        ref.invalidate(momentProvider(momentId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moment closed')),
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
                },
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(momentProvider(momentId));
          ref.invalidate(momentHealthProvider(momentId));
          ref.invalidate(momentGuidanceProvider(momentId));
          ref.invalidate(momentParticipantsProvider(momentId));
          ref.invalidate(momentContributionsProvider(momentId));
        },
        child: asyncMoment.when(
          data: (moment) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header with health badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moment.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (moment.description != null && moment.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              moment.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    asyncHealth.when(
                      data: (health) => MomentHealthBadge(
                        status: health.status,
                        label: health.label,
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Progress Card
                MomentProgressCard(moment: moment),
                const SizedBox(height: 16),
                
                // Guidance
                asyncGuidance.when(
                  data: (guidance) => MomentGuidanceCard(guidance: guidance),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                
                // Participants
                asyncParticipants.when(
                  data: (participants) {
                    if (participants.isEmpty) {
                      return const SizedBox();
                    }
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
                                  'Participants',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AddParticipantDialog(momentId: momentId),
                                    );
                                  },
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('Invite'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...participants.map((p) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: MomentraColors.warmOrange.withValues(alpha: 0.2),
                                child: Text(
                                  p.displayNameOrEmail[0].toUpperCase(),
                                  style: const TextStyle(color: MomentraColors.warmOrange),
                                ),
                              ),
                              title: Text(p.displayNameOrEmail),
                              subtitle: Text(p.role),
                              trailing: p.role == 'creator'
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: MomentraColors.warmOrange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Creator',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: MomentraColors.warmOrange,
                                        ),
                                      ),
                                    )
                                  : null,
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                
                // Contributions
                asyncContributions.when(
                  data: (contributions) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Contributions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (contributions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No contributions yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: MomentraColors.lightGray,
                                  ),
                                ),
                              )
                            else
                              ...contributions.take(10).map((contribution) {
                                final participant = asyncParticipants.maybeWhen(
                                  data: (participants) => participants.firstWhere(
                                    (p) => p.id == contribution.participantId || 
                                           p.email == contribution.participantId,
                                    orElse: () => participants.first,
                                  ),
                                  orElse: () => null,
                                );
                                
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: MomentraColors.surfaceVariant,
                                    child: Text(
                                      participant?.displayNameOrEmail[0].toUpperCase() ?? '?',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  title: Text(participant?.displayNameOrEmail ?? contribution.participantId),
                                  subtitle: Text(
                                    contribution.note ?? 'Contribution',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: Text(
                                    '₹${contribution.amount.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: MomentraColors.warmOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
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
                    ref.invalidate(momentProvider(momentId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
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
                    showDialog(
                      context: context,
                      builder: (_) => AddParticipantDialog(momentId: momentId),
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
                    showDialog(
                      context: context,
                      builder: (_) => AddContributionDialog(momentId: momentId),
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
}

