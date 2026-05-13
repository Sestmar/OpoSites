import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/models/repaso_models.dart';
import '../data/repaso_repository.dart';

// ── Infraestructura ───────────────────────────────────────────────────────────

final repasoRepositoryProvider = Provider<RepasoRepository>(
  (ref) => RepasoRepository(dio: ref.watch(dioProvider)),
);

// ── Estado ────────────────────────────────────────────────────────────────────

class RepasoState {
  const RepasoState({
    required this.sesion,
    this.preguntaActual = 0,
    this.ultimaRespuesta,
    this.mostrandoFeedback = false,
    this.completada = false,
    this.puntuacionFinal,
    this.error,
    this.respuestaSeleccionada = -1,
  });

  final RepasoSesion sesion;
  final int preguntaActual;
  final RespuestaRepasoResult? ultimaRespuesta;

  /// true mientras se muestra el feedback (correcto/incorrecto) antes de avanzar.
  final bool mostrandoFeedback;
  final bool completada;
  final double? puntuacionFinal;
  final String? error;

  /// Índice de la opción que eligió el usuario en la pregunta actual (-1 si no ha respondido).
  final int respuestaSeleccionada;

  RepasoPregunta get preguntaActualObj => sesion.preguntas[preguntaActual];

  bool get esUltimaPregunta =>
      preguntaActual == sesion.preguntas.length - 1;

  RepasoState copyWith({
    int? preguntaActual,
    RespuestaRepasoResult? ultimaRespuesta,
    bool? mostrandoFeedback,
    bool? completada,
    double? puntuacionFinal,
    String? error,
    bool clearError = false,
    bool clearUltimaRespuesta = false,
    int? respuestaSeleccionada,
  }) =>
      RepasoState(
        sesion: sesion,
        preguntaActual: preguntaActual ?? this.preguntaActual,
        ultimaRespuesta: clearUltimaRespuesta
            ? null
            : (ultimaRespuesta ?? this.ultimaRespuesta),
        mostrandoFeedback: mostrandoFeedback ?? this.mostrandoFeedback,
        completada: completada ?? this.completada,
        puntuacionFinal: puntuacionFinal ?? this.puntuacionFinal,
        error: clearError ? null : (error ?? this.error),
        respuestaSeleccionada: respuestaSeleccionada ?? this.respuestaSeleccionada,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

final repasoNotifierProvider =
    StateNotifierProvider.autoDispose<RepasoNotifier, AsyncValue<RepasoState>>(
  (ref) => RepasoNotifier(ref.read(repasoRepositoryProvider)),
);

class RepasoNotifier extends StateNotifier<AsyncValue<RepasoState>> {
  RepasoNotifier(this._repo) : super(const AsyncLoading());

  final RepasoRepository _repo;

  /// Inicia una nueva sesión de repaso.
  Future<void> iniciar() async {
    state = const AsyncLoading();
    try {
      final sesion = await _repo.iniciarSesion();
      state = AsyncData(RepasoState(
        sesion: sesion,
        preguntaActual: sesion.preguntaActual,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Registra la respuesta del usuario a la pregunta actual.
  Future<void> responder(int opcionIndex) async {
    final current = state.valueOrNull;
    if (current == null || current.mostrandoFeedback) return;

    try {
      final resultado = await _repo.responder(
        sesionId: current.sesion.sesionId,
        preguntaIndex: current.preguntaActual,
        respuestaUsuario: opcionIndex,
      );

      state = AsyncData(current.copyWith(
        ultimaRespuesta: resultado,
        mostrandoFeedback: true,
        completada: resultado.sesionCompletada,
        puntuacionFinal: resultado.puntuacion,
        respuestaSeleccionada: opcionIndex,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(
        error: e.toString(),
        clearError: false,
      ));
    }
  }

  /// Avanza a la siguiente pregunta después de ver el feedback.
  void avanzar() {
    final current = state.valueOrNull;
    if (current == null || !current.mostrandoFeedback) return;
    if (current.completada) return;

    state = AsyncData(current.copyWith(
      preguntaActual: current.preguntaActual + 1,
      mostrandoFeedback: false,
      clearUltimaRespuesta: true,
      clearError: true,
      respuestaSeleccionada: -1,
    ));
  }
}
