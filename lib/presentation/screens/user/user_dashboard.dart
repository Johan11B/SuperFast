// lib/presentation/screens/user/user_dashboard.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../business/business_registration_page.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../settings/ajustes_page.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../core/services/business_registration_service.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta - SuperFast'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AjustesPage(
                    userRole: 'user',
                    primaryColor: Colors.green,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            _buildUserInfo(user),
            const SizedBox(height: 16),

            // Estado del negocio
            _buildBusinessStatus(context, user), // CORREGIDO: agregar context
            const SizedBox(height: 16),

            // Acciones disponibles según el rol
            _buildUserActions(context, user),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(UserEntity? user) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              child: user?.photoUrl != null
                  ? CircleAvatar(backgroundImage: NetworkImage(user!.photoUrl!))
                  : Text(
                _getAvatarText(user), // CORREGIDO: usar método helper
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Usuario',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    backgroundColor: _getRoleColor(user?.role),
                    label: Text(
                      _getRoleDisplayName(user?.role),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MÉTODO NUEVO: Helper para texto del avatar
  String _getAvatarText(UserEntity? user) {
    if (user?.name?.isNotEmpty == true) {
      return user!.name!.substring(0, 1).toUpperCase();
    }
    if (user?.email.isNotEmpty == true) {
      return user!.email.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  // CORREGIDO: Agregar parámetro context
  Widget _buildBusinessStatus(BuildContext context, UserEntity? user) {
    // Si ya es empresa, no mostrar nada (porque ya tiene su propio panel)
    if (user?.role == 'business') {
      return const SizedBox.shrink();
    }

    // Si es usuario, verificar si tiene solicitud pendiente
    return FutureBuilder<Map<String, dynamic>?>(
      future: BusinessRegistrationService().getUserRegistrationStatus(user?.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatusCard(
            'Verificando estado...',
            'Consultando información de tu solicitud',
            Colors.blue,
            Icons.hourglass_empty,
          );
        }

        if (snapshot.hasError) {
          return _buildStatusCard(
            'Error de conexión',
            'No se pudo verificar el estado de tu solicitud',
            Colors.orange,
            Icons.warning,
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final registration = snapshot.data!;
          final status = registration['status'];

          if (status == 'pending') {
            return _buildStatusCard(
              '⏳ Solicitud Pendiente',
              'Tu solicitud "${registration['businessName']}" está en revisión. '
                  'Te notificaremos cuando sea aprobada (24-48 horas).',
              Colors.orange,
              Icons.pending_actions,
            );
          } else if (status == 'rejected') {
            return _buildStatusCard(
              '❌ Solicitud Rechazada',
              'Tu solicitud fue rechazada. Contacta al soporte para más información.',
              Colors.red,
              Icons.cancel,
            );
          }
        }

        // Si no tiene solicitud, mostrar opción para registrar
        return _buildRegisterPrompt(context); // CORREGIDO: pasar context
      },
    );
  }

  Widget _buildStatusCard(String title, String message, Color color, IconData icon) {
    return Card(
      color: color.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CORREGIDO: Agregar parámetro context
  Widget _buildRegisterPrompt(BuildContext context) {
    return Card(
      color: Colors.orange.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Quieres vender en SuperFast?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra tu empresa y comienza a recibir pedidos',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BusinessRegistrationPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrar Mi Empresa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActions(BuildContext context, UserEntity? user) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                // Si es usuario normal, puede registrar empresa
                if (user?.role == 'user') ...[
                  _buildActionCard(
                    icon: Icons.business,
                    title: 'Registrar Mi Empresa',
                    subtitle: 'Convierte tu negocio en digital',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusinessRegistrationPage()),
                      );
                    },
                  ),
                ],

                // Acciones generales para todos los usuarios
                _buildActionCard(
                  icon: Icons.shopping_cart,
                  title: 'Mis Pedidos',
                  subtitle: 'Historial y pedidos activos',
                  color: Colors.purple,
                  onTap: () {
                    _showComingSoon(context, 'Mis Pedidos');
                  },
                ),

                _buildActionCard(
                  icon: Icons.favorite,
                  title: 'Favoritos',
                  subtitle: 'Negocios y productos favoritos',
                  color: Colors.pink,
                  onTap: () {
                    _showComingSoon(context, 'Favoritos');
                  },
                ),

                _buildActionCard(
                  icon: Icons.history,
                  title: 'Historial',
                  subtitle: 'Mi actividad reciente',
                  color: Colors.teal,
                  onTap: () {
                    _showComingSoon(context, 'Historial');
                  },
                ),

                _buildActionCard(
                  icon: Icons.help_center,
                  title: 'Centro de Ayuda',
                  subtitle: 'Soporte y preguntas frecuentes',
                  color: Colors.indigo,
                  onTap: () {
                    _showComingSoon(context, 'Centro de Ayuda');
                  },
                ),

                // Información de la cuenta
                _buildActionCard(
                  icon: Icons.info,
                  title: 'Información de la Cuenta',
                  subtitle: 'Detalles de tu perfil y estado',
                  color: Colors.blue,
                  onTap: () {
                    _showAccountInfo(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showAccountInfo(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de la Cuenta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem('👤 Nombre:', user?.name ?? 'No especificado'),
              _buildInfoItem('📧 Email:', user?.email ?? 'N/A'),
              _buildInfoItem('🎯 Rol:', _getRoleDisplayName(user?.role)),
              _buildInfoItem('🆔 ID:', user?.id?.substring(0, 8) ?? 'N/A'),
              const SizedBox(height: 16),

              // Estado de la cuenta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de la Cuenta:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (user?.role == 'user') ..._getUserAccountInfo(),
                    if (user?.role == 'business') ..._getBusinessAccountInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  List<Widget> _getUserAccountInfo() {
    return [
      const Text('• Eres un usuario comprador'),
      const Text('• Puedes realizar pedidos en cualquier negocio'),
      const Text('• Puedes registrar tu empresa para vender'),
    ];
  }

  List<Widget> _getBusinessAccountInfo() {
    return [
      const Text('• Eres una empresa vendedora'),
      const Text('• Puedes gestionar productos y pedidos'),
      const Text('• Apareces en la app para recibir pedidos'),
    ];
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Próximamente'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin': return 'ADMINISTRADOR';
      case 'business': return 'EMPRESA';
      case 'user': return 'USUARIO';
      default: return 'USUARIO';
    }
  }
}