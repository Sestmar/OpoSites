import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/calendario_repository.dart';
import '../data/models/calendario_evento.dart';

part 'calendario_provider.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
CalendarioRepository calendarioRepository(CalendarioRepositoryRef ref) =>
    CalendarioRepository(dio: ref.watch(dioProvider));

// ── Notifier principal ─────────────────────────────────────────────────────────

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
@Riverpod(keepAlive: true)
class CalendarioNotifier extends _$CalendarioNotifier {
  @override
  AsyncValue<List<CalendarioEvento>> build() =>
      const AsyncData(<CalendarioEvento>[]);

  /// Carga todos los eventos del mes de [mes] (año + mes, el día se ignora).
  ///
  /// Rango usado: primer instante del mes → primer instante del mes siguiente.
  /// Reemplaza la lista completa — no acumula meses previos.
  Future<void> cargarMes(DateTime mes) async {
    state = const AsyncLoading();

    final desde = DateTime(mes.year, mes.month, 1);
    final hasta = DateTime(mes.year, mes.month + 1, 1);

    state = await AsyncValue.guard(
      () => ref.read(calendarioRepositoryProvider).getEventos(
            desde: _isoSinZona(desde),
            hasta: _isoSinZona(hasta),
          ),
    );
  }

  /// Crea un evento manual y lo inserta en la lista local.
  ///
  /// No-op de red: el servidor asigna el [id] y devuelve el evento completo.
  /// Lanza [ApiException] si falla — la UI captura para SnackBar.
  Future<void> crearEvento(CreateEventoRequest request) async {
    final created = await ref
        .read(calendarioRepositoryProvider)
        .crearEvento(request);

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, created]);
  }

  /// Actualiza un evento manual existente y refleja el cambio en la lista local.
  ///
  /// Lanza [ForbiddenException] si el evento tiene [autoGenerado] = true.
  /// Lanza [ApiException] para otros errores de red.
  Future<void> actualizarEvento(int id, UpdateEventoRequest request) async {
    final current = state.valueOrNull ?? [];
    final evento = current.firstWhere(
      (e) => e.id == id,
      orElse: () => throw NotFoundException('Evento $id no encontrado en el estado local.'),
    );

    if (evento.autoGenerado) {
      throw const ForbiddenException();
    }

    final updated = await ref
        .read(calendarioRepositoryProvider)
        .actualizarEvento(id, request);

    state = AsyncData(
      current.map((e) => e.id == id ? updated : e).toList(),
    );
  }

  /// Elimina un evento manual y lo retira de la lista local.
  ///
  /// Lanza [ForbiddenException] si el evento tiene [autoGenerado] = true.
  /// Lanza [ApiException] para otros errores de red.
  Future<void> eliminarEvento(int id) async {
    final current = state.valueOrNull ?? [];
    final evento = current.firstWhere(
      (e) => e.id == id,
      orElse: () => throw NotFoundException('Evento $id no encontrado en el estado local.'),
    );

    if (evento.autoGenerado) {
      throw const ForbiddenException();
    }

    await ref.read(calendarioRepositoryProvider).eliminarEvento(id);

    state = AsyncData(current.where((e) => e.id != id).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Formatea un [DateTime] como ISO 8601 sin zona horaria: "2026-04-01T00:00:00".
  ///
  /// El servidor espera este formato para @DateTimeFormat(iso=DATE_TIME).
  static String _isoSinZona(DateTime dt) =>
      dt.toIso8601String().substring(0, 19);
}

// ── Provider derivado: eventos de un día concreto ──────────────────────────────

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
@riverpod
List<CalendarioEvento> eventosDia(EventosDiaRef ref, DateTime dia) {
  final state = ref.watch(calendarioNotifierProvider);
  final eventos = state.valueOrNull ?? [];

  return eventos.where((e) {
    // fechaInicio es ISO 8601: "2026-04-29T10:00:00" — parseamos para comparar.
    final fecha = DateTime.tryParse(e.fechaInicio);
    if (fecha == null) return false;
    return fecha.year == dia.year &&
        fecha.month == dia.month &&
        fecha.day == dia.day;
  }).toList()
    ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
}
