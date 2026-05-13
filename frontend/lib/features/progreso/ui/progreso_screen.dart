import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable.dart';
import '../../home/ui/widgets/ai_suggestion_card.dart';
import '../../home/ui/widgets/stat_tile.dart';
import '../data/models/progreso_tema.dart';
import '../providers/progreso_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

class ProgresoScreen extends ConsumerStatefulWidget {
  const ProgresoScreen({super.key});

  @override
  ConsumerState<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends ConsumerState<ProgresoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progresoResumenNotifierProvider.notifier).load();
      ref.read(progresoTemasProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(),
              SizedBox(height: 12),
              _StatsRow(),
              SizedBox(height: 10),
              _FallosRow(),
              SizedBox(height: 12),
              _RepasoCard(),
              SizedBox(height: 12),
              _AiSection(),
              SizedBox(height: 20),
              _TemasSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero: anillo gradiente + título con última palabra en color ────────────────

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final state = ref.watch(progresoResumenNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(b),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(b), width: 0.5),
        boxShadow: AppShadows.card,
      ),
      child: state.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => SizedBox(
          height: 140,
          child: Center(
            child: Text(
              'Error al cargar el progreso',
              style: AppText.body.copyWith(color: AppColors.accentRose),
            ),
          ),
        ),
        data: (resumen) {
          if (resumen == null) {
            return SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Completá tu primer test para ver el progreso.',
                  style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final pct = resumen.porcentajeAciertosGlobal;
          final (perfLabel, perfColor) = _performanceInfo(pct);
          final (titleNormal, titleGradient) = _performanceTitle(pct);

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Título: primera parte normal + segunda con gradiente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESUMEN ACTUAL',
                          style: AppText.label.copyWith(
                            color: AppColors.textMutedFor(b),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          titleNormal,
                          style: AppText.display.copyWith(
                            color: AppColors.textFor(b),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.accentRose],
                          ).createShader(bounds),
                          child: Text(
                            titleGradient,
                            style: AppText.display.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aciertos globales',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.primaryFor(b),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Anillo de progreso con gradiente teal → rose
                  TweenAnimationBuilder<double>(
                    key: ValueKey(pct),
                    tween: Tween(begin: 0.0, end: (pct / 100).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _GradientRingPainter(value),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: AppText.h2.copyWith(
                              color: AppColors.textFor(b),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, thickness: 0.5, color: AppColors.borderFor(b)),
              const SizedBox(height: 12),

              // Footer: indicador de rendimiento + timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: perfColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        perfLabel,
                        style: AppText.caption.copyWith(
                          color: AppColors.textMutedFor(b),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ACTUALIZADO HOY',
                    style: AppText.label.copyWith(
                      color: AppColors.textFaintFor(b),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Primera parte en color normal, segunda en gradiente teal → rose.
  (String, String) _performanceTitle(double pct) {
    if (pct >= 70) return ('Excelente', 'ritmo');
    if (pct >= 40) return ('Buen', 'ritmo');
    if (pct > 0)  return ('En', 'progreso');
    return ('Empezando a', 'estudiar');
  }

  (String, Color) _performanceInfo(double pct) {
    if (pct >= 70) return ('Rendimiento óptimo', AppColors.accentMint);
    if (pct >= 40) return ('Ritmo sostenido', AppColors.accentWarm);
    if (pct > 0)  return ('Necesita refuerzo', AppColors.accentRose);
    return ('Sin actividad aún', AppColors.accentRose);
  }
}

// ── Dos stat tiles: respondidas + racha ───────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final resumen = ref.watch(progresoResumenNotifierProvider).valueOrNull;

    final respondidas = resumen?.totalRespondidas ?? 0;
    final racha = resumen?.rachaActual ?? 0;

    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.task_alt_outlined,
            iconColor: AppColors.primaryFor(b),
            iconBgColor: AppColors.primaryFor(b).withOpacity(0.14),
            value: '$respondidas',
            label: 'Respondidas',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: AppColors.accentWarm,
            iconBgColor: AppColors.accentWarm.withOpacity(0.14),
            value: '$racha ${racha == 1 ? 'día' : 'días'}',
            label: 'Mantén el foco',
            valueColor: AppColors.accentWarm,
          ),
        ),
      ],
    );
  }
}

// ── Fila de fallos (full-width, navigable) ─────────────────────────────────────

class _FallosRow extends ConsumerWidget {
  const _FallosRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final resumen = ref.watch(progresoResumenNotifierProvider).valueOrNull;

