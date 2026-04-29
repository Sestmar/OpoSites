import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell persistente de la app — contiene la barra de navegación inferior
/// y el body de la rama activa.
///
/// [navigationShell] es inyectado por [StatefulShellRoute.indexedStack] y
/// actúa como body: renderiza la sub-navegación de la rama activa.
///
/// Para cambiar de rama usamos [navigationShell.goBranch]:
///   - Si el índice ya es el activo, [initialLocation: true] hace que se
///     vuelva a la raíz de esa rama (comportamiento estándar de tabs).
class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      // Doble-tap en el tab activo → volver a la raíz de esa rama
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Practicar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
