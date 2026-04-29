import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/screens/select_oposicion_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/calendario/ui/calendario_screen.dart';
import '../../features/chat/ui/chat_list_screen.dart';
import '../../features/chat/ui/chat_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/ui/main_scaffold.dart';
import '../../features/home/ui/more_screen.dart';
import '../../features/noticias/ui/noticia_detalle_screen.dart';
import '../../features/noticias/ui/noticias_list_screen.dart';
import '../../features/plan/ui/plan_config_screen.dart';
import '../../features/plan/ui/plan_hoy_screen.dart';
import '../../features/practicar/ui/practicar_menu_screen.dart';
import '../../features/progreso/ui/progreso_screen.dart';
import '../../features/simulacros/ui/simulacro_active_screen.dart';
import '../../features/simulacros/ui/simulacro_result_screen.dart';
import '../../features/simulacros/ui/simulacros_list_screen.dart';
import '../../features/tests/ui/test_active_screen.dart';
import '../../features/tests/ui/test_config_screen.dart';
import '../../features/tests/ui/test_fallos_screen.dart';
import '../../features/tests/ui/test_result_screen.dart';

part 'app_router.g.dart';

// ── Constantes de rutas ────────────────────────────────────────────────────────

abstract final class AppRoutes {
  // ── Auth (fuera del shell) ─────────────────────────────────────────────────
  static const splash          = '/splash';
  static const login           = '/login';
  static const register        = '/register';
  static const selectOposicion = '/select-oposicion';

  // ── Tab raíces (dentro del shell) ──────────────────────────────────────────
  static const home      = '/home';
  static const practicar = '/practicar';
  static const progreso  = '/progreso';
  static const mas       = '/mas';

  // ── Practicar sub-rutas ────────────────────────────────────────────────────
  static const practicarTests      = '/practicar/tests';
  static const practicarSimulacros = '/practicar/simulacros';

  // ── Test screens (fuera del shell — flujo inmersivo) ───────────────────────
  static const testActivo    = '/test/activo';
  static const testResultado = '/test/resultado';
  static const testFallos    = '/test/fallos';

  // ── Simulacro screens (fuera del shell — flujo inmersivo) ─────────────────
  static const simulacroActivo    = '/simulacros/activo';
  static const simulacroResultado = '/simulacros/resultado';

  // ── Más sub-rutas (dentro del shell, rama Más) ─────────────────────────────
  static const noticias       = '/noticias';
  static const noticiaDetalle = '/noticias/:id';
  static String noticiaDetalleUri(int id) => '/noticias/$id';

  static const calendario = '/calendario';
  static const planHoy    = '/plan/hoy';
  static const planConfig = '/plan/config';
  static const chat       = '/chat';
  static String chatDetalle(int id) => '/chat/$id';
}

// ── Auth listenable ────────────────────────────────────────────────────────────

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

// ── Router ─────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final listenable = _AuthListenable();
  ref.listen<AuthState>(authProvider, (_, __) => listenable.notify());
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: listenable,

    // ── Guard de sesión ────────────────────────────────────────────────────
    //
    // AuthInitial/Loading   → splash (esperamos restauración de sesión)
    // AuthAuthenticated     → home (si viene de auth/splash)
    // AuthUnauthenticated   → login (si intenta acceder a rutas protegidas)
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loc = state.matchedLocation;

      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;
      final isSplash    = loc == AppRoutes.splash;

      return switch (authState) {
        AuthInitial() || AuthLoading() =>
          isSplash ? null : AppRoutes.splash,

        AuthAuthenticated() =>
          (isAuthRoute || isSplash) ? AppRoutes.home : null,

        AuthUnauthenticated() || AuthError() =>
          isAuthRoute ? null : AppRoutes.login,
      };
    },

    routes: [
      // ── Auth (fuera del shell) ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectOposicion,
        builder: (_, __) => const SelectOposicionScreen(),
      ),

      // ── Tests — flujo inmersivo (fuera del shell) ────────────────────────
      GoRoute(
        path: AppRoutes.testActivo,
        builder: (_, __) => const TestActiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.testResultado,
        builder: (_, __) => const TestResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.testFallos,
        builder: (_, __) => const TestFallosScreen(),
      ),

      // ── Simulacros — flujo inmersivo (fuera del shell) ───────────────────
      GoRoute(
        path: AppRoutes.simulacroActivo,
        builder: (_, __) => const SimulacroActiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.simulacroResultado,
        builder: (_, __) => const SimulacroResultScreen(),
      ),

      // ── Shell con 4 tabs ─────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainScaffold(navigationShell: shell),
        branches: [
          // ── Rama 0: Inicio ───────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),

          // ── Rama 1: Practicar ────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.practicar,
                builder: (_, __) => const PracticarMenuScreen(),
                routes: [
                  GoRoute(
                    path: 'tests',
                    builder: (_, __) => const TestConfigScreen(),
                  ),
                  GoRoute(
                    path: 'simulacros',
                    builder: (_, __) => const SimulacrosListScreen(),
                  ),
                ],
              ),
            ],
          ),

          // ── Rama 2: Progreso ─────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progreso,
                builder: (_, __) => const ProgresoScreen(),
              ),
            ],
          ),

          // ── Rama 3: Más ──────────────────────────────────────────────────
          //
          // Todas las rutas de esta rama comparten el mismo navigator,
          // por lo que el back-button devuelve a la pantalla anterior
          // dentro de la rama (ej. Noticias → MoreScreen).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mas,
                builder: (_, __) => const MoreScreen(),
              ),
              GoRoute(
                path: AppRoutes.noticias,
                builder: (_, __) => const NoticiasListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => NoticiaDetalleScreen(
                      id: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.calendario,
                builder: (_, __) => const CalendarioScreen(),
              ),
              GoRoute(
                path: AppRoutes.planHoy,
                builder: (_, __) => const PlanHoyScreen(),
              ),
              GoRoute(
                path: AppRoutes.planConfig,
                builder: (_, __) => const PlanConfigScreen(),
              ),
              GoRoute(
                path: AppRoutes.chat,
                builder: (_, __) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ChatScreen(
                      conversacionId:
                          int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

