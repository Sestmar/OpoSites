import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/test_question.dart';
import 'test_session_provider.dart' show testsRepositoryProvider;

part 'test_fallos_provider.g.dart';

// ── Notifier ───────────────────────────────────────────────────────────────────

/// Gestiona la lista de preguntas falladas del usuario (GET /tests/fallos).
///
/// El estado usa [AsyncValue] de Riverpod para manejar loading/error/data
/// de forma idiomática. La lista arranca vacía — la UI dispara [load]
/// con los filtros que necesite.
///
/// keepAlive: true para que los fallos cargados persistan mientras el usuario
/// navega entre pantallas de repaso.
@Riverpod(keepAlive: true)
class TestFallos extends _$TestFallos {
  @override
  AsyncValue<List<TestQuestion>> build() =>
      const AsyncData(<TestQuestion>[]);

  /// Carga o recarga los fallos aplicando filtros opcionales.
  ///
  /// [ramaId] y [temaId] son opcionales. Sin filtros devuelve hasta 50
  /// preguntas falladas de todas las ramas (límite server-side).
  Future<void> load({int? ramaId, int? temaId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(testsRepositoryProvider).getFallos(
            ramaId: ramaId,
            temaId: temaId,
          ),
    );
  }
}
