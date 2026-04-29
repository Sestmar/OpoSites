import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/models/plan_configuracion.dart';
import '../data/models/plan_hoy.dart';
import '../data/models/plan_tarea.dart';
import '../data/plan_repository.dart';

part 'plan_provider.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
PlanRepository planRepository(PlanRepositoryRef ref) =>
    PlanRepository(dio: ref.watch(dioProvider));

// ── Plan de hoy ────────────────────────────────────────────────────────────────

/// Plan de estudio del día actual.
///
/// Estado inicial null — la pantalla de Plan dispara [load] al montarse.
///
/// ### completarTarea
/// Actualiza la tarea en el estado local **sin refetch completo**:
/// llama al backend, reemplaza la tarea con la respuesta del servidor y
/// recalcula [PlanHoy.tareasCompletadas]. Si falla, el estado NO cambia —
/// la excepción sube al caller para que la UI muestre un SnackBar de error.
///
/// ### regenerarPlan
/// Llama a POST /plan/generar y reemplaza el estado completo con el plan
/// devuelto por el servidor (7 días regenerados, tareas ya completadas
/// preservadas por el backend).
@Riverpod(keepAlive: true)
class PlanHoyNotifier extends _$PlanHoyNotifier {
  @override
  AsyncValue<PlanHoy?> build() => const AsyncData(null);

  /// Carga o recarga el plan del día actual.
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).getPlanHoy(),
    );
  }

  /// Marca [tareaId] como completada con actualización optimista del estado.
  ///
  /// En caso de error lanza [ApiException] sin modificar el estado — la UI
  /// debe capturarla (try/catch) para mostrar feedback sin perder el plan:
  /// ```dart
  /// try {
  ///   await ref.read(planHoyNotifierProvider.notifier).completarTarea(tarea.id);
  /// } on ApiException catch (e) {
  ///   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  /// }
  /// ```
  Future<void> completarTarea(int tareaId) async {
    final currentPlan = state.valueOrNull;
    if (currentPlan == null) return;

    final PlanTarea updatedTarea =
        await ref.read(planRepositoryProvider).completarTarea(tareaId);

    final updatedTareas = currentPlan.tareas
        .map((t) => t.id == tareaId ? updatedTarea : t)
        .toList();
    final completadas = updatedTareas.where((t) => t.completada).length;

    state = AsyncData(
      PlanHoy(
        fecha: currentPlan.fecha,
        tareas: updatedTareas,
        tareasCompletadas: completadas,
        totalTareas: currentPlan.totalTareas,
      ),
    );
  }

  /// Regenera el plan de 7 días y actualiza el estado con el plan de hoy.
  Future<void> regenerarPlan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).regenerarPlan(),
    );
  }
}

// ── Configuración del plan ─────────────────────────────────────────────────────

/// Configuración del plan de estudio (horasSemana, preferencia, fechaExamen).
///
/// Estado inicial null — la pantalla de Plan Config dispara [load] al montarse.
///
/// ### actualizar
/// Envía el PUT con solo los campos modificados (gracias a
/// [UpdatePlanConfiguracionRequest] con `includeIfNull: false`) y reemplaza
/// el estado con la respuesta del servidor — la UI siempre refleja la fuente
/// de verdad del backend, no un estado local calculado.
///
/// Uso desde UI:
/// ```dart
/// await ref.read(planConfiguracionNotifierProvider.notifier).actualizar(
///   UpdatePlanConfiguracionRequest(horasSemana: 10),
/// );
/// ```
@Riverpod(keepAlive: true)
class PlanConfiguracionNotifier extends _$PlanConfiguracionNotifier {
  @override
  AsyncValue<PlanConfiguracion?> build() => const AsyncData(null);

  /// Carga la configuración actual del plan.
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).getConfiguracion(),
    );
  }

  /// Actualiza la configuración y reemplaza el estado con la respuesta.
  ///
  /// Solo se envían al servidor los campos no-null de [request].
  Future<void> actualizar(UpdatePlanConfiguracionRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).actualizarConfiguracion(request),
    );
  }
}
