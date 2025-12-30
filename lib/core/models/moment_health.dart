class MomentHealth {
  final String status; // green, yellow, red
  final String label; // on-track, at-risk, critical
  final double gap;
  final double fundingRatio;
  final double expectedFundingRatio;
  
  MomentHealth({
    required this.status,
    required this.label,
    required this.gap,
    required this.fundingRatio,
    required this.expectedFundingRatio,
  });
  
  factory MomentHealth.fromJson(Map<String, dynamic> json) {
    return MomentHealth(
      status: json['status'] as String,
      label: json['label'] as String,
      gap: (json['gap'] ?? 0.0).toDouble(),
      fundingRatio: (json['funding_ratio'] ?? json['fundingRatio'] ?? 0.0).toDouble(),
      expectedFundingRatio: (json['expected_funding_ratio'] ?? json['expectedFundingRatio'] ?? 0.0).toDouble(),
    );
  }
}

