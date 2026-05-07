import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/providers/usuario_provider.dart';
import '../../../plan/providers/plan_provider.dart';
import '../../../plan/providers/plan_semana_provider.dart';
import '../../../progreso/data/models/progreso_resumen.dart';
import '../../../progreso/providers/progreso_provider.dart';
import '../../../progreso/data/models/racha.dart';
import '../../../noticias/providers/noticias_provider.dart';
import '../../ui/widgets/ai_suggestion_card.dart';
import '../../ui/widgets/continue_card.dart';
import '../../ui/widgets/greeting_section.dart';
import '../../ui/widgets/home_header.dart';
import '../../ui/widgets/plan_today_card.dart';
import '../../ui/widgets/quick_access_grid.dart';
import '../../ui/widgets/quiet_list_section.dart';
import '../../ui/widgets/stat_tile.dart';

/// Pantalla de inicio — dashboard principal rediseñado (Bloques 2, 3 y 4).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  bool _headerBlurred = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(planSemanaProvider.future).ignore();
      ref.read(rachaNotifierProvider.notifier).load();
      ref.read(progresoResumenNotifierProvider.notifier).load();
    });
  }

  void _onScroll() {
    final shouldBlur = _scrollController.offset > 40;
    if (shouldBlur != _headerBlurred) {
      setState(() => _headerBlurred = shouldBlur);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    final planState = ref.watch(planSemanaProvider).whenData(
          (s) => s.dias.isNotEmpty ? s.dias.first : null,
        );
    final racha = ref.watch(rachaNotifierProvider).valueOrNull;
    final resumen = ref.watch(progresoResumenNotifierProvider).valueOrNull;
    final userAsync = ref.watch(currentUserProvider);
    final noLeidas = ref.watch(noticiaConteosProvider(null)).valueOrNull?.noLeidas;

    final diasHastaExamen = _diasHastaExamen(
      userAsync.valueOrNull?.fechaExamenObjetivo,
    );
    final aiSuggestion = _buildAiSuggestion(resumen, racha);

    return Scaffold(
      backgroundColor: AppColors.bgFor(b),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Header sticky ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 56,
            titleSpacing: 16,
            flexibleSpace: _HeaderBlurBackground(
              isBlurred: _headerBlurred,
              brightness: b,
            ),
            title: HomeHeader(rachaActual: racha?.rachaActual ?? 0),
          ),

          // ── Contenido ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([

                // Greeting
                const GreetingSection(),
                const SizedBox(height: 20),

                // Card "Continuar"
                ContinueCard(
                  planState: planState,
                  onTap: () => context.push(AppRoutes.planHoy),
                  onRetry: () =>
                      ref.read(planSemanaProvider.notifier).reload(),
                ),
                const SizedBox(height: 12),

                // Stats row (racha · aciertos · días)
                _StatsRow(
                  racha: racha?.rachaActual,
                  porcentajeAciertos: resumen?.porcentajeAciertosGlobal,
                  diasHastaExamen: diasHastaExamen,
                  onTapProgreso: () => context.go(AppRoutes.progreso),
                ),
                const SizedBox(height: 12),

                // Plan de hoy (timeline)
                _PlanSection(planState: planState),
                const SizedBox(height: 12),

                // Sugerido por IA
                AiSuggestionCard(
                  suggestion: aiSuggestion,
                  onTap: () => _onAiCardTap(context, resumen),
                ),
                const SizedBox(height: 20),

                // Accesos rápidos
                QuickAccessGrid(
                  onTestRapido: () =>
                      context.push(AppRoutes.practicarTests),
                  onSimulacro: () =>
                      context.push(AppRoutes.practicarSimulacros),
                  onPorTemas: () => context.go(AppRoutes.practicar),
                  onMisFallos: () => context.push(AppRoutes.testFallos),
                ),
                const SizedBox(height: 24),

                // También disponible
                QuietListSection(
                  onCalendario: () => context.push(AppRoutes.calendario),
                  onNoticias: () => context.push(AppRoutes.noticias),
                  onChat: () => context.push(AppRoutes.chat),
                  noticiasBadge: noLeidas,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Calcula los días hasta la fecha de examen. Devuelve null si no hay fecha
  /// configurada o ya pasó.
  static int? _diasHastaExamen(String? fechaStr) {
    if (fechaStr == null) return null;
    try {
      final fecha = DateTime.parse(fechaStr);
      final hoy = DateTime.now();
      final diff =
          fecha.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
      return diff >= 0 ? diff : null;
    } catch (_) {
      return null;
    }
  }

  /// Deriva la sugerencia de la IA a partir de datos reales:
  ///   1. Tema débil más prioritario (menor % de acierto con suficientes respuestas)
  ///   2. Mensaje motivacional si hay racha activa
  ///   3. Mensaje genérico de inicio
  static String _buildAiSuggestion(
    ProgresoResumen? resumen,
    Racha? racha,
  ) {
    if (resumen != null && resumen.temasDebiles.isNotEmpty) {
      final tema = resumen.temasDebiles.first;
      final pct = tema.porcentajeAcierto.round();
      return 'Repasa ${tema.nombre} — tienes un $pct% de aciertos';
    }
    if (racha != null && racha.rachaActual > 1) {
      return '¡Llevas ${racha.rachaActual} días de racha! Sigue con el plan de hoy.';
    }
    return 'Empieza un test para detectar tus puntos débiles.';
  }

  /// Navega a la acción más relevante según la sugerencia de la IA.
  void _onAiCardTap(BuildContext context, ProgresoResumen? resumen) {
    if (resumen != null && resumen.temasDebiles.isNotEmpty) {
      // Hay tema débil → ir a Tests para practicarlo
      context.push(AppRoutes.practicarTests);
    } else {
      // Sin datos suficientes → ir a Progreso para ver el estado
      context.go(AppRoutes.progreso);
    }
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int? racha;
  final double? porcentajeAciertos;
  final int? diasHastaExamen;
  final VoidCallback? onTapProgreso;

  const _StatsRow({
    this.racha,
    this.porcentajeAciertos,
    this.diasHastaExamen,
    this.onTapProgreso,
  });

  Color _diasColor(int? dias) {
    if (dias == null) return AppColors.accentWarm;
    if (dias > 90) return AppColors.accentMint;
    if (dias > 30) return AppColors.accentWarm;
    return AppColors.accentRose;
  }

  Color _diasBgColor(int? dias, Brightness b) {
    if (dias == null) return AppColors.accentWarmSoftFor(b);
    if (dias > 90) return AppColors.accentMintSoftFor(b);
    if (dias > 30) return AppColors.accentWarmSoftFor(b);
    return AppColors.accentRoseSoftFor(b);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final pct = porcentajeAciertos;
    final diasColor = _diasColor(diasHastaExamen);
    final diasBg = _diasBgColor(diasHastaExamen, b);

    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.local_fire_department,
            iconColor: AppColors.accentWarm,
            iconBgColor: AppColors.accentWarmSoftFor(b),
            value: racha != null ? '$racha' : '—',
            label: 'días seguidos',
            valueColor: AppColors.accentWarm,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.trending_up,
            iconColor: AppColors.accentMint,
            iconBgColor: AppColors.accentMintSoftFor(b),
            value: pct != null ? '${pct.round()}%' : '—',
            label: 'aciertos',
            valueColor: pct != null ? AppColors.accentMint : null,
            onTap: onTapProgreso,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.calendar_today,
            iconColor: diasColor,
            iconBgColor: diasBg,
            value: diasHastaExamen != null ? '$diasHastaExamen' : '—',
            label: 'al examen',
            valueColor: diasHastaExamen != null ? diasColor : null,
          ),
        ),
      ],
    );
  }
}

