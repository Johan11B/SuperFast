// lib/presentation/screens/business/business_edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/business_profile_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'dart:io';

class BusinessEditProfileScreen extends StatefulWidget {
  const BusinessEditProfileScreen({super.key});

  @override
  State<BusinessEditProfileScreen> createState() => _BusinessEditProfileScreenState();
}

class _BusinessEditProfileScreenState extends State<BusinessEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  final BusinessProfileService _businessProfileService = BusinessProfileService();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  bool _isLoading = false;
  String _selectedCategory = 'Restaurante';
  File? _selectedLogo;
  String? _currentLogoUrl;

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
    _loadBusinessData();
  }

  void _loadBusinessData() {
    final businessViewModel = context.read<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    if (business != null) {
      _nameController.text = business.name;
      _descriptionController.text = business.description ?? '';
      _addressController.text = business.address;
      _phoneController.text = business.phone;
      _selectedCategory = business.category;
      // Nota: Necesitarías agregar logoUrl a BusinessEntity
    }
  }

  Future<void> _pickLogo() async {
    try {
      final File? imageFile = await _storageService.pickImageFromGallery();
      if (imageFile != null) {
        setState(() {
          _selectedLogo = imageFile;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error seleccionando logo: $e');
    }
  }

  Future<void> _takeLogoPhoto() async {
    try {
      final File? imageFile = await _storageService.takePhotoWithCamera();
      if (imageFile != null) {
        setState(() {
          _selectedLogo = imageFile;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error tomando foto: $e');
    }
  }

  Future<String?> _uploadLogo() async {
    if (_selectedLogo == null) return null;

    try {
      final businessViewModel = context.read<BusinessViewModel>();
      final business = businessViewModel.currentBusiness;

      if (business == null) throw Exception('Empresa no encontrada');

      // Subir logo a Supabase
      final logoUrl = await _storageService.uploadBusinessLogo(
        _selectedLogo!,
        business.id,
      );

      return logoUrl;
    } catch (e) {
      _showErrorSnackbar('Error subiendo logo: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final businessViewModel = context.read<BusinessViewModel>();
      final business = businessViewModel.currentBusiness;

      if (business == null) throw Exception('Empresa no encontrada');

      // Subir logo si hay uno nuevo
      String? newLogoUrl;
      if (_selectedLogo != null) {
        newLogoUrl = await _uploadLogo();
      }

      // Actualizar perfil de la empresa
      await _businessProfileService.updateBusinessProfile(
        businessId: business.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: newLogoUrl,
      );

      // Recargar datos de la empresa
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;
      if (user != null) {
        await businessViewModel.loadCurrentBusiness(user.id);
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackbar('Información de la empresa actualizada exitosamente');
      }
    } catch (e) {
      _showErrorSnackbar('Error actualizando empresa: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLogoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takeLogoPhoto();
              },
            ),
            if (_currentLogoUrl != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar logo actual', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentLogo();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCurrentLogo() async {
    try {
      final businessViewModel = context.read<BusinessViewModel>();
      final business = businessViewModel.currentBusiness;

      if (business == null) return;

      await _businessProfileService.updateBusinessProfile(
        businessId: business.id,
        logoUrl: '',
      );

      // Eliminar logo del storage
      if (_currentLogoUrl != null) {
        await _storageService.deleteImage(_currentLogoUrl!);
      }

      setState(() {
        _currentLogoUrl = null;
        _selectedLogo = null;
      });

      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;
      if (user != null) {
        await businessViewModel.loadCurrentBusiness(user.id);
      }

      _showSuccessSnackbar('Logo eliminado exitosamente');
    } catch (e) {
      _showErrorSnackbar('Error eliminando logo: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessViewModel = context.watch<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Empresa'),
        backgroundColor: Colors.orange,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sección del logo
              _buildLogoSection(),
              const SizedBox(height: 24),

              // Información de la empresa
              _buildBusinessInfoSection(),
              const SizedBox(height: 32),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const Text(
          'Logo de la Empresa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                image: _selectedLogo != null
                    ? DecorationImage(
                  image: FileImage(_selectedLogo!),
                  fit: BoxFit.cover,
                )
                    : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(_currentLogoUrl!),
                  fit: BoxFit.cover,
                )
                    : null),
              ),
              child: _selectedLogo == null &&
                  (_currentLogoUrl == null || _currentLogoUrl!.isEmpty)
                  ? const Icon(Icons.business, size: 40, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  onPressed: _showLogoOptions,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedLogo != null ? 'Nuevo logo seleccionado' : 'Toca para cambiar logo',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de la Empresa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la empresa',
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el nombre de la empresa';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
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
          decoration: const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.category),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección',
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la dirección';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el teléfono';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Guardar Cambios'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}