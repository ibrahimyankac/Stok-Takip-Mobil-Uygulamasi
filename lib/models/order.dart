import 'order_item.dart';

class Order {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem>? items; // Sipariş kalemlerini de içerebilir

  const Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  // JSON'dan Order nesnesi oluşturma
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : null,
    );
  }

  // Order nesnesini JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  // Database insert için JSON (id olmadan)
  Map<String, dynamic> toInsertJson() {
    return {
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
    };
  }

  // Database update için JSON
  Map<String, dynamic> toUpdateJson() {
    return {
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Kopya oluşturma (immutable update için)
  Order copyWith({
    String? id,
    String? orderNumber,
    double? totalAmount,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  // Sipariş durumları için constants
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Yardımcı metodlar
  bool get isCompleted => status == statusCompleted;
  bool get isCancelled => status == statusCancelled;
  
  int get itemCount => items?.length ?? 0;
  
  String get formattedTotal => '₺${totalAmount.toStringAsFixed(2)}';
  
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}.'
        '${createdAt.month.toString().padLeft(2, '0')}.'
        '${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}.'
        '${createdAt.month.toString().padLeft(2, '0')}.'
        '${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, totalAmount: $totalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}