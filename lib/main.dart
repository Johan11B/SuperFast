import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/auth/login_page.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'data/repositories/auth_repository.dart';
import 'data/datasources/auth_remote_datasource.dart';

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
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
              authRepository: AuthRepository(
                  remoteDataSource: AuthRemoteDataSource()
              )
          ),
        ),
        ChangeNotifierProvider(
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
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF008C9E),
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}