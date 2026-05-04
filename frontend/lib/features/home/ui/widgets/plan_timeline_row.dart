import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../plan/data/models/plan_tarea.dart';

/// Estado visual de una tarea en la timeline.
enum TimelineTaskStatus { done, active, pending }

/// Fila individual del timeline del plan de hoy.
///
/// Adapta el diseño original (que usaba hora) al modelo real de [PlanTarea],
/// que no tiene campo `hora`. La columna izquierda muestra el tipo de tarea
/// en lugar de la hora.
class PlanTimelineRow extends StatelessWidget {
  final PlanTarea tarea;
  final TimelineTaskStatus status;

  /// Si es la última fila, oculta el conector vertical inferior.
  final bool isLast;

  const PlanTimelineRow({
    super.key,
    required this.tarea,
    required this.status,
    this.isLast = false,
  });

  String get _title =>
      tarea.descripcion ??
      tarea.nombreTema ??
      tarea.nombreSimulacro ??
      'Tarea';

  String get _tipoLabel => switch (tarea.tipo) {
        TipoPlanTarea.test => 'TEST',
        TipoPlanTarea.repaso => 'REPASO',
        TipoPlanTarea.simulacro => 'SIMULACRO',
      };

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isDone = status == TimelineTaskStatus.done;
    final isActive = status == TimelineTaskStatus.active;
    final isPending = status == TimelineTaskStatus.pending;

    final titleColor = isDone
        ? AppColors.textMutedFor(b)
        : isPending
            ? AppColors.textFaintFor(b)
            : AppColors.textFor(b);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Columna izquierda: dot + línea ─────────────────────────────
          SizedBox(
            width: 20,
            child: Column(
              children: [
                _DotWidget(status: status, brightness: b),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        color: AppColors.borderFor(b),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Contenido ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de tipo
                  _TipoBadge(
                    label: _tipoLabel,
                    isDone: isDone,
                    isActive: isActive,
                    brightness: b,
                  ),
                  const SizedBox(height: 4),

                  // Título
                  Text(
                    _title,
                    style: AppText.body.copyWith(
                      color: titleColor,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.textMutedFor(b),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ── Dot ───────────────────────────────────────────────────────────────────────

class _DotWidget extends StatelessWidget {
  final TimelineTaskStatus status;
  final Brightness brightness;

  const _DotWidget({required this.status, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: switch (status) {
        TimelineTaskStatus.done => Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.accentMint,
              shape: BoxShape.circle,
            ),
          ),
        TimelineTaskStatus.active => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primarySoftFor(brightness),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primaryFor(brightness),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        TimelineTaskStatus.pending => Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(brightness),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderFor(brightness),
                width: 0.5,
              ),
            ),
          ),
      },
    );
  }
}

// ── Badge de tipo ─────────────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final Brightness brightness;

  const _TipoBadge({
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.textFaintFor(brightness)
        : isActive
            ? AppColors.primaryFor(brightness)
            : AppColors.textFaintFor(brightness);

    return Text(
      label,
      style: AppText.label.copyWith(
        color: color,
        letterSpacing: 0.4,
      ),
    );
  }
}
