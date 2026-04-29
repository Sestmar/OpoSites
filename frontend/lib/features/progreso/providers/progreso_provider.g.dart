// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progreso_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$progresoRepositoryHash() =>
    r'be89f308d7b4c7489fababd4ed16bc1c7e565b91';

/// See also [progresoRepository].
@ProviderFor(progresoRepository)
final progresoRepositoryProvider = Provider<ProgresoRepository>.internal(
  progresoRepository,
  name: r'progresoRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progresoRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProgresoRepositoryRef = ProviderRef<ProgresoRepository>;
String _$progresoResumenNotifierHash() =>
    r'29301f8321c44191c89dcf642e8554c70820619a';

/// Resumen global de progreso del usuario.
///
/// Estado inicial null — la pantalla de Progreso dispara [load] al montarse.
/// Ejemplo de uso en UI:
/// ```dart
/// final state = ref.watch(progresoResumenNotifierProvider);
/// state.when(
///   data: (resumen) => resumen == null ? _empty() : _resumenCard(resumen),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, _) => _errorWidget(e),
/// );
/// ```
///
/// Copied from [ProgresoResumenNotifier].
@ProviderFor(ProgresoResumenNotifier)
final progresoResumenNotifierProvider = NotifierProvider<
    ProgresoResumenNotifier, AsyncValue<ProgresoResumen?>>.internal(
  ProgresoResumenNotifier.new,
  name: r'progresoResumenNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progresoResumenNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProgresoResumenNotifier = Notifier<AsyncValue<ProgresoResumen?>>;
String _$progresoTemasHash() => r'3eff26c671fd8c56dfb21774ccf5fd2a7d756d05';

/// Lista de estadísticas por tema.
///
/// Arranca vacía — la UI dispara [load] con el [ramaId] de la oposición activa.
/// La lista viene ordenada por porcentaje de acierto ascendente (temas débiles
/// primero) — apta para una lista directa sin reordenar en el cliente.
///
/// Copied from [ProgresoTemas].
@ProviderFor(ProgresoTemas)
final progresoTemasProvider =
    NotifierProvider<ProgresoTemas, AsyncValue<List<ProgresoTema>>>.internal(
  ProgresoTemas.new,
  name: r'progresoTemasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progresoTemasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProgresoTemas = Notifier<AsyncValue<List<ProgresoTema>>>;
String _$progresoEvolucionHash() => r'33535eda439eb10b35bed3df201290ae7a64b128';

/// Evolución semanal de nota media y tests completados.
///
/// Arranca vacía — la UI dispara [load] al entrar en la pantalla de Progreso.
/// Cada [EvolucionSemanal] tiene:
///   - [semana]: "YYYY-Www" → label del eje X en fl_chart.
///   - [notaMedia]: 0.0–10.0 → valor del eje Y.
///   - [testsCompletados]: puede mostrarse como tooltip en el punto.
///
/// Recomendación de uso con fl_chart:
///   spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.notaMedia))
///
/// Copied from [ProgresoEvolucion].
@ProviderFor(ProgresoEvolucion)
final progresoEvolucionProvider = NotifierProvider<ProgresoEvolucion,
    AsyncValue<List<EvolucionSemanal>>>.internal(
  ProgresoEvolucion.new,
  name: r'progresoEvolucionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$progresoEvolucionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProgresoEvolucion = Notifier<AsyncValue<List<EvolucionSemanal>>>;
String _$rachaNotifierHash() => r'7e61071c3523bbbcb09f7706433bd9ca47241eb2';

/// Racha actual y mejor racha del usuario.
///
/// Estado inicial null — la UI dispara [load] al montar la pantalla de Progreso.
/// [Racha.ultimoEstudio] es "YYYY-MM-DD" o null si nunca estudió.
///
/// Copied from [RachaNotifier].
@ProviderFor(RachaNotifier)
final rachaNotifierProvider =
    NotifierProvider<RachaNotifier, AsyncValue<Racha?>>.internal(
  RachaNotifier.new,
  name: r'rachaNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rachaNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RachaNotifier = Notifier<AsyncValue<Racha?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
