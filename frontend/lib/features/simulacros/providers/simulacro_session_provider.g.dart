// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulacro_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$simulacrosRepositoryHash() =>
    r'8de7dae3335201ede00c3b815fc1d3affde9361c';

/// See also [simulacrosRepository].
@ProviderFor(simulacrosRepository)
final simulacrosRepositoryProvider = Provider<SimulacrosRepository>.internal(
  simulacrosRepository,
  name: r'simulacrosRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$simulacrosRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SimulacrosRepositoryRef = ProviderRef<SimulacrosRepository>;
String _$activeSimulacroHash() => r'a34fe0179bd798df5afb5039425551f08bb11780';

/// Gestiona el ciclo de vida completo de un simulacro:
///   idle → loading → active → submitting → completed
///                   ↓                    ↓
///                 error               error
///
/// keepAlive: true para que el estado sobreviva la navegación mientras
/// el simulacro esté en curso (el usuario puede ir a una pregunta concreta
/// y volver sin perder respuestas ni reiniciar el timer).
///
/// Copied from [ActiveSimulacro].
@ProviderFor(ActiveSimulacro)
final activeSimulacroProvider =
    NotifierProvider<ActiveSimulacro, SimulacroState>.internal(
  ActiveSimulacro.new,
  name: r'activeSimulacroProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSimulacroHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveSimulacro = Notifier<SimulacroState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
