import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/plan_hoy.dart';
import '../data/models/plan_tarea.dart';
import '../providers/plan_semana_provider.dart';

// ── Constantes ─────────────────────────────────────────────────────────────────

const _dayAbbr = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];

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
      // Dispara la carga de la semana si aún no tiene datos
      ref.read(planSemanaProvider.future).ignore();
    });
  }

  Future<void> _completarTarea(PlanTarea tarea) async {
    setState(() => _loadingTaskId = tarea.id);
    try {
      await ref
          .read(planSemanaProvider.notifier)
          .completarTarea(tarea.id);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planSemanaProvider);

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Plan de estudio')),
        body: _ErrorBody(
          message: _msgError(e),
          onRetry: _reload,
        ),
      ),
      data: (semana) {
        final dia = semana.diaSeleccionado;
        final fechaDia = dia != null ? _parseDate(dia.fecha) : DateTime.now();

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
              // ── Barra de navegación de días ──────────────────────────────
              _DayNavBar(
                dias: semana.dias,
                selectedIndex: semana.diaSeleccionadoIndex,
                onSelectDia: (i) =>
                    ref.read(planSemanaProvider.notifier).seleccionarDia(i),
              ),
              const Divider(height: 1),

              // ── Contenido del día seleccionado ───────────────────────────
              Expanded(
                child: dia == null || dia.tareas.isEmpty
                    ? _EmptyDayBody(
                        fecha: fechaDia,
                        onAddTarea: () => _mostrarAddTarea(fechaDia),
                      )
                    : _PlanBody(
                        plan: dia,
                        loadingTaskId: _loadingTaskId,
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

// ── Helper ─────────────────────────────────────────────────────────────────────

String _msgError(Object e) {
  if (e is ApiException) return e.message;
  return 'Ocurrió un error inesperado. Intentalo de nuevo.';
}

DateTime _parseDate(String fecha) {
  final parts = fecha.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

// ── Barra de navegación de días ────────────────────────────────────────────────

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

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: dias.length,
        itemBuilder: (_, i) {
          final dia = dias[i];
          final fecha = _parseDate(dia.fecha);
          final isSelected = i == selectedIndex;
          final isToday = _isToday(fecha);
          final progreso = dia.totalTareas == 0
              ? 0.0
              : dia.tareasCompletadas / dia.totalTareas;
          final completado = dia.totalTareas > 0 &&
              dia.tareasCompletadas == dia.totalTareas;

          final teal = AppColors.primaryFor(b);
          final labelColor = isSelected
              ? teal
              : AppColors.textMutedFor(b);
          final bgColor = isSelected
              ? teal.withOpacity(0.12)
              : Colors.transparent;

          return GestureDetector(
            onTap: () => onSelectDia(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: teal.withOpacity(0.4), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Abreviatura del día
                  Text(
                    _dayAbbr[fecha.weekday],
                    style: AppText.label.copyWith(
                      color: labelColor,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Número del día
                  Text(
                    '${fecha.day}',
                    style: AppText.body.copyWith(
                      color: isSelected
                          ? teal
                          : AppColors.textFor(b),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Indicador de progreso
                  if (dia.totalTareas > 0)
                    SizedBox(
                      width: 24,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progreso,
                          backgroundColor: AppColors.borderFor(b),
                          valueColor: AlwaysStoppedAnimation(
                            completado
                                ? teal
                                : teal.withOpacity(0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 3),
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

// ── Cuerpo con datos ───────────────────────────────────────────────────────────

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.plan,
    required this.onCompletar,
    required this.onEliminar,
    this.loadingTaskId,
  });

  final PlanHoy plan;
  final int? loadingTaskId;
  final Future<void> Function(PlanTarea) onCompletar;
  final Future<void> Function(PlanTarea) onEliminar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final completadas = plan.tareasCompletadas;
    final total = plan.totalTareas;
    final progreso = total == 0 ? 0.0 : completadas / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // ── Tarjeta de progreso del día ────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _labelFecha(_parseDate(plan.fecha)),
                    style: AppText.cardTitle
                        .copyWith(color: AppColors.textFor(b)),
                  ),
                  Text(
                    '$completadas / $total tareas',
                    style: AppText.body.copyWith(
                      color: AppColors.textMutedFor(b),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                ),
              ),
              if (completadas == total && total > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.primaryFor(b)),
                    const SizedBox(width: 6),
                    Text(
                      '¡Día completado!',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.primaryFor(b),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Lista de tareas ────────────────────────────────────────────────
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
      ],
    );
  }

  String _labelFecha(DateTime fecha) {
    final now = DateTime.now();
    if (fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day) return 'Hoy';
    final tomorrow = now.add(const Duration(days: 1));
    if (fecha.year == tomorrow.year &&
        fecha.month == tomorrow.month &&
        fecha.day == tomorrow.day) return 'Mañana';
    const meses = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${fecha.day} ${meses[fecha.month]}';
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

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Ícono de estado ────────────────────────────────────────────────
          GestureDetector(
            onTap: completada ? null : onCompletar,
            child: Icon(
              completada
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: completada
                  ? AppColors.primaryFor(b)
                  : AppColors.textFaintFor(b),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // ── Texto ────────────────────────────────────────────────────────
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
                    decoration:
                        completada ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textFaintFor(b),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: tipoColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _tipoLabel(tarea.tipo).toUpperCase(),
                        style: AppText.label.copyWith(
                          color: tipoColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (tarea.manual) ...[
                      const SizedBox(width: 6),
                      Text(
                        'manual',
                        style: AppText.caption
                            .copyWith(color: AppColors.textFaintFor(b)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Acciones ─────────────────────────────────────────────────────
          if (!completada) ...[
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              _AccionesTarea(
                onCompletar: onCompletar,
                onEliminar: onEliminar,
              ),
          ],
        ],
      ),
    );
  }

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

class _AccionesTarea extends StatelessWidget {
  const _AccionesTarea({
    required this.onCompletar,
    required this.onEliminar,
  });

  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (v) {
        if (v == 'completar') onCompletar();
        if (v == 'eliminar') onEliminar();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'completar',
          child: Row(
            children: [
              Icon(Icons.check_rounded, size: 18),
              SizedBox(width: 8),
              Text('Completar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text('Eliminar',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ],
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
        20,
        20,
        20,
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
              style:
                  AppText.label.copyWith(color: AppColors.textMutedFor(b))),
          const SizedBox(height: 8),
          SegmentedButton<TipoPlanTarea>(
            segments: const [
              ButtonSegment(
                value: TipoPlanTarea.repaso,
                label: Text('Repaso'),
                icon: Icon(Icons.menu_book_outlined),
              ),
              ButtonSegment(
                value: TipoPlanTarea.test,
                label: Text('Test'),
                icon: Icon(Icons.quiz_outlined),
              ),
              ButtonSegment(
                value: TipoPlanTarea.simulacro,
                label: Text('Simulacro'),
                icon: Icon(Icons.timer_outlined),
              ),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 20),
          Text('DESCRIPCIÓN (OPCIONAL)',
              style:
                  AppText.label.copyWith(color: AppColors.textMutedFor(b))),
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

// ── Día sin tareas ─────────────────────────────────────────────────────────────

class _EmptyDayBody extends StatelessWidget {
  const _EmptyDayBody({required this.fecha, required this.onAddTarea});

  final DateTime fecha;
  final VoidCallback onAddTarea;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isToday = _isToday(fecha);

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
              isToday ? 'No hay tareas para hoy' : 'Sin tareas este día',
              style: AppText.h2.copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Podés añadir tareas manualmente con el botón "+".',
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
              style:
                  AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
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
