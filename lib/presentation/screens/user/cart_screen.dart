// cart_screen.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../../domain/entities/order_entity.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    // Podrías cargar la dirección por defecto del usuario aquí
    _addressController.text = '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartViewModel = context.watch<CartViewModel>();
    final orderViewModel = context.read<OrderViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final catalogViewModel = context.read<CatalogViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: cartViewModel.items.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(cartViewModel, orderViewModel, authViewModel, catalogViewModel),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega productos desde el catálogo',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Volver al catálogo
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Explorar Catálogo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartViewModel cartViewModel, OrderViewModel orderViewModel, AuthViewModel authViewModel, CatalogViewModel catalogViewModel) {
    return Column(
      children: [
        // LISTA DE PRODUCTOS
        Expanded(
          child: ListView.builder(
            itemCount: cartViewModel.items.length,
            itemBuilder: (context, index) {
              final item = cartViewModel.items[index];
              return _buildCartItem(item, cartViewModel);
            },
          ),
        ),

        // RESUMEN Y CHECKOUT
        _buildOrderSummary(cartViewModel, orderViewModel, authViewModel, catalogViewModel),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, CartViewModel cartViewModel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildProductImage(item.product),
        title: Text(
          item.product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.product.formattedPrice} x ${item.quantity}'),
            Text(
              'Total: \$${(item.totalPrice).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Nota: ${item.notes!}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (item.quantity > 1) {
                  cartViewModel.updateQuantity(item.product.id, item.quantity - 1);
                } else {
                  cartViewModel.removeFromCart(item.product.id);
                }
              },
            ),
            Text('${item.quantity}'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (item.quantity < item.product.stock) {
                  cartViewModel.updateQuantity(item.product.id, item.quantity + 1);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay más stock disponible')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showRemoveItemDialog(item, cartViewModel);
              },
            ),
          ],
        ),
        onTap: () {
          _showEditItemDialog(item, cartViewModel);
        },
      ),
    );
  }

  Widget _buildProductImage(ProductEntity product) {
    if (product.imageUrls.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(product.imageUrls.first),
      );
    } else {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          product.name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildOrderSummary(CartViewModel cartViewModel, OrderViewModel orderViewModel, AuthViewModel authViewModel, CatalogViewModel catalogViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // DIRECCIÓN DE ENTREGA
          _buildAddressSection(),

          // NOTA DEL PEDIDO
          _buildOrderNotesSection(),

          // MÉTODO DE PAGO
          _buildPaymentMethodSection(),

          const SizedBox(height: 16),

          // RESUMEN DE PRECIOS
          _buildPriceSummary(cartViewModel),

          const SizedBox(height: 16),

          // BOTÓN DE PEDIDO
          ElevatedButton(
            onPressed: () {
              _placeOrder(cartViewModel, orderViewModel, authViewModel, catalogViewModel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Realizar Pedido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dirección de entrega',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu dirección completa',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 2,
          onChanged: (value) {
            context.read<CartViewModel>().setDeliveryAddress(value);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOrderNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas para el negocio (opcional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'Instrucciones especiales, alergias, etc.',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 2,
          onChanged: (value) {
            context.read<CartViewModel>().setUserNote(value);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de pago',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
            DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
            DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
            context.read<CartViewModel>().setPaymentMethod(value!);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPriceSummary(CartViewModel cartViewModel) {
    return Column(
      children: [
        _buildPriceRow('Subtotal', cartViewModel.subtotal),
        _buildPriceRow('Costo de envío', cartViewModel.deliveryFee),
        _buildPriceRow('Impuestos (10%)', cartViewModel.tax),
        const Divider(),
        _buildPriceRow(
          'TOTAL',
          cartViewModel.totalAmount,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(CartItem item, CartViewModel cartViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Estás seguro de que quieres eliminar ${item.product.name} del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cartViewModel.removeFromCart(item.product.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(CartItem item, CartViewModel cartViewModel) {
    final notesController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${item.product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio: ${item.product.formattedPrice}'),
            const SizedBox(height: 16),
            const Text('Notas (opcional):'),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Ej: Sin picante, bien cocido, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              cartViewModel.updateItemNotes(item.product.id, notesController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _placeOrder(CartViewModel cartViewModel, OrderViewModel orderViewModel, AuthViewModel authViewModel, CatalogViewModel catalogViewModel) async {
    final user = authViewModel.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para realizar un pedido')),
      );
      return;
    }

    if (_addressController.text.isEmpty || _addressController.text == 'Ingresa tu dirección de entrega') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una dirección de entrega')),
      );
      return;
    }

    // Verificar que todos los productos estén disponibles
    for (final item in cartViewModel.items) {
      if (!item.product.canBeSold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.product.name} ya no está disponible')),
        );
        return;
      }
    }

    // OBTENER EL NOMBRE REAL DEL NEGOCIO - CORRECCIÓN IMPORTANTE
    final businessId = cartViewModel.items.first.product.businessId;
    final business = catalogViewModel.getBusinessById(businessId);

    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener información del negocio')),
      );
      return;
    }

    final businessName = business.name; // ✅ NOMBRE REAL DEL NEGOCIO

    // Crear el pedido
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    final orderItems = cartViewModel.items.map((item) => OrderItem(
      productId: item.product.id,
      productName: item.product.name,
      quantity: item.quantity,
      price: item.product.price,
      notes: item.notes,
      modifications: item.modifications,
    )).toList();

    final order = OrderEntity(
      id: orderId,
      userId: user.id,
      businessId: businessId,
      userName: user.name ?? user.email.split('@')[0], // Nombre del usuario o email
      businessName: businessName, // ✅ NOMBRE REAL DEL NEGOCIO
      status: 'pending',
      totalAmount: cartViewModel.totalAmount,
      subtotal: cartViewModel.subtotal,
      deliveryFee: cartViewModel.deliveryFee,
      tax: cartViewModel.tax,
      createdAt: DateTime.now(),
      items: orderItems,
      userNote: cartViewModel.userNote,
      deliveryAddress: cartViewModel.deliveryAddress,
      paymentMethod: cartViewModel.paymentMethod,
      paymentStatus: 'pending',
    );

    final success = await orderViewModel.createOrder(order);

    if (success) {
      cartViewModel.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido realizado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Volver al catálogo
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar el pedido: ${orderViewModel.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}