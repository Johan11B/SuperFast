// lib/presentation/screens/admin/admin_businesses_screen.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../../domain/entities/business_entity.dart';

class AdminBusinessesScreen extends StatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  State<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends State<AdminBusinessesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  void _loadBusinesses() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadBusinesses();
    });
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  adminViewModel.updateBusinessSearch('');
                },
              ),
            ),
            onChanged: (value) {
              adminViewModel.updateBusinessSearch(value);
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aprobados'),
              Tab(text: 'Pendientes'),
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
      ),
    );
  }

  Widget _buildBusinessesList(List<BusinessEntity> businesses, AdminViewModel adminViewModel, bool isPending) {
    if (adminViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.business_center,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No hay negocios pendientes' : 'No hay negocios aprobados',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadBusinesses,
              child: const Text('Recargar'),
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

  Widget _buildBusinessCard(BusinessEntity business, AdminViewModel adminViewModel, bool isPending) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: business.statusColor,
          child: Icon(
            Icons.business,
            color: Colors.white,
          ),
        ),
        title: Text(
          business.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(business.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: business.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: business.statusColor),
                  ),
                  child: Text(
                    business.statusDisplayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: business.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    business.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            if (business.rating != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${business.rating} (${business.reviewCount} reviews)'),
                ],
              ),
            ],
          ],
        ),
        trailing: isPending
            ? _buildPendingBusinessActions(business, adminViewModel)
            : _buildApprovedBusinessActions(business, adminViewModel),
      ),
    );
  }

  Widget _buildPendingBusinessActions(BusinessEntity business, AdminViewModel adminViewModel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _showApproveDialog(business, adminViewModel),
          tooltip: 'Aprobar negocio',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _showRejectDialog(business, adminViewModel),
          tooltip: 'Rechazar negocio',
        ),
      ],
    );
  }

  Widget _buildApprovedBusinessActions(BusinessEntity business, AdminViewModel adminViewModel) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleBusinessAction(value, business, adminViewModel),
      itemBuilder: (context) => [
        if (business.isApproved)
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
        if (business.isSuspended)
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

  void _handleBusinessAction(String action, BusinessEntity business, AdminViewModel adminViewModel) {
    switch (action) {
      case 'suspend':
        _showSuspendDialog(business, adminViewModel);
        break;
      case 'activate':
        adminViewModel.activateBusiness(business.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Negocio ${business.name} activado')),
        );
        break;
      case 'view_details':
        _showBusinessDetails(business);
        break;
    }
  }

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
                ),
              );
            },
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

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
              if (business.rating != null)
                _buildDetailItem('Rating:', '${business.rating} ⭐ (${business.reviewCount} reviews)'),
              if (business.description != null)
                _buildDetailItem('Descripción:', business.description!),
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
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