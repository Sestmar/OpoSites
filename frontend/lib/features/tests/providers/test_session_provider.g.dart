// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$testsRepositoryHash() => r'993251c081fa8a46557dfc66fad738c3efe03dd9';

/// See also [testsRepository].
@ProviderFor(testsRepository)
final testsRepositoryProvider = Provider<TestsRepository>.internal(
  testsRepository,
  name: r'testsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$testsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TestsRepositoryRef = ProviderRef<TestsRepository>;
String _$activeTestHash() => r'de75cfdefa7cb8bf40d74a66b5f7009b2c7f4754';

/// Gestiona el ciclo de vida completo de un test libre:
///   idle → loading → active → submitting → completed
///                   ↓                    ↓
///                 error               error
///
/// keepAlive: true para que el estado sobreviva la navegación entre pantallas
/// mientras el test esté en curso.
///
/// Copied from [ActiveTest].
@ProviderFor(ActiveTest)
final activeTestProvider = NotifierProvider<ActiveTest, TestState>.internal(
  ActiveTest.new,
  name: r'activeTestProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeTestHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveTest = Notifier<TestState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
