class MomentGuidanceNudge {
  final String message;
  final String priority; // low, medium, high
  
  MomentGuidanceNudge({
    required this.message,
    required this.priority,
  });
  
  factory MomentGuidanceNudge.fromJson(Map<String, dynamic> json) {
    return MomentGuidanceNudge(
      message: json['message'] as String,
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

class MomentGuidance {
  final List<MomentGuidanceNudge> nudges;
  
  MomentGuidance({required this.nudges});
  
  factory MomentGuidance.fromJson(Map<String, dynamic> json) {
    return MomentGuidance(
      nudges: (json['nudges'] as List<dynamic>?)
          ?.map((n) => MomentGuidanceNudge.fromJson(n as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

