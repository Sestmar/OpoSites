import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/chip_label.dart';
import '../../../plan/data/models/plan_hoy.dart';
import '../../../plan/data/models/plan_tarea.dart';
import 'plan_timeline_row.dart';

/// Card "Plan de hoy" — barra de progreso animada + timeline de tareas.
///
/// Recibe [plan] directamente (no AsyncValue) — el estado de carga lo gestiona
/// [HomeScreen] antes de mostrar esta card.
class PlanTodayCard extends StatelessWidget {
  final PlanHoy plan;

  const PlanTodayCard({super.key, required this.plan});

  double get _progress =>
      plan.totalTareas > 0
          ? (plan.tareasCompletadas / plan.totalTareas).clamp(0.0, 1.0)
          : 0.0;

  String get _progressLabel =>
      '${(plan.tareasCompletadas / plan.totalTareas * 100).round()}%';

  TimelineTaskStatus _statusFor(int index) {
    if (plan.tareas[index].completada) return TimelineTaskStatus.done;
    final firstActive = plan.tareas.indexWhere((t) => !t.completada);
    return index == firstActive
        ? TimelineTaskStatus.active
        : TimelineTaskStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final allDone = plan.tareasCompletadas >= plan.totalTareas;

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan de hoy',
                      style: AppText.cardTitle
                          .copyWith(color: AppColors.textFor(b)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.totalTareas == 0
                          ? 'Sin tareas configuradas'
                          : '${plan.tareasCompletadas} de ${plan.totalTareas} completadas',
                      style: AppText.caption
                          .copyWith(color: AppColors.textMutedFor(b)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ChipLabel(
                text: allDone ? '¡Listo!' : _progressLabel,
                backgroundColor:
                    allDone ? AppColors.accentMintSoftFor(b) : null,
                textColor: allDone ? AppColors.accentMint : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Barra de progreso animada ─────────────────────────────────────
          _AnimatedProgressBar(
            key: ValueKey(plan.tareasCompletadas),
            progress: _progress,
            brightness: b,
          ),

          const SizedBox(height: 16),

          // ── Timeline ──────────────────────────────────────────────────────
          if (plan.tareas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No hay tareas para hoy.',
                style: AppText.body
                    .copyWith(color: AppColors.textMutedFor(b)),
              ),
            )
          else
            ...List.generate(plan.tareas.length, (i) {
              return PlanTimelineRow(
                tarea: plan.tareas[i],
                status: _statusFor(i),
                isLast: i == plan.tareas.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

// ── Barra de progreso animada ─────────────────────────────────────────────────

class _AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final Brightness brightness;

  const _AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        return Stack(
          children: [
            // Track
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceMutedFor(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Fill con gradiente teal → rose
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accentRose],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
