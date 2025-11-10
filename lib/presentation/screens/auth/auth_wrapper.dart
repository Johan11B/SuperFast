// lib/presentation/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/user_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_page.dart';
import '../admin/admin_panel.dart';
import '../business/business_panel.dart';
import '../user/user_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastUserId;
  String? _lastRole;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initializeAuthListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return StreamBuilder<UserEntity?>(
      stream: authViewModel.authRepository.authStateChanges,
      builder: (context, snapshot) {
        debugPrint('🔄 AuthWrapper - Estado: ${snapshot.connectionState}, '
            'Tiene datos: ${snapshot.hasData}, '
            'Error: ${snapshot.error}');

        // Mostrar loading durante la inicialización
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ AuthWrapper - Esperando estado de autenticación...');
          return _buildLoadingScreen('Verificando sesión...');
        }

        // Si hay error en el stream
        if (snapshot.hasError) {
          debugPrint('❌ AuthWrapper - Error en stream: ${snapshot.error}');
          return _buildErrorScreen(snapshot.error.toString());
        }

        // Si no hay usuario autenticado
        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint('🚫 AuthWrapper - No hay usuario, mostrando LoginPage');
          _resetLastUser();
          return const LoginPage();
        }

        // Usuario autenticado
        final user = snapshot.data!;
        debugPrint('✅ AuthWrapper - Usuario autenticado: ${user.email} con rol: ${user.role}');

        return _handleAuthenticatedUser(user);
      },
    );
  }

  Widget _handleAuthenticatedUser(UserEntity user) {
    final currentUserId = user.id;
    final currentRole = user.role;

    // Verificar si es un usuario/rol diferente al anterior
    final isNewUserOrRole = _lastUserId != currentUserId || _lastRole != currentRole;

    debugPrint('🔍 Comparación usuario: $_lastUserId -> $currentUserId');
    debugPrint('🔍 Comparación rol: $_lastRole -> $currentRole');
    debugPrint('🔍 isNewUserOrRole: $isNewUserOrRole, _isNavigating: $_isNavigating');

    if (isNewUserOrRole && !_isNavigating) {
      debugPrint('🎯 Navegando a pantalla de $currentRole (Usuario: ${user.email})');

      _lastUserId = currentUserId;
      _lastRole = currentRole;
      _isNavigating = true;

      // Navegar inmediatamente usando post-frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateBasedOnRole(currentRole);
      });

      // Mostrar loading mientras navega
      return _buildLoadingScreen('Cargando aplicación...');
    }

    // Si ya estamos en la pantalla correcta, mostrar el contenido
    // Pero si estamos en proceso de navegación, seguir mostrando loading
    if (_isNavigating) {
      return _buildLoadingScreen('Cargando aplicación...');
    }

    // Si ya estamos en la pantalla correcta, mostrar el contenido real
    return _getCurrentScreen(user.role);
  }

  Widget _getCurrentScreen(String role) {
    switch (role) {
      case 'admin':
        return const AdminPanel();
      case 'business':
        return const BusinessPanel();
      case 'user':
        return const UserDashboard();
      default:
        return const LoginPage();
    }
  }

  void _navigateBasedOnRole(String role) {
    debugPrint('🚀 Ejecutando navegación a: $role');

    try {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => _getCurrentScreen(role)),
            (route) => false,
      );
      debugPrint('✅ Navegación completada a: $role');
    } catch (e) {
      debugPrint('❌ Error en navegación: $e');
    } finally {
      // Resetear flag después de un delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _isNavigating = false;
        debugPrint('🔄 Flag _isNavigating resetado a false');
      });
    }
  }

  void _resetLastUser() {
    _lastUserId = null;
    _lastRole = null;
    _isNavigating = false;
    debugPrint('🔄 Estado resetado: _lastUserId: null, _lastRole: null, _isNavigating: false');
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
                onPressed: () {
                  setState(() {});
                },
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

  @override
  void dispose() {
    _resetLastUser();
    super.dispose();
  }
}