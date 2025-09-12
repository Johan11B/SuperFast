import 'package:flutter/material.dart';
import 'screens/PantalladeBienvenida.dart'; // Importamos la pantalla de bienvenida

void main() {
  runApp(SuperFastApp());
}

class SuperFastApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperFast',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PantalladeBienvenida(),
    );
  }
}
