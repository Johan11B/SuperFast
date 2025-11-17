// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'presentation/screens/auth/auth_wrapper.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'presentation/viewmodels/business_viewmodel.dart'; // ✅ NUEVO
import 'data/repositories/auth_repository.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'core/services/role_service.dart';
import 'core/services/user_service.dart';
import 'core/services/business_registration_service.dart';
import 'core/services/order_service.dart';
import 'core/services/product_service.dart'; // ✅ NUEVO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SuperFastApp());
}

class SuperFastApp extends StatelessWidget {
  const SuperFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ========== SERVICIOS ==========
        Provider(create: (_) => RoleService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => BusinessRegistrationService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => ProductService()), // ✅ NUEVO

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

        // ✅ NUEVO: BusinessViewModel
        ChangeNotifierProvider<BusinessViewModel>(
          create: (context) => BusinessViewModel(
            productService: context.read<ProductService>(),
            businessRegistrationService: context.read<BusinessRegistrationService>(),
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
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}