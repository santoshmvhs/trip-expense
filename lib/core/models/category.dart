class Category {
  final String id;
  final String name;
  final String? icon;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
      };
}

class Subcategory {
  final String id;
  final String categoryId;
  final String name;
  final int sortOrder;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.sortOrder,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'sort_order': sortOrder,
      };
}

