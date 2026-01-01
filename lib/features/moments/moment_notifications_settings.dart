import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/momentra_logo_appbar.dart';
import '../../theme/app_theme.dart';

/// Notification preferences for moments
/// This is a UI-only implementation. Backend notification infrastructure would be added later.
class MomentNotificationsSettings extends ConsumerStatefulWidget {
  final String momentId;
  
  const MomentNotificationsSettings({
    super.key,
    required this.momentId,
  });
  
  @override
  ConsumerState<MomentNotificationsSettings> createState() => _MomentNotificationsSettingsState();
}

class _MomentNotificationsSettingsState extends ConsumerState<MomentNotificationsSettings> {
  bool _notifyOnContribution = true;
  bool _notifyOnParticipantAdded = true;
  bool _notifyOnHealthChange = true;
  bool _notifyOnTargetReached = true;
  bool _notifyOnDeadlineApproaching = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MomentraLogoAppBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moment Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose what notifications you want to receive for this moment',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('New Contributions'),
            subtitle: const Text('Get notified when someone adds a contribution'),
            value: _notifyOnContribution,
            onChanged: (value) {
              setState(() {
                _notifyOnContribution = value;
              });
              // TODO: Save to backend
            },
          ),
          SwitchListTile(
            title: const Text('New Participants'),
            subtitle: const Text('Get notified when someone joins the moment'),
            value: _notifyOnParticipantAdded,
            onChanged: (value) {
              setState(() {
                _notifyOnParticipantAdded = value;
              });
              // TODO: Save to backend
            },
          ),
          SwitchListTile(
            title: const Text('Health Status Changes'),
            subtitle: const Text('Get notified when moment health changes (e.g., at-risk)'),
            value: _notifyOnHealthChange,
            onChanged: (value) {
              setState(() {
                _notifyOnHealthChange = value;
              });
              // TODO: Save to backend
            },
          ),
          SwitchListTile(
            title: const Text('Target Reached'),
            subtitle: const Text('Get notified when the moment reaches its target'),
            value: _notifyOnTargetReached,
            onChanged: (value) {
              setState(() {
                _notifyOnTargetReached = value;
              });
              // TODO: Save to backend
            },
          ),
          SwitchListTile(
            title: const Text('Deadline Approaching'),
            subtitle: const Text('Get notified when the deadline is approaching'),
            value: _notifyOnDeadlineApproaching,
            onChanged: (value) {
              setState(() {
                _notifyOnDeadlineApproaching = value;
              });
              // TODO: Save to backend
            },
          ),
          const SizedBox(height: 24),
          Card(
            color: MomentraColors.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: MomentraColors.warmOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notification preferences are saved locally. Backend integration coming soon.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

