import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../domain/entities/user_entity.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _initialLoadCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  void _loadInitialUsers() {
    if (!_initialLoadCompleted && !_isLoading) {
      print('🔄 Carga inicial de usuarios...');
      setState(() {
        _isLoading = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminViewModel>().loadUsers().then((_) {
          if (mounted) {
            setState(() {
              _initialLoadCompleted = true;
              _isLoading = false;
            });
          }
        }).catchError((error) {
          print('❌ Error en carga inicial: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      });
    }
  }

  // ✅ CORREGIDO: Ahora devuelve Future<void>
  Future<void> _reloadUsers() async {
    print('🔄 Recarga manual de usuarios...');
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AdminViewModel>().loadUsers();
    } catch (error) {
      print('❌ Error al recargar usuarios: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          // Header con búsqueda y filtros
          _buildHeader(adminViewModel),

          // Estadísticas rápidas
          _buildQuickStats(adminViewModel),

          // Lista de usuarios
          Expanded(
            child: _buildUsersList(adminViewModel),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reloadUsers,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh),
        tooltip: 'Recargar usuarios',
      ),
    );
  }

  Widget _buildHeader(AdminViewModel adminViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Título y contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${adminViewModel.filteredUsers.length} usuarios',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        adminViewModel.updateUserSearch('');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _reloadUsers,
                    tooltip: 'Recargar usuarios',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: adminViewModel.updateUserSearch,
          ),
          const SizedBox(height: 12),

          // Filtros
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('👑 Admins', 'admin'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🏢 Empresas', 'business'),
                  const SizedBox(width: 8),
                  _buildFilterChip('👥 Usuarios', 'user'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AdminViewModel adminViewModel) {
    final stats = _calculateUserStats(adminViewModel.users);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total'].toString(), Colors.blue),
          _buildStatItem('Admins', stats['admin'].toString(), Colors.red),
          _buildStatItem('Empresas', stats['business'].toString(), Colors.orange),
          _buildStatItem('Usuarios', stats['user'].toString(), Colors.green),
        ],
      ),
    );
  }

  Map<String, int> _calculateUserStats(List<UserEntity> users) {
    return {
      'total': users.length,
      'admin': users.where((user) => user.role == 'admin').length,
      'business': users.where((user) => user.role == 'business').length,
      'user': users.where((user) => user.role == 'user').length,
    };
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildUsersList(AdminViewModel adminViewModel) {
    if (_isLoading && adminViewModel.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando usuarios...'),
          ],
        ),
      );
    }

    // Aplicar filtro de rol
    final filteredUsers = _applyRoleFilter(adminViewModel.filteredUsers);

    if (filteredUsers.isEmpty) {
      return _buildEmptyState(adminViewModel);
    }

    return RefreshIndicator(
      onRefresh: _reloadUsers, // ✅ CORREGIDO: Ahora _reloadUsers devuelve Future<void>
      child: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return _buildUserCard(user, adminViewModel);
        },
      ),
    );
  }

  List<UserEntity> _applyRoleFilter(List<UserEntity> users) {
    if (_selectedFilter == 'all') return users;
    return users.where((user) => user.role == _selectedFilter).toList();
  }

  Widget _buildEmptyState(AdminViewModel adminViewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No hay usuarios registrados'
                : 'No hay usuarios con rol $_selectedFilter',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isNotEmpty)
            const Text(
              'Prueba con otros términos de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _reloadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar usuarios'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserEntity user, AdminViewModel adminViewModel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: _getRoleColor(user.role),
          child: _buildAvatarContent(user),
        ),
        title: Text(
          user.name?.isNotEmpty == true ? user.name! : 'Usuario Sin Nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Chip de rol
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRoleColor(user.role)),
                  ),
                  child: Text(
                    _getRoleDisplayName(user.role),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ID abreviado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: ${user.id.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user, adminViewModel),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_details',
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: const [
                  Icon(Icons.swap_horiz, size: 20),
                  SizedBox(width: 8),
                  Text('Cambiar rol'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _showUserDetails(user);
        },
      ),
    );
  }

  Widget _buildAvatarContent(UserEntity user) {
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.photoUrl!),
        radius: 25,
      );
    }

    final displayText = _getAvatarText(user);
    return Text(
      displayText,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  String _getAvatarText(UserEntity user) {
    if (user.name?.isNotEmpty == true) {
      return user.name!.substring(0, 1).toUpperCase();
    }
    if (user.email.isNotEmpty) {
      return user.email.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  void _handleUserAction(String action, UserEntity user, AdminViewModel adminViewModel) {
    switch (action) {
      case 'view_details':
        _showUserDetails(user);
        break;
      case 'change_role':
        _showChangeRoleDialog(user, adminViewModel);
        break;
      case 'delete':
        _showDeleteUserDialog(user, adminViewModel);
        break;
    }
  }

  void _showChangeRoleDialog(UserEntity user, AdminViewModel adminViewModel) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar rol de usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: ${user.email}'),
            const SizedBox(height: 16),
            const Text('Selecciona el nuevo rol:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Administrador'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'business',
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Empresa'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'user',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Usuario'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedRole = value;
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmRoleChange(user, adminViewModel, selectedRole);
            },
            child: const Text('Cambiar Rol'),
          ),
        ],
      ),
    );
  }

  void _confirmRoleChange(UserEntity user, AdminViewModel adminViewModel, String newRole) {
    if (user.role == newRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El usuario ya tiene este rol')),
      );
      return;
    }

    adminViewModel.changeUserRole(user.id, newRole);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rol cambiado a ${_getRoleDisplayName(newRole)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteUserDialog(UserEntity user, AdminViewModel adminViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres eliminar a ${user.email}?'),
            const SizedBox(height: 8),
            Text(
              'Nombre: ${user.name ?? "No especificado"}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Esta acción no se puede deshacer. El usuario perderá acceso al sistema.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.deleteUser(user.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Usuario'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar y información básica
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _getRoleColor(user.role),
                      child: _buildAvatarContent(user),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name ?? 'Usuario Sin Nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Información detallada
              _buildDetailItem('ID de Usuario:', user.id),
              _buildDetailItem('Rol:', _getRoleDisplayName(user.role)),
              if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                _buildDetailItem('Foto URL:', user.photoUrl!),

              const SizedBox(height: 16),
              const Text(
                'Información de la cuenta:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildAccountInfo(user.role),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(String role) {
    List<Widget> infoItems = [];

    switch (role) {
      case 'admin':
        infoItems.addAll([
          _buildInfoItem('• Tiene acceso completo al sistema'),
          _buildInfoItem('• Puede gestionar usuarios y negocios'),
          _buildInfoItem('• Puede cambiar roles y permisos'),
        ]);
        break;
      case 'business':
        infoItems.addAll([
          _buildInfoItem('• Puede gestionar su negocio'),
          _buildInfoItem('• Puede recibir y gestionar pedidos'),
          _buildInfoItem('• Aparece en la app para los clientes'),
        ]);
        break;
      case 'user':
        infoItems.addAll([
          _buildInfoItem('• Puede realizar pedidos'),
          _buildInfoItem('• Puede registrar su empresa'),
          _buildInfoItem('• Acceso básico a la aplicación'),
        ]);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoItems,
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'business': return Colors.orange;
      case 'user': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin': return 'ADMINISTRADOR';
      case 'business': return 'EMPRESA';
      case 'user': return 'USUARIO';
      default: return role.toUpperCase();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}