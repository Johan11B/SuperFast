import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/google_signin_service.dart';
import 'register_page.dart';
import 'admin_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  final googleService = GoogleSignInService();

  void login() async {
    final user = await authService.login(
        emailController.text.trim(), passwordController.text.trim());
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanel()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al iniciar sesión")));
    }
  }

  void loginGoogle() async {
    final user = await googleService.signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanel()),
      );
    }
  }

  // Define el color de fondo de la aplicación (#008C9E)
  final Color backgroundColor = const Color(0xFF008C9E);
  // Define un color de acento azul para el logo (si se necesitara para algo más)
  final Color primaryColor = const Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    // El widget Scaffold se envuelve en un Container para el borde negro
    return Container(
      color: Colors.black, // Borde exterior negro
      padding: const EdgeInsets.all(8.0), // Simula el margen exterior
      child: Scaffold(
        // Cambia el color de fondo al valor hexadecimal #008C9E
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
                      // Logo real con un Container para la forma y sombra
                      Container(
                        width: 100, // Ancho del contenedor
                        height: 100, // Alto del contenedor
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20), // Borde redondeado
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          // Aquí se carga la imagen del logo
                          image: const DecorationImage(
                            image: AssetImage('assets/logo.jpg'), // ¡Tu imagen real!
                            fit: BoxFit.cover, // Para que la imagen cubra el contenedor
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Texto SuperFast
                      const Text(
                        "SuperFast",
                        style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      // Texto de bienvenida
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

                // 2. Contenedor de Formulario (Email, Contraseña, Iniciar Sesión)
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
                      // Campo Email
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

                      // Campo Contraseña
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
                        onPressed: login,
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
                        onPressed: () {
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
                        onPressed: loginGoogle,
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
                        label: const Text(
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
}