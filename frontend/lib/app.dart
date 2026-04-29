import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Widget raíz de la aplicación.
///
/// Observa [appRouterProvider] para obtener el [GoRouter] configurado con
/// el guard de sesión. El [ProviderScope] que envuelve este widget
/// (declarado en main.dart) es el contenedor de todos los providers.
class OpoSitesApp extends ConsumerWidget {
  const OpoSitesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'opoSites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
