// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendario_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calendarioRepositoryHash() =>
    r'9b3280f86ca76c562c06a79cb9217543a6de8ac7';

/// See also [calendarioRepository].
@ProviderFor(calendarioRepository)
final calendarioRepositoryProvider = Provider<CalendarioRepository>.internal(
  calendarioRepository,
  name: r'calendarioRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarioRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CalendarioRepositoryRef = ProviderRef<CalendarioRepository>;
String _$eventosDiaHash() => r'56c3a3915d6ff4fbc04dc73ccafe5933c97b9b2e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Lista de eventos del día [dia] filtrada desde el mes cargado en [CalendarioNotifier].
///
/// ### Uso
/// ```dart
/// final eventos = ref.watch(eventosDiaProvider(DateTime(2026, 4, 29)));
/// ```
///
/// El parámetro [dia] debe pasarse normalizado a medianoche
/// (ej. [DateTime(año, mes, día)]) para que el cache de Riverpod funcione
/// correctamente — [DateTime.now()] incluye horas y generaría una clave nueva
/// cada vez.
///
/// No tiene [keepAlive] — se recalcula automáticamente cuando cambia
/// [CalendarioNotifier] o cuando el widget deja de escucharlo.
///
/// Copied from [eventosDia].
@ProviderFor(eventosDia)
const eventosDiaProvider = EventosDiaFamily();

/// Lista de eventos del día [dia] filtrada desde el mes cargado en [CalendarioNotifier].
///
/// ### Uso
/// ```dart
/// final eventos = ref.watch(eventosDiaProvider(DateTime(2026, 4, 29)));
/// ```
///
/// El parámetro [dia] debe pasarse normalizado a medianoche
/// (ej. [DateTime(año, mes, día)]) para que el cache de Riverpod funcione
/// correctamente — [DateTime.now()] incluye horas y generaría una clave nueva
/// cada vez.
///
/// No tiene [keepAlive] — se recalcula automáticamente cuando cambia
/// [CalendarioNotifier] o cuando el widget deja de escucharlo.
///
/// Copied from [eventosDia].
class EventosDiaFamily extends Family<List<CalendarioEvento>> {
  /// Lista de eventos del día [dia] filtrada desde el mes cargado en [CalendarioNotifier].
  ///
  /// ### Uso
  /// ```dart
  /// final eventos = ref.watch(eventosDiaProvider(DateTime(2026, 4, 29)));
  /// ```
  ///
  /// El parámetro [dia] debe pasarse normalizado a medianoche
  /// (ej. [DateTime(año, mes, día)]) para que el cache de Riverpod funcione
  /// correctamente — [DateTime.now()] incluye horas y generaría una clave nueva
  /// cada vez.
  ///
  /// No tiene [keepAlive] — se recalcula automáticamente cuando cambia
  /// [CalendarioNotifier] o cuando el widget deja de escucharlo.
  ///
  /// Copied from [eventosDia].
  const EventosDiaFamily();

  /// Lista de eventos del día [dia] filtrada desde el mes cargado en [CalendarioNotifier].
  ///
  /// ### Uso
  /// ```dart
  /// final eventos = ref.watch(eventosDiaProvider(DateTime(2026, 4, 29)));
  /// ```
  ///
  /// El parámetro [dia] debe pasarse normalizado a medianoche
  /// (ej. [DateTime(año, mes, día)]) para que el cache de Riverpod funcione
  /// correctamente — [DateTime.now()] incluye horas y generaría una clave nueva
  /// cada vez.
  ///
  /// No tiene [keepAlive] — se recalcula automáticamente cuando cambia
  /// [CalendarioNotifier] o cuando el widget deja de escucharlo.
  ///
  /// Copied from [eventosDia].
  EventosDiaProvider call(
    DateTime dia,
  ) {
    return EventosDiaProvider(
      dia,
    );
  }

  @override
  EventosDiaProvider getProviderOverride(
    covariant EventosDiaProvider provider,
  ) {
    return call(
      provider.dia,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'eventosDiaProvider';
}

/// Lista de eventos del día [dia] filtrada desde el mes cargado en [CalendarioNotifier].
///
/// ### Uso
/// ```dart
/// final eventos = ref.watch(eventosDiaProvider(DateTime(2026, 4, 29)));
/// ```
///
/// El parámetro [dia] debe pasarse normalizado a medianoche
/// (ej. [DateTime(año, mes, día)]) para que el cache de Riverpod funcione
/// correctamente — [DateTime.now()] incluye horas y generaría una clave nueva
/// cada vez.
///
/// No tiene [keepAlive] — se recalcula automáticamente cuando cambia
/// [CalendarioNotifier] o cuando el widget deja de escucharlo.
///
/// Copied from [eventosDia].
class EventosDiaProvider extends AutoDisposeProvider<List<CalendarioEvento>> {
  /// Lista de eventos del día [dia] filtrada desde el mes cargado en [CalendarioNotifier].
  ///
  /// ### Uso
  /// ```dart
  /// final eventos = ref.watch(eventosDiaProvider(DateTime(2026, 4, 29)));
  /// ```
  ///
  /// El parámetro [dia] debe pasarse normalizado a medianoche
  /// (ej. [DateTime(año, mes, día)]) para que el cache de Riverpod funcione
  /// correctamente — [DateTime.now()] incluye horas y generaría una clave nueva
  /// cada vez.
  ///
  /// No tiene [keepAlive] — se recalcula automáticamente cuando cambia
  /// [CalendarioNotifier] o cuando el widget deja de escucharlo.
  ///
  /// Copied from [eventosDia].
  EventosDiaProvider(
    DateTime dia,
  ) : this._internal(
          (ref) => eventosDia(
            ref as EventosDiaRef,
            dia,
          ),
          from: eventosDiaProvider,
          name: r'eventosDiaProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$eventosDiaHash,
          dependencies: EventosDiaFamily._dependencies,
          allTransitiveDependencies:
              EventosDiaFamily._allTransitiveDependencies,
          dia: dia,
        );

  EventosDiaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dia,
  }) : super.internal();

  final DateTime dia;

  @override
  Override overrideWith(
    List<CalendarioEvento> Function(EventosDiaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EventosDiaProvider._internal(
        (ref) => create(ref as EventosDiaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dia: dia,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<CalendarioEvento>> createElement() {
    return _EventosDiaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventosDiaProvider && other.dia == dia;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dia.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EventosDiaRef on AutoDisposeProviderRef<List<CalendarioEvento>> {
  /// The parameter `dia` of this provider.
  DateTime get dia;
}

class _EventosDiaProviderElement
    extends AutoDisposeProviderElement<List<CalendarioEvento>>
    with EventosDiaRef {
  _EventosDiaProviderElement(super.provider);

  @override
  DateTime get dia => (origin as EventosDiaProvider).dia;
}

String _$calendarioNotifierHash() =>
    r'72f4ecccf5c7c16bcf889d33daad47a2fae44237';

/// Lista de eventos del calendario para el mes cargado.
///
/// ### Flujo de uso
/// 1. La pantalla llama [cargarMes(DateTime)] en initState → carga todos los
///    eventos del mes (desde el día 1 hasta el último día del mes).
/// 2. La UI deriva los eventos de un día concreto usando [eventosDiaProvider].
/// 3. Para CRUD manual, la UI llama [crearEvento], [actualizarEvento] o
///    [eliminarEvento] — los cambios se reflejan en el estado local sin refetch.
///
/// ### Eventos auto-generados
/// [actualizarEvento] y [eliminarEvento] lanzan [ForbiddenException] si el
/// evento tiene [autoGenerado] = true — la UI debe ocultarlos previamente.
/// El servidor también devolvería 403, pero la validación local es más rápida.
///
/// Copied from [CalendarioNotifier].
@ProviderFor(CalendarioNotifier)
final calendarioNotifierProvider = NotifierProvider<CalendarioNotifier,
    AsyncValue<List<CalendarioEvento>>>.internal(
  CalendarioNotifier.new,
  name: r'calendarioNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarioNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CalendarioNotifier = Notifier<AsyncValue<List<CalendarioEvento>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
