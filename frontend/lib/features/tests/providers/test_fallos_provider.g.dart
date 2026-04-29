// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_fallos_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$testFallosHash() => r'e57afc31684e61c79247e2729d4aaa63cfaa7789';

/// Gestiona la lista de preguntas falladas del usuario (GET /tests/fallos).
///
/// El estado usa [AsyncValue] de Riverpod para manejar loading/error/data
/// de forma idiomática. La lista arranca vacía — la UI dispara [load]
/// con los filtros que necesite.
///
/// keepAlive: true para que los fallos cargados persistan mientras el usuario
/// navega entre pantallas de repaso.
///
/// Copied from [TestFallos].
@ProviderFor(TestFallos)
final testFallosProvider =
    NotifierProvider<TestFallos, AsyncValue<List<TestQuestion>>>.internal(
  TestFallos.new,
  name: r'testFallosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$testFallosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TestFallos = Notifier<AsyncValue<List<TestQuestion>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
