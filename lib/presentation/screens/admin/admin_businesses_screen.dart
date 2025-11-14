// lib/presentation/screens/admin/admin_businesses_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';

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
      length: 2,
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.check_circle), text: 'Aprobados'),
              Tab(icon: Icon(Icons.pending), text: 'Pendientes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña de Negocios Aprobados
            _buildBusinessesList(adminViewModel.businesses, adminViewModel, false),

            // Pestaña de Negocios Pendientes
            _buildBusinessesList(adminViewModel.pendingBusinesses, adminViewModel, true),
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

  Widget _buildBusinessesList(List<Map<String, dynamic>> businesses, AdminViewModel adminViewModel, bool isPending) {
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.business_center,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No hay negocios pendientes' : 'No hay negocios aprobados',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Las solicitudes de empresas aparecerán aquí'
                  : 'Las empresas aprobadas aparecerán aquí',
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
          return _buildBusinessCard(business, adminViewModel, isPending);
        },
      ),
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> business, AdminViewModel adminViewModel, bool isPending) {
    String getBusinessName() => business['businessName'] ?? 'Sin nombre';
    String getBusinessEmail() => business['userEmail'] ?? 'Sin email';
    String getBusinessCategory() => business['category'] ?? 'General';
    String getBusinessStatus() => business['status'] ?? 'pending';

    Color getStatusColor(String status) {
      switch (status) {
        case 'approved': return Colors.green;
        case 'pending': return Colors.orange;
        case 'rejected': return Colors.red;
        case 'suspended': return Colors.grey;
        default: return Colors.grey;
      }
    }

    String getStatusDisplayText(String status) {
      switch (status) {
        case 'approved': return 'APROBADO';
        case 'pending': return 'PENDIENTE';
        case 'rejected': return 'RECHAZADO';
        case 'suspended': return 'SUSPENDIDO';
        default: return status.toUpperCase();
      }
    }

    String getBusinessId() => business['id'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getStatusColor(getBusinessStatus()),
          child: const Icon(
            Icons.business,
            color: Colors.white,
          ),
        ),
        title: Text(
          getBusinessName(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              getBusinessEmail(),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(getBusinessStatus()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: getStatusColor(getBusinessStatus())),
                  ),
                  child: Text(
                    getStatusDisplayText(getBusinessStatus()),
                    style: TextStyle(
                      fontSize: 12,
                      color: getStatusColor(getBusinessStatus()),
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
                    getBusinessCategory(),
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
        trailing: isPending
            ? _buildPendingBusinessActions(business, adminViewModel)
            : _buildApprovedBusinessActions(business, adminViewModel),
        onTap: () {
          _showBusinessDetails(business);
        },
      ),
    );
  }

  Widget _buildPendingBusinessActions(Map<String, dynamic> business, AdminViewModel adminViewModel) {
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
  }

  Widget _buildApprovedBusinessActions(Map<String, dynamic> business, AdminViewModel adminViewModel) {
    String businessStatus = business['status'] ?? '';

    return PopupMenuButton<String>(
      onSelected: (value) => _handleBusinessAction(value, business, adminViewModel),
      itemBuilder: (context) => [
        if (businessStatus == 'approved')
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
        if (businessStatus == 'suspended')
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
  }

  void _handleBusinessAction(String action, Map<String, dynamic> business, AdminViewModel adminViewModel) {
    String businessId = business['id'] ?? '';
    String businessName = business['businessName'] ?? 'Negocio';

    switch (action) {
      case 'suspend':
        _showSuspendDialog(business, adminViewModel);
        break;
      case 'activate':
        adminViewModel.activateBusiness(businessId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Negocio $businessName activado'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'view_details':
        _showBusinessDetails(business);
        break;
    }
  }

  void _showApproveDialog(Map<String, dynamic> business, AdminViewModel adminViewModel) {
    String businessId = business['id'] ?? '';
    String businessName = business['businessName'] ?? 'Negocio';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Negocio'),
        content: Text('¿Estás seguro de que quieres aprobar el negocio "$businessName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.approveBusiness(businessId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "$businessName" aprobado'),
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

  void _showRejectDialog(Map<String, dynamic> business, AdminViewModel adminViewModel) {
    String businessId = business['id'] ?? '';
    String businessName = business['businessName'] ?? 'Negocio';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Negocio'),
        content: Text('¿Estás seguro de que quieres rechazar el negocio "$businessName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.rejectBusiness(businessId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "$businessName" rechazado'),
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

  void _showSuspendDialog(Map<String, dynamic> business, AdminViewModel adminViewModel) {
    String businessId = business['id'] ?? '';
    String businessName = business['businessName'] ?? 'Negocio';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspender Negocio'),
        content: Text('¿Estás seguro de que quieres suspender el negocio "$businessName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              adminViewModel.suspendBusiness(businessId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Negocio "$businessName" suspendido'),
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

  void _showBusinessDetails(Map<String, dynamic> business) {
    String businessName = business['businessName'] ?? 'Sin nombre';
    String userEmail = business['userEmail'] ?? 'Sin email';
    String category = business['category'] ?? 'General';
    String address = business['address'] ?? 'Sin dirección';
    String phone = business['phone'] ?? 'No disponible';
    String description = business['description'] ?? 'Sin descripción';
    String status = business['status'] ?? 'pending';

    String getStatusDisplayText(String status) {
      switch (status) {
        case 'approved': return 'APROBADO';
        case 'pending': return 'PENDIENTE';
        case 'rejected': return 'RECHAZADO';
        case 'suspended': return 'SUSPENDIDO';
        default: return status.toUpperCase();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Negocio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Nombre:', businessName),
              _buildDetailItem('Email:', userEmail),
              _buildDetailItem('Categoría:', category),
              _buildDetailItem('Dirección:', address),
              _buildDetailItem('Teléfono:', phone),
              _buildDetailItem('Estado:', getStatusDisplayText(status)),
              if (description != 'Sin descripción')
                _buildDetailItem('Descripción:', description),
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
            width: 80,
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

  // Helper methods para acceder a las propiedades del Map
  String getBusinessName(Map<String, dynamic> business) => business['businessName'] ?? 'Sin nombre';
  String getBusinessEmail(Map<String, dynamic> business) => business['userEmail'] ?? 'Sin email';
  String getBusinessCategory(Map<String, dynamic> business) => business['category'] ?? 'General';
  String getBusinessAddress(Map<String, dynamic> business) => business['address'] ?? 'Sin dirección';
  String getBusinessPhone(Map<String, dynamic> business) => business['phone'] ?? 'No disponible';
  String getBusinessDescription(Map<String, dynamic> business) => business['description'] ?? 'Sin descripción';
  String getBusinessStatus(Map<String, dynamic> business) => business['status'] ?? 'pending';
  String getBusinessId(Map<String, dynamic> business) => business['id'] ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}