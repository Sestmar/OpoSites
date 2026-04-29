// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noticias_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$noticiasRepositoryHash() =>
    r'c11c2bb343f9f39cf8f72f0ba3590ff27cadf441';

/// See also [noticiasRepository].
@ProviderFor(noticiasRepository)
final noticiasRepositoryProvider = Provider<NoticiasRepository>.internal(
  noticiasRepository,
  name: r'noticiasRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noticiasRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NoticiasRepositoryRef = ProviderRef<NoticiasRepository>;
String _$noticiasListNotifierHash() =>
    r'5bd4489e00698c879db58a9d9035f9a329335a51';

/// Lista paginada de noticias con filtros y soporte de infinite scroll.
///
/// ### Flujo de uso
/// 1. La pantalla llama [cargar] en [initState] → limpia lista y carga página 0.
/// 2. Al llegar al final del scroll, la UI llama [cargarMas] → añade página 1, 2…
/// 3. Para cambiar filtros, la UI llama [cargar] con los nuevos filtros.
///
/// ### cargar vs cargarMas
/// - [cargar] pone el estado en AsyncLoading y reemplaza la lista completa.
/// - [cargarMas] NO modifica el estado de carga visible — añade ítems silenciosamente.
///   Lanza excepción si falla para que la UI muestre un SnackBar sin perder la lista.
///
/// Copied from [NoticiasListNotifier].
@ProviderFor(NoticiasListNotifier)
final noticiasListNotifierProvider = NotifierProvider<NoticiasListNotifier,
    AsyncValue<NoticiasListState>>.internal(
  NoticiasListNotifier.new,
  name: r'noticiasListNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noticiasListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NoticiasListNotifier = Notifier<AsyncValue<NoticiasListState>>;
String _$noticiaDetalleNotifierHash() =>
    r'6c5c61c78c17aeabe9b0bcc2f917b9482ff9b21c';

/// Detalle de una noticia individual.
///
/// ### Flujo de uso
/// 1. La pantalla llama [cargar(id)] en initState → carga el detalle.
/// 2. Tras mostrar el contenido, la UI llama [marcarLeida(id)] → POST al backend
///    y actualiza [leida: true] en el estado local.
/// 3. Opcional: llamar [NoticiasListNotifier.actualizarLeida(id)] para
///    sincronizar el estado en la lista sin recargar toda la página.
///
/// Estado inicial null — la pantalla dispara [cargar] al montarse.
///
/// Copied from [NoticiaDetalleNotifier].
@ProviderFor(NoticiaDetalleNotifier)
final noticiaDetalleNotifierProvider =
    NotifierProvider<NoticiaDetalleNotifier, AsyncValue<Noticia?>>.internal(
  NoticiaDetalleNotifier.new,
  name: r'noticiaDetalleNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noticiaDetalleNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NoticiaDetalleNotifier = Notifier<AsyncValue<Noticia?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
