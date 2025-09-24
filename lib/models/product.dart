class Product {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final String unitId;
  final String? barcode;
  final double currentStock;
  final double minStockLevel;
  final double currentPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.unitId,
    this.barcode,
    required this.currentStock,
    required this.minStockLevel,
    required this.currentPrice,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  // Supabase'den JSON data'yı Product nesnesine çevir
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryId: json['category_id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (json['min_stock_level'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isDeleted: json['is_deleted'] == true,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  // Product nesnesini JSON'a çevir (Supabase'e göndermek için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit_id': unitId,
      'barcode': barcode,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      'price': currentPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Yeni bir Product oluşturmak için (id olmadan)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'description': description,
      'category_id': categoryId,
      'unit_id': unitId,
      'barcode': barcode,
      'current_stock': currentStock,
      'min_stock_level': minStockLevel,
      'price': currentPrice,
    };
  }

  // Product'ı güncellemek için
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? unitId,
    String? barcode,
    double? currentStock,
    double? minStockLevel,
    double? currentPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      barcode: barcode ?? this.barcode,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      currentPrice: currentPrice ?? this.currentPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Stok durumunu kontrol et
  bool get isLowStock => currentStock <= minStockLevel;
  
  // Stok miktarını string olarak göster
  String get stockDisplayText => currentStock.toStringAsFixed(2);
  
  // Fiyatı formatted string olarak göster
  String get priceDisplayText => '₺${currentPrice.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'Product(id: $id, name: $name, stock: $currentStock, price: $currentPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}