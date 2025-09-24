import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static CacheManager? _instance;
  static SharedPreferences? _preferences;

  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyProductsCache = 'products_cache';
  static const String _keyCategoriesCache = 'categories_cache';
  static const String _keyUnitsCache = 'units_cache';
  static const String _keyAppState = 'app_state';
  static const String _keySelectedTabIndex = 'selected_tab_index';

  CacheManager._();

  static Future<CacheManager> getInstance() async {
    _instance ??= CacheManager._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Son senkronizasyon zamanı
  Future<void> setLastSyncTime(DateTime time) async {
    await _preferences!.setString(_keyLastSyncTime, time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = _preferences!.getString(_keyLastSyncTime);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  // Ürünleri cache'le
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final jsonString = jsonEncode(products);
    await _preferences!.setString(_keyProductsCache, jsonString);
  }

  List<Map<String, dynamic>>? getCachedProducts() {
    final jsonString = _preferences!.getString(_keyProductsCache);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Kategorileri cache'le
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    final jsonString = jsonEncode(categories);
    await _preferences!.setString(_keyCategoriesCache, jsonString);
  }

  List<Map<String, dynamic>>? getCachedCategories() {
    final jsonString = _preferences!.getString(_keyCategoriesCache);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Birimleri cache'le
  Future<void> cacheUnits(List<Map<String, dynamic>> units) async {
    final jsonString = jsonEncode(units);
    await _preferences!.setString(_keyUnitsCache, jsonString);
  }

  List<Map<String, dynamic>>? getCachedUnits() {
    final jsonString = _preferences!.getString(_keyUnitsCache);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Uygulama durumunu kaydet
  Future<void> setAppState(String key, dynamic value) async {
    if (value is String) {
      await _preferences!.setString('${_keyAppState}_$key', value);
    } else if (value is int) {
      await _preferences!.setInt('${_keyAppState}_$key', value);
    } else if (value is bool) {
      await _preferences!.setBool('${_keyAppState}_$key', value);
    } else if (value is double) {
      await _preferences!.setDouble('${_keyAppState}_$key', value);
    }
  }

  T? getAppState<T>(String key) {
    return _preferences!.get('${_keyAppState}_$key') as T?;
  }

  // Seçili tab index'i kaydet
  Future<void> setSelectedTabIndex(int index) async {
    await _preferences!.setInt(_keySelectedTabIndex, index);
  }

  int getSelectedTabIndex() {
    return _preferences!.getInt(_keySelectedTabIndex) ?? 0;
  }

  // Cache'i temizle
  Future<void> clearCache() async {
    await _preferences!.remove(_keyProductsCache);
    await _preferences!.remove(_keyCategoriesCache);
    await _preferences!.remove(_keyUnitsCache);
    await _preferences!.remove(_keyLastSyncTime);
  }

  // Tüm cache'i temizle
  Future<void> clearAllCache() async {
    await _preferences!.clear();
  }

  // Cache'in ne kadar eski olduğunu kontrol et
  bool isCacheExpired({Duration maxAge = const Duration(minutes: 30)}) {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > maxAge;
  }
}