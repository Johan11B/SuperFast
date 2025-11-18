// lib/presentation/screens/user/user_orders_screen.dart
import 'package:flutter/material.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Mis Pedidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Próximamente...'),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}