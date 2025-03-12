import 'package:flutter/material.dart';
import 'pantalla_inicio.dart';
import 'pantalla_pedidos.dart';
import 'pantalla_perfil.dart';

class MenuPrincipalScreen extends StatefulWidget {
  @override
  _MenuPrincipalScreenState createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  int _indiceSeleccionado = 0;

  final List<Widget> _pantallas = [
    PantallaInicio(),   // ← Tu catálogo de productos
    PantallaPedidos(),  // ← Sección de pedidos
    PantallaPerfil(),   // ← Perfil del usuario
  ];

  void _cambiarIndice(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SuperFast'),
        backgroundColor: Colors.teal,
      ),
      body: _pantallas[_indiceSeleccionado],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _cambiarIndice,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
