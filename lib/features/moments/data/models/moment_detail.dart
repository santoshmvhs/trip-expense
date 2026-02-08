import 'moment.dart';
import 'health.dart';
import 'guidance.dart';
import 'participant.dart';
import 'contribution.dart';

class MomentDetail {
  final Moment moment;
  final HealthStatus? health;
  final Guidance guidance;
  final List<Participant> participants;
  final List<Contribution> contributions;
  
  MomentDetail({
    required this.moment,
    this.health,
    required this.guidance,
    required this.participants,
    required this.contributions,
  });
  
  factory MomentDetail.fromJson(Map<String, dynamic> json) {
    return MomentDetail(
      moment: Moment.fromJson(json['moment']),
      health: json['health'] != null 
          ? HealthStatus.fromJson(json['health'])
          : null,
      guidance: Guidance.fromJson(json['guidance'] ?? {'nudges': []}),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => Participant.fromJson(p))
          .toList() ?? [],
      contributions: (json['contributions'] as List<dynamic>?)
          ?.map((c) => Contribution.fromJson(c))
          .toList() ?? [],
    );
  }
}

