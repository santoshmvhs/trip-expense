class GuidanceNudge {
  final String message;
  final String priority; // low, medium, high
  
  GuidanceNudge({
    required this.message,
    required this.priority,
  });
  
  factory GuidanceNudge.fromJson(Map<String, dynamic> json) {
    return GuidanceNudge(
      message: json['message'],
      priority: json['priority'] ?? 'medium',
    );
  }
}

class Guidance {
  final List<GuidanceNudge> nudges;
  
  Guidance({required this.nudges});
  
  factory Guidance.fromJson(Map<String, dynamic> json) {
    return Guidance(
      nudges: (json['nudges'] as List<dynamic>?)
          ?.map((n) => GuidanceNudge.fromJson(n))
          .toList() ?? [],
    );
  }
}

