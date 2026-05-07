import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/plan_hoy.dart';
import '../data/models/plan_tarea.dart';
import '../providers/plan_provider.dart';
import '../providers/plan_semana_provider.dart';

// ── Constantes ─────────────────────────────────────────────────────────────────

const _dayAbbr = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];

const _meses = [
  '',
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const _minutosPorTipo = {
  TipoPlanTarea.test: 20,
  TipoPlanTarea.repaso: 30,
  TipoPlanTarea.simulacro: 60,
};

// ── Pantalla principal ─────────────────────────────────────────────────────────

class PlanHoyScreen extends ConsumerStatefulWidget {
  const PlanHoyScreen({super.key});

  @override
  ConsumerState<PlanHoyScreen> createState() => _PlanHoyScreenState();
}

class _PlanHoyScreenState extends ConsumerState<PlanHoyScreen> {
  int? _loadingTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planSemanaProvider.future).ignore();
      final cfg = ref.read(planConfiguracionNotifierProvider);
      if (!cfg.hasValue || cfg.value == null) {
        ref.read(planConfiguracionNotifierProvider.notifier).load();
      }
    });
  }

  Future<void> _completarTarea(PlanTarea tarea) async {
    setState(() => _loadingTaskId = tarea.id);
    try {
      await ref.read(planSemanaProvider.notifier).completarTarea(tarea.id);
    } catch (e) {
      if (mounted) _showError(_msgError(e));
    } finally {
      if (mounted) setState(() => _loadingTaskId = null);
    }
  }

  Future<void> _eliminarTarea(PlanTarea tarea) async {
    try {
      await ref.read(planSemanaProvider.notifier).eliminarTarea(tarea.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tarea eliminada')));
      }
    } catch (e) {
      if (mounted) _showError(_msgError(e));
    }
  }

  Future<void> _reload() async {
    await ref.read(planSemanaProvider.notifier).reload();
  }

  Future<void> _mostrarAddTarea(DateTime fechaDia) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddTareaSheet(
        onGuardar: (tipo, descripcion) async {
          Navigator.of(ctx).pop();
          try {
            await ref.read(planSemanaProvider.notifier).crearTarea(
                  tipo: tipo,
                  descripcion: descripcion,
                  fecha: fechaDia,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tarea añadida')),
              );
            }
          } catch (e) {
            if (mounted) _showError(_msgError(e));
          }
        },
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final semanaState = ref.watch(planSemanaProvider);
    final diasHastaExamen =
        ref.watch(planConfiguracionNotifierProvider).valueOrNull?.diasHastaExamen;

    return semanaState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Plan de estudio')),
        body: _ErrorBody(message: _msgError(e), onRetry: _reload),
      ),
      data: (semana) {
        final dia = semana.diaSeleccionado;
        final fechaDia =
            dia != null ? _parseDate(dia.fecha) : DateTime.now();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Plan de estudio'),
            actions: [
              IconButton(
                tooltip: 'Recargar',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _reload,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _mostrarAddTarea(fechaDia),
            icon: const Icon(Icons.add),
            label: const Text('Añadir tarea'),
          ),
          body: Column(
            children: [
              // ── Barra semanal ──────────────────────────────────────────
              _DayNavBar(
                dias: semana.dias,
                selectedIndex: semana.diaSeleccionadoIndex,
                onSelectDia: (i) =>
                    ref.read(planSemanaProvider.notifier).seleccionarDia(i),
              ),
              const Divider(height: 1),

              // ── Contenido ──────────────────────────────────────────────
              Expanded(
                child: dia == null || dia.tareas.isEmpty
                    ? _EmptyDayBody(
                        fecha: fechaDia,
                        onAddTarea: () => _mostrarAddTarea(fechaDia),
                      )
                    : _PlanBody(
                        plan: dia,
                        loadingTaskId: _loadingTaskId,
                        diasHastaExamen: diasHastaExamen,
                        onCompletar: _completarTarea,
                        onEliminar: _eliminarTarea,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers globales ───────────────────────────────────────────────────────────

String _msgError(Object e) =>
    e is ApiException ? e.message : 'Ocurrió un error inesperado.';

DateTime _parseDate(String fecha) {
  final p = fecha.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _labelFecha(DateTime fecha) {
  final now = DateTime.now();
  final esHoy =
      fecha.year == now.year && fecha.month == now.month && fecha.day == now.day;
  if (esHoy) return 'Hoy';
  final tomorrow = now.add(const Duration(days: 1));
  final esManana = fecha.year == tomorrow.year &&
      fecha.month == tomorrow.month &&
      fecha.day == tomorrow.day;
  if (esManana) return 'Mañana';
  return '${_dayAbbr[fecha.weekday]}  ·  ${fecha.day} ${_meses[fecha.month]}';
}

int _estimarMinutosDia(List<PlanTarea> tareas) =>
    tareas.fold(0, (sum, t) => sum + (_minutosPorTipo[t.tipo] ?? 20));

// ── Barra semanal ──────────────────────────────────────────────────────────────

class _DayNavBar extends StatelessWidget {
  const _DayNavBar({
    required this.dias,
    required this.selectedIndex,
    required this.onSelectDia,
  });

  final List<PlanHoy> dias;
  final int selectedIndex;
  final ValueChanged<int> onSelectDia;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final teal = AppColors.primaryFor(b);

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: dias.length,
        itemBuilder: (_, i) {
          final dia = dias[i];
          final fecha = _parseDate(dia.fecha);
          final isSelected = i == selectedIndex;
          final isToday = _isToday(fecha);
          final completado = dia.totalTareas > 0 &&
              dia.tareasCompletadas == dia.totalTareas;
          final hasTareas = dia.totalTareas > 0;

          final fgColor = isSelected ? teal : AppColors.textMutedFor(b);

          return GestureDetector(
            onTap: () => onSelectDia(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? teal.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: teal.withOpacity(0.5), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Inicial del día
                  Text(
                    _dayAbbr[fecha.weekday],
                    style: AppText.label.copyWith(
                      color: fgColor,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w600,
                      fontSize: isSelected ? 11.5 : 10.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Número del día
                  Text(
                    '${fecha.day}',
                    style: AppText.body.copyWith(
                      color: isSelected ? teal : AppColors.textFor(b),
                      fontWeight: FontWeight.w700,
                      fontSize: isSelected ? 17 : 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Indicador de progreso
                  _DayDot(
                    hasTareas: hasTareas,
                    completado: completado,
                    parcial: hasTareas && !completado && dia.tareasCompletadas > 0,
                    color: teal,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime fecha) {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.hasTareas,
    required this.completado,
    required this.parcial,
    required this.color,
  });

  final bool hasTareas;
  final bool completado;
  final bool parcial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    if (!hasTareas) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderFor(b), width: 1.5),
        ),
      );
    }
    if (completado) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
    }
    // Parcial o sin empezar
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: parcial ? color.withOpacity(0.5) : Colors.transparent,
        border: Border.all(
          color: parcial ? color.withOpacity(0.5) : AppColors.textFaintFor(b),
          width: 1.5,
        ),
      ),
    );
  }
}

// ── Cuerpo con datos ───────────────────────────────────────────────────────────

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.plan,
    required this.onCompletar,
    required this.onEliminar,
    this.loadingTaskId,
    this.diasHastaExamen,
  });

  final PlanHoy plan;
  final int? loadingTaskId;
  final int? diasHastaExamen;
  final Future<void> Function(PlanTarea) onCompletar;
  final Future<void> Function(PlanTarea) onEliminar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final completadas = plan.tareasCompletadas;
    final total = plan.totalTareas;
    final todoDone = completadas == total && total > 0;
    final minutosTotales = _estimarMinutosDia(plan.tareas);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // ── Tarjeta de progreso del día ────────────────────────────────
        _ProgressCard(
          fecha: _parseDate(plan.fecha),
          completadas: completadas,
          total: total,
          minutosTotales: minutosTotales,
          diasHastaExamen: diasHastaExamen,
        ),
        const SizedBox(height: 20),

        // ── Sección de tareas ──────────────────────────────────────────
        Text(
          'TAREAS',
          style: AppText.label.copyWith(color: AppColors.textMutedFor(b)),
        ),
        const SizedBox(height: 10),
        ...plan.tareas.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TareaTile(
              tarea: t,
              isLoading: loadingTaskId == t.id,
              onCompletar: () => onCompletar(t),
              onEliminar: () => onEliminar(t),
            ),
          ),
        ),

        // ── Bloque inferior ────────────────────────────────────────────
        const SizedBox(height: 12),
        if (todoDone)
          _FooterCelebracion()
        else if (diasHastaExamen != null && diasHastaExamen! > 0)
          _FooterExamen(diasHastaExamen: diasHastaExamen!),
      ],
    );
  }
}

// ── Tarjeta de progreso ────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.fecha,
    required this.completadas,
    required this.total,
    required this.minutosTotales,
    this.diasHastaExamen,
  });

  final DateTime fecha;
  final int completadas;
  final int total;
  final int minutosTotales;
  final int? diasHastaExamen;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final teal = AppColors.primaryFor(b);
    final progreso = total == 0 ? 0.0 : completadas / total;
    final label = _labelFecha(fecha);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Texto izquierda ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: AppColors.textMutedFor(b),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$completadas',
                      style: AppText.h2.copyWith(
                        color: teal,
                        fontSize: 36,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ $total',
                        style: AppText.cardTitle.copyWith(
                          color: AppColors.textMutedFor(b),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'tareas completadas',
                  style: AppText.caption.copyWith(
                    color: AppColors.textFaintFor(b),
                  ),
                ),
                const SizedBox(height: 14),
                // Chips de metainfo
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label: _formatMinutos(minutosTotales),
                    ),
                    if (diasHastaExamen != null && diasHastaExamen! > 0)
                      _MetaChip(
                        icon: Icons.event_rounded,
                        label: '$diasHastaExamen días',
                        highlight: diasHastaExamen! <= 30,
                      ),
                  ],
                ),
                if (diasHastaExamen != null && diasHastaExamen! <= 30) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Modo intensivo — el plan prioriza simulacros.',
                    style: AppText.caption.copyWith(
                      color: AppColors.accentWarmSoftFor(b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),

          // ── Anillo de progreso ───────────────────────────────────────
          _ProgressRing(
            value: progreso,
            completadas: completadas,
            total: total,
          ),
        ],
      ),
    );
  }

  String _formatMinutos(int min) {
    if (min < 60) return '~$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '~${h}h' : '~${h}h ${m}m';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final teal = AppColors.primaryFor(b);
    final color = highlight ? teal : AppColors.textMutedFor(b);
    final bg = highlight
        ? teal.withOpacity(0.12)
        : AppColors.surfaceFor(b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: highlight
            ? Border.all(color: teal.withOpacity(0.35), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── Anillo de progreso ─────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.value,
    required this.completadas,
    required this.total,
    this.size = 84,
  });

  final double value;
  final int completadas;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final teal = AppColors.primaryFor(b);
    final done = completadas == total && total > 0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: teal.withOpacity(0.12),
              color: done ? teal : teal,
            ),
          ),
          if (done)
            Icon(Icons.check_rounded, color: teal, size: 28)
          else
            Text(
              '${(value * 100).round()}%',
              style: AppText.cardTitle.copyWith(
                color: value > 0 ? teal : AppColors.textFaintFor(b),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tile de tarea ──────────────────────────────────────────────────────────────

class _TareaTile extends StatelessWidget {
  const _TareaTile({
    required this.tarea,
    required this.onCompletar,
    required this.onEliminar,
    this.isLoading = false,
  });

  final PlanTarea tarea;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final completada = tarea.completada;
    final tipoColor = _tipoColor(tarea.tipo, b);
    final minutos = _minutosPorTipo[tarea.tipo] ?? 20;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: (completada || isLoading) ? null : onCompletar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Ícono de tipo ────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tipoColor.withOpacity(completada ? 0.06 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _tipoIcon(tarea.tipo),
                  size: 20,
                  color: completada
                      ? AppColors.textFaintFor(b)
                      : tipoColor,
                ),
              ),
              const SizedBox(width: 13),

              // ── Texto ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.descripcion ?? _tipoLabel(tarea.tipo),
                      style: AppText.body.copyWith(
                        color: completada
                            ? AppColors.textFaintFor(b)
                            : AppColors.textFor(b),
                        decoration: completada
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.textFaintFor(b),
                      ),
                    ),
                    if (tarea.nombreTema != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        tarea.nombreTema!,
                        style: AppText.caption.copyWith(
                          color: AppColors.textMutedFor(b),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TipoChip(
                          label: _tipoLabel(tarea.tipo).toUpperCase(),
                          color: tipoColor,
                          faded: completada,
                        ),
                        const SizedBox(width: 6),
                        _TipoChip(
                          label: '~$minutos min',
                          color: AppColors.textMutedFor(b),
                          faded: completada,
                          icon: Icons.schedule_rounded,
                        ),
                        if (tarea.manual) ...[
                          const SizedBox(width: 6),
                          _TipoChip(
                            label: 'manual',
                            color: AppColors.textFaintFor(b),
                            faded: completada,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Acción derecha ───────────────────────────────────────
              const SizedBox(width: 10),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (completada)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryFor(b),
                  size: 22,
                )
              else
                _AccionesRight(
                  esManual: tarea.manual,
                  onCompletar: onCompletar,
                  onEliminar: onEliminar,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _tipoIcon(TipoPlanTarea tipo) => switch (tipo) {
        TipoPlanTarea.test => Icons.quiz_rounded,
        TipoPlanTarea.repaso => Icons.menu_book_rounded,
        TipoPlanTarea.simulacro => Icons.timer_rounded,
      };

  static String _tipoLabel(TipoPlanTarea tipo) => switch (tipo) {
        TipoPlanTarea.test => 'Test',
        TipoPlanTarea.repaso => 'Repaso',
        TipoPlanTarea.simulacro => 'Simulacro',
      };

  static Color _tipoColor(TipoPlanTarea tipo, Brightness b) => switch (tipo) {
        TipoPlanTarea.test => AppColors.accentMintSoftFor(b),
        TipoPlanTarea.repaso => AppColors.primaryFor(b),
        TipoPlanTarea.simulacro => AppColors.accentWarmSoftFor(b),
      };
}

class _TipoChip extends StatelessWidget {
  const _TipoChip({
    required this.label,
    required this.color,
    this.faded = false,
    this.icon,
  });

  final String label;
  final Color color;
  final bool faded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = faded ? color.withOpacity(0.5) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: effectiveColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppText.label.copyWith(
              color: effectiveColor,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionesRight extends StatelessWidget {
  const _AccionesRight({
    required this.esManual,
    required this.onCompletar,
    required this.onEliminar,
  });

  final bool esManual;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    if (!esManual) {
      // Para tareas generadas: chevron indica tappable
      return Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textFaintFor(Theme.of(context).brightness),
        size: 22,
      );
    }
    // Para tareas manuales: menú con opciones
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: AppColors.textFaintFor(Theme.of(context).brightness),
      ),
      onSelected: (v) {
        if (v == 'completar') onCompletar();
        if (v == 'eliminar') onEliminar();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'completar',
          child: Row(children: [
            Icon(Icons.check_rounded, size: 18),
            SizedBox(width: 8),
            Text('Completar'),
          ]),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: Row(children: [
            Icon(Icons.delete_outline,
                size: 18,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text('Eliminar',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ],
    );
  }
}

// ── Bloques de footer ──────────────────────────────────────────────────────────

class _FooterCelebracion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final teal = AppColors.primaryFor(b);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.emoji_events_rounded, color: teal, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Día completado!',
                  style: AppText.cardTitle
                      .copyWith(color: AppColors.textFor(b)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Todas las tareas de hoy están listas.',
                  style: AppText.caption
                      .copyWith(color: AppColors.textMutedFor(b)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterExamen extends StatelessWidget {
  const _FooterExamen({required this.diasHastaExamen});

  final int diasHastaExamen;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final teal = AppColors.primaryFor(b);
    final urgent = diasHastaExamen <= 30;
    final color = urgent ? AppColors.accentWarmSoftFor(b) : teal;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.event_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$diasHastaExamen días para el examen',
                  style: AppText.cardTitle.copyWith(
                      color: AppColors.textFor(b)),
                ),
                const SizedBox(height: 3),
                Text(
                  urgent
                      ? 'Estás en modo intensivo. Seguí así.'
                      : 'Cada tarea completada cuenta.',
                  style: AppText.caption
                      .copyWith(color: AppColors.textMutedFor(b)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyDayBody extends StatelessWidget {
  const _EmptyDayBody({required this.fecha, required this.onAddTarea});

  final DateTime fecha;
  final VoidCallback onAddTarea;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final esHoy = _isToday(fecha);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today_outlined,
                size: 64, color: AppColors.textFaintFor(b)),
            const SizedBox(height: 20),
            Text(
              esHoy ? 'Sin tareas para hoy' : 'Sin tareas este día',
              style: AppText.h2.copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Añadí una tarea manual o regenerá el plan automático desde Configuración.',
              textAlign: TextAlign.center,
              style:
                  AppText.body.copyWith(color: AppColors.textMutedFor(b)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onAddTarea,
              icon: const Icon(Icons.add),
              label: const Text('Añadir tarea'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime fecha) {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }
}

// ── Error ──────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 52, color: AppColors.textFaintFor(b)),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el plan',
              style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: AppText.bodySmall
                    .copyWith(color: AppColors.textMutedFor(b))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet para añadir tarea ────────────────────────────────────────────

class _AddTareaSheet extends StatefulWidget {
  const _AddTareaSheet({required this.onGuardar});

  final Future<void> Function(TipoPlanTarea tipo, String? descripcion)
      onGuardar;

  @override
  State<_AddTareaSheet> createState() => _AddTareaSheetState();
}

class _AddTareaSheetState extends State<_AddTareaSheet> {
  TipoPlanTarea _tipo = TipoPlanTarea.repaso;
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    await widget.onGuardar(
      _tipo,
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderFor(b),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Añadir tarea',
              style: AppText.h2.copyWith(color: AppColors.textFor(b))),
          const SizedBox(height: 20),
          Text('TIPO',
              style: AppText.label
                  .copyWith(color: AppColors.textMutedFor(b))),
          const SizedBox(height: 8),
          SegmentedButton<TipoPlanTarea>(
            segments: const [
              ButtonSegment(
                  value: TipoPlanTarea.repaso,
                  label: Text('Repaso'),
                  icon: Icon(Icons.menu_book_outlined)),
              ButtonSegment(
                  value: TipoPlanTarea.test,
                  label: Text('Test'),
                  icon: Icon(Icons.quiz_outlined)),
              ButtonSegment(
                  value: TipoPlanTarea.simulacro,
                  label: Text('Simulacro'),
                  icon: Icon(Icons.timer_outlined)),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
            style: const ButtonStyle(
                visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 20),
          Text('DESCRIPCIÓN (OPCIONAL)',
              style: AppText.label
                  .copyWith(color: AppColors.textMutedFor(b))),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLength: 200,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Ej: Repasar el Título I de la Constitución',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _guardar,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Añadir tarea'),
          ),
        ],
      ),
    );
  }
}
