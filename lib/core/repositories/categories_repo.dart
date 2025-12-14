  import '../supabase/supabase_client.dart';
  import '../models/category.dart';

  class CategoriesRepo {
    Future<List<Category>> getCategories() async {
      final res = await supabase()
          .from('categories')
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      return (res as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    Future<List<Subcategory>> getSubcategories(String categoryId) async {
      final res = await supabase()
          .from('subcategories')
          .select()
          .eq('category_id', categoryId)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      return (res as List)
          .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    Future<List<Subcategory>> getAllSubcategories() async {
      final res = await supabase()
          .from('subcategories')
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      return (res as List)
          .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

