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
                // Logo con borde negro
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black, // Color del borde
                      width: 10.0, // Grosor del borde
                    ),
                    borderRadius: BorderRadius.circular(12.0), // Opcional: bordes redondeados
                  ),
                  padding: const EdgeInsets.all(8.0), // Espacio entre la imagen y el borde
                  child: Image.asset(
                    'assets/logoSuper.png',
                    height: 180,
                  ),
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

                // Botón Registrarse
                TextButton(
                  onPressed: () {
                    // Aquí puedes agregar la navegación al registro
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
