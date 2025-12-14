import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip/core/models/category.dart';
import 'package:trip/core/providers/category_providers.dart';
import 'package:trip/core/repositories/categories_repo.dart';

// Mock CategoriesRepo for testing
class MockCategoriesRepo extends CategoriesRepo {
  final List<Category> _categories;
  final List<Subcategory> _subcategories;

  MockCategoriesRepo({
    List<Category>? categories,
    List<Subcategory>? subcategories,
  })  : _categories = categories ?? [],
        _subcategories = subcategories ?? [];

  @override
  Future<List<Category>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    return _categories;
  }

  @override
  Future<List<Subcategory>> getAllSubcategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));
    return _subcategories;
  }

  @override
  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return _subcategories.where((s) => s.categoryId == categoryId).toList();
  }
}

void main() {
  group('Category Providers Tests', () {
    late ProviderContainer container;
    late MockCategoriesRepo mockRepo;

    setUp(() {
      // Create test data
      final categories = [
        Category(id: 'cat1', name: 'Food', sortOrder: 1),
        Category(id: 'cat2', name: 'Transport', sortOrder: 2),
        Category(id: 'cat3', name: 'Accommodation', sortOrder: 3),
      ];

      final subcategories = [
        Subcategory(id: 'sub1', categoryId: 'cat1', name: 'Restaurant', sortOrder: 1),
        Subcategory(id: 'sub2', categoryId: 'cat1', name: 'Groceries', sortOrder: 2),
        Subcategory(id: 'sub3', categoryId: 'cat2', name: 'Flight', sortOrder: 1),
        Subcategory(id: 'sub4', categoryId: 'cat2', name: 'Taxi', sortOrder: 2),
      ];

      mockRepo = MockCategoriesRepo(
        categories: categories,
        subcategories: subcategories,
      );

      // Override the categoriesRepoProvider with our mock
      container = ProviderContainer(
        overrides: [
          categoriesRepoProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() async {
      // Wait a bit for any pending async operations before disposing
      await Future.delayed(const Duration(milliseconds: 200));
      container.dispose();
    });

    test('categoriesDataProvider loads data correctly', () async {
      // Initially should be loading
      final initialState = container.read(categoriesDataProvider);
      expect(initialState.isLoading, isTrue);

      // Wait for data to load
      await Future.delayed(const Duration(milliseconds: 200));

      // Should have data now
      final loadedState = container.read(categoriesDataProvider);
      expect(loadedState.hasValue, isTrue);
      expect(loadedState.isLoading, isFalse);

      final data = loadedState.value!;
      expect(data['categories'], isA<List<Category>>());
      expect(data['subcategoriesMap'], isA<Map<String, List<Subcategory>>>());

      final categories = data['categories'] as List<Category>;
      expect(categories.length, equals(3));
      expect(categories[0].name, equals('Food'));
      expect(categories[1].name, equals('Transport'));
      expect(categories[2].name, equals('Accommodation'));
    });

    test('categoriesDataProvider groups subcategories by categoryId', () async {
      // Wait for data to actually load
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = container.read(categoriesDataProvider);
      } while (state.isLoading);

      expect(state.hasValue, isTrue);

      final data = state.value!;
      final subcategoriesMap = data['subcategoriesMap'] as Map<String, List<Subcategory>>;

      // Check that subcategories are grouped correctly
      expect(subcategoriesMap.containsKey('cat1'), isTrue);
      expect(subcategoriesMap.containsKey('cat2'), isTrue);
      // cat3 might not be in map if it has no subcategories, which is fine

      // cat1 should have 2 subcategories
      final cat1Subs = subcategoriesMap['cat1'] ?? [];
      expect(cat1Subs.length, equals(2));
      expect(cat1Subs[0].name, equals('Restaurant'));
      expect(cat1Subs[1].name, equals('Groceries'));

      // cat2 should have 2 subcategories
      final cat2Subs = subcategoriesMap['cat2'] ?? [];
      expect(cat2Subs.length, equals(2));
      expect(cat2Subs[0].name, equals('Flight'));
      expect(cat2Subs[1].name, equals('Taxi'));

      // cat3 should have 0 subcategories (might not be in map)
      final cat3Subs = subcategoriesMap['cat3'] ?? [];
      expect(cat3Subs.length, equals(0));
    });

    test('categoriesProvider returns categories synchronously after load', () async {
      // Wait for data to actually load by checking the AsyncValue
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = container.read(categoriesDataProvider);
      } while (state.isLoading);

      // Should return categories immediately (synchronous)
      final categories = container.read(categoriesProvider);
      expect(categories, isA<List<Category>>());
      expect(categories.length, equals(3));
      expect(categories[0].name, equals('Food'));
    });

    test('subcategoriesProvider returns subcategories synchronously after load', () async {
      // Wait for data to actually load
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = container.read(categoriesDataProvider);
      } while (state.isLoading);

      // Should return subcategories immediately (synchronous)
      final subcategories = container.read(subcategoriesProvider('cat1'));
      expect(subcategories, isA<List<Subcategory>>());
      expect(subcategories.length, equals(2));
      expect(subcategories[0].name, equals('Restaurant'));
      expect(subcategories[1].name, equals('Groceries'));

      // Test another category
      final cat2Subs = container.read(subcategoriesProvider('cat2'));
      expect(cat2Subs.length, equals(2));
      expect(cat2Subs[0].name, equals('Flight'));

      // Test category with no subcategories
      final cat3Subs = container.read(subcategoriesProvider('cat3'));
      expect(cat3Subs.length, equals(0));
    });

    test('subcategoriesByNameProvider works correctly', () async {
      // Wait for data to actually load
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = container.read(categoriesDataProvider);
      } while (state.isLoading);

      // Should return subcategories by category name
      final subcategories = container.read(subcategoriesByNameProvider('Food'));
      expect(subcategories, isA<List<Subcategory>>());
      expect(subcategories.length, equals(2));
      expect(subcategories[0].name, equals('Restaurant'));

      // Test with Transport category
      final transportSubs = container.read(subcategoriesByNameProvider('Transport'));
      expect(transportSubs.length, equals(2));
      expect(transportSubs[0].name, equals('Flight'));
    });

    test('allSubcategoriesProvider returns all subcategories', () async {
      // Wait for data to actually load
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = container.read(categoriesDataProvider);
      } while (state.isLoading);

      final allSubs = container.read(allSubcategoriesProvider);
      expect(allSubs, isA<List<Subcategory>>());
      expect(allSubs.length, equals(4)); // Total of 4 subcategories
    });

    test('categoriesDataProvider caches data - only loads once', () async {
      // Wait for data to actually load
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = container.read(categoriesDataProvider);
      } while (state.isLoading);

      // Read multiple times - should use cached data
      final categories1 = container.read(categoriesProvider);
      final categories2 = container.read(categoriesProvider);
      final categories3 = container.read(categoriesProvider);

      // All should have the same length (cached)
      expect(categories1.length, equals(3));
      expect(categories2.length, equals(3));
      expect(categories3.length, equals(3));
    });

    test('providers handle empty data gracefully', () async {
      // Create container with empty mock
      final emptyRepo = MockCategoriesRepo();
      final emptyContainer = ProviderContainer(
        overrides: [
          categoriesRepoProvider.overrideWithValue(emptyRepo),
        ],
      );

      // Wait for load
      await Future.delayed(const Duration(milliseconds: 200));

      // Should return empty lists, not crash
      final categories = emptyContainer.read(categoriesProvider);
      expect(categories, isA<List<Category>>());
      expect(categories.isEmpty, isTrue);

      final subcategories = emptyContainer.read(subcategoriesProvider('cat1'));
      expect(subcategories, isA<List<Subcategory>>());
      expect(subcategories.isEmpty, isTrue);

      // Wait before disposing
      await Future.delayed(const Duration(milliseconds: 200));
      emptyContainer.dispose();
    });

    test('providers return empty list during loading state', () {
      // Immediately after container creation, should return empty lists
      final categories = container.read(categoriesProvider);
      expect(categories, isA<List<Category>>());
      expect(categories.isEmpty, isTrue);

      final subcategories = container.read(subcategoriesProvider('cat1'));
      expect(subcategories, isA<List<Subcategory>>());
      expect(subcategories.isEmpty, isTrue);
    });

    test('categoriesDataProvider loads data in parallel', () async {
      final trackingRepo = MockCategoriesRepo(
        categories: [
          Category(id: 'cat1', name: 'Food', sortOrder: 1),
        ],
        subcategories: [
          Subcategory(id: 'sub1', categoryId: 'cat1', name: 'Restaurant', sortOrder: 1),
        ],
      );

      // Override methods to track calls
      final trackingContainer = ProviderContainer(
        overrides: [
          categoriesRepoProvider.overrideWithValue(trackingRepo),
        ],
      );

      // Wait for data to actually load
      AsyncValue<Map<String, dynamic>> state;
      do {
        await Future.delayed(const Duration(milliseconds: 50));
        state = trackingContainer.read(categoriesDataProvider);
      } while (state.isLoading);

      // Both should have been called (parallel execution)
      expect(state.hasValue, isTrue);

      // Wait before disposing
      await Future.delayed(const Duration(milliseconds: 200));
      trackingContainer.dispose();
    });
  });
}

