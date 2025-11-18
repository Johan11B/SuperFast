// lib/presentation/screens/user/user_edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../../core/services/user_profile_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../domain/entities/user_entity.dart';

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});

  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final UserProfileService _userProfileService = UserProfileService();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  bool _isLoading = false;
  bool _isChangingPassword = false;
  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email;
      _currentPhotoUrl = user.photoUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final File? imageFile = await _storageService.pickImageFromGallery();
      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error seleccionando imagen: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final File? imageFile = await _storageService.takePhotoWithCamera();
      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error tomando foto: $e');
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return null;

    try {
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;

      if (user == null) throw Exception('Usuario no autenticado');

      final imageUrl = await _storageService.uploadProfileImage(
        _selectedImage!,
        user.id,
      );

      return imageUrl;
    } catch (e) {
      _showErrorSnackbar('Error subiendo imagen: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;

      if (user == null) throw Exception('Usuario no autenticado');

      // Subir imagen si hay una nueva
      String? newPhotoUrl;
      if (_selectedImage != null) {
        newPhotoUrl = await _uploadProfileImage();
      }

      // Actualizar perfil
      await _userProfileService.updateUserProfile(
        userId: user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim() != user.email ?
        _emailController.text.trim() : null,
        photoUrl: newPhotoUrl,
      );

      // ✅ CORREGIDO: Ahora el método existe en AuthViewModel
      await authViewModel.loadCurrentUser();

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackbar('Perfil actualizado exitosamente');
      }
    } catch (e) {
      _showErrorSnackbar('Error actualizando perfil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Las contraseñas no coinciden');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackbar('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      await _userProfileService.changePassword(_newPasswordController.text);

      if (mounted) {
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        _showSuccessSnackbar('Contraseña cambiada exitosamente');
      }
    } catch (e) {
      _showErrorSnackbar('Error cambiando contraseña: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  void _showImageOptions() {
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
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_currentPhotoUrl != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto actual', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentPhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCurrentPhoto() async {
    try {
      final authViewModel = context.read<AuthViewModel>();
      final user = authViewModel.currentUser;

      if (user == null) return;

      await _userProfileService.updateUserProfile(
        userId: user.id,
        photoUrl: '',
      );

      if (_currentPhotoUrl != null) {
        await _storageService.deleteImage(_currentPhotoUrl!);
      }

      setState(() {
        _currentPhotoUrl = null;
        _selectedImage = null;
      });

      // ✅ CORREGIDO: Ahora el método existe en AuthViewModel
      await authViewModel.loadCurrentUser();

      _showSuccessSnackbar('Foto eliminada exitosamente');
    } catch (e) {
      _showErrorSnackbar('Error eliminando foto: $e');
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
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
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
              // Sección de imagen de perfil
              _buildProfileImageSection(user),
              const SizedBox(height: 24),

              // Información personal
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),

              // Cambio de contraseña
              _buildChangePasswordSection(),
              const SizedBox(height: 32),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODOS CORREGIDOS PARA EL PROBLEMA DE TIPADO DE IMAGEN
  Widget _buildProfileImageSection(UserEntity? user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _getBackgroundImage(),
              child: _shouldShowInitials()
                  ? Text(
                _getInitials(user),
                style: const TextStyle(fontSize: 24, color: Colors.white),
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: _showImageOptions,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedImage != null ? 'Nueva imagen seleccionada' : 'Toca para cambiar foto',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  bool _shouldShowInitials() {
    return _selectedImage == null &&
        (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty);
  }

  String _getInitials(UserEntity? user) {
    if (user?.name?.isNotEmpty == true) {
      return user!.name!.substring(0, 1).toUpperCase();
    } else if (user?.email.isNotEmpty == true) {
      return user!.email.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Personal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu email';
            }
            if (!value.contains('@')) {
              return 'Ingresa un email válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildChangePasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cambiar Contraseña',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Deja estos campos vacíos si no quieres cambiar la contraseña',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _newPasswordController,
          decoration: const InputDecoration(
            labelText: 'Nueva contraseña',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(
            labelText: 'Confirmar nueva contraseña',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        if (_isChangingPassword)
          const Center(child: CircularProgressIndicator())
        else if (_newPasswordController.text.isNotEmpty ||
            _confirmPasswordController.text.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cambiar Contraseña'),
            ),
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
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}