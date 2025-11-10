import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importaciones
import 'domain/entities/user_entity.dart';
import 'presentation/screens/auth/login_page.dart';
import 'presentation/screens/admin/admin_panel.dart';
import 'presentation/screens/business/business_panel.dart';
import 'presentation/screens/user/user_dashboard.dart';
import 'presentation/screens/settings/ajustes_page.dart';
import 'presentation/screens/performance/performance_results_page.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'data/repositories/auth_repository.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'core/services/role_service.dart';

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
        Provider(create: (_) => RoleService()),
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
          create: (context) => AdminViewModel(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SuperFast',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          primaryColor: const Color(0xFF008C9E),
          scaffoldBackgroundColor: const Color(0xFFEFEFEF),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return StreamBuilder<UserEntity?>(
      stream: authViewModel.authRepository.authStateChanges,
      builder: (context, snapshot) {
        print('🔄 AuthWrapper - Estado del stream: ${snapshot.connectionState}');
        print('🔄 AuthWrapper - Tiene datos: ${snapshot.hasData}');

        // Mientras carga el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ AuthWrapper - Esperando estado de autenticación...');
          return _buildLoadingScreen();
        }

        // Si hay error en el stream
        if (snapshot.hasError) {
          print('❌ AuthWrapper - Error en stream: ${snapshot.error}');
          return _buildErrorScreen(snapshot.error.toString());
        }

        // Si no hay usuario autenticado
        if (!snapshot.hasData || snapshot.data == null) {
          print('🚫 AuthWrapper - No hay usuario, mostrando LoginPage');
          return const LoginPage();
        }

        // Usuario autenticado - redirigir según rol
        final user = snapshot.data!;
        print('✅ AuthWrapper - Usuario autenticado: ${user.email} con rol: ${user.role}');

        return authViewModel.getHomeScreenByRole();
      },
    );
  }

  Widget _buildLoadingScreen() {
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
              'Verificando sesión...',
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
}