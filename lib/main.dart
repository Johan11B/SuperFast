import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importaciones
import 'presentation/screens/auth/auth_wrapper.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'data/repositories/auth_repository.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'core/services/role_service.dart';
import 'core/services/user_service.dart';
import 'core/services/business_service.dart';
import 'core/services/order_service.dart';

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
        // ✅ SERVICIOS
        Provider(create: (_) => RoleService()),
        Provider(create: (_) => UserService()), // ✅ AGREGAR UserService
        Provider(create: (_) => BusinessService()),
        Provider(create: (_) => OrderService()),

        // ✅ VIEWMODELS
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: AuthRepository(
              remoteDataSource: AuthRemoteDataSource(),
              roleService: context.read<RoleService>(),
            ),
            roleService: context.read<RoleService>(),
          ),
        ),

        ChangeNotifierProvider<AdminViewModel>(
          create: (context) => AdminViewModel(
            userService: context.read<UserService>(), // ✅ AGREGAR PARÁMETROS
            businessService: context.read<BusinessService>(), // ✅ AGREGAR PARÁMETROS
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