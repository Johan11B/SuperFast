import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_page.dart';
import '../../../domain/entities/user_entity.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN

class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  final Color primaryColor = const Color(0xFF008C9E);

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,

      // 1. AppBar estilizado
      appBar: AppBar(
        backgroundColor: primaryColor,
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
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
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
            // 3. Información del usuario actual
            if (authViewModel.currentUser != null) ...[
              _buildUserInfo(authViewModel.currentUser!),
              const SizedBox(height: 30),
            ],

            // 4. Sección Perfil
            const Text(
              "Perfil",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsField(),
            const SizedBox(height: 10),
            _buildSettingsField(),

            const SizedBox(height: 30),

            // 5. Sección Preferencias
            const Text(
              "Preferencias",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsField(),
            const SizedBox(height: 10),
            _buildSettingsField(),
            const SizedBox(height: 10),
            _buildSettingsField(),

            const SizedBox(height: 30),

            // 6. Sección Seguridad
            const Text(
              "Seguridad",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsField(),

            const SizedBox(height: 30),

            // 7. Botón Cerrar Sesión
            InkWell(
              onTap: () async {
                try {
                  await authViewModel.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al cerrar sesión: $e'))
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade300),
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
                        Icon(Icons.door_front_door_outlined, color: Colors.red, size: 28),
                        SizedBox(width: 15),
                        Text(
                          "Cerrar Sesión",
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
              user.name?.isNotEmpty == true
                  ? user.name!.substring(0, 1).toUpperCase()
                  : user.email.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 20, color: Colors.white),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? 'Usuario',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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