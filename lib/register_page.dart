import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
  final authService = AuthService();
  bool _termsAccepted = false; // Estado para el Checkbox

  // Color principal de la aplicación (#008C9E) para el botón Registrarse
  final Color primaryColor = const Color(0xFF008C9E);

  void register() async {
    // Validar que los términos y condiciones estén aceptados
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes aceptar los términos y condiciones")));
      return;
    }

    if (passwordController.text == confirmController.text) {
      final user = await authService.register(
          emailController.text.trim(), passwordController.text.trim());
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al registrarse")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las contraseñas no coinciden")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se calcula una altura adecuada para el logo (por ejemplo, 140px)
    const double logoSize = 140.0;

    return Scaffold(
      // Se ELIMINA el AppBar para quitar el texto "Registro"
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          // Padding vertical reducido y se utiliza SafeArea para manejar la barra de estado
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Área superior: Logo (Ahora más grande y más arriba)
                  Container(
                    width: logoSize,
                    height: logoSize,
                    // Se reduce el margen superior al estar más arriba
                    margin: const EdgeInsets.only(bottom: 20, top: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25), // Bordes ligeramente más redondeados
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      // Uso de Asset para el logo
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Separador para subir el formulario si es necesario
                  // const SizedBox(height: 20),

                  // 2. Campos de texto
                  _buildTextField(nameController, "Nombre"),
                  const SizedBox(height: 15),
                  _buildTextField(emailController, "Email"),
                  const SizedBox(height: 15),
                  _buildTextField(passwordController, "Contraseña", obscure: true),
                  const SizedBox(height: 15),
                  _buildTextField(confirmController, "Confirmar contraseña", obscure: true),
                  const SizedBox(height: 20),

                  // 3. Checkbox "términos y condiciones"
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (bool? newValue) {
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

                  // 4. Botón Registrarse (Estilo Píldora)
                  ElevatedButton(
                    onPressed: register,
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
                    child: const Text(
                      "Registrarse",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. ¿Ya tienes cuenta? Inicia sesión
                  TextButton(
                    onPressed: () {
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

  // Helper para construir los TextField con el estilo
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
}