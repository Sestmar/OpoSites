import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Pantalla de inicio mostrada mientras se restaura la sesión.
///
/// Solo observa [authProvider]:
///   - [AuthInitial] / [AuthLoading] → spinner mientras se comprueba SecureStorage.
///   - Cualquier otro estado ([AuthAuthenticated] / [AuthUnauthenticated]) →
///     el redirect de go_router se encarga de la navegación; esta pantalla
///     no necesita hacer nada.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isRestoring =
        authState is AuthInitial || authState is AuthLoading;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'opoSites',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu copiloto de oposiciones',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 48),
            if (isRestoring) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
