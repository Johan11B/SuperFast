// lib/presentation/screens/user/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../business/business_registration_page.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../core/services/business_registration_service.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;

    return RefreshIndicator(
      onRefresh: () async {
        // Recargar datos si es necesario
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            _buildUserInfo(user),
            const SizedBox(height: 16),

            // Estado del negocio
            _buildBusinessStatus(context, user),
            const SizedBox(height: 16),

            // Acciones rápidas
            _buildQuickActions(context, user),
            const SizedBox(height: 16),

            // Estadísticas (si las hay)
            _buildUserStats(),
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
                _getAvatarText(user),
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

  Widget _buildBusinessStatus(BuildContext context, UserEntity? user) {
    if (user?.role == 'business') {
      return const SizedBox.shrink();
    }

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

        return _buildRegisterPrompt(context);
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

  Widget _buildQuickActions(BuildContext context, UserEntity? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionChip(
              icon: Icons.history,
              label: 'Historial',
              color: Colors.purple,
              onTap: () => _showComingSoon(context, 'Historial'),
            ),
            _buildActionChip(
              icon: Icons.favorite,
              label: 'Favoritos',
              color: Colors.pink,
              onTap: () => _showComingSoon(context, 'Favoritos'),
            ),
            _buildActionChip(
              icon: Icons.help_center,
              label: 'Ayuda',
              color: Colors.blue,
              onTap: () => _showComingSoon(context, 'Centro de Ayuda'),
            ),
            _buildActionChip(
              icon: Icons.info,
              label: 'Info Cuenta',
              color: Colors.teal,
              onTap: () => _showAccountInfo(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withAlpha(25),
      onPressed: onTap,
    );
  }

  Widget _buildUserStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Pedidos', '0', Icons.shopping_cart, Colors.green),
                _buildStatItem('Favoritos', '0', Icons.favorite, Colors.pink),
                _buildStatItem('Reseñas', '0', Icons.star, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
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
          Expanded(child: Text(value)),
        ],
      ),
    );
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

  String _getAvatarText(UserEntity? user) {
    if (user?.name?.isNotEmpty == true) {
      return user!.name!.substring(0, 1).toUpperCase();
    }
    if (user?.email.isNotEmpty == true) {
      return user!.email.substring(0, 1).toUpperCase();
    }
    return 'U';
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