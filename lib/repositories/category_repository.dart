import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../core/cache_manager.dart';

class CategoryRepository {
  final _supabase = Supabase.instance.client;
  CacheManager? _cacheManager;

  CategoryRepository() {
    _initCache();
  }

  Future<void> _initCache() async {
    _cacheManager = await CacheManager.getInstance();
  }

  // Tüm kategorileri getir
  Future<List<Category>> getAllCategories() async {
    try {
      // Önce cache'ten kontrol et
      if (_cacheManager != null && !_cacheManager!.isCacheExpired()) {
        final cachedCategories = _cacheManager!.getCachedCategories();
        if (cachedCategories != null) {
          return cachedCategories.map<Category>((json) => Category.fromJson(json)).toList();
        }
      }

      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .select()
          .order('name');

      final categories = response.map<Category>((json) => Category.fromJson(json)).toList();
      
      // Cache'e kaydet
      if (_cacheManager != null) {
        await _cacheManager!.cacheCategories(response);
        await _cacheManager!.setLastSyncTime(DateTime.now());
      }

      return categories;
    } catch (e) {
      // Hata durumunda cache'ten döndür
      if (_cacheManager != null) {
        final cachedCategories = _cacheManager!.getCachedCategories();
        if (cachedCategories != null) {
          return cachedCategories.map<Category>((json) => Category.fromJson(json)).toList();
        }
      }
      throw Exception('Kategoriler alınırken hata oluştu: $e');
    }
  }

  // ID ile kategori getir
  Future<Category?> getCategoryById(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Category.fromJson(response) : null;
    } catch (e) {
      throw Exception('Kategori alınırken hata oluştu: $e');
    }
  }

  // Kategori sayısını getir
  Future<int> getCategoryCount() async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .select('id')
          .count();
      
      return response.count;
    } catch (e) {
      throw Exception('Kategori sayısı alınırken hata oluştu: $e');
    }
  }

  // Yeni kategori ekle
  Future<Category> createCategory(String name, String? description) async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .insert({
            'name': name,
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Kategori eklenirken hata oluştu: $e');
    }
  }

  // Kategori güncelle
  Future<Category> updateCategory(String id, String name, String? description) async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .update({
            'name': name,
            'description': description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Kategori güncellenirken hata oluştu: $e');
    }
  }

  // Kategori sil 
  Future<void> deleteCategory(String id) async {
    try {
      // Önce bu kategoriye ait ürün var mı kontrol et
      final products = await _supabase
          .from(AppConstants.productsTable)
          .select('id')
          .eq('category_id', id);

      if (products.isNotEmpty) {
        throw Exception('Bu kategoriye ait ${products.length} ürün var. Önce ürünleri silin veya başka kategoriye taşıyın.');
      }

      await _supabase
          .from(AppConstants.categoriesTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }
}