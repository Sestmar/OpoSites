import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/chip_label.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../plan/data/models/plan_hoy.dart';
import '../../../plan/data/models/plan_tarea.dart';

/// Card "Continuar" — muestra la tarea activa del plan de hoy con progreso.
///
/// Maneja todos los estados posibles del [planState]:
///   - Loading    → indicador sutil
///   - Data null  → CTA para generar plan
///   - Data vacío → sin tareas hoy
///   - Data ok    → card con ProgressRing + info de tarea activa
///   - Error      → mensaje + retry
class ContinueCard extends StatelessWidget {
  final AsyncValue<PlanHoy?> planState;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const ContinueCard({
    super.key,
    required this.planState,
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return planState.when(
      loading: () => _LoadingCard(),
      error: (e, _) => _ErrorCard(onRetry: onRetry),
      data: (plan) {
        if (plan == null || plan.totalTareas == 0) {
          return _EmptyCard(onTap: onTap);
        }
        return _PlanCard(plan: plan, onTap: onTap);
      },
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return AppCard.large(
      child: SizedBox(
        height: 108,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryFor(b),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final VoidCallback? onRetry;
  const _ErrorCard({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return AppCard.large(
      child: SizedBox(
        height: 108,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              color: AppColors.textFaintFor(b),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudo cargar el plan',
              style:
                  AppText.bodySmall.copyWith(color: AppColors.textMutedFor(b)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Reintentar',
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.primaryFor(b),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty (sin plan configurado) ──────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _EmptyCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: AppCard.large(
        child: SizedBox(
          height: 108,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.today_outlined,
                color: AppColors.primaryFor(b),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'Sin plan para hoy',
                style: AppText.cardTitle
                    .copyWith(color: AppColors.textFor(b)),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca para generar tu plan de estudio',
                style: AppText.caption
                    .copyWith(color: AppColors.textMutedFor(b)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan activo ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanHoy plan;
  final VoidCallback? onTap;

  const _PlanCard({required this.plan, this.onTap});

  /// Primera tarea no completada = la activa. Null si todas completadas.
  PlanTarea? get _activeTarea =>
      plan.tareas.cast<PlanTarea?>().firstWhere(
            (t) => t != null && !t.completada,
            orElse: () => null,
          );

  double get _progress =>
      plan.totalTareas > 0
          ? (plan.tareasCompletadas / plan.totalTareas * 100).clamp(0, 100)
          : 0;

  String _tareaTitle(PlanTarea tarea) =>
      tarea.descripcion ??
      tarea.nombreTema ??
      tarea.nombreSimulacro ??
      'Siguiente tarea';

  IconData _tipoIcon(TipoPlanTarea tipo) => switch (tipo) {
        TipoPlanTarea.test => Icons.quiz_outlined,
        TipoPlanTarea.repaso => Icons.book_outlined,
        TipoPlanTarea.simulacro => Icons.assignment_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final activeTarea = _activeTarea;
    final allDone = activeTarea == null;

    return GestureDetector(
      onTap: onTap,
      child: AppCard.large(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fila superior: chip + progress ring ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChipLabel(
                  text: allDone ? '¡Completado!' : 'Continuar',
                  backgroundColor: allDone
                      ? AppColors.accentMintSoftFor(b)
                      : null,
                  textColor: allDone ? AppColors.accentMint : null,
                ),
                const Spacer(),
                ProgressRing(
                  value: _progress,
                  size: 44,
                  stroke: 3.5,
                  color: allDone
                      ? AppColors.accentMint
                      : AppColors.primaryFor(b),
                  trackColor: AppColors.surfaceMutedFor(b),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Fila inferior: icono + título + subtítulo ──────────────────
            if (allDone)
              Text(
                '¡Terminaste todas las tareas de hoy!',
                style:
                    AppText.body.copyWith(color: AppColors.textMutedFor(b)),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono del tipo de tarea
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoftFor(b),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _tipoIcon(activeTarea!.tipo),
                      size: 15,
                      color: AppColors.primaryFor(b),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tareaTitle(activeTarea),
                          style: AppText.cardTitle
                              .copyWith(color: AppColors.textFor(b)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.tareasCompletadas} de ${plan.totalTareas} tareas',
                          style: AppText.caption
                              .copyWith(color: AppColors.textMutedFor(b)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.textFaintFor(b),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
