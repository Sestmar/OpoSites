import 'package:flutter/material.dart';

/// Pantalla de login — placeholder para Bloque 3.
/// La UI final (formulario, validación, Google Sign-In) va en Bloque 4.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: const Center(
        child: Text('Login — placeholder Bloque 3'),
      ),
    );
  }
}
