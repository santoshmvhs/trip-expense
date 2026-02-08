class HealthStatus {
  final String status; // green, yellow, red
  final String label; // on-track, at-risk, critical
  final double gap;
  final double fundingRatio;
  final double expectedFundingRatio;
  
  HealthStatus({
    required this.status,
    required this.label,
    required this.gap,
    required this.fundingRatio,
    required this.expectedFundingRatio,
  });
  
  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'],
      label: json['label'],
      gap: (json['gap'] ?? 0.0).toDouble(),
      fundingRatio: (json['fundingRatio'] ?? 0.0).toDouble(),
      expectedFundingRatio: (json['expectedFundingRatio'] ?? 0.0).toDouble(),
    );
  }
}

