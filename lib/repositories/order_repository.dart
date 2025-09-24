import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class OrderRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Yeni sipariş oluşturma (transaction ile)
  Future<Order> createOrder({
    required List<OrderItem> items,
    String? notes,
  }) async {
    try {
      // Sipariş numarası oluştur
      final orderNumber = await _generateOrderNumber();
      
      // Toplam tutarı hesapla
      final totalAmount = items.fold<double>(
        0.0, 
        (sum, item) => sum + item.totalPrice,
      );

      // Transaction başlat
      final response = await _client.rpc('create_order_with_items', params: {
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'notes': notes,
        'order_items': items.map((item) => {
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
        }).toList(),
      });

      if (response == null) {
        throw Exception('Sipariş oluşturulamadı');
      }

      // Oluşturulan siparişi getir
      return await getOrderById(response['order_id']);
    } catch (e) {
      throw Exception('Sipariş oluşturma hatası: $e');
    }
  }

  // Sipariş numarası oluşturma
  Future<String> _generateOrderNumber() async {
    try {
      final today = DateTime.now();
      final datePrefix = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      
      // Bugünkü siparişlerin sayısını bul
      final response = await _client
          .from('orders')
          .select('order_number')
          .like('order_number', '$datePrefix%')
          .order('order_number', ascending: false)
          .limit(1);

      int nextNumber = 1;
      if (response.isNotEmpty) {
        final lastOrderNumber = response.first['order_number'] as String;
        final lastNumber = int.tryParse(lastOrderNumber.substring(8)) ?? 0;
        nextNumber = lastNumber + 1;
      }

      return '$datePrefix${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      // Hata durumunda rastgele numara oluştur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'SIP$timestamp';
    }
  }

  // ID ile sipariş getirme
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items:order_items(
              *,
              product:products(*)
            )
          ''')
          .eq('id', orderId)
          .single();

      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Sipariş bulunamadı: $e');
    }
  }

  // Tarih aralığına göre siparişleri getir
  Future<List<Order>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items(
              id,
              product_id,
              quantity,
              unit_price,
              total_price,
              products!inner(
                id,
                name,
                barcode
              )
            )
          ''')
          .gte('created_at', startDate.toUtc().toIso8601String())
          .lte('created_at', endDate.toUtc().toIso8601String())
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((orderData) {
        // Order items verisini düzenle
        final List<dynamic> orderItemsData = orderData['order_items'] as List<dynamic>;
        final List<OrderItem> orderItems = orderItemsData.map((itemData) {
          final productData = itemData['products'];
          return OrderItem(
            id: itemData['id']?.toString() ?? '',
            orderId: orderData['id'].toString(),
            productId: itemData['product_id'].toString(),
            productName: productData['name'],
            productBarcode: productData['barcode'],
            quantity: (itemData['quantity'] as num).toDouble(),
            unitPrice: (itemData['unit_price'] as num).toDouble(),
            totalPrice: (itemData['total_price'] as num).toDouble(),
            createdAt: DateTime.now(), // Fallback for missing created_at
          );
        }).toList();

        // Order objesini oluştur
        final order = Order(
          id: orderData['id'].toString(),
          orderNumber: orderData['order_number'],
          totalAmount: (orderData['total_amount'] as num).toDouble(),
          status: orderData['status'],
          notes: orderData['notes'],
          createdAt: DateTime.parse(orderData['created_at']),
          updatedAt: orderData['updated_at'] != null 
              ? DateTime.parse(orderData['updated_at'])
              : null,
        );

        // Items'ı set et
        return order.copyWith(items: orderItems);
      }).toList();
    } catch (e) {
      throw Exception('Siparişler getirilemedi: $e');
    }
  }

  // Tüm siparişleri getirme
  Future<List<Order>> getAllOrders({
    int limit = 50,
    int offset = 0,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('''
            *,
            order_items:order_items(
              *,
              product:products(*)
            )
          ''');

      // Filtreler
      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Siparişler getirilemedi: $e');
    }
  }

  // Günlük satışları getirme
  Future<List<Order>> getDailySales(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items:order_items(
              *,
              product:products(*)
            )
          ''')
          .eq('status', Order.statusCompleted)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return response.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Günlük satışlar getirilemedi: $e');
    }
  }

  // Günlük satış özeti
  Future<Map<String, dynamic>> getDailySalesSummary(DateTime date) async {
    try {
      final dailySales = await getDailySales(date);
      
      final totalOrders = dailySales.length;
      final totalAmount = dailySales.fold<double>(
        0.0, 
        (sum, order) => sum + order.totalAmount,
      );
      
      final totalItems = dailySales.fold<int>(
        0, 
        (sum, order) => sum + order.itemCount,
      );

      return {
        'total_orders': totalOrders,
        'total_amount': totalAmount,
        'total_items': totalItems,
        'orders': dailySales,
      };
    } catch (e) {
      throw Exception('Günlük satış özeti alınamadı: $e');
    }
  }

  // Sipariş güncelleme
  Future<Order> updateOrder(String orderId, {
    String? status,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (status != null) updateData['status'] = status;
      if (notes != null) updateData['notes'] = notes;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      return await getOrderById(orderId);
    } catch (e) {
      throw Exception('Sipariş güncellenemedi: $e');
    }
  }

  // Sipariş silme (soft delete - status'u cancelled yapar)
  Future<void> cancelOrder(String orderId) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': Order.statusCancelled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Sipariş iptal edilemedi: $e');
    }
  }

  // Sipariş kalemi ekleme
  Future<void> addOrderItem(String orderId, OrderItem item) async {
    try {
      await _client
          .from('order_items')
          .insert(item.toInsertJson()..['order_id'] = orderId);

      // Siparişin toplam tutarını güncelle
      await _updateOrderTotal(orderId);
    } catch (e) {
      throw Exception('Sipariş kalemi eklenemedi: $e');
    }
  }

  // Sipariş kalemi güncelleme
  Future<void> updateOrderItem(String itemId, {
    double? quantity,
    double? unitPrice,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (quantity != null) {
        updateData['quantity'] = quantity;
        if (unitPrice != null) {
          updateData['total_price'] = quantity * unitPrice;
        }
      }
      
      if (unitPrice != null) {
        updateData['unit_price'] = unitPrice;
        if (quantity == null) {
          // Mevcut quantity'yi al
          final currentItem = await _client
              .from('order_items')
              .select('quantity')
              .eq('id', itemId)
              .single();
          updateData['total_price'] = currentItem['quantity'] * unitPrice;
        }
      }

      await _client
          .from('order_items')
          .update(updateData)
          .eq('id', itemId);

      // Siparişin toplam tutarını güncelle
      final orderItem = await _client
          .from('order_items')
          .select('order_id')
          .eq('id', itemId)
          .single();
      
      await _updateOrderTotal(orderItem['order_id']);
    } catch (e) {
      throw Exception('Sipariş kalemi güncellenemedi: $e');
    }
  }

  // Sipariş kalemi silme
  Future<void> removeOrderItem(String itemId) async {
    try {
      // Önce order_id'yi al
      final orderItem = await _client
          .from('order_items')
          .select('order_id')
          .eq('id', itemId)
          .single();

      await _client
          .from('order_items')
          .delete()
          .eq('id', itemId);

      // Siparişin toplam tutarını güncelle
      await _updateOrderTotal(orderItem['order_id']);
    } catch (e) {
      throw Exception('Sipariş kalemi silinemedi: $e');
    }
  }

  // Sipariş toplam tutarını güncelleme (private method)
  Future<void> _updateOrderTotal(String orderId) async {
    try {
      final items = await _client
          .from('order_items')
          .select('total_price')
          .eq('order_id', orderId);

      final totalAmount = items.fold<double>(
        0.0,
        (sum, item) => sum + (item['total_price'] as num).toDouble(),
      );

      await _client
          .from('orders')
          .update({
            'total_amount': totalAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Sipariş toplamı güncellenemedi: $e');
    }
  }

  // Stoktan düşürme işlemi
  Future<void> processOrderStock(String orderId) async {
    try {
      // Sipariş kalemlerini al
      final orderItems = await _client
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', orderId);

      // Her ürün için stok düşür
      for (final item in orderItems) {
        final productId = item['product_id'] as String;
        final quantity = (item['quantity'] as num).toDouble();

        // Mevcut stoku al
        final product = await _client
            .from('products')
            .select('current_stock')
            .eq('id', productId)
            .single();

        final currentStock = (product['current_stock'] as num).toDouble();
        final newStock = currentStock - quantity;

        if (newStock < 0) {
          throw Exception('Yetersiz stok: Ürün ID $productId');
        }

        // Stoku güncelle
        await _client
            .from('products')
            .update({
              'current_stock': newStock,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', productId);
      }
    } catch (e) {
      throw Exception('Stok işlemi başarısız: $e');
    }
  }
}