    if (resumen == null) return const SizedBox.shrink();

    final fallos = resumen.totalRespondidas - resumen.totalCorrectas;

    return Pressable(
      onTap: () {
        // TODO: navegar a pantalla de revisión de fallos
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderFor(b), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentRose.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.heart_broken_outlined,
                color: AppColors.accentRose,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$fallos Fallos',
                    style: AppText.cardTitle.copyWith(
                      color: AppColors.textFor(b),
                    ),
                  ),
                  Text(
                    'Errores por corregir',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textMutedFor(b),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppColors.textFaintFor(b)),
          ],
        ),
      ),
    );
  }
}

// ── Sugerencia IA basada en el tema más débil ──────────────────────────────────

class _AiSection extends ConsumerWidget {
  const _AiSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(progresoResumenNotifierProvider).valueOrNull;
    if (resumen == null || resumen.temasDebiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final tema = resumen.temasDebiles.first;
    final pct = tema.porcentajeAcierto.toStringAsFixed(0);
    final suggestion =
        'Refuerza ${tema.nombre} — tenés un $pct% de aciertos en este tema.';

    return AiSuggestionCard(
      suggestion: suggestion,
      onTap: () {
        // TODO: navegar al tema o iniciar repaso
      },
    );
  }
}

// ── Desglose por temas ─────────────────────────────────────────────────────────

class _TemasSection extends ConsumerWidget {
  const _TemasSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = Theme.of(context).brightness;
    final state = ref.watch(progresoTemasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DESGLOSE POR TEMAS',
              style: AppText.label.copyWith(color: AppColors.textMutedFor(b)),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.temario),
              child: Text(
                'Ver todos',
                style: AppText.caption.copyWith(color: AppColors.primaryFor(b)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        state.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => Text(
            'Error al cargar temas',
            style: AppText.body.copyWith(color: AppColors.accentRose),
          ),
          data: (temas) {
            if (temas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_outlined,
                        size: 40,
                        color: AppColors.textFaintFor(b),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Completá tests para ver estadísticas por tema.',
                        style: AppText.body.copyWith(
                          color: AppColors.textMutedFor(b),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (int i = 0; i < temas.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _TemaTile(tema: temas[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Tarjeta de tema rediseñada: borde izquierdo coloreado + chip % ─────────────

class _TemaTile extends StatelessWidget {
  const _TemaTile({required this.tema});

  final ProgresoTema tema;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final pct = tema.porcentajeAcierto;
    final color = _colorForPct(pct, b);

    return Opacity(
      opacity: pct == 0 ? 0.6 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(b),
              border: Border.all(color: AppColors.borderFor(b), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Borde izquierdo coloreado según rendimiento
                Container(width: 4, color: color),

                // Contenido
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tema.nombre,
                                style: AppText.cardTitle.copyWith(
                                  color: AppColors.textFor(b),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: AppText.label.copyWith(color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tema.correctas}/${tema.totalRespondidas} respondidas',
                          style: AppText.caption.copyWith(
                            color: AppColors.textMutedFor(b),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TweenAnimationBuilder<double>(
                          key: ValueKey(tema.temaId),
                          tween: Tween(
                            begin: 0.0,
                            end: (pct / 100).clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 7,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForPct(double pct, Brightness b) {
    if (pct >= 75) return AppColors.accentMint;
    if (pct >= 50) return AppColors.accentWarm;
    if (pct > 0)  return AppColors.accentRose;
    return AppColors.textFaintFor(b);
  }
}

// ── Pintor del anillo con gradiente teal → rose ────────────────────────────────

class _GradientRingPainter extends CustomPainter {
  final double value; // 0.0 – 1.0

  const _GradientRingPainter(this.value);

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (fondo del anillo)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );

    if (value <= 0) return;

    // Arco con gradiente teal → rose
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: const [
            Color(0xFF14B8A6),
            Color(0xFFFB7185),
          ],
          tileMode: TileMode.clamp,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => old.value != value;
}

// ── 5.2 Repaso personalizado ───────────────────────────────────────────────────

class _RepasoCard extends StatelessWidget {
  const _RepasoCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.repasoActivo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.tertiary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.refresh_outlined,
                  color: colorScheme.tertiary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repasar mis fallos',
                    style: AppText.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '10 preguntas sobre tus temas más débiles',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onTertiaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: colorScheme.tertiary),
          ],
        ),
      ),
    );
  }
}
