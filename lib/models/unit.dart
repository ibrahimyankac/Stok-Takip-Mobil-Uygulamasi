class Unit {
  final String id;
  final String name;
  final String shortName;
  final String? type;
  final bool isActive;
  final DateTime createdAt;

  const Unit({
    required this.id,
    required this.name,
    required this.shortName,
    this.type,
    this.isActive = true,
    required this.createdAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['symbol']?.toString() ?? json['short_name']?.toString() ?? '',
      type: json['description']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': shortName,
      'description': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Backwards compatibility için abbreviation getter
  String get abbreviation => shortName;

  @override
  String toString() => 'Unit(id: $id, name: $name, shortName: $shortName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Unit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}