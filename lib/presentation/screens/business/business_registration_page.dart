// lib/presentation/screens/business/business_registration_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/business_registration_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

class BusinessRegistrationPage extends StatefulWidget {
  const BusinessRegistrationPage({super.key});

  @override
  State<BusinessRegistrationPage> createState() => _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState extends State<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  final BusinessRegistrationService _businessService = BusinessRegistrationService();

  bool _isLoading = false;
  String _selectedCategory = 'Restaurante';
  final List<String> _categories = [
    'Restaurante',
    'Cafetería',
    'Tienda',
    'Supermercado',
    'Farmacia',
    'Ropa',
    'Electrónicos',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingBusiness();
  }

  Future<void> _checkExistingBusiness() async {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user != null) {
      final hasBusiness = await _businessService.userHasBusiness(user.id);
      if (hasBusiness && mounted) {
        final status = await _businessService.getUserBusinessStatus(user.id);
        _showBusinessStatusDialog(status);
      }
    }
  }

  void _showBusinessStatusDialog(String? status) {
    String title = 'Solicitud de Empresa';
    String message = '';
    bool canDismiss = true;

    switch (status) {
      case 'pending':
        title = 'Solicitud Pendiente';
        message = 'Ya tienes una solicitud de empresa en revisión. '
            'Por favor espera la aprobación de nuestro equipo.';
        canDismiss = true;
        break;
      case 'approved':
        title = 'Empresa Aprobada';
        message = '¡Felicidades! Tu empresa ha sido aprobada. '
            'Ahora puedes gestionar tu negocio desde el panel de empresa.';
        canDismiss = true;
        break;
      case 'rejected':
        title = 'Solicitud Rechazada';
        message = 'Tu solicitud de empresa fue rechazada. '
            'Puedes contactar al soporte para más información o enviar una nueva solicitud.';
        canDismiss = true;
        break;
      default:
        return; // No mostrar diálogo si no hay estado
    }

    showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (status == 'rejected')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Permitir registrar nuevamente
              },
              child: const Text('Intentar Nuevamente'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (status == 'approved' || status == 'pending') {
                Navigator.of(context).pop(); // Volver al dashboard
              }
            },
            child: Text(status == 'rejected' ? 'Cancelar' : 'Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      if (user.role != 'user') {
        throw Exception('Solo usuarios con rol "user" pueden registrar empresas');
      }

      await _businessService.registerBusiness(
        userId: user.id,
        userEmail: user.email,
        businessName: _businessNameController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Solicitud Enviada'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Tu solicitud de registro ha sido enviada.'),
            SizedBox(height: 8),
            Text('📋 Estado: Pendiente de aprobación'),
            SizedBox(height: 8),
            Text('⏰ Tiempo estimado: 24-48 horas'),
            SizedBox(height: 8),
            Text(
              'Recibirás una notificación cuando tu empresa sea aprobada.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver al dashboard
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    String errorMessage = 'Error al registrar la empresa';

    if (error.contains('Usuario no encontrado')) {
      errorMessage = 'Usuario no encontrado. Por favor, inicia sesión nuevamente.';
    } else if (error.contains('rol "user"')) {
      errorMessage = 'Solo usuarios normales pueden registrar empresas.';
    } else if (error.contains('network')) {
      errorMessage = 'Error de conexión. Verifica tu internet.';
    } else {
      errorMessage = 'Error: $error';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error de Registro'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Mi Empresa'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildRegistrationForm(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Registrando tu empresa...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Esto puede tomar unos momentos',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información importante - CORREGIDO: sin withOpacity
            _buildInfoCard(),
            const SizedBox(height: 20),

            // Nombre del negocio
            _buildTextField(
              controller: _businessNameController,
              label: 'Nombre del Negocio *',
              hintText: 'Ej: Mi Restaurante Delicioso',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre del negocio';
                }
                if (value.length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoría
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // Dirección
            _buildTextField(
              controller: _addressController,
              label: 'Dirección Completa *',
              hintText: 'Ej: Av. Principal #123, Ciudad, Estado',
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la dirección del negocio';
                }
                if (value.length < 10) {
                  return 'La dirección debe ser más específica';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teléfono
            _buildTextField(
              controller: _phoneController,
              label: 'Teléfono de Contacto *',
              hintText: 'Ej: +1 234 567 8900',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un teléfono de contacto';
                }
                if (value.length < 8) {
                  return 'Ingresa un número de teléfono válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción (opcional)
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción del Negocio (Opcional)',
              hintText: 'Describe los productos o servicios que ofreces...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Botón de registro
            _buildRegisterButton(),
            const SizedBox(height: 20),

            // Información del proceso
            _buildProcessInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(25), // CORREGIDO: usar withAlpha en lugar de withOpacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Información Importante',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Tu solicitud será revisada por nuestro equipo\n'
                '• El proceso de aprobación toma 24-48 horas\n'
                '• Recibirás una notificación cuando sea aprobada\n'
                '• Mientras tanto, puedes seguir usando la app como usuario',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría del Negocio *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona una categoría';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerBusiness,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Registrando...'),
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center),
            SizedBox(width: 8),
            Text(
              'Registrar Empresa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // CORREGIDO: usar shade en lugar de withOpacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 ¿Qué pasa después?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '1. Envías la solicitud de registro\n'
                '2. Nuestro equipo revisa la información\n'
                '3. Recibes aprobación o correcciones\n'
                '4. ¡Listo! Podrás gestionar tu negocio\n'
                '5. Aparecerás en la app para recibir pedidos',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}