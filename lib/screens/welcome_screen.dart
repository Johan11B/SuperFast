import 'package:flutter/material.dart';
import 'menu_principal.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logoSuper.jpeg', // Asegúrate que esta imagen esté en la carpeta assets
                  height: 180,
                ),
                SizedBox(height: 30),

                // Título
                Text(
                  'Bienvenido a SuperFast',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Subtítulo
                Text(
                  'Tu app de domicilios rápida, confiable y local.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // Botón Iniciar Sesión
                ElevatedButton(
                  onPressed: () {
                    // Al presionar, va al menú principal
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MenuPrincipalScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),

                SizedBox(height: 20),

                // Botón Registrarse (a futuro puedes conectarlo)
                TextButton(
                  onPressed: () {
                    // Puedes navegar a pantalla de registro aquí
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
