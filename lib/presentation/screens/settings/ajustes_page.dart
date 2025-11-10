import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_page.dart';
import '../../../domain/entities/user_entity.dart';

class AjustesPage extends StatelessWidget {
  final Color primaryColor;
  final String userRole;

  const AjustesPage({
    super.key,
    this.primaryColor = const Color(0xFF008C9E),
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _getAppBarColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 35,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            if (authViewModel.currentUser != null) ...[
              _buildUserInfo(authViewModel.currentUser!),
              const SizedBox(height: 30),
            ],

            // Secciones según el rol
            ..._buildRoleSpecificSections(),

            const SizedBox(height: 30),

            // Botón Cerrar Sesión (siempre visible)
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // Métodos de personalización según el rol
  Color _getAppBarColor() {
    switch (userRole) {
      case 'admin':
        return const Color(0xFF008C9E); // Azul
      case 'business':
        return Colors.orange; // Naranja
      case 'user':
        return Colors.green; // Verde
      default:
        return const Color(0xFF008C9E);
    }
  }

  String _getTitle() {
    switch (userRole) {
      case 'admin':
        return "Ajustes Administrador";
      case 'business':
        return "Ajustes Empresa";
      case 'user':
        return "Ajustes Usuario";
      default:
        return "Ajustes";
    }
  }

  List<Widget> _buildRoleSpecificSections() {
    switch (userRole) {
      case 'admin':
        return _buildAdminSections();
      case 'business':
        return _buildBusinessSections();
      case 'user':
        return _buildUserSections();
      default:
        return _buildUserSections();
    }
  }

  // SECCIONES PARA ADMIN
  List<Widget> _buildAdminSections() {
    return [
      // Gestión de Sistema
      _buildSectionTitle('Gestión del Sistema'),
      _buildSettingsItem(
        icon: Icons.people,
        title: 'Gestión de Usuarios',
        subtitle: 'Administrar roles y permisos',
        onTap: () {
          print('Navegar a gestión de usuarios');
        },
      ),
      _buildSettingsItem(
        icon: Icons.analytics,
        title: 'Reportes y Estadísticas',
        subtitle: 'Ver métricas del sistema',
        onTap: () {
          print('Navegar a reportes');
        },
      ),
      _buildSettingsItem(
        icon: Icons.security,
        title: 'Configuración de Seguridad',
        subtitle: 'Ajustes de permisos globales',
        onTap: () {
          print('Navegar a seguridad');
        },
      ),

      const SizedBox(height: 30),

      // Configuración General
      _buildSectionTitle('Configuración General'),
      _buildSettingsItem(
        icon: Icons.notifications,
        title: 'Notificaciones',
        subtitle: 'Configurar alertas del sistema',
      ),
      _buildSettingsItem(
        icon: Icons.language,
        title: 'Idioma y Región',
        subtitle: 'Preferencias regionales',
      ),
    ];
  }

  // SECCIONES PARA BUSINESS
  List<Widget> _buildBusinessSections() {
    return [
      // Gestión de Negocio
      _buildSectionTitle('Gestión del Negocio'),
      _buildSettingsItem(
        icon: Icons.inventory,
        title: 'Gestión de Productos',
        subtitle: 'Administrar catálogo',
        onTap: () {
          print('Navegar a productos');
        },
      ),
      _buildSettingsItem(
        icon: Icons.receipt_long,
        title: 'Pedidos y Ventas',
        subtitle: 'Ver historial de pedidos',
        onTap: () {
          print('Navegar a pedidos');
        },
      ),
      _buildSettingsItem(
        icon: Icons.analytics,
        title: 'Analíticas del Negocio',
        subtitle: 'Métricas de ventas y crecimiento',
        onTap: () {
          print('Navegar a analíticas');
        },
      ),

      const SizedBox(height: 30),

      // Configuración
      _buildSectionTitle('Configuración'),
      _buildSettingsItem(
        icon: Icons.store,
        title: 'Información del Negocio',
        subtitle: 'Datos de la empresa',
      ),
      _buildSettingsItem(
        icon: Icons.payment,
        title: 'Métodos de Pago',
        subtitle: 'Configurar formas de pago',
      ),
      _buildSettingsItem(
        icon: Icons.notifications,
        title: 'Notificaciones',
        subtitle: 'Alertas de pedidos',
      ),
    ];
  }

  // SECCIONES PARA USER
  List<Widget> _buildUserSections() {
    return [
      // Cuenta y Preferencias
      _buildSectionTitle('Cuenta y Preferencias'),
      _buildSettingsItem(
        icon: Icons.person,
        title: 'Editar Perfil',
        subtitle: 'Actualizar información personal',
        onTap: () {
          print('Navegar a editar perfil');
        },
      ),
      _buildSettingsItem(
        icon: Icons.security,
        title: 'Seguridad',
        subtitle: 'Contraseña y verificación',
      ),
      _buildSettingsItem(
        icon: Icons.notifications,
        title: 'Notificaciones',
        subtitle: 'Preferencias de alertas',
      ),

      const SizedBox(height: 30),

      // App y Soporte
      _buildSectionTitle('App y Soporte'),
      _buildSettingsItem(
        icon: Icons.help,
        title: 'Centro de Ayuda',
        subtitle: 'Preguntas frecuentes',
      ),
      _buildSettingsItem(
        icon: Icons.privacy_tip,
        title: 'Privacidad y Términos',
        subtitle: 'Políticas de la aplicación',
      ),
      _buildSettingsItem(
        icon: Icons.star,
        title: 'Calificar App',
        subtitle: 'Deja tu opinión',
      ),
    ];
  }

  // WIDGETS REUTILIZABLES
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRoleColor()),
                  ),
                  child: Text(
                    _getRoleDisplayName(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoleColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          // Mostrar indicador de carga
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(width: 10),
                  Text('Cerrando sesión...'),
                ],
              ),
              duration: Duration(seconds: 5),
            ),
          );

          print('🚪 Iniciando proceso de logout...');

          // Cerrar sesión
          await context.read<AuthViewModel>().logout();

          print('✅ Logout completado exitosamente');

          if (context.mounted) {
            // Navegar al login y limpiar el stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (Route<dynamic> route) => false,
            );

            // Mostrar mensaje de éxito
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Sesión cerrada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('❌ Error en logout: $e');

          if (context.mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error al cerrar sesión: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
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
                Icon(Icons.logout, color: Colors.red, size: 28),
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
    );
  }

  // Métodos auxiliares para personalización
  Color _getRoleColor() {
    switch (userRole) {
      case 'admin': return Colors.red;
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getRoleDisplayName() {
    switch (userRole) {
      case 'admin': return 'ADMINISTRADOR';
      case 'business': return 'EMPRESA';
      case 'user': return 'USUARIO';
      default: return 'USUARIO';
    }
  }
}