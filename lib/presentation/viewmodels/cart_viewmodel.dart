// lib/presentation/viewmodels/cart_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';

class CartItem {
  final ProductEntity product;
  int quantity;
  final String? notes;
  final List<String> modifications;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.notes,
    this.modifications = const [],
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    int? quantity,
    String? notes,
    List<String>? modifications,
  }) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      modifications: modifications ?? this.modifications,
    );
  }
}

class CartViewModel with ChangeNotifier {
  final List<CartItem> _items = [];
  String _deliveryAddress = '';
  String _userNote = '';
  String _paymentMethod = 'cash';

  List<CartItem> get items => List.from(_items);
  String get deliveryAddress => _deliveryAddress;
  String get userNote => _userNote;
  String get paymentMethod => _paymentMethod;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => _items.isNotEmpty ? 1000 : 0.0; // Fee fijo por ahora
  double get tax => subtotal * 0.01; // 10% de impuesto
  double get totalAmount => subtotal + deliveryFee + tax;

  // ========== OPERACIONES DEL CARRITO ==========
  void addToCart(ProductEntity product, {int quantity = 1, String? notes}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      // Producto ya existe, incrementar cantidad
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      // Nuevo producto
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        notes: notes,
      ));
    }

    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
      notifyListeners();
    }
  }

  void updateItemNotes(String productId, String notes) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(notes: notes);
      notifyListeners();
    }
  }

  void addModification(String productId, String modification) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final newModifications = List<String>.from(_items[index].modifications)..add(modification);
      _items[index] = _items[index].copyWith(modifications: newModifications);
      notifyListeners();
    }
  }

  void removeModification(String productId, String modification) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final newModifications = List<String>.from(_items[index].modifications)..remove(modification);
      _items[index] = _items[index].copyWith(modifications: newModifications);
      notifyListeners();
    }
  }

  // ========== INFORMACIÓN DEL PEDIDO ==========
  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setUserNote(String note) {
    _userNote = note;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // ========== VERIFICACIONES ==========
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final item = _items.firstWhere(
            (item) => item.product.id == productId,
        orElse: () => CartItem(product: ProductEntity(
            id: '', businessId: '', name: '', description: '',
            price: 0, category: '', imageUrls: [],
            isAvailable: false, stock: 0, createdAt: DateTime.now()
        ))
    );
    return item.quantity;
  }

  // ========== LIMPIAR CARRITO ==========
  void clearCart() {
    _items.clear();
    _deliveryAddress = '';
    _userNote = '';
    _paymentMethod = 'cash';
    notifyListeners();
  }

  // ========== GENERAR RESUMEN ==========
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'totalAmount': totalAmount,
      'items': _items.map((item) => {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'unitPrice': item.product.price,
        'totalPrice': item.totalPrice,
        'notes': item.notes,
        'modifications': item.modifications,
      }).toList(),
    };
  }
}