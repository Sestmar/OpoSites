import 'package:flutter/material.dart';

/// Pantalla de registro — placeholder para Bloque 3.
/// La UI final va en Bloque 4.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: const Center(
        child: Text('Register — placeholder Bloque 3'),
      ),
    );
  }
}
