import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/categories_repo.dart';
import '../models/category.dart';

final categoriesRepoProvider = Provider((_) => CategoriesRepo());

// StateNotifier that loads and caches categories immediately
class CategoriesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  CategoriesNotifier(this._repo) : super(const AsyncValue.loading()) {
    _loadData();
  }

  final CategoriesRepo _repo;

  Future<void> _loadData() async {
    try {
      // Fetch both in parallel for maximum speed
      final results = await Future.wait([
        _repo.getCategories(),
        _repo.getAllSubcategories(),
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
      
      state = AsyncValue.data({
        'categories': categories,
        'subcategoriesMap': groupedSubcategories,
      });
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Provider that loads immediately and caches forever
final categoriesDataProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  ref.keepAlive(); // Keep alive forever
  return CategoriesNotifier(ref.watch(categoriesRepoProvider));
});

// Simple provider that just returns categories (from cached data)
final categoriesProvider = Provider<List<Category>>((ref) {
  final data = ref.watch(categoriesDataProvider);
  return data.when(
    data: (map) => map['categories'] as List<Category>,
    loading: () => [],
    error: (_, __) => [],
  );
});

// Simple provider that returns subcategories for a category (from cached data)
final subcategoriesProvider = Provider.family<List<Subcategory>, String>((ref, String categoryId) {
  final data = ref.watch(categoriesDataProvider);
  return data.when(
    data: (map) {
      final subcategoriesMap = map['subcategoriesMap'] as Map<String, List<Subcategory>>;
      return subcategoriesMap[categoryId] ?? [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final allSubcategoriesProvider = Provider<List<Subcategory>>((ref) {
  final data = ref.watch(categoriesDataProvider);
  return data.when(
    data: (map) {
      final subcategoriesMap = map['subcategoriesMap'] as Map<String, List<Subcategory>>;
      return subcategoriesMap.values.expand((list) => list).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Helper provider to get subcategories by category name (for backward compatibility)
final subcategoriesByNameProvider = Provider.family<List<Subcategory>, String>((ref, String categoryName) {
  final data = ref.watch(categoriesDataProvider);
  return data.when(
    data: (map) {
      final categories = map['categories'] as List<Category>;
      final subcategoriesMap = map['subcategoriesMap'] as Map<String, List<Subcategory>>;
      try {
        final category = categories.firstWhere(
          (c) => c.name == categoryName,
        );
        return subcategoriesMap[category.id] ?? [];
      } catch (e) {
        return [];
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

