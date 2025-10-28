import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool _termsAccepted = false;

  final Color primaryColor = const Color(0xFF008C9E);

  void _register() async {
    final authViewModel = context.read<AuthViewModel>();

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes aceptar los términos y condiciones")));
      return;
    }

    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las contraseñas no coinciden")));
      return;
    }

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, completa todos los campos")));
      return;
    }

    final success = await authViewModel.register(
        emailController.text.trim(),
        passwordController.text.trim(),
        nameController.text.trim()
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso. Ahora puedes iniciar sesión"))
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
    const double logoSize = 140.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Logo
                  Container(
                    width: logoSize,
                    height: logoSize,
                    margin: const EdgeInsets.only(bottom: 20, top: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25),
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

                  // 2. Campos de texto
                  _buildTextField(nameController, "Nombre"),
                  const SizedBox(height: 15),
                  _buildTextField(emailController, "Email"),
                  const SizedBox(height: 15),
                  _buildTextField(passwordController, "Contraseña", obscure: true),
                  const SizedBox(height: 15),
                  _buildTextField(confirmController, "Confirmar contraseña", obscure: true),
                  const SizedBox(height: 20),

                  // 3. Checkbox términos
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: authViewModel.isLoading ? null : (bool? newValue) {
                            setState(() {
                              _termsAccepted = newValue ?? false;
                            });
                          },
                          activeColor: Colors.grey[400],
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        const Text(
                            "términos y condiciones",
                            style: TextStyle(fontSize: 14, color: Colors.black87)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 4. Botón Registrarse
                  ElevatedButton(
                    onPressed: authViewModel.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                      elevation: 10,
                      shadowColor: primaryColor.withOpacity(0.5),
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
                      "Registrarse",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Enlace a login
                  TextButton(
                    onPressed: authViewModel.isLoading ? null : () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));
                    },
                    child: const Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
            isDense: true,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}