class MomentWishlistItem {
  final String id;
  final String momentId;
  final String name;
  final String? description;
  final double? price;
  final String? link;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'wanted', 'purchased', 'fulfilled'
  final String? imageUrl;
  final int quantity;
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final String? contributionId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  MomentWishlistItem({
    required this.id,
    required this.momentId,
    required this.name,
    this.description,
    this.price,
    this.link,
    required this.priority,
    required this.status,
    this.imageUrl,
    required this.quantity,
    this.purchasedBy,
    this.purchasedAt,
    this.contributionId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory MomentWishlistItem.fromJson(Map<String, dynamic> json) {
    return MomentWishlistItem(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      link: json['link'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'wanted',
      imageUrl: json['image_url'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      purchasedBy: json['purchased_by'] as String?,
      purchasedAt: json['purchased_at'] != null
          ? DateTime.parse(json['purchased_at'] as String)
          : null,
      contributionId: json['contribution_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'moment_id': momentId,
      'name': name,
      'description': description,
      'price': price,
      'link': link,
      'priority': priority,
      'status': status,
      'image_url': imageUrl,
      'quantity': quantity,
      'purchased_by': purchasedBy,
      'purchased_at': purchasedAt?.toIso8601String(),
      'contribution_id': contributionId,
    };
  }
  
  MomentWishlistItem copyWith({
    String? id,
    String? momentId,
    String? name,
    String? description,
    double? price,
    String? link,
    String? priority,
    String? status,
    String? imageUrl,
    int? quantity,
    String? purchasedBy,
    DateTime? purchasedAt,
    String? contributionId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MomentWishlistItem(
      id: id ?? this.id,
      momentId: momentId ?? this.momentId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      link: link ?? this.link,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      contributionId: contributionId ?? this.contributionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  double get totalPrice => (price ?? 0.0) * quantity;
  
  bool get isPurchased => status == 'purchased' || status == 'fulfilled';
}

