import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/categories_repo.dart';
import '../models/category.dart';

final categoriesRepoProvider = Provider((_) => CategoriesRepo());

// Simple cached provider: Fetch all categories and subcategories once, cache forever
final allCategoriesDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Keep data alive forever - categories rarely change
  ref.keepAlive();
  
  final repo = ref.watch(categoriesRepoProvider);
  // Fetch both in parallel for maximum speed
  final results = await Future.wait([
    repo.getCategories(),
    repo.getAllSubcategories(),
  ]);
  
  final categories = results[0] as List<Category>;
  final allSubcategories = results[1] as List<Subcategory>;
  
  // Group subcategories by category_id
  final groupedSubcategories = <String, List<Subcategory>>{};
  for (final subcategory in allSubcategories) {
    if (!groupedSubcategories.containsKey(subcategory.categoryId)) {
      groupedSubcategories[subcategory.categoryId] = [];
    }
    groupedSubcategories[subcategory.categoryId]!.add(subcategory);
  }
  
  return {
    'categories': categories,
    'subcategoriesMap': groupedSubcategories,
  };
});

// Simple provider that just returns categories (from cached data)
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final data = await ref.watch(allCategoriesDataProvider.future);
  return data['categories'] as List<Category>;
});

// Simple provider that returns subcategories for a category (from cached data)
final subcategoriesProvider = FutureProvider.family<List<Subcategory>, String>((ref, String categoryId) async {
  final data = await ref.watch(allCategoriesDataProvider.future);
  final subcategoriesMap = data['subcategoriesMap'] as Map<String, List<Subcategory>>;
  return subcategoriesMap[categoryId] ?? [];
});

final allSubcategoriesProvider = FutureProvider<List<Subcategory>>((ref) async {
  final data = await ref.watch(allCategoriesDataProvider.future);
  final subcategoriesMap = data['subcategoriesMap'] as Map<String, List<Subcategory>>;
  return subcategoriesMap.values.expand((list) => list).toList();
});

// Helper provider to get subcategories by category name (for backward compatibility)
final subcategoriesByNameProvider = FutureProvider.family<List<Subcategory>, String>((ref, String categoryName) async {
  final data = await ref.watch(allCategoriesDataProvider.future);
  final categories = data['categories'] as List<Category>;
  final subcategoriesMap = data['subcategoriesMap'] as Map<String, List<Subcategory>>;
  final category = categories.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => throw Exception('Category not found: $categoryName'),
  );
  return subcategoriesMap[category.id] ?? [];
});

