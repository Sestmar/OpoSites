import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/plan_hoy.dart';
import '../data/models/plan_tarea.dart';
import '../data/plan_repository.dart';
import 'plan_provider.dart';

// ── Estado ─────────────────────────────────────────────────────────────────────

class PlanSemanaState {
  const PlanSemanaState({
    required this.dias,
    required this.diaSeleccionadoIndex,
  });

  /// 7 días, ordenados desde [desde] en adelante.
  final List<PlanHoy> dias;

  /// Índice del día actualmente visible (0 = hoy/inicio de semana).
  final int diaSeleccionadoIndex;

  PlanHoy? get diaSeleccionado =>
      dias.isNotEmpty ? dias[diaSeleccionadoIndex] : null;

  PlanSemanaState copyWith({
    List<PlanHoy>? dias,
    int? diaSeleccionadoIndex,
  }) =>
      PlanSemanaState(
        dias: dias ?? this.dias,
        diaSeleccionadoIndex: diaSeleccionadoIndex ?? this.diaSeleccionadoIndex,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class PlanSemanaNotifier extends AsyncNotifier<PlanSemanaState> {
  @override
  Future<PlanSemanaState> build() async {
    final dias = await ref.read(planRepositoryProvider).getSemana();
    return PlanSemanaState(dias: dias, diaSeleccionadoIndex: 0);
  }

  /// Selecciona el día visible por su índice en la lista.
  void seleccionarDia(int index) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(diaSeleccionadoIndex: index));
  }

  /// Recarga la semana completa desde el backend.
  Future<void> reload() async {
    final prevIndex = state.valueOrNull?.diaSeleccionadoIndex ?? 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dias = await ref.read(planRepositoryProvider).getSemana();
      return PlanSemanaState(dias: dias, diaSeleccionadoIndex: prevIndex);
    });
  }

  /// Marca [tareaId] como completada. Actualiza el día correspondiente en local.
  Future<void> completarTarea(int tareaId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updatedTarea =
        await ref.read(planRepositoryProvider).completarTarea(tareaId);
    _reemplazarTarea(current, updatedTarea);
  }

  /// Crea una tarea manual para el día indicado por [fecha].
  Future<void> crearTarea({
    required TipoPlanTarea tipo,
    String? descripcion,
    required DateTime fecha,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final tarea = await ref.read(planRepositoryProvider).crearTarea(
          tipo: tipo,
          descripcion: descripcion,
          fecha: fecha,
        );
    _appendTarea(current, tarea);
  }

  /// Elimina [tareaId] del estado local tras confirmar con el backend.
  Future<void> eliminarTarea(int tareaId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(planRepositoryProvider).eliminarTarea(tareaId);
    _quitarTarea(current, tareaId);
  }

  // ── Helpers de mutación local ────────────────────────────────────────────────

  void _reemplazarTarea(PlanSemanaState current, PlanTarea updated) {
    final nuevos = current.dias.map((dia) {
      final idx = dia.tareas.indexWhere((t) => t.id == updated.id);
      if (idx == -1) return dia;
      final nuevasTareas = List<PlanTarea>.of(dia.tareas)..[idx] = updated;
      final completadas = nuevasTareas.where((t) => t.completada).length;
      return PlanHoy(
        fecha: dia.fecha,
        tareas: nuevasTareas,
        tareasCompletadas: completadas,
        totalTareas: dia.totalTareas,
      );
    }).toList();
    state = AsyncData(current.copyWith(dias: nuevos));
  }

  void _appendTarea(PlanSemanaState current, PlanTarea tarea) {
    final nuevos = current.dias.map((dia) {
      if (dia.fecha != tarea.fecha) return dia;
      final nuevasTareas = [...dia.tareas, tarea];
      return PlanHoy(
        fecha: dia.fecha,
        tareas: nuevasTareas,
        tareasCompletadas: dia.tareasCompletadas,
        totalTareas: dia.totalTareas + 1,
      );
    }).toList();
    state = AsyncData(current.copyWith(dias: nuevos));
  }

  void _quitarTarea(PlanSemanaState current, int tareaId) {
    final nuevos = current.dias.map((dia) {
      final tieneTarea = dia.tareas.any((t) => t.id == tareaId);
      if (!tieneTarea) return dia;
      final nuevasTareas = dia.tareas.where((t) => t.id != tareaId).toList();
      final completadas = nuevasTareas.where((t) => t.completada).length;
      return PlanHoy(
        fecha: dia.fecha,
        tareas: nuevasTareas,
        tareasCompletadas: completadas,
        totalTareas: nuevasTareas.length,
      );
    }).toList();
    state = AsyncData(current.copyWith(dias: nuevos));
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final planSemanaProvider =
    AsyncNotifierProvider<PlanSemanaNotifier, PlanSemanaState>(
  PlanSemanaNotifier.new,
);
