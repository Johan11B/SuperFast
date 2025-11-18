// lib/presentation/screens/settings/ajustes_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/business_viewmodel.dart';
import '../auth/auth_wrapper.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/business_entity.dart';

// Importar las pantallas de edición
import '../user/user_edit_profile_screen.dart';
import '../business/business_edit_profile_screen.dart';

class AjustesPage extends StatefulWidget {
  final Color primaryColor;
  final String userRole;

  const AjustesPage({
    super.key,
    this.primaryColor = const Color(0xFF008C9E),
    required this.userRole,
  });

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  @override
  void initState() {
    super.initState();
    // Forzar recarga al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final authViewModel = context.read<AuthViewModel>();
    authViewModel.refreshUserData().then((_) {
      if (mounted) {
        setState(() {});
      }
    });

    // Si es business, cargar datos de la empresa
    if (widget.userRole == 'business') {
      final businessViewModel = context.read<BusinessViewModel>();
      final user = authViewModel.currentUser;
      if (user != null) {
        businessViewModel.loadCurrentBusiness(user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

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
        // ✅ MANTENIDO: Logo de SuperFast en AppBar
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

      body: user == null
          ? _buildLoading()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario/empresa
            _buildUserInfo(context, user),
            const SizedBox(height: 30),

            // AJUSTES PRINCIPALES
            ..._buildMainSettings(context, user),

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

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando información...'),
        ],
      ),
    );
  }

  // 🎨 CONFIGURACIÓN VISUAL POR ROL
  Color _getAppBarColor() {
    switch (widget.userRole) {
      case 'admin': return const Color(0xFF008C9E);
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return const Color(0xFF008C9E);
    }
  }

  String _getTitle() {
    switch (widget.userRole) {
      case 'admin': return "Ajustes Admin";
      case 'business': return "Ajustes Empresa";
      case 'user': return "Ajustes Usuario";
      default: return "Ajustes";
    }
  }

  // ⚙️ AJUSTES PRINCIPALES SEGÚN ROL
  List<Widget> _buildMainSettings(BuildContext context, UserEntity user) {
    switch (widget.userRole) {
      case 'admin':
        return _buildAdminMainSettings(context);
      case 'business':
        return _buildBusinessMainSettings(context, user);
      case 'user':
        return _buildUserMainSettings(context, user);
      default:
        return _buildUserMainSettings(context, user);
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

  // 🏢 AJUSTES PRINCIPALES PARA BUSINESS
  List<Widget> _buildBusinessMainSettings(BuildContext context, UserEntity user) {
    return [
      _buildSectionTitle('Gestión del Negocio'),
      _buildSettingsItem(
        context: context,
        icon: Icons.store,
        title: 'Información de la Empresa',
        subtitle: 'Editar datos del negocio',
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BusinessEditProfileScreen()),
          );

          if (result == true && mounted) {
            _refreshData();
            _showSuccessMessage(context, 'Información de la empresa actualizada');
          }
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

  // 👤 AJUSTES PRINCIPALES PARA USER
  List<Widget> _buildUserMainSettings(BuildContext context, UserEntity user) {
    return [
      _buildSectionTitle('Mi Cuenta'),
      _buildSettingsItem(
        context: context,
        icon: Icons.person,
        title: 'Editar Perfil',
        subtitle: 'Actualizar información personal',
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserEditProfileScreen()),
          );

          if (result == true && mounted) {
            _refreshData();
            _showSuccessMessage(context, 'Perfil actualizado correctamente');
          }
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
          subtitle: 'Seleccionar idioma de la aplicación',
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

  // 👤 INFORMACIÓN DEL USUARIO/EMPRESA - CORREGIDA
  Widget _buildUserInfo(BuildContext context, UserEntity user) {
    final businessViewModel = context.watch<BusinessViewModel>();
    final business = businessViewModel.currentBusiness;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // ✅ CORREGIDO: Mostrar logo de empresa si es business, sino avatar de usuario
          if (widget.userRole == 'business' && business != null)
            _buildBusinessLogo(business)
          else
            _buildUserAvatar(user),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userRole == 'business' && business != null
                      ? business.name
                      : user.name ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
                // Información adicional para empresas
                if (widget.userRole == 'business' && business != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    business.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                // Información sobre cómo cambiar la imagen
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _showImageInfo(context);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Para cambiar ${widget.userRole == 'business' ? 'el logo' : 'la imagen'}, ve a "Editar Perfil"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Widget para mostrar logo de empresa
  Widget _buildBusinessLogo(BusinessEntity business) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        image: business.logoUrl != null && business.logoUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(business.logoUrl!),
          fit: BoxFit.cover,
        )
            : null,
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: business.logoUrl == null || business.logoUrl!.isEmpty
          ? const Center(
        child: Icon(
          Icons.business,
          color: Colors.orange,
          size: 30,
        ),
      )
          : null,
    );
  }

  // ✅ NUEVO: Widget para mostrar avatar de usuario
  Widget _buildUserAvatar(UserEntity user) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getRoleColor(),
        borderRadius: BorderRadius.circular(30),
        image: user.photoUrl != null && user.photoUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(user.photoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: user.photoUrl == null || user.photoUrl!.isEmpty
          ? Center(
        child: Text(
          user.name?.isNotEmpty == true
              ? user.name!.substring(0, 1).toUpperCase()
              : user.email.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
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
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: widget.primaryColor, size: 20),
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
    switch (widget.userRole) {
      case 'admin': return Colors.red;
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getRoleDisplayName() {
    switch (widget.userRole) {
      case 'admin': return 'ADMINISTRADOR';
      case 'business': return 'EMPRESA';
      case 'user': return 'USUARIO';
      default: return 'USUARIO';
    }
  }

  // ℹ️ INFORMACIÓN SOBRE CÓMO CAMBIAR LA IMAGEN
  void _showImageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.userRole == 'business' ? Icons.store : Icons.photo_camera,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              widget.userRole == 'business'
                  ? 'Cambiar Logo de Empresa'
                  : 'Cambiar Imagen de Perfil',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para cambiar ${widget.userRole == 'business' ? 'el logo de tu empresa' : 'tu imagen de perfil'}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoStep('1. Ve a "Editar Perfil" en la sección de ajustes'),
            _buildInfoStep('2. En la pantalla de edición, toca el ícono de cámara'),
            _buildInfoStep('3. Selecciona una imagen desde tu galería o toma una foto'),
            _buildInfoStep('4. Guarda los cambios'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.userRole == 'business'
                    ? 'El logo se actualizará automáticamente en todas las pantallas de tu empresa'
                    : 'La imagen se actualizará automáticamente en todas las pantallas',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar a la pantalla de edición correspondiente
              if (widget.userRole == 'business') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BusinessEditProfileScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserEditProfileScreen()),
                );
              }
            },
            child: Text(
              widget.userRole == 'business'
                  ? 'Ir a Editar Empresa'
                  : 'Ir a Editar Perfil',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
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

  // ✅ NUEVO MÉTODO: Mostrar mensaje de éxito
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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