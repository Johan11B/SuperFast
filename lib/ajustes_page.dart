import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'admin_panel.dart';

class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  final Color primaryColor = const Color(0xFF008C9E);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco

      // 1. AppBar estilizado
      appBar: AppBar(
        backgroundColor: primaryColor, // Fondo teal
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Ajustes",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 40,
          ),
        ),
        centerTitle: false,
        actions: [
          // Logo en la esquina derecha
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              // Usar el mismo logo del panel administrativo
              image: const DecorationImage(
                image: AssetImage('assets/logo_panel.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),

      // 2. Contenido del cuerpo
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. Sección Perfil
            const Text(
              "Perfil",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsField(),
            const SizedBox(height: 10),
            _buildSettingsField(), // Dos campos para Perfil

            const SizedBox(height: 30),

            // 4. Sección Preferencias
            const Text(
              "Preferencias",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsField(),
            const SizedBox(height: 10),
            _buildSettingsField(),
            const SizedBox(height: 10),
            _buildSettingsField(), // Tres campos para Preferencias

            const SizedBox(height: 30),

            // 5. Sección Seguridad
            const Text(
              "Seguridad",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsField(), // Un campo para Seguridad

            const SizedBox(height: 30),

            // 6. Botón Cerrar Sesión (ListTile personalizado)
            InkWell(
              onTap: () async {
                await authService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (Route<dynamic> route) => false, // Limpia todas las rutas anteriores
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade300), // Borde suave
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.door_front_door_outlined, color: Colors.red, size: 28), // Icono rojo
                        SizedBox(width: 15),
                        Text(
                          "Cerrar Sesión",
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 28), // Flecha a la derecha
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper para los campos de configuración vacíos
  Widget _buildSettingsField() {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}