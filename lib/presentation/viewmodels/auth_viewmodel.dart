// lib/presentation/viewmodels/auth_viewmodel.dart - VERSIÓN COMPLETA
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/utils/performance_manager.dart';
import '../../core/services/role_service.dart';
import '../screens/auth/login_page.dart';
import '../screens/admin/admin_panel.dart';
import '../screens/business/business_panel.dart';
import '../screens/user/user_panel.dart';

class AuthViewModel with ChangeNotifier {
  final IAuthRepository authRepository;
  final RoleService roleService;

  AuthViewModel({
    required this.authRepository,
    required this.roleService,
  });

  UserEntity? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isLoggingOut = false;
  StreamSubscription<UserEntity?>? _authSubscription;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoggingOut => _isLoggingOut;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  void setLoggingOut(bool value) {
    _isLoggingOut = value;
    notifyListeners();
  }

  Widget getHomeScreenByRole() {
    if (_currentUser == null) {
      return const LoginPage();
    }

    switch (_currentUser!.role) {
      case 'admin':
        return const AdminPanel();
      case 'business':
        return const BusinessPanel();
      case 'user':
        return const UserPanel();
      default:
        return const UserPanel();
    }
  }

  bool canAccess(String feature) {
    if (_currentUser == null) return false;

    final permissions = {
      'admin': ['all'],
      'business': ['manage_products', 'view_orders', 'analytics'],
      'user': ['place_orders', 'view_history', 'rate_products'],
    };

    final userPermissions = permissions[_currentUser!.role] ?? [];
    return userPermissions.contains('all') || userPermissions.contains(feature);
  }

  Future<bool> login(String email, String password) async {
    return await PerformanceManager.measure(
      'Complete Login Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          final user = await authRepository.signInWithEmail(email, password);

          if (user != null) {
            _currentUser = user;
            setLoading(false);
            return true;
          } else {
            setErrorMessage('Error al iniciar sesión. Verifica tus credenciales.');
            setLoading(false);
            return false;
          }
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-credential':
            case 'wrong-password':
            case 'user-not-found':
              errorMessage = 'Credenciales incorrectas. Verifica tu email y contraseña.';
              break;
            case 'user-disabled':
              errorMessage = 'Esta cuenta ha sido deshabilitada. Contacta al soporte.';
              break;
            case 'too-many-requests':
              errorMessage = 'Demasiados intentos fallidos. Espera un momento e inténtalo de nuevo.';
              break;
            case 'network-request-failed':
              errorMessage = 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido. Verifícalo.';
              break;
            default:
              errorMessage = 'Error al iniciar sesión: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado al iniciar sesión. Inténtalo de nuevo.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  Future<bool> register(String email, String password, String name) async {
    return await PerformanceManager.measure(
      'Complete Registration Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          final user = await authRepository.signUpWithEmail(email, password, name);

          if (user != null) {
            _currentUser = user;
            setLoading(false);
            return true;
          } else {
            setErrorMessage('Error al registrar usuario.');
            setLoading(false);
            return false;
          }
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'Este email ya está registrado. Inicia sesión o usa otro email.';
              break;
            case 'weak-password':
              errorMessage = 'La contraseña es muy débil. Usa al menos 6 caracteres.';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido. Verifícalo.';
              break;
            default:
              errorMessage = 'Error al registrar: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado al registrar. Inténtalo de nuevo.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  Future<bool> loginWithGoogle() async {
    return await PerformanceManager.measure(
      'Complete Google Sign-In Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          final user = await authRepository.signInWithGoogle();

          if (user != null) {
            _currentUser = user;
            setLoading(false);
            return true;
          } else {
            setErrorMessage('Error al iniciar sesión con Google.');
            setLoading(false);
            return false;
          }
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'account-exists-with-different-credential':
              errorMessage = 'Ya existe una cuenta con este email usando otro método de inicio de sesión.';
              break;
            case 'network-request-failed':
              errorMessage = 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
              break;
            default:
              errorMessage = 'Error Google Sign-In: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado con Google Sign-In. Inténtalo de nuevo.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  Future<void> logout() async {
    return await PerformanceManager.measure(
      'Complete Logout Process',
          () async {
        try {
          setLoggingOut(true);
          setLoading(true);

          await authRepository.signOut();

          _currentUser = null;
          setLoading(false);
          setLoggingOut(false);
        } catch (e) {
          setErrorMessage('Error al cerrar sesión: $e');
          setLoading(false);
          setLoggingOut(false);
          rethrow;
        }
      },
    );
  }

  Future<bool> resetPassword(String email) async {
    return await PerformanceManager.measure(
      'Complete Password Reset Process',
          () async {
        try {
          setLoading(true);
          setErrorMessage('');

          await authRepository.resetPassword(email);
          setLoading(false);
          return true;
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No existe una cuenta con este email.';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido.';
              break;
            default:
              errorMessage = 'Error al resetear password: ${e.message}';
          }
          setErrorMessage(errorMessage);
          setLoading(false);
          return false;
        } catch (e) {
          setErrorMessage('Error inesperado al resetear password.');
          setLoading(false);
          return false;
        }
      },
    );
  }

  void clearError() {
    setErrorMessage('');
  }

  void initializeAuthListener() {
    if (_authSubscription != null) return;

    _authSubscription = authRepository.authStateChanges.listen(
          (UserEntity? user) {
        debugPrint('🔄 AuthListener - Usuario recibido: ${user?.email}');

        // Si estamos en proceso de logout, ignorar cambios temporales
        if (_isLoggingOut && user != null) {
          debugPrint('🔄 AuthListener - Ignorando usuario durante logout');
          return;
        }

        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error en auth listener: $error');
        setErrorMessage('Error en autenticación: $error');
      },
    );
  }

  // ✅ MÉTODO AGREGADO: Cargar datos actualizados del usuario
  Future<void> loadCurrentUser() async {
    try {
      setLoading(true);

      // Obtener el usuario actual de Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('🔄 Cargando datos actualizados del usuario: ${firebaseUser.uid}');

        // Por ahora, simplemente actualizamos con los datos que ya tenemos
        // Esto mantiene la funcionalidad existente sin romper nada
        if (_currentUser != null) {
          // Mantenemos el usuario actual pero forzamos una notificación
          notifyListeners();
        }
      }

      setLoading(false);
    } catch (e) {
      setLoading(false);
      debugPrint('❌ Error en loadCurrentUser: $e');
      // No mostramos error al usuario para no interrumpir la experiencia
    }
  }

  // ✅ MÉTODO AGREGADO: Para cuando necesites forzar una recarga completa
  Future<void> refreshUserData() async {
    try {
      setLoading(true);

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('🔄 Refrescando datos del usuario: ${firebaseUser.uid}');

        // ✅ USAR EL NUEVO MÉTODO getCurrentUser
        final updatedUser = await authRepository.getCurrentUser();
        if (updatedUser != null) {
          _currentUser = updatedUser;
          debugPrint('✅ Datos de usuario actualizados: ${updatedUser.email}');
          debugPrint('📸 PhotoUrl actualizada: ${updatedUser.photoUrl}');
        } else {
          debugPrint('⚠️ No se pudieron obtener datos actualizados del usuario');
        }

        notifyListeners();
      }

      setLoading(false);
    } catch (e) {
      setLoading(false);
      debugPrint('❌ Error en refreshUserData: $e');
    }
  }

  // ✅ MÉTODO CORREGIDO: Para actualizar datos locales del usuario (compatible con tu UserEntity)
  void updateLocalUserData({
    String? name,
    String? email,
    String? photoUrl,
    String? businessName,
    String? businessEmail,
    String? businessCategory,
    String? businessAddress,
    String? businessPhone,
  }) {
    if (_currentUser != null) {
      // Crear una nueva instancia con los datos actualizados
      final updatedUser = UserEntity(
        id: _currentUser!.id,
        email: email ?? _currentUser!.email,
        name: name ?? _currentUser!.name,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        role: _currentUser!.role,
        // ✅ CORREGIDO: Solo los campos que existen en tu UserEntity
        businessName: businessName ?? _currentUser!.businessName,
        businessEmail: businessEmail ?? _currentUser!.businessEmail,
        businessCategory: businessCategory ?? _currentUser!.businessCategory,
        businessAddress: businessAddress ?? _currentUser!.businessAddress,
        businessPhone: businessPhone ?? _currentUser!.businessPhone,
      );

      _currentUser = updatedUser;
      notifyListeners();

      debugPrint('✅ Datos locales del usuario actualizados');
    }
  }

  // ✅ MÉTODO ESPECÍFICO PARA ACTUALIZAR SOLO EL PERFIL BÁSICO
  void updateUserProfileData({
    String? name,
    String? email,
    String? photoUrl,
  }) {
    updateLocalUserData(
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }

  // ✅ MÉTODO ESPECÍFICO PARA ACTUALIZAR DATOS DE EMPRESA
  void updateBusinessProfileData({
    String? businessName,
    String? businessEmail,
    String? businessCategory,
    String? businessAddress,
    String? businessPhone,
  }) {
    updateLocalUserData(
      businessName: businessName,
      businessEmail: businessEmail,
      businessCategory: businessCategory,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}