// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$planRepositoryHash() => r'1548423939f2f234c3c0ca4334bd1e8b99c5ae21';

/// See also [planRepository].
@ProviderFor(planRepository)
final planRepositoryProvider = Provider<PlanRepository>.internal(
  planRepository,
  name: r'planRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlanRepositoryRef = ProviderRef<PlanRepository>;
String _$planHoyNotifierHash() => r'608e9a62a7d3adbe975e6cf7cd295a20d3064712';

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
///
/// Copied from [PlanHoyNotifier].
@ProviderFor(PlanHoyNotifier)
final planHoyNotifierProvider =
    NotifierProvider<PlanHoyNotifier, AsyncValue<PlanHoy?>>.internal(
  PlanHoyNotifier.new,
  name: r'planHoyNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planHoyNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlanHoyNotifier = Notifier<AsyncValue<PlanHoy?>>;
String _$planConfiguracionNotifierHash() =>
    r'b880412239547ed6de83b8476ac7fa444da5241a';

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
///
/// Copied from [PlanConfiguracionNotifier].
@ProviderFor(PlanConfiguracionNotifier)
final planConfiguracionNotifierProvider = NotifierProvider<
    PlanConfiguracionNotifier, AsyncValue<PlanConfiguracion?>>.internal(
  PlanConfiguracionNotifier.new,
  name: r'planConfiguracionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planConfiguracionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlanConfiguracionNotifier = Notifier<AsyncValue<PlanConfiguracion?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
