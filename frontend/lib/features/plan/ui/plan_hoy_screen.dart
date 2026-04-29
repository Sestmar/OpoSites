import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  /// ID de la tarea que se está marcando en este momento (para deshabilitar
  /// el botón y evitar doble tap).
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al completar la tarea: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTaskId = null);
    }
  }

  Future<void> _regenerarPlan() async {
    // regenerarPlan no lanza — los errores quedan en el estado (AsyncError).
    await ref.read(planHoyNotifierProvider.notifier).regenerarPlan();
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
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () => ref.read(planHoyNotifierProvider.notifier).load(),
        ),
        data: (plan) {
          if (plan == null) {
            return _EmptyBody(onRegenerar: _regenerarPlan);
          }
          return _PlanBody(
            plan: plan,
            loadingTaskId: _loadingTaskId,
            onCompletar: _completarTarea,
          );
        },
      ),
    );
  }
}

// ── Cuerpo con datos ───────────────────────────────────────────────────────────

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.plan,
    required this.onCompletar,
    this.loadingTaskId,
  });

  final PlanHoy plan;
  final int? loadingTaskId;
  final Future<void> Function(PlanTarea) onCompletar;

  @override
  Widget build(BuildContext context) {
    final completadas = plan.tareasCompletadas;
    final total = plan.totalTareas;
    final progreso = total == 0 ? 0.0 : completadas / total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fecha y barra de progreso del día
        Text(
          plan.fecha,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$completadas / $total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Lista de tareas
        ...plan.tareas.map(
          (t) => _TareaTile(
            tarea: t,
            isLoading: loadingTaskId == t.id,
            onCompletar: () => onCompletar(t),
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
    this.isLoading = false,
  });

  final PlanTarea tarea;
  final VoidCallback onCompletar;
  final bool isLoading;

  String get _titulo {
    if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) {
      return tarea.descripcion!;
    }
    final tipo = _tipoLabel(tarea.tipo);
    if (tarea.nombreTema != null) return '$tipo · ${tarea.nombreTema}';
    if (tarea.nombreSimulacro != null) return tarea.nombreSimulacro!;
    return tipo;
  }

  static String _tipoLabel(TipoPlanTarea tipo) => switch (tipo) {
        TipoPlanTarea.test => 'Test',
        TipoPlanTarea.repaso => 'Repaso',
        TipoPlanTarea.simulacro => 'Simulacro',
      };

  static Color _tipoColor(TipoPlanTarea tipo) => switch (tipo) {
        TipoPlanTarea.test => Colors.blue,
        TipoPlanTarea.repaso => Colors.green,
        TipoPlanTarea.simulacro => Colors.deepOrange,
      };

  @override
  Widget build(BuildContext context) {
    final color = _tipoColor(tarea.tipo);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: tarea.completada
            ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
        title: Text(
          _titulo,
          style: TextStyle(
            decoration:
                tarea.completada ? TextDecoration.lineThrough : null,
            color: tarea.completada ? Colors.grey.shade500 : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _TipoBadge(label: _tipoLabel(tarea.tipo), color: color),
        ),
        trailing: tarea.completada
            ? null
            : isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onCompletar,
                    child: const Text('Completar'),
                  ),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay plan generado.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Usá el botón "Regenerar" para generar tu plan de los próximos 7 días.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRegenerar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Regenerar plan'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
