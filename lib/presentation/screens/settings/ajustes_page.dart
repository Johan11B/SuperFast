// lib/presentation/screens/settings/ajustes_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/auth_wrapper.dart';
import '../../../domain/entities/user_entity.dart';

// ✅ AGREGAR IMPORTACIONES DE LAS PANTALLAS DE EDICIÓN
import '../user/user_edit_profile_screen.dart';
import '../business/business_edit_profile_screen.dart';

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
            fontSize: 24,
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
              _buildUserInfo(context, authViewModel.currentUser!),
              const SizedBox(height: 30),
            ],

            // AJUSTES PRINCIPALES (según rol)
            ..._buildMainSettings(context),

            const SizedBox(height: 20),

            // CONFIGURACIÓN DE LA APP
            _buildAppSettings(context),

            const SizedBox(height: 20),

            // SOPORTE
            _buildSupportSection(context),

            const SizedBox(height: 30),

            // Botón Cerrar Sesión
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // 🎨 CONFIGURACIÓN VISUAL POR ROL
  Color _getAppBarColor() {
    switch (userRole) {
      case 'admin': return const Color(0xFF008C9E);
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return const Color(0xFF008C9E);
    }
  }

  String _getTitle() {
    switch (userRole) {
      case 'admin': return "Ajustes Admin";
      case 'business': return "Ajustes Empresa";
      case 'user': return "Ajustes Usuario";
      default: return "Ajustes";
    }
  }

  // ⚙️ AJUSTES PRINCIPALES SEGÚN ROL
  List<Widget> _buildMainSettings(BuildContext context) {
    switch (userRole) {
      case 'admin':
        return _buildAdminMainSettings(context);
      case 'business':
        return _buildBusinessMainSettings(context);
      case 'user':
        return _buildUserMainSettings(context);
      default:
        return _buildUserMainSettings(context);
    }
  }

  // 👑 AJUSTES PRINCIPALES PARA ADMIN
  List<Widget> _buildAdminMainSettings(BuildContext context) {
    return [
      _buildSectionTitle('Administración del Sistema'),
      _buildSettingsItem(
        context: context,
        icon: Icons.people,
        title: 'Gestión de Usuarios',
        subtitle: 'Administrar usuarios y roles',
        onTap: () => _showComingSoon(context, 'Gestión de Usuarios'),
      ),
      _buildSettingsItem(
        context: context,
        icon: Icons.business,
        title: 'Gestión de Empresas',
        subtitle: 'Aprobar y administrar empresas',
        onTap: () => _showComingSoon(context, 'Gestión de Empresas'),
      ),
      _buildSettingsItem(
        context: context,
        icon: Icons.analytics,
        title: 'Estadísticas del Sistema',
        subtitle: 'Métricas y reportes generales',
        onTap: () => _showComingSoon(context, 'Estadísticas del Sistema'),
      ),
    ];
  }

  // 🏢 AJUSTES PRINCIPALES PARA BUSINESS - ✅ CORREGIDO
  List<Widget> _buildBusinessMainSettings(BuildContext context) {
    return [
      _buildSectionTitle('Gestión del Negocio'),
      _buildSettingsItem(
        context: context,
        icon: Icons.store,
        title: 'Información de la Empresa',
        subtitle: 'Editar datos del negocio',
        onTap: () {
          // ✅ CORREGIDO: Navegar a la pantalla real en lugar de "Próximamente"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessEditProfileScreen()),
          );
        },
      ),
      _buildSettingsItem(
        context: context,
        icon: Icons.inventory,
        title: 'Mis Productos',
        subtitle: 'Gestionar catálogo de productos',
        onTap: () => _showComingSoon(context, 'Gestión de Productos'),
      ),
      _buildSettingsItem(
        context: context,
        icon: Icons.receipt_long,
        title: 'Pedidos y Ventas',
        subtitle: 'Ver historial de pedidos',
        onTap: () => _showComingSoon(context, 'Pedidos y Ventas'),
      ),
    ];
  }

  // 👤 AJUSTES PRINCIPALES PARA USER - ✅ CORREGIDO
  List<Widget> _buildUserMainSettings(BuildContext context) {
    return [
      _buildSectionTitle('Mi Cuenta'),
      _buildSettingsItem(
        context: context,
        icon: Icons.person,
        title: 'Editar Perfil',
        subtitle: 'Actualizar información personal',
        onTap: () {
          // ✅ CORREGIDO: Navegar a la pantalla real en lugar de "Próximamente"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserEditProfileScreen()),
          );
        },
      ),
      _buildSettingsItem(
        context: context,
        icon: Icons.favorite,
        title: 'Mis Favoritos',
        subtitle: 'Productos y empresas favoritas',
        onTap: () => _showComingSoon(context, 'Mis Favoritos'),
      ),
      _buildSettingsItem(
        context: context,
        icon: Icons.shopping_bag,
        title: 'Mis Pedidos',
        subtitle: 'Historial de compras',
        onTap: () => _showComingSoon(context, 'Mis Pedidos'),
      ),
    ];
  }

  // 📱 CONFIGURACIÓN DE LA APP (para todos)
  Widget _buildAppSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Configuración de la App'),
        _buildSettingsItem(
          context: context,
          icon: Icons.notifications,
          title: 'Notificaciones',
          subtitle: 'Configurar alertas y notificaciones',
          onTap: () => _showComingSoon(context, 'Configuración de Notificaciones'),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.language,
          title: 'Idioma',
          subtitle: 'Seleccionar idiama de la aplicación',
          onTap: () => _showComingSoon(context, 'Selección de Idioma'),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.visibility,
          title: 'Tema',
          subtitle: 'Cambiar entre modo claro y oscuro',
          onTap: () => _showComingSoon(context, 'Configuración de Tema'),
        ),
      ],
    );
  }

  // 🆘 SOPORTE (para todos)
  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Soporte y Ayuda'),
        _buildSettingsItem(
          context: context,
          icon: Icons.help,
          title: 'Centro de Ayuda',
          subtitle: 'Preguntas frecuentes y soporte',
          onTap: () => _showComingSoon(context, 'Centro de Ayuda'),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.security,
          title: 'Privacidad y Seguridad',
          subtitle: 'Políticas de privacidad y datos',
          onTap: () => _showComingSoon(context, 'Privacidad y Seguridad'),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.info,
          title: 'Acerca de',
          subtitle: 'Información de la aplicación',
          onTap: () => _showComingSoon(context, 'Acerca de'),
        ),
      ],
    );
  }

  // 👤 INFORMACIÓN DEL USUARIO
  Widget _buildUserInfo(BuildContext context, UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar del usuario
          GestureDetector(
            onTap: () => _showImageOptions(context, user),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getRoleColor(),
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
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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

  // 🧩 COMPONENTES REUTILIZABLES
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // 🚪 BOTÓN CERRAR SESIÓN
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // 🎨 COLORES Y TEXTO POR ROL
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

  // 📸 OPCIONES PARA CAMBIAR IMAGEN
  void _showImageOptions(BuildContext context, UserEntity user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Cambiar imagen de perfil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Tomar foto para perfil');
              },
            ),
            if (user.photoUrl != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Eliminar imagen de perfil');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 💬 DIÁLOGO DE CONFIRMACIÓN PARA LOGOUT
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _performLogout(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // 🔐 EJECUTAR LOGOUT
  void _performLogout(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authViewModel = context.read<AuthViewModel>();

    try {
      // Cerrar diálogo
      Navigator.of(context).pop();

      // Mostrar indicador
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 10),
              Text('Cerrando sesión...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      await authViewModel.logout();

      if (context.mounted) {
        // Navegar al AuthWrapper
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (Route<dynamic> route) => false,
        );

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🚧 FUNCIÓN PARA OPCIONES NO IMPLEMENTADAS
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Próximamente'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}