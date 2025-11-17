// lib/domain/entities/product_entity.dart
class ProductEntity {
  final String id;
  final String businessId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrls;
  final bool isAvailable;
  final int stock;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.businessId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.isAvailable,
    required this.stock,
    required this.createdAt,
    this.updatedAt,
  });

  // CopyWith method para actualizaciones inmutables
  ProductEntity copyWith({
    String? id,
    String? businessId,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrls,
    bool? isAvailable,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'stock': stock,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Crear desde Map de Firestore
  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'General',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      stock: (map['stock'] ?? 0).toInt(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  // Métodos de utilidad
  bool get hasStock => stock > 0;
  bool get canBeSold => isAvailable && hasStock;
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get stockStatus {
    if (!isAvailable) return 'No disponible';
    if (stock == 0) return 'Sin stock';
    if (stock < 5) return 'Stock bajo ($stock)';
    return 'En stock ($stock)';
  }

  // Para debugging
  @override
  String toString() {
    return 'ProductEntity(id: $id, name: $name, price: $price, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductEntity && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}