import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../data/repo/moments_repo.dart';
import '../state/moments_list_provider.dart';
import '../../../../widgets/participant_list.dart';
import '../data/models/participant.dart';

class CloseMomentScreen extends ConsumerStatefulWidget {
  final String momentId;
  
  const CloseMomentScreen({super.key, required this.momentId});
  
  @override
  ConsumerState<CloseMomentScreen> createState() => _CloseMomentScreenState();
}

class _CloseMomentScreenState extends ConsumerState<CloseMomentScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _summary;
  
  @override
  void initState() {
    super.initState();
    _loadSummary();
  }
  
  Future<void> _loadSummary() async {
    try {
      final repo = ref.read(momentsRepoProvider);
      final summary = await repo.getMomentSummary(widget.momentId);
      setState(() => _summary = summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: $e')),
        );
      }
    }
  }
  
  Future<void> _closeMoment() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(momentsRepoProvider);
      await repo.closeMoment(widget.momentId);
      
      ref.invalidate(momentsListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment closed')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close moment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Scaffold(
      backgroundColor: MomentraColors.charcoal,
      appBar: AppBar(title: const Text('Close Moment')),
      body: _summary == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Final Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Progress: ${(_summary!['moment']['currentAmount'] / _summary!['moment']['targetAmount'] * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            '${formatter.format(_summary!['moment']['currentAmount'])} / ${formatter.format(_summary!['moment']['targetAmount'])}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_summary!['participants'] != null)
                    ParticipantList(
                      participants: (_summary!['participants'] as List)
                          .map((p) => Participant.fromJson(p))
                          .toList(),
                      participantTotals: Map<String, double>.from(
                        _summary!['participantTotals']?.map(
                          (k, v) => MapEntry(k, (v as num).toDouble()),
                        ) ?? {},
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contributions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(_summary!['contributions'] as List).map((c) {
                            return ListTile(
                              title: Text(c['note'] ?? 'Contribution'),
                              trailing: Text(
                                formatter.format(c['amount']),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              dense: true,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _closeMoment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Close Moment'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

