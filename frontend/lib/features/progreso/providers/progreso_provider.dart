import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/models/evolucion_semanal.dart';
import '../data/models/progreso_resumen.dart';
import '../data/models/progreso_tema.dart';
import '../data/models/racha.dart';
import '../data/progreso_repository.dart';

part 'progreso_provider.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ProgresoRepository progresoRepository(ProgresoRepositoryRef ref) =>
    ProgresoRepository(dio: ref.watch(dioProvider));

// ── Notifiers ──────────────────────────────────────────────────────────────────

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
@Riverpod(keepAlive: true)
class ProgresoResumenNotifier extends _$ProgresoResumenNotifier {
  @override
  AsyncValue<ProgresoResumen?> build() => const AsyncData(null);

  /// Carga o recarga el resumen. [ramaId] null = todas las ramas.
  Future<void> load({int? ramaId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(progresoRepositoryProvider).getResumen(ramaId: ramaId),
    );
  }
}

/// Lista de estadísticas por tema.
///
/// Arranca vacía — la UI dispara [load] con el [ramaId] de la oposición activa.
/// La lista viene ordenada por porcentaje de acierto ascendente (temas débiles
/// primero) — apta para una lista directa sin reordenar en el cliente.
@Riverpod(keepAlive: true)
class ProgresoTemas extends _$ProgresoTemas {
  @override
  AsyncValue<List<ProgresoTema>> build() => const AsyncData(<ProgresoTema>[]);

  /// Carga o recarga los temas. [ramaId] null = todos los temas practicados.
  Future<void> load({int? ramaId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(progresoRepositoryProvider).getTemas(ramaId: ramaId),
    );
  }
}

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
@Riverpod(keepAlive: true)
class ProgresoEvolucion extends _$ProgresoEvolucion {
  @override
  AsyncValue<List<EvolucionSemanal>> build() =>
      const AsyncData(<EvolucionSemanal>[]);

  /// Carga o recarga la evolución. [semanas] default 12 = 3 meses.
  Future<void> load({int semanas = 12}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(progresoRepositoryProvider).getEvolucion(semanas: semanas),
    );
  }
}

/// Racha actual y mejor racha del usuario.
///
/// Estado inicial null — la UI dispara [load] al montar la pantalla de Progreso.
/// [Racha.ultimoEstudio] es "YYYY-MM-DD" o null si nunca estudió.
@Riverpod(keepAlive: true)
class RachaNotifier extends _$RachaNotifier {
  @override
  AsyncValue<Racha?> build() => const AsyncData(null);

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(progresoRepositoryProvider).getRacha(),
    );
  }
}
