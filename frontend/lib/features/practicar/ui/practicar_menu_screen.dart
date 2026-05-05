import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/providers/auth_provider.dart';
import '../../documentos/data/models/documento.dart';
import '../../tests/providers/test_session_provider.dart';

// ── Provider local: últimos documentos ────────────────────────────────────────

final _recentDocsProvider =
    FutureProvider.autoDispose<List<Documento>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<List<dynamic>>(ApiEndpoints.documentos);
  final all = (response.data ?? [])
      .map((e) => Documento.fromJson(e as Map<String, dynamic>))
      .toList();
  // Ordenar por fecha desc y tomar los 3 más recientes
  all.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  return all.take(3).toList();
});

// ── Pantalla ───────────────────────────────────────────────────────────────────

class PracticarMenuScreen extends ConsumerStatefulWidget {
  const PracticarMenuScreen({super.key});

  @override
  ConsumerState<PracticarMenuScreen> createState() =>
      _PracticarMenuScreenState();
}

class _PracticarMenuScreenState extends ConsumerState<PracticarMenuScreen> {
  bool _sesionRapidaLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Escuchar cambio de estado del test activo
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final auth = ref.watch(authProvider);
    final ramaId = auth is AuthAuthenticated ? auth.ramaPrincipalId : null;

    // Navegar al test cuando se active, limpiar spinner si error
    ref.listen<TestState>(activeTestProvider, (_, next) {
      if (next is TestStateActive) {
        setState(() => _sesionRapidaLoading = false);
        context.push(AppRoutes.testActivo);
      } else if (next is TestStateError) {
        setState(() => _sesionRapidaLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo iniciar el test. Intentá de nuevo.'),
            backgroundColor: AppColors.accentRose,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgFor(b),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título con gradiente ───────────────────────────────────────
              _GradientTitle(b: b),
              const SizedBox(height: 6),
              Text(
                'Optimizá tu tiempo de estudio con sesiones enfocadas.',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textMutedFor(b),
                ),
              ),
              const SizedBox(height: 20),

              // ── Sesión rápida ──────────────────────────────────────────────
              if (ramaId != null) ...[
                _SesionRapidaPill(
                  isLoading: _sesionRapidaLoading,
                  onTap: () async {
                    setState(() => _sesionRapidaLoading = true);
                    await ref
                        .read(activeTestProvider.notifier)
                        .generarTest(ramaId: ramaId, cantidad: 10);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Cards de modos (3 en fila) ─────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ModeCardSquare(
                      b: b,
                      accentColor: AppColors.primaryFor(b),
                      glowColor: AppColors.primaryFor(b).withOpacity(0.12),
                      icon: Icons.edit_note_rounded,
                      titulo: 'Tests libres',
                      badge: 'TOP',
                      onTap: () => context.push(AppRoutes.practicarTests),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeCardSquare(
                      b: b,
                      accentColor: AppColors.accentWarm,
                      glowColor: AppColors.accentWarm.withOpacity(0.10),
                      icon: Icons.timer_rounded,
                      titulo: 'Simulacros',
                      onTap: () => context.push(AppRoutes.practicarSimulacros),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeCardSquare(
                      b: b,
                      accentColor: AppColors.accentRose,
                      glowColor: AppColors.accentRose.withOpacity(0.10),
                      icon: Icons.history_edu_rounded,
                      titulo: 'Mis fallos',
                      onTap: () => context.push(AppRoutes.testFallos),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Practicar por tema ─────────────────────────────────────────
              _PorTemaTile(b: b),
              const SizedBox(height: 24),

              // ── Recursos Recientes ─────────────────────────────────────────
              _RecursosRecientes(b: b),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Título gradiente ───────────────────────────────────────────────────────────

class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.b});

  final Brightness b;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elige tu',
          style: AppText.display.copyWith(color: AppColors.textFor(b)),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accentRose],
          ).createShader(bounds),
          child: Text(
            'modo.',
            style: AppText.display.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── Pill sesión rápida ─────────────────────────────────────────────────────────

class _SesionRapidaPill extends StatelessWidget {
  const _SesionRapidaPill({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text(
          isLoading ? 'Generando…' : 'Sesión rápida — 10 preguntas ahora',
          style: AppText.label.copyWith(
            color: AppColors.primary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Card de modo (cuadrada, 1/3 de fila) ──────────────────────────────────────

class _ModeCardSquare extends StatelessWidget {
  const _ModeCardSquare({
    required this.b,
    required this.accentColor,
    required this.glowColor,
    required this.icon,
    required this.titulo,
    required this.onTap,
    this.badge,
  });

  final Brightness b;
  final Color accentColor;
  final Color glowColor;
  final IconData icon;
  final String titulo;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: 148,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(b),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderFor(b), width: 0.5),
            boxShadow: [
              BoxShadow(color: glowColor, blurRadius: 16, spreadRadius: -4),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              // Badge opcional (solo si cabe)
              if (badge != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accentColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    badge!,
                    style: AppText.label.copyWith(
                      color: accentColor,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Título
              Text(
                titulo,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textFor(b),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Flecha
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile "Practicar por tema" ──────────────────────────────────────────────────

class _PorTemaTile extends StatelessWidget {
  const _PorTemaTile({required this.b});

  final Brightness b;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(AppRoutes.temario),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(b),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderFor(b), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryFor(b).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryFor(b),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practicar por tema',
                    style: AppText.body.copyWith(
                      color: AppColors.textFor(b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Elige un tema específico del temario',
                    style: AppText.caption.copyWith(
                      color: AppColors.textMutedFor(b),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaintFor(b),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recursos Recientes ─────────────────────────────────────────────────────────

class _RecursosRecientes extends ConsumerWidget {
  const _RecursosRecientes({required this.b});

  final Brightness b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(_recentDocsProvider);

    return docsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (docs) {
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECURSOS RECIENTES',
              style: AppText.label.copyWith(
                color: AppColors.textFaintFor(b),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(b),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderFor(b), width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < docs.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: AppColors.borderFor(b).withOpacity(0.5),
                        indent: 16,
                        endIndent: 16,
                      ),
                    _DocTile(doc: docs[i], b: b, context: context),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.doc,
    required this.b,
    required this.context,
  });

  final Documento doc;
  final Brightness b;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final isPdf = doc.tipoArchivo.toUpperCase() == 'PDF';
    final icon = isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined;

    return Pressable(
      onTap: () => context.push(
        AppRoutes.documentoDetalle(doc.id),
        extra: doc,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgFor(b),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textMutedFor(b), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.nombre,
                    style: AppText.body.copyWith(color: AppColors.textFor(b)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${doc.tipoArchivo} • ${doc.tamanoFormateado}',
                    style: AppText.caption.copyWith(
                      color: AppColors.textFaintFor(b),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaintFor(b),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
