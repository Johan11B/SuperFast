import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../domain/entities/business_entity.dart'; // ✅ IMPORTAR LA ENTIDAD

class AdminBusinessesScreen extends StatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  State<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends State<AdminBusinessesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  void _loadBusinesses() {
    if (!_initialLoadCompleted) {
      print('🔄 Carga inicial de negocios...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminViewModel>().loadBusinesses().then((_) {
          _initialLoadCompleted = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFEFEF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar negocios...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      if (!adminViewModel.isLoadingBusinesses) {
                        adminViewModel.loadBusinesses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recargando negocios...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Recargar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      adminViewModel.updateBusinessSearch('');
                    },
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              adminViewModel.updateBusinessSearch(value);
            },
          ),
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.pending), text: 'Pendientes'),
              const Tab(icon: Icon(Icons.check_circle), text: 'Aprobados'),
              const Tab(icon: Icon(Icons.pause_circle), text: 'Suspendidos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ✅ CAMBIADO: Usar BusinessEntity directamente
            _buildBusinessesList(adminViewModel.pendingBusinesses, adminViewModel, 'pending'),
            _buildBusinessesList(adminViewModel.approvedBusinesses, adminViewModel, 'approved'),
            _buildBusinessesList(adminViewModel.suspendedBusinesses, adminViewModel, 'suspended'),
          ],
        ),
        floatingActionButton: adminViewModel.isLoadingBusinesses
            ? FloatingActionButton(
          onPressed: null,
          child: const CircularProgressIndicator(color: Colors.white),
        )
            : FloatingActionButton(
          onPressed: () {
            adminViewModel.loadBusinesses();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recargando todos los negocios...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Icon(Icons.refresh),
          tooltip: 'Recargar negocios',
        ),
      ),
    );
  }

  // ✅ CAMBIADO: Ahora recibe List<BusinessEntity>
  Widget _buildBusinessesList(List<BusinessEntity> businesses, AdminViewModel adminViewModel, String tabType) {
    if (adminViewModel.isLoadingBusinesses && businesses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando negocios...'),
          ],
        ),
      );
    }

    if (businesses.isEmpty) {
      String emptyMessage = '';
      String emptySubtitle = '';

      switch (tabType) {
        case 'pending':
          emptyMessage = 'No hay negocios pendientes';
          emptySubtitle = 'Las solicitudes de empresas aparecerán aquí';
          break;
        case 'approved':
          emptyMessage = 'No hay negocios aprobados';
          emptySubtitle = 'Las empresas aprobadas aparecerán aquí';
          break;
        case 'suspended':
          emptyMessage = 'No hay negocios suspendidos';
          emptySubtitle = 'Las empresas suspendidas aparecerán aquí';
          break;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTabIcon(tabType),
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => adminViewModel.loadBusinesses(),
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await adminViewModel.loadBusinesses();
      },
      child: ListView.builder(
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          final business = businesses[index];
          return _buildBusinessCard(business, adminViewModel, tabType);
        },
      ),
    );
  }

  IconData _getTabIcon(String tabType) {
    switch (tabType) {
      case 'pending': return Icons.pending_actions;
      case 'approved': return Icons.business_center;
      case 'suspended': return Icons.pause_circle;
      default: return Icons.business;
    }
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity en lugar de Map
  Widget _buildBusinessCard(BusinessEntity business, AdminViewModel adminViewModel, String tabType) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: business.statusColor, // ✅ USAR PROPIEDAD DE LA ENTIDAD
          child: const Icon(
            Icons.business,
            color: Colors.white,
          ),
        ),
        title: Text(
          business.name, // ✅ USAR PROPIEDAD DIRECTA
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              business.email, // ✅ USAR PROPIEDAD DIRECTA
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: business.statusColor.withOpacity(0.1), // ✅ USAR PROPIEDAD DE LA ENTIDAD
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: business.statusColor), // ✅ USAR PROPIEDAD DE LA ENTIDAD
                  ),
                  child: Text(
                    business.statusDisplayText, // ✅ USAR PROPIEDAD DE LA ENTIDAD
                    style: TextStyle(
                      fontSize: 12,
                      color: business.statusColor, // ✅ USAR PROPIEDAD DE LA ENTIDAD
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    business.category, // ✅ USAR PROPIEDAD DIRECTA
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildBusinessActions(business, adminViewModel, tabType),
        onTap: () {
          _showBusinessDetails(business);
        },
      ),
    );
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  Widget _buildBusinessActions(BusinessEntity business, AdminViewModel adminViewModel, String tabType) {
    switch (tabType) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: adminViewModel.isLoading ? null : () => _showApproveDialog(business, adminViewModel),
              tooltip: 'Aprobar negocio',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: adminViewModel.isLoading ? null : () => _showRejectDialog(business, adminViewModel),
              tooltip: 'Rechazar negocio',
            ),
          ],
        );

      case 'approved':
        return PopupMenuButton<String>(
          onSelected: (value) => _handleBusinessAction(value, business, adminViewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'suspend',
              child: Row(
                children: [
                  Icon(Icons.pause, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Suspender'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view_details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
          ],
        );

      case 'suspended':
        return PopupMenuButton<String>(
          onSelected: (value) => _handleBusinessAction(value, business, adminViewModel),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'activate',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Activar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view_details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  void _handleBusinessAction(String action, BusinessEntity business, AdminViewModel adminViewModel) {
    switch (action) {
      case 'suspend':
        _showSuspendDialog(business, adminViewModel);
        break;
      case 'activate':
        adminViewModel.activateBusiness(business.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Negocio ${business.name} activado'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'delete':
        _showDeleteDialog(business, adminViewModel);
        break;
      case 'view_details':
        _showBusinessDetails(business);
        break;
    }
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  void _showApproveDialog(BusinessEntity business, AdminViewModel adminViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Negocio'),
        content: Text('¿Estás seguro de que quieres aprobar el negocio "${business.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.approveBusiness(business.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "${business.name}" aprobado'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  void _showRejectDialog(BusinessEntity business, AdminViewModel adminViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Negocio'),
        content: Text('¿Estás seguro de que quieres rechazar el negocio "${business.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.rejectBusiness(business.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "${business.name}" rechazado'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  void _showSuspendDialog(BusinessEntity business, AdminViewModel adminViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspender Negocio'),
        content: Text('¿Estás seguro de que quieres suspender el negocio "${business.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.suspendBusiness(business.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "${business.name}" suspendido'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspender', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  void _showDeleteDialog(BusinessEntity business, AdminViewModel adminViewModel) {
    String title = 'Eliminar Negocio';
    String content = '¿Estás seguro de que quieres eliminar permanentemente el negocio "${business.name}"?';

    if (business.isApproved || business.isSuspended) {
      content += '\n\n⚠️ El usuario perderá su rol de empresa y volverá a ser usuario normal.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.deleteBusiness(business.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "${business.name}" eliminado permanentemente'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
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

  // ✅ CAMBIADO: Ahora recibe BusinessEntity
  void _showBusinessDetails(BusinessEntity business) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Negocio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Nombre:', business.name),
              _buildDetailItem('Email:', business.email),
              _buildDetailItem('Categoría:', business.category),
              _buildDetailItem('Dirección:', business.address),
              _buildDetailItem('Teléfono:', business.phone ?? 'No disponible'),
              _buildDetailItem('Estado:', business.statusDisplayText),
              if (business.description != null && business.description!.isNotEmpty)
                _buildDetailItem('Descripción:', business.description!),
              if (business.rating != null)
                _buildDetailItem('Rating:', '${business.rating!.toStringAsFixed(1)} ⭐'),
              _buildDetailItem('Reseñas:', '${business.reviewCount} reseñas'),
              if (business.createdAt != null)
                _buildDetailItem('Creado:', _formatDate(business.createdAt!)),
              if (business.updatedAt != null)
                _buildDetailItem('Actualizado:', _formatDate(business.updatedAt!)),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}