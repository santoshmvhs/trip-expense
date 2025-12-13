class Group {
  final String id;
  final String name;
  final String currency;
  final String createdBy;

  Group({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdBy,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        currency: (json['currency'] as String?) ?? 'INR',
        createdBy: json['created_by'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'created_by': createdBy,
      };
}

