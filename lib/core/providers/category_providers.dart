import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/categories_repo.dart';
import '../models/category.dart';

final categoriesRepoProvider = Provider((_) => CategoriesRepo());

final categoriesProvider = FutureProvider((ref) {
  // Keep data alive to cache it and avoid re-fetching
  ref.keepAlive();
  return ref.watch(categoriesRepoProvider).getCategories();
});

final subcategoriesProvider = FutureProvider.family((ref, String categoryId) {
  return ref.watch(categoriesRepoProvider).getSubcategories(categoryId);
});

final allSubcategoriesProvider = FutureProvider((ref) {
  return ref.watch(categoriesRepoProvider).getAllSubcategories();
});

// Helper provider to get subcategories by category name (for backward compatibility)
final subcategoriesByNameProvider = FutureProvider.family((ref, String categoryName) async {
  final categories = await ref.watch(categoriesProvider.future);
  final category = categories.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => throw Exception('Category not found: $categoryName'),
  );
  return ref.watch(subcategoriesProvider(category.id).future);
});

