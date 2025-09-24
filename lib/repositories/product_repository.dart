import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/constants.dart';
import '../core/cache_manager.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;
  CacheManager? _cacheManager;

  ProductRepository() {
    _initCache();
  }

  Future<void> _initCache() async {
    _cacheManager = await CacheManager.getInstance();
  }

  // Tüm ürünleri getir
  Future<List<Product>> getAllProducts() async {
    try {
      // Önce cache'ten kontrol et
      if (_cacheManager != null && !_cacheManager!.isCacheExpired()) {
        final cachedProducts = _cacheManager!.getCachedProducts();
        if (cachedProducts != null) {
          return cachedProducts.map<Product>((json) => Product.fromJson(json)).toList();
        }
      }

      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .order('name');

      final products = response.map<Product>((json) => Product.fromJson(json)).toList();
      
      // Cache'e kaydet
      if (_cacheManager != null) {
        await _cacheManager!.cacheProducts(response);
        await _cacheManager!.setLastSyncTime(DateTime.now());
      }

      return products;
    } catch (e) {
      // Hata durumunda cache'ten döndür
      if (_cacheManager != null) {
        final cachedProducts = _cacheManager!.getCachedProducts();
        if (cachedProducts != null) {
          return cachedProducts.map<Product>((json) => Product.fromJson(json)).toList();
        }
      }
      throw Exception('Ürünler alınırken hata oluştu: $e');
    }
  }

  // ID ile ürün getir
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Product.fromJson(response) : null;
    } catch (e) {
      throw Exception('Ürün alınırken hata oluştu: $e');
    }
  }

  // Barkod ile ürün getir
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      return response != null ? Product.fromJson(response) : null;
    } catch (e) {
      throw Exception('Barkod ile ürün alınırken hata oluştu: $e');
    }
  }

  // Kategoriye göre ürünleri getir
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .eq('category_id', categoryId)
          .order('name');

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Kategori ürünleri alınırken hata oluştu: $e');
    }
  }

  // Düşük stoklu ürünleri getir
  Future<List<Product>> getLowStockProducts() async {
    try {
      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .filter('current_stock', 'lte', 'min_stock_level')
          .order('name');

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Düşük stoklu ürünler alınırken hata oluştu: $e');
    }
  }

  // Ürün ara (isim veya barkoda göre)
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from(AppConstants.productsTable)
          .select()
          .or('name.ilike.%$query%,barcode.ilike.%$query%')
          .order('name');

      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ürün arama yapılırken hata oluştu: $e');
    }
  }

  // Duplicate ürün kontrolü
  Future<bool> isDuplicateProduct(String name, String? barcode, {String? excludeId}) async {
    try {
      var query = _supabase
          .from(AppConstants.productsTable)
          .select('id, name, barcode')
          .or('name.ilike.$name');

      // Barkod varsa barkod kontrolü de ekle
      if (barcode != null && barcode.isNotEmpty) {
        query = query.or('barcode.eq.$barcode');
      }

      // Güncelleme işleminde mevcut ürünü hariç tut
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Duplicate kontrol yapılırken hata oluştu: $e');
    }
  }

  // Hangi alanda duplicate olduğunu kontrol et
  Future<String?> checkDuplicateField(String name, String? barcode, {String? excludeId}) async {
    try {
      // İsim kontrolü
      var nameQuery = _supabase
          .from(AppConstants.productsTable)
          .select('id, name')
          .ilike('name', name);
      
      if (excludeId != null) {
        nameQuery = nameQuery.neq('id', excludeId);
      }
      
      final nameResult = await nameQuery;
      if (nameResult.isNotEmpty) {
        return 'Bu isimde bir ürün zaten mevcut: "${nameResult.first['name']}"';
      }

      // Barkod kontrolü (eğer barkod varsa)
      if (barcode != null && barcode.isNotEmpty) {
        var barcodeQuery = _supabase
            .from(AppConstants.productsTable)
            .select('id, name, barcode')
            .eq('barcode', barcode);
            
        if (excludeId != null) {
          barcodeQuery = barcodeQuery.neq('id', excludeId);
        }
        
        final barcodeResult = await barcodeQuery;
        if (barcodeResult.isNotEmpty) {
          return 'Bu barkodda bir ürün zaten mevcut: "${barcodeResult.first['name']}" (${barcodeResult.first['barcode']})';
        }
      }

      return null; // Duplicate yok
    } catch (e) {
      throw Exception('Duplicate alan kontrolü yapılırken hata oluştu: $e');
    }
  }

  // Yeni ürün ekle (duplicate kontrolü ile)
  Future<Product> createProduct(Product product) async {
    try {
      // Önce duplicate kontrolü yap
      final duplicateMessage = await checkDuplicateField(
        product.name, 
        product.barcode,
      );
      
      if (duplicateMessage != null) {
        throw Exception(duplicateMessage);
      }

      final response = await _supabase
          .from(AppConstants.productsTable)
          .insert(product.toInsertJson())
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Ürün oluşturulurken hata oluştu: $e');
    }
  }

  // Ürün güncelle (duplicate kontrolü ile)
  Future<Product> updateProduct(Product product) async {
    try {
      // Önce duplicate kontrolü yap (mevcut ürünü hariç tut)
      final duplicateMessage = await checkDuplicateField(
        product.name, 
        product.barcode,
        excludeId: product.id,
      );
      
      if (duplicateMessage != null) {
        throw Exception(duplicateMessage);
      }

      final response = await _supabase
          .from(AppConstants.productsTable)
          .update({
            'name': product.name,
            'description': product.description,
            'category_id': product.categoryId,
            'unit_id': product.unitId,
            'barcode': product.barcode,
            'current_stock': product.currentStock,
            'min_stock_level': product.minStockLevel,
            'price': product.currentPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', product.id)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Ürün sil (geçici olarak hard delete - database column'ları eklenene kadar)
  Future<void> deleteProduct(String id) async {
    try {
      // Önce bu ürünle ilgili order_items kayıtlarını kontrol et
      final orderItems = await _supabase
          .from('order_items')
          .select('id')
          .eq('product_id', id);
      
      if (orderItems.isNotEmpty) {
        // Order items kayıtlarını sil
        await _supabase
            .from('order_items')
            .delete()
            .eq('product_id', id);
      }
      
      // Sonra ürünü sil
      await _supabase
          .from(AppConstants.productsTable)
          .delete()
          .eq('id', id);
          
    } catch (e) {
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Stok güncelle (Supabase function kullanarak)
  Future<void> updateStock(String productId, double quantity, String movementType) async {
    try {
      await _supabase.rpc('add_stock_and_log', params: {
        'product_id': productId,
        'quantity': quantity,
        'movement_type': movementType,
        'notes': 'Mobil uygulama üzerinden güncelleme',
      });
    } catch (e) {
      throw Exception('Stok güncellenirken hata oluştu: $e');
    }
  }

  // Fiyat güncelle (Supabase function kullanarak)
  Future<void> updatePrice(String productId, double newPrice) async {
    try {
      await _supabase.rpc('change_price_and_log', params: {
        'product_id': productId,
        'new_price': newPrice,
        'notes': 'Mobil uygulama üzerinden fiyat güncelleme',
      });
    } catch (e) {
      throw Exception('Fiyat güncellenirken hata oluştu: $e');
    }
  }

  // Ürün sayısını getir
  Future<int> getProductCount() async {
    try {
      final response = await _supabase
          .from(AppConstants.productsTable)
          .select('id')
          .count();
      
      return response.count;
    } catch (e) {
      throw Exception('Ürün sayısı alınırken hata oluştu: $e');
    }
  }
}