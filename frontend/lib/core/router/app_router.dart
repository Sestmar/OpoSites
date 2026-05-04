import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/screens/select_oposicion_screen.dart';
import '../../features/perfil/ui/perfil_screen.dart';
import '../../features/perfil/ui/editar_perfil_screen.dart';
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
import '../../features/documentos/data/models/documento.dart';
import '../../features/documentos/data/models/material_generado.dart';
import '../../features/documentos/ui/conceptos_clave_screen.dart';
import '../../features/documentos/ui/documento_detalle_screen.dart';
import '../../features/documentos/ui/documentos_screen.dart';
import '../../features/documentos/ui/flashcards_screen.dart';
import '../../features/documentos/data/models/documento_test.dart';
import '../../features/documentos/ui/documento_test_result_screen.dart';
import '../../features/documentos/ui/documento_test_screen.dart';
import '../../features/documentos/ui/mapa_mental_screen.dart';
import '../../features/documentos/ui/resumen_screen.dart';
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

  static const perfil      = '/perfil';
  static const editarPerfil = '/perfil/editar';
  static const cambiarOposicionPerfil = '/perfil/cambiar-oposicion';

  // ── Documentos sub-rutas ───────────────────────────────────────────────────
  static const documentos = '/documentos';
  static String documentoDetalle(int id)    => '/documentos/$id';
  static String documentoFlashcards(int id)  => '/documentos/$id/flashcards';
  static String documentoResumen(int id)     => '/documentos/$id/resumen';
  static String documentoConceptos(int id)   => '/documentos/$id/conceptos';
  static String documentoMapaMental(int id)  => '/documentos/$id/mapa-mental';
  static String documentoTest(int id)        => '/documentos/$id/test';
  static String documentoTestResultado(int id) => '/documentos/$id/test/resultado';
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

      final isAuthRoute     = loc == AppRoutes.login || loc == AppRoutes.register;
      final isSplash        = loc == AppRoutes.splash;
      final isSelectOposicion = loc == AppRoutes.selectOposicion;

      return switch (authState) {
        AuthInitial() || AuthLoading() =>
          isSplash ? null : AppRoutes.splash,

        // Sin rama → onboarding obligatorio antes del home
        AuthAuthenticated(ramaPrincipalId: null) =>
          isSelectOposicion ? null : AppRoutes.selectOposicion,

        // Con rama (o -1 por fallo de red) → home normal
        AuthAuthenticated() =>
          (isAuthRoute || isSplash || isSelectOposicion) ? AppRoutes.home : null,

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
              GoRoute(
                path: AppRoutes.perfil,
                builder: (_, __) => const PerfilScreen(),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (_, __) => const EditarPerfilScreen(),
                  ),
                  GoRoute(
                    path: 'cambiar-oposicion',
                    builder: (_, __) =>
                        const SelectOposicionScreen(fromPerfil: true),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.documentos,
                builder: (_, __) => const DocumentosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final extra = state.extra;
                      if (extra is! Documento) {
                        return const _ExtraLostScreen();
                      }
                      return DocumentoDetalleScreen(
                        docId: int.parse(state.pathParameters['id']!),
                        documento: extra,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'flashcards',
                        builder: (_, state) {
                          final extra = state.extra;
                          if (extra is! MaterialGenerado) {
                            return const _ExtraLostScreen();
                          }
                          return FlashcardsScreen(material: extra);
                        },
                      ),
                      GoRoute(
                        path: 'resumen',
                        builder: (_, state) {
                          final extra = state.extra;
                          if (extra is! MaterialGenerado) {
                            return const _ExtraLostScreen();
                          }
                          return ResumenScreen(material: extra);
                        },
                      ),
                      GoRoute(
                        path: 'conceptos',
                        builder: (_, state) {
                          final extra = state.extra;
                          if (extra is! MaterialGenerado) {
                            return const _ExtraLostScreen();
                          }
                          return ConceptosClaveScreen(material: extra);
                        },
                      ),
                      GoRoute(
                        path: 'mapa-mental',
                        builder: (_, state) {
                          final extra = state.extra;
                          if (extra is! MaterialGenerado) {
                            return const _ExtraLostScreen();
                          }
                          return MapaMentalScreen(material: extra);
                        },
                      ),
                      GoRoute(
                        path: 'test',
                        builder: (_, state) {
                          final extra = state.extra;
                          if (extra is! DocumentoTest) {
                            return const _ExtraLostScreen();
                          }
                          return DocumentoTestScreen(test: extra);
                        },
                        routes: [
                          GoRoute(
                            path: 'resultado',
                            builder: (_, state) {
                              final extra = state.extra;
                              if (extra is! DocumentoTestSesion) {
                                return const _ExtraLostScreen();
                              }
                              return DocumentoTestResultScreen(sesion: extra);
                            },
                          ),
                        ],
                      ),
                    ],
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

// ── Pantalla de seguridad cuando extra se pierde (hot restart / deep link) ─────

class _ExtraLostScreen extends StatelessWidget {
  const _ExtraLostScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('La sesión de navegación expiró.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AppRoutes.documentos),
              child: const Text('Volver a documentos'),
            ),
          ],
        ),
      ),
    );
  }
}
