import 'product.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;
  final Product? product; // Ürün bilgilerini de içerebilir
  
  // Additional fields for convenience
  final String? productName;
  final String? productBarcode;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    this.product,
    this.productName,
    this.productBarcode,
  });

  // JSON'dan OrderItem nesnesi oluşturma
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      productName: json['product_name'] as String?,
      productBarcode: json['product_barcode'] as String?,
      product: json['product'] != null 
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  // OrderItem nesnesini JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      if (productName != null) 'product_name': productName,
      if (productBarcode != null) 'product_barcode': productBarcode,
      if (product != null) 'product': product!.toJson(),
    };
  }

  // Database insert için JSON (id olmadan)
  Map<String, dynamic> toInsertJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  // Kopya oluşturma
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? createdAt,
    Product? product,
    String? productName,
    String? productBarcode,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      productBarcode: productBarcode ?? this.productBarcode,
    );
  }

  // Yardımcı metodlar
  String get formattedQuantity => quantity % 1 == 0 
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  
  String get formattedUnitPrice => '₺${unitPrice.toStringAsFixed(2)}';
  
  String get formattedTotalPrice => '₺${totalPrice.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'OrderItem(id: $id, productId: $productId, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}