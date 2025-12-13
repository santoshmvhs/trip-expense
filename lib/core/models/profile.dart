class Profile {
  final String id;
  final String name;
  final String defaultCurrency;
  final String? photoUrl;

  Profile({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    this.photoUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        defaultCurrency: (json['default_currency'] as String?) ?? 'INR',
        photoUrl: json['photo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'default_currency': defaultCurrency,
        'photo_url': photoUrl,
      };
}

