import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../admin/admin_panel.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final Color backgroundColor = const Color(0xFF008C9E);
  final Color primaryColor = const Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    // Inicializar listener de autenticación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initializeAuthListener();
    });
  }

  void _login() async {
    final authViewModel = context.read<AuthViewModel>();

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, completa todos los campos"))
      );
      return;
    }

    final success = await authViewModel.login(
        emailController.text.trim(),
        passwordController.text.trim()
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanel()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authViewModel.errorMessage))
      );
    }
  }

  void _loginGoogle() async {
    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.loginWithGoogle();

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanel()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authViewModel.errorMessage))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Área superior: Logo, SuperFast y Bienvenida
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/logo.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "SuperFast",
                        style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Bienvenido de nuevo",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Contenedor de Formulario
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Email", style: TextStyle(color: Colors.black)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                        ),
                      ),
                      const SizedBox(height: 15),

                      const Text("Contraseña", style: TextStyle(color: Colors.black)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Botón Iniciar sesión
                      ElevatedButton(
                        onPressed: authViewModel.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 5,
                        ),
                        child: authViewModel.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          "Iniciar sesión",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Botones de Registro y Google
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Botón de Registrarse
                      ElevatedButton(
                        onPressed: authViewModel.isLoading ? null : () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Registrarse",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Botón Iniciar con Google
                      ElevatedButton.icon(
                        icon: const Icon(Icons.mail_outline, size: 20),
                        onPressed: authViewModel.isLoading ? null : _loginGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 1,
                        ),
                        label: authViewModel.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                            : const Text(
                          "Iniciar con Google",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}