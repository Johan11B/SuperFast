import 'package:flutter/material.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN

class AppConstants {
  static const String appName = 'SuperFast';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF008C9E);
  static const Color scaffoldBackgroundColor = Color(0xFFEFEFEF);
  static const Color accentColor = Color(0xFF1E88E5);

  // Assets
  static const String logoPath = 'assets/logo.jpg';
  static const String logoPanelPath = 'assets/logo_panel.jpg';

  // Firebase Collections (para futuro uso)
  static const String usersCollection = 'users';
  static const String businessesCollection = 'businesses';
  static const String ordersCollection = 'orders';
}