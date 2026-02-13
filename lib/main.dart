// lib/main.dart - VERSIÓN COMPLETA ACTUALIZADA
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/screens/auth/auth_wrapper.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'presentation/viewmodels/business_viewmodel.dart';
import 'presentation/viewmodels/catalog_viewmodel.dart';
import 'data/repositories/auth_repository.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'core/services/role_service.dart';
import 'core/services/user_service.dart';
import 'core/services/business_registration_service.dart';
import 'core/services/order_service.dart';
import 'core/services/product_service.dart';
import 'core/services/supabase_storage_service.dart';
import 'core/services/catalog_service.dart';
import 'core/services/user_profile_service.dart';
import 'core/services/business_profile_service.dart';
import 'presentation/viewmodels/order_viewmodel.dart';
import 'presentation/viewmodels/cart_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  await Firebase.initializeApp();

  // 2. Configurar e inicializar Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const SuperFastApp());
}

class SuperFastApp extends StatelessWidget {
  const SuperFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ========== SERVICIOS BÁSICOS ==========
        Provider(create: (_) => RoleService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => BusinessRegistrationService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => SupabaseStorageService()),
        Provider(create: (_) => CatalogService()),
        Provider(create: (_) => UserProfileService()),
        Provider(create: (_) => BusinessProfileService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => OrderService()),

        // ========== SERVICIOS QUE DEPENDEN DE OTROS ==========
        Provider<ProductService>(
          create: (context) => ProductService(
            storageService: context.read<SupabaseStorageService>(),
          ),
        ),

        // ========== REPOSITORIOS ==========
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            remoteDataSource: AuthRemoteDataSource(),
            roleService: context.read<RoleService>(),
          ),
        ),

        // ========== VIEWMODELS ==========
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
            roleService: context.read<RoleService>(),
          ),
        ),

        ChangeNotifierProvider<AdminViewModel>(
          create: (context) => AdminViewModel(
            userService: context.read<UserService>(),
            businessRegistrationService: context.read<BusinessRegistrationService>(),
          ),
        ),

        ChangeNotifierProvider<CartViewModel>(
          create: (_) => CartViewModel(),
        ),

        ChangeNotifierProvider<OrderViewModel>(
          create: (context) => OrderViewModel(
            orderService: context.read<OrderService>(),
          ),
        ),

        ChangeNotifierProvider<BusinessViewModel>(
          create: (context) => BusinessViewModel(
            productService: context.read<ProductService>(),
            businessRegistrationService: context.read<BusinessRegistrationService>(),
            storageService: context.read<SupabaseStorageService>(),
          ),
        ),

        // 🔹 CATALOG VIEWMODEL
        ChangeNotifierProvider<CatalogViewModel>(
          create: (context) {
            print('🔄 Creando CatalogViewModel...');
            return CatalogViewModel(
              catalogService: context.read<CatalogService>(),
            );
          },
        ),
        // ✅ AGREGAR ORDER VIEWMODEL
        ChangeNotifierProvider<OrderViewModel>(
          create: (context) => OrderViewModel(
            orderService: context.read<OrderService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SuperFast',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          primaryColor: const Color(0xFF008C9E),
          scaffoldBackgroundColor: const Color(0xFFEFEFEF),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF008C9E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF008C9E),
            foregroundColor: Colors.white,
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}