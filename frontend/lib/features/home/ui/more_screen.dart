import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/providers/auth_provider.dart';
import '../../noticias/providers/noticias_provider.dart';
import '../../perfil/providers/perfil_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final isAdmin = ref.watch(perfilNotifierProvider).valueOrNull?.isAdmin ?? false;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(b: b)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel('CONTENIDOS', b: b),
                const SizedBox(height: 8),
                _NoticiasCard(b: b),
                const SizedBox(height: 8),
                _MoreCard(
                  icon: Icons.calendar_month_rounded,
                  accentColor: AppColors.accentMint,
                  titulo: 'Calendario',
                  subtitulo: 'Eventos, simulacros y fechas importantes',
                  onTap: () => context.push(AppRoutes.calendario),
                  b: b,
                ),
                const SizedBox(height: 20),
                _SectionLabel('PLAN DE ESTUDIO', b: b),
                const SizedBox(height: 8),
                _MoreCard(
                  icon: Icons.today_rounded,
                  accentColor: AppColors.accentWarm,
                  titulo: 'Plan de hoy',
                  subtitulo: 'Tus tareas de estudio para hoy',
                  onTap: () => context.push(AppRoutes.planHoy),
                  b: b,
                ),
                const SizedBox(height: 8),
                _MoreCard(
                  icon: Icons.tune_rounded,
                  accentColor: AppColors.accentWarm.withOpacity(0.8),
                  titulo: 'Configurar plan',
                  subtitulo: 'Horas, preferencia y fecha del examen',
                  onTap: () => context.push(AppRoutes.planConfig),
                  b: b,
                ),
                const SizedBox(height: 20),
                _SectionLabel('INTELIGENCIA ARTIFICIAL', b: b),
                const SizedBox(height: 8),
                _MoreCard(
                  icon: Icons.smart_toy_rounded,
                  accentColor: AppColors.primaryFor(b),
                  titulo: 'Chat IA',
                  subtitulo: 'Consulta dudas con inteligencia artificial',
                  onTap: () => context.push(AppRoutes.chat),
                  b: b,
                ),
                const SizedBox(height: 8),
                _MoreCard(
                  icon: Icons.auto_stories_rounded,
                  accentColor: AppColors.accentRose,
                  titulo: 'Mis documentos',
                  subtitulo:
                      'Sube tu temario y genera flashcards, resúmenes y más',
                  onTap: () => context.push(AppRoutes.documentos),
                  b: b,
                ),
                const SizedBox(height: 20),
                _SectionLabel('CUENTA', b: b),
                const SizedBox(height: 8),
                _MoreCard(
                  icon: Icons.person_rounded,
                  accentColor: const Color(0xFF818CF8),
                  titulo: 'Mi perfil',
                  subtitulo: 'Foto, datos personales y cerrar sesión',
                  onTap: () => context.push(AppRoutes.perfil),
                  b: b,
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  _MoreCard(
                    icon: Icons.admin_panel_settings_rounded,
                    accentColor: AppColors.accentWarm,
                    titulo: 'Panel Admin',
                    subtitulo: 'Ingesta de noticias y gestión de borradores',
                    onTap: () => context.push(AppRoutes.admin),
                    b: b,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de Noticias con badge de no leídas ────────────────────────────────────

/// Tile de Noticias que muestra un badge con el número de noticias no leídas.
/// Usa la rama principal del usuario autenticado como contexto del conteo,
/// igual que hace NoticiasListScreen al inicializarse.
class _NoticiasCard extends ConsumerWidget {
  const _NoticiasCard({required this.b});

  final Brightness b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ramaId = (ref.watch(authProvider) as AuthAuthenticated?)?.ramaPrincipalId;
    final noLeidas = ref.watch(noticiaConteosProvider(ramaId)).valueOrNull?.noLeidas ?? 0;

    return _MoreCard(
      icon: Icons.newspaper_rounded,
      accentColor: AppColors.primaryFor(b),
      titulo: 'Noticias',
      subtitulo: 'Convocatorias y novedades de tu oposición',
      onTap: () => context.push(AppRoutes.noticias),
      badgeCount: noLeidas > 0 ? noLeidas : null,
      b: b,
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.b});
  final Brightness b;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _StaticParticlesBackground(),
          // Fade inferior hacia el fondo de la lista
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.bgFor(b)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'M',
                        style: AppText.display
                            .copyWith(color: AppColors.textFor(b)),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.accentRose],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'ás',
                          style:
                              AppText.display.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Todo lo que necesitás para prepararte.',
                    style: AppText.bodySmall
                        .copyWith(color: AppColors.textMutedFor(b)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Academic icons background ──────────────────────────────────────────────────

class _StaticParticlesBackground extends StatelessWidget {
  const _StaticParticlesBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _FloatingIcon(Icons.school_outlined,
            alignment: const Alignment(-0.80, -0.75), size: 54, angle: -0.20),
        _FloatingIcon(Icons.menu_book_outlined,
            alignment: const Alignment(0.10, -0.90), size: 46, angle: 0.30),
        _FloatingIcon(Icons.auto_stories_outlined,
            alignment: const Alignment(0.85, -0.55), size: 44, angle: -0.40),
        _FloatingIcon(Icons.collections_bookmark_outlined,
            alignment: const Alignment(-0.40, 0.20), size: 38, angle: 0.50),
        _FloatingIcon(Icons.menu_book_outlined,
            alignment: const Alignment(0.55, 0.30), size: 42, angle: -0.15),
        _FloatingIcon(Icons.school_outlined,
            alignment: const Alignment(-0.10, 0.85), size: 36, angle: 0.10),
        _FloatingIcon(Icons.auto_stories_outlined,
            alignment: const Alignment(0.88, 0.80), size: 34, angle: 0.60),
      ],
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon(
    this.icon, {
    required this.alignment,
    required this.size,
    required this.angle,
  });

  final IconData icon;
  final Alignment alignment;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: angle,
        child: Icon(
          icon,
          size: size,
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {required this.b});
  final String title;
  final Brightness b;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppText.label.copyWith(color: AppColors.textFaintFor(b)),
    );
  }
}

// ── More card ─────────────────────────────────────────────────────────────────

class _MoreCard extends StatelessWidget {
  const _MoreCard({
    required this.icon,
    required this.accentColor,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    required this.b,
    this.badgeCount,
  });

  final IconData icon;
  final Color accentColor;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final Brightness b;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(b),
          border: Border.all(color: AppColors.borderFor(b), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Badge(
              isLabelVisible: badgeCount != null,
              label: Text(
                badgeCount != null && badgeCount! > 99 ? '99+' : '$badgeCount',
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppText.body.copyWith(
                      color: AppColors.textFor(b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: AppText.caption
                        .copyWith(color: AppColors.textMutedFor(b)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textFaintFor(b),
            ),
          ],
        ),
      ),
    );
  }
}