// ── Sección plan de hoy ───────────────────────────────────────────────────────

class _PlanSection extends StatelessWidget {
  final AsyncValue planState;

  const _PlanSection({required this.planState});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return planState.when(
      loading: () => _PlanLoadingCard(brightness: b),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) {
        if (plan == null || plan.totalTareas == 0) {
          return _PlanEmptyCard(brightness: b);
        }
        return PlanTodayCard(plan: plan);
      },
    );
  }
}

class _PlanLoadingCard extends StatelessWidget {
  final Brightness brightness;
  const _PlanLoadingCard({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(brightness), width: 0.5),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryFor(brightness),
          ),
        ),
      ),
    );
  }
}

class _PlanEmptyCard extends StatelessWidget {
  final Brightness brightness;
  const _PlanEmptyCard({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(brightness), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.accentMint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sin plan para hoy · configura uno en Plan',
              style: AppText.body
                  .copyWith(color: AppColors.textMutedFor(brightness)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fondo del header con blur ─────────────────────────────────────────────────

class _HeaderBlurBackground extends StatelessWidget {
  final bool isBlurred;
  final Brightness brightness;

  const _HeaderBlurBackground({
    required this.isBlurred,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlurred) return const SizedBox.expand();

    final bgColor = brightness == Brightness.dark
        ? AppColors.darkBg.withOpacity(0.85)
        : AppColors.lightBg.withOpacity(0.85);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderFor(brightness),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

