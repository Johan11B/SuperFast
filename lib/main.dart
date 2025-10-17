import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Se usa configuración manual

  runApp(const SuperFastApp());
}

class SuperFastApp extends StatelessWidget {
  const SuperFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperFast',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const LoginPage(),
    );
  }
}
