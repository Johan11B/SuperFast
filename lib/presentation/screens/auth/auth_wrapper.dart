// lib/presentation/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/user_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_page.dart';
import '../admin/admin_panel.dart';
import '../business/business_panel.dart';
import '../user/user_panel.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      authViewModel.initializeAuthListener();
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    if (!_isInitialized) {
      return _buildLoadingScreen('Inicializando...');
    }

    return StreamBuilder<UserEntity?>(
      stream: authViewModel.authRepository.authStateChanges,
      builder: (context, snapshot) {
        // Mostrar loading durante la inicialización
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen('Verificando sesión...');
        }

        // Si hay error en el stream
        if (snapshot.hasError) {
          debugPrint('❌ AuthWrapper - Error: ${snapshot.error}');
          return _buildErrorScreen(snapshot.error.toString());
        }

        // Si no hay usuario autenticado
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // Usuario autenticado - navegar directamente
        final user = snapshot.data!;
        debugPrint('✅ AuthWrapper - Usuario: ${user.email}, Rol: ${user.role}');

        return _getHomeScreenByRole(user.role);
      },
    );
  }

  // Método simplificado para obtener pantalla por rol
  Widget _getHomeScreenByRole(String role) {
    switch (role) {
      case 'admin':
        return const AdminPanel();
      case 'business':
        return const BusinessPanel();
      case 'user':
        return const UserPanel();
      default:
        return const LoginPage();
    }
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF008C9E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'SuperFast',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Error de Conexión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}