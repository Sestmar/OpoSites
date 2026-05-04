import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';
import '../data/models/plan_hoy.dart';
import '../data/models/plan_tarea.dart';
import '../providers/plan_provider.dart';

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
      ref.read(planHoyNotifierProvider.notifier).load();
    });
  }

  Future<void> _completarTarea(PlanTarea tarea) async {
    setState(() => _loadingTaskId = tarea.id);
    try {
      await ref.read(planHoyNotifierProvider.notifier).completarTarea(tarea.id);
    } catch (e) {
      if (mounted) _showError(_msgError(e));
    } finally {
      if (mounted) setState(() => _loadingTaskId = null);
    }
  }

  Future<void> _eliminarTarea(PlanTarea tarea) async {
    try {
      await ref.read(planHoyNotifierProvider.notifier).eliminarTarea(tarea.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea eliminada')),
        );
      }
    } catch (e) {
      if (mounted) _showError(_msgError(e));
    }
  }

  Future<void> _regenerarPlan() async {
    await ref.read(planHoyNotifierProvider.notifier).regenerarPlan();
  }

  Future<void> _mostrarAddTarea() async {
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
            await ref.read(planHoyNotifierProvider.notifier).crearTarea(
                  tipo: tipo,
                  descripcion: descripcion,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tarea añadida al plan')),
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
    final state = ref.watch(planHoyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de hoy'),
        actions: [
          IconButton(
            tooltip: 'Regenerar plan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : _regenerarPlan,
          ),
        ],
      ),
      floatingActionButton: state.hasValue && state.value != null
          ? FloatingActionButton.extended(
              onPressed: _mostrarAddTarea,
              icon: const Icon(Icons.add),
              label: const Text('Añadir tarea'),
            )
          : null,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: _msgError(e),
          onRetry: () => ref.read(planHoyNotifierProvider.notifier).load(),
        ),
        data: (plan) {
          if (plan == null || plan.tareas.isEmpty) {
            return _EmptyBody(onRegenerar: _regenerarPlan);
          }
          return _PlanBody(
            plan: plan,
            loadingTaskId: _loadingTaskId,
            onCompletar: _completarTarea,
            onEliminar: _eliminarTarea,
          );
        },
      ),
    );
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────

String _msgError(Object e) {
  if (e is ApiException) return e.message;
  return 'Ocurrió un error inesperado. Intentalo de nuevo.';
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
        // ── Barra de progreso del día ──────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(plan.fecha,
                      style: AppText.cardTitle
                          .copyWith(color: AppColors.textFor(b))),
                  Text(
                    '$completadas / $total',
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
                        size: 16,
                        color: AppColors.primaryFor(b)),
                    const SizedBox(width: 6),
                    Text(
                      '¡Plan de hoy completado!',
                      style: AppText.bodySmall.copyWith(
                          color: AppColors.primaryFor(b),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Lista de tareas ────────────────────────────────────────────────
        Text('TAREAS DE HOY',
            style:
                AppText.label.copyWith(color: AppColors.textMutedFor(b))),
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
          // ── Ícono de estado ──────────────────────────────────────────────
          Icon(
            completada
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: completada
                ? AppColors.primaryFor(b)
                : AppColors.textFaintFor(b),
            size: 22,
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
                        style: AppText.caption.copyWith(
                            color: AppColors.textFaintFor(b)),
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
                  size: 18,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text('Eliminar',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
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
    // El sheet ya se cerró desde el padre
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
          // ── Handle ────────────────────────────────────────────────────────
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

          Text('Añadir tarea al plan',
              style:
                  AppText.h2.copyWith(color: AppColors.textFor(b))),
          const SizedBox(height: 20),

          // ── Tipo ──────────────────────────────────────────────────────────
          Text('TIPO',
              style: AppText.label
                  .copyWith(color: AppColors.textMutedFor(b))),
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
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 20),

          // ── Descripción ───────────────────────────────────────────────────
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

          // ── Botón guardar ─────────────────────────────────────────────────
          FilledButton(
            onPressed: _saving ? null : _guardar,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Añadir tarea'),
          ),
        ],
      ),
    );
  }
}

// ── Estados vacío y error ──────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onRegenerar});

  final VoidCallback onRegenerar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

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
              'No hay tareas para hoy',
              style: AppText.h2.copyWith(color: AppColors.textFor(b)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Generá tu plan automático o añadí tareas manualmente con el botón "+".',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRegenerar,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Generar plan automático'),
            ),
          ],
        ),
      ),
    );
  }
}

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
