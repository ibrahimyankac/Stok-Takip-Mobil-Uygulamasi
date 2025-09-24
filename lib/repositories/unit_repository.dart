import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../core/cache_manager.dart';

class UnitRepository {
  final _supabase = Supabase.instance.client;
  CacheManager? _cacheManager;

  UnitRepository() {
    _initCache();
  }

  Future<void> _initCache() async {
    _cacheManager = await CacheManager.getInstance();
  }

  // Tüm birimleri getir
  Future<List<Unit>> getAllUnits() async {
    try {
      // Önce cache'ten kontrol et
      if (_cacheManager != null && !_cacheManager!.isCacheExpired()) {
        final cachedUnits = _cacheManager!.getCachedUnits();
        if (cachedUnits != null) {
          return cachedUnits.map<Unit>((json) => Unit.fromJson(json)).toList();
        }
      }

      final response = await _supabase
          .from(AppConstants.unitsTable)
          .select()
          .order('name');

      final units = response.map<Unit>((json) => Unit.fromJson(json)).toList();
      
      // Cache'e kaydet
      if (_cacheManager != null) {
        await _cacheManager!.cacheUnits(response);
        await _cacheManager!.setLastSyncTime(DateTime.now());
      }

      return units;
    } catch (e) {
      // Hata durumunda cache'ten döndür
      if (_cacheManager != null) {
        final cachedUnits = _cacheManager!.getCachedUnits();
        if (cachedUnits != null) {
          return cachedUnits.map<Unit>((json) => Unit.fromJson(json)).toList();
        }
      }
      throw Exception('Birimler alınırken hata oluştu: $e');
    }
  }

  // ID ile birim getir
  Future<Unit?> getUnitById(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.unitsTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Unit.fromJson(response) : null;
    } catch (e) {
      throw Exception('Birim alınırken hata oluştu: $e');
    }
  }

  // Birim sayısını getir
  Future<int> getUnitCount() async {
    try {
      final response = await _supabase
          .from(AppConstants.unitsTable)
          .select('id')
          .count();
      
      return response.count;
    } catch (e) {
      throw Exception('Birim sayısı alınırken hata oluştu: $e');
    }
  }

  // Yeni birim ekle
  Future<Unit> createUnit(String name, String shortName, String type) async {
    try {
      final response = await _supabase
          .from(AppConstants.unitsTable)
          .insert({
            'name': name,
            'short_name': shortName,
            'type': type,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Unit.fromJson(response);
    } catch (e) {
      throw Exception('Birim eklenirken hata oluştu: $e');
    }
  }

  // Birim güncelle
  Future<Unit> updateUnit(String id, String name, String shortName, String type) async {
    try {
      final response = await _supabase
          .from(AppConstants.unitsTable)
          .update({
            'name': name,
            'short_name': shortName,
            'type': type,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return Unit.fromJson(response);
    } catch (e) {
      throw Exception('Birim güncellenirken hata oluştu: $e');
    }
  }

  // Birim sil
  Future<void> deleteUnit(String id) async {
    try {
      // Önce bu birime ait ürün var mı kontrol et
      final products = await _supabase
          .from(AppConstants.productsTable)
          .select('id')
          .eq('unit_id', id);

      if (products.isNotEmpty) {
        throw Exception('Bu birime ait ${products.length} ürün var. Önce ürünleri silin veya başka birime taşıyın.');
      }

      await _supabase
          .from(AppConstants.unitsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Birim silinirken hata oluştu: $e');
    }
  }
}