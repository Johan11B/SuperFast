// lib/presentation/screens/admin/admin_users_screen.dart - VERSIÓN CORREGIDA
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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Column(
        children: [
          // Header con búsqueda
          _buildHeader(adminViewModel),

          // Lista de usuarios
          Expanded(
            child: _buildUsersList(adminViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AdminViewModel adminViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuarios por email o nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  adminViewModel.updateUserSearch('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: adminViewModel.updateUserSearch,
          ),
          const SizedBox(height: 12),

          // Filtros con SingleChildScrollView para evitar overflow
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Admins', 'admin'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Empresas', 'business'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Usuarios', 'user'),
                ],
              ),
            ),
          ),
        ],
      ),
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
    if (adminViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Aplicar filtro
    final filteredUsers = _applyRoleFilter(adminViewModel.users);

    if (filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await adminViewModel.loadUsers();
      },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No hay usuarios registrados'
                : 'No hay usuarios con rol $_selectedFilter',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserEntity user, AdminViewModel adminViewModel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: _buildAvatarContent(user),
        ),
        title: Text(
          user.name ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Chip(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
              label: Text(
                _getRoleDisplayName(user.role),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user, adminViewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20),
                  SizedBox(width: 8),
                  Text('Cambiar rol'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MÉTODO CORREGIDO: Maneja strings vacíos o nulos
  Widget _buildAvatarContent(UserEntity user) {
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(user.photoUrl!));
    }

    final displayText = _getAvatarText(user);
    return Text(
      displayText,
      style: const TextStyle(color: Colors.white),
    );
  }

  // MÉTODO CORREGIDO: Evita errores con strings vacíos
  String _getAvatarText(UserEntity user) {
    if (user.name?.isNotEmpty == true) {
      return user.name!.substring(0, 1).toUpperCase();
    }
    if (user.email.isNotEmpty) {
      return user.email.substring(0, 1).toUpperCase();
    }
    return '?'; // Fallback para emails vacíos
  }

  void _handleUserAction(String action, UserEntity user, AdminViewModel adminViewModel) {
    switch (action) {
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
        title: const Text('Cambiar rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario: ${user.email}'),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'business', child: Text('Empresa')),
                DropdownMenuItem(value: 'user', child: Text('Usuario')),
              ],
              onChanged: (value) {
                selectedRole = value!;
                Navigator.of(context).pop();
                _confirmRoleChange(user, adminViewModel, selectedRole);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRoleChange(UserEntity user, AdminViewModel adminViewModel, String newRole) {
    adminViewModel.changeUserRole(user.id, newRole);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rol cambiado a $newRole')),
    );
  }

  void _showDeleteUserDialog(UserEntity user, AdminViewModel adminViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              adminViewModel.deleteUser(user.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario eliminado')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
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
      case 'admin': return 'ADMIN';
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