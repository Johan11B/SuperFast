// lib/presentation/screens/business/business_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/business_viewmodel.dart';

class BusinessProductsScreen extends StatefulWidget {
  const BusinessProductsScreen({super.key});

  @override
  State<BusinessProductsScreen> createState() => _BusinessProductsScreenState();
}

class _BusinessProductsScreenState extends State<BusinessProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final businessViewModel = context.read<BusinessViewModel>();
    businessViewModel.updateSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessViewModel = context.watch<BusinessViewModel>();

    return Scaffold(
      body: Column(
        children: [
          // 🔍 BARRA DE BÚSQUEDA
          _buildSearchBar(businessViewModel),

          // 🏷️ FILTROS POR CATEGORÍA
          _buildCategoryFilters(businessViewModel),

          // 📦 LISTA DE PRODUCTOS
          Expanded(
            child: _buildProductsList(businessViewModel),
          ),
        ],
      ),

      // ➕ BOTÓN AGREGAR PRODUCTO
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 🔍 BARRA DE BÚSQUEDA
  Widget _buildSearchBar(BusinessViewModel businessViewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              businessViewModel.updateSearchQuery('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // 🏷️ FILTROS POR CATEGORÍA
  Widget _buildCategoryFilters(BusinessViewModel businessViewModel) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('Todos', 'Todas', businessViewModel),
          const SizedBox(width: 8),
          ...businessViewModel.categories.where((cat) => cat != 'Todas').map(
                (category) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildFilterChip(category, category, businessViewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, BusinessViewModel viewModel) {
    return FilterChip(
      label: Text(label),
      selected: viewModel.selectedCategory == value,
      onSelected: (selected) {
        viewModel.updateSelectedCategory(value);
      },
    );
  }

  // 📦 LISTA DE PRODUCTOS
  Widget _buildProductsList(BusinessViewModel businessViewModel) {
    if (businessViewModel.isLoadingProducts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando productos...'),
          ],
        ),
      );
    }

    if (businessViewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar productos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                businessViewModel.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (businessViewModel.currentBusiness != null) {
                  businessViewModel.loadBusinessProducts(
                      businessViewModel.currentBusiness!.id
                  );
                }
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (businessViewModel.filteredProducts.isEmpty) {
      return _buildEmptyState(businessViewModel);
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (businessViewModel.currentBusiness != null) {
          await businessViewModel.loadBusinessProducts(
              businessViewModel.currentBusiness!.id
          );
        }
      },
      child: ListView.builder(
        itemCount: businessViewModel.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = businessViewModel.filteredProducts[index];
          return _buildProductCard(product, businessViewModel);
        },
      ),
    );
  }

  // 🎯 ESTADO VACÍO
  Widget _buildEmptyState(BusinessViewModel businessViewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay productos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron productos para "${_searchController.text}"'
                : 'Agrega tu primer producto para comenzar',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Producto'),
          ),
        ],
      ),
    );
  }

  // 🃏 TARJETA DE PRODUCTO
  Widget _buildProductCard(ProductEntity product, BusinessViewModel businessViewModel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: product.isAvailable ? Colors.green : Colors.grey,
          child: product.imageUrls.isNotEmpty
              ? CircleAvatar(
            backgroundImage: NetworkImage(product.imageUrls.first),
            radius: 25,
          )
              : Text(
            product.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: product.isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              product.description.isNotEmpty
                  ? product.description
                  : 'Sin descripción',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // PRECIO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // STOCK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStockColor(product.stock),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                // CATEGORÍA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              product.isAvailable ? '🟢 Disponible' : '🔴 No disponible',
              style: TextStyle(
                fontSize: 12,
                color: product.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product, businessViewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: product.isAvailable ? 'disable' : 'enable',
              child: Row(
                children: [
                  Icon(
                    product.isAvailable ? Icons.pause : Icons.play_arrow,
                    size: 20,
                    color: product.isAvailable ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(product.isAvailable ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _showProductDetails(product, businessViewModel);
        },
      ),
    );
  }

  // 🎮 MANEJO DE ACCIONES
  void _handleProductAction(String action, ProductEntity product, BusinessViewModel businessViewModel) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(context, product);
        break;
      case 'enable':
        businessViewModel.toggleProductAvailability(product.id, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${product.name}" activado'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'disable':
        businessViewModel.toggleProductAvailability(product.id, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${product.name}" desactivado'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case 'delete':
        _showDeleteProductDialog(context, product, businessViewModel);
        break;
    }
  }

  // 🗑️ DIÁLOGO ELIMINAR PRODUCTO
  void _showDeleteProductDialog(BuildContext context, ProductEntity product, BusinessViewModel businessViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres eliminar "${product.name}"?'),
            const SizedBox(height: 8),
            Text(
              'Precio: \$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Stock: ${product.stock} unidades',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Esta acción no se puede deshacer',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
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
              businessViewModel.deleteProduct(product.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Producto "${product.name}" eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 👁️ DETALLES DEL PRODUCTO
  void _showProductDetails(ProductEntity product, BusinessViewModel businessViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imágenes (si hay)
              if (product.imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(product.imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildDetailItem('Nombre:', product.name),
              _buildDetailItem('Descripción:', product.description.isNotEmpty ? product.description : 'Sin descripción'),
              _buildDetailItem('Precio:', '\$${product.price.toStringAsFixed(2)}'),
              _buildDetailItem('Categoría:', product.category),
              _buildDetailItem('Stock:', '${product.stock} unidades'),
              _buildDetailItem('Disponibilidad:', product.isAvailable ? '🟢 Disponible' : '🔴 No disponible'),
              _buildDetailItem('Estado Stock:', _getStockStatus(product.stock)),

              const SizedBox(height: 16),
              const Text(
                'Información de Inventario:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildInventoryInfo(product),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditProductDialog(context, product);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryInfo(ProductEntity product) {
    List<Widget> infoItems = [];

    if (product.stock == 0) {
      infoItems.add(const Text('• ⚠️ Producto sin stock'));
      infoItems.add(const Text('• No está disponible para venta'));
    } else if (product.stock < 5) {
      infoItems.add(const Text('• ⚠️ Stock bajo'));
      infoItems.add(Text('• Considera reponer stock (${product.stock} unidades)'));
    } else {
      infoItems.add(const Text('• ✅ Stock saludable'));
      infoItems.add(Text('• ${product.stock} unidades disponibles'));
    }

    if (!product.isAvailable) {
      infoItems.add(const Text('• 🔴 Producto desactivado'));
      infoItems.add(const Text('• No visible para clientes'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoItems.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: item,
      )).toList(),
    );
  }

  String _getStockStatus(int stock) {
    if (stock == 0) return 'Sin stock';
    if (stock < 5) return 'Stock bajo';
    if (stock < 10) return 'Stock medio';
    return 'Stock alto';
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  // ➕ DIÁLOGO AGREGAR PRODUCTO - CORREGIDO
  void _showAddProductDialog(BuildContext context) {
    final businessViewModel = context.read<BusinessViewModel>();

    // VERIFICAR businessId ANTES de abrir el diálogo
    if (businessViewModel.currentBusiness?.id.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener la información de la empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        onSubmit: (product) async {
          final success = await businessViewModel.addProduct(product);

          if (success && context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto agregado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${businessViewModel.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  // ✏️ DIÁLOGO EDITAR PRODUCTO - CORREGIDO
  void _showEditProductDialog(BuildContext context, ProductEntity product) {
    // VERIFICAR que el producto tenga ID válido
    if (product.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: El producto no tiene ID válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        onSubmit: (updatedProduct) async {
          final businessViewModel = context.read<BusinessViewModel>();
          final success = await businessViewModel.updateProduct(updatedProduct);

          if (success && context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${businessViewModel.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

// 📝 FORMULARIO DE PRODUCTO (DIÁLOGO) - COMPLETAMENTE CORREGIDO
class ProductFormDialog extends StatefulWidget {
  final Function(ProductEntity) onSubmit;
  final ProductEntity? product;

  const ProductFormDialog({
    super.key,
    required this.onSubmit,
    this.product,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isAvailable = true;

  final List<String> _categories = [
    'General', 'Restaurante', 'Cafetería', 'Tienda', 'Supermercado',
    'Farmacia', 'Ropa', 'Electrónicos', 'Hogar', 'Otros'
  ];

  @override
  void initState() {
    super.initState();

    // Si estamos editando, llenar los campos
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _selectedCategory = widget.product!.category;
      _isAvailable = widget.product!.isAvailable;

      print('🔄 ProductFormDialog - Editando producto:');
      print('   - ID: ${widget.product!.id}');
      print('   - BusinessId: ${widget.product!.businessId}');
      print('   - Nombre: ${widget.product!.name}');
    } else {
      print('🔄 ProductFormDialog - Creando nuevo producto');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessViewModel = context.read<BusinessViewModel>();

    return AlertDialog(
      title: Text(widget.product == null ? 'Agregar Producto' : 'Editar Producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NOMBRE
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto *',
                  hintText: 'Ej: Pizza Margarita',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // DESCRIPCIÓN
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe tu producto...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // PRECIO
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  hintText: 'Ej: 19.99',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es requerido';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Ingresa un precio válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // STOCK
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  hintText: 'Ej: 50',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El stock es requerido';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'Ingresa un stock válido (0 o más)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CATEGORÍA
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // DISPONIBILIDAD
              SwitchListTile(
                title: const Text('Producto Disponible'),
                subtitle: const Text('Los clientes podrán ver y comprar este producto'),
                value: _isAvailable,
                onChanged: (bool value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Guardar Producto'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final businessViewModel = context.read<BusinessViewModel>();

      // OBTENER businessId de forma segura
      final String businessId;
      if (widget.product != null && widget.product!.businessId.isNotEmpty) {
        businessId = widget.product!.businessId;
      } else if (businessViewModel.currentBusiness?.id.isNotEmpty ?? false) {
        businessId = businessViewModel.currentBusiness!.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo obtener la información de la empresa'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // OBTENER ID de forma segura - SI ES EDICIÓN, usar el ID existente
      final String productId;
      if (widget.product != null && widget.product!.id.isNotEmpty) {
        productId = widget.product!.id;
      } else {
        productId = ''; // Para nuevos productos, Firestore generará el ID
      }

      print('🔄 _submitForm - Creando producto:');
      print('   - ID: $productId');
      print('   - BusinessId: $businessId');
      print('   - Nombre: ${_nameController.text.trim()}');

      // Crear el producto - CORREGIDO: Pasar correctamente ID y businessId
      final product = ProductEntity(
        id: productId, // ✅ CORREGIDO: Usar el ID existente para edición
        businessId: businessId, // ✅ CORREGIDO: Usar businessId válido
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrls: widget.product?.imageUrls ?? [],
        isAvailable: _isAvailable,
        stock: int.parse(_stockController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Llamar al callback
      widget.onSubmit(product);
    }
  }
}