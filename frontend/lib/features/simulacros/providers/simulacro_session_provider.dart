import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../../tests/data/models/question_answer.dart';
import '../../tests/data/models/test_question.dart';
import '../../tests/data/models/test_session.dart';
import '../data/models/simulacro_result.dart';
import '../data/simulacros_repository.dart';

part 'simulacro_session_provider.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
SimulacrosRepository simulacrosRepository(SimulacrosRepositoryRef ref) =>
    SimulacrosRepository(dio: ref.watch(dioProvider));

// ── Estado ─────────────────────────────────────────────────────────────────────

sealed class SimulacroState {
  const SimulacroState();
}

/// Sin simulacro activo.
final class SimulacroStateIdle extends SimulacroState {
  const SimulacroStateIdle();
}

/// Iniciando el simulacro (POST /simulacros/{id}/iniciar en curso).
final class SimulacroStateLoading extends SimulacroState {
  const SimulacroStateLoading();
}

/// Simulacro en curso. El usuario está respondiendo preguntas.
///
/// [duracionMinutos] es el tiempo total asignado al simulacro.
/// La UI debe usar este valor para arrancar el cronómetro descendente.
/// El provider NO gestiona el timer — eso es responsabilidad de la UI
/// para no bloquear el árbol de widgets con ticks cada segundo.
final class SimulacroStateActive extends SimulacroState {
  const SimulacroStateActive({
    required this.simulacroId,
    required this.session,
    required this.answers,
    required this.duracionMinutos,
  });

  final int simulacroId;
  final TestSession session;
  final List<QuestionAnswer> answers;

  /// Duración total en minutos — extraída de [TestSession.tiempoMinutos].
  /// Siempre non-null en simulacros (viene de Simulacro.duracionMinutos).
  final int duracionMinutos;

  int get respondidas =>
      answers.where((a) => a.respuestaUsuario != null).length;

  SimulacroStateActive copyWithAnswer(int preguntaId, String opcion) {
    return SimulacroStateActive(
      simulacroId: simulacroId,
      session: session,
      duracionMinutos: duracionMinutos,
      answers: answers
          .map((a) => a.preguntaId == preguntaId
              ? QuestionAnswer(
                  preguntaId: preguntaId,
                  respuestaUsuario: opcion,
                )
              : a)
          .toList(),
    );
  }
}

/// Entregando respuestas (POST /simulacros/{id}/entregar en curso).
final class SimulacroStateSubmitting extends SimulacroState {
  const SimulacroStateSubmitting({
    required this.simulacroId,
    required this.session,
    required this.answers,
  });

  final int simulacroId;
  final TestSession session;
  final List<QuestionAnswer> answers;
}

/// Simulacro completado. [result.analisisPorTema] siempre tiene datos.
final class SimulacroStateCompleted extends SimulacroState {
  const SimulacroStateCompleted({required this.result});
  final SimulacroResult result;
}

/// Error durante el inicio o la entrega.
final class SimulacroStateError extends SimulacroState {
  const SimulacroStateError(this.message);
  final String message;
}

// ── Notifier ───────────────────────────────────────────────────────────────────

/// Gestiona el ciclo de vida completo de un simulacro:
///   idle → loading → active → submitting → completed
///                   ↓                    ↓
///                 error               error
///
/// keepAlive: true para que el estado sobreviva la navegación mientras
/// el simulacro esté en curso (el usuario puede ir a una pregunta concreta
/// y volver sin perder respuestas ni reiniciar el timer).
@Riverpod(keepAlive: true)
class ActiveSimulacro extends _$ActiveSimulacro {
  @override
  SimulacroState build() => const SimulacroStateIdle();

  // ── Inicio ─────────────────────────────────────────────────────────────────

  /// Inicia el simulacro y pasa a [SimulacroStateActive].
  ///
  /// El servidor registra el [fecha_inicio] en la sesión.
  /// La UI debe arrancar el cronómetro cuando este método complete.
  Future<void> iniciarSimulacro(int simulacroId) async {
    state = const SimulacroStateLoading();
    try {
      final session = await ref
          .read(simulacrosRepositoryProvider)
          .iniciar(simulacroId);

      // tiempoMinutos siempre tiene valor en simulacros
      final duracion = session.tiempoMinutos ?? 60;

      state = SimulacroStateActive(
        simulacroId: simulacroId,
        session: session,
        answers: _initAnswers(session.preguntas),
        duracionMinutos: duracion,
      );
    } on Exception catch (e) {
      state = SimulacroStateError(e.toString());
    }
  }

  // ── Respuestas ─────────────────────────────────────────────────────────────

  /// Registra o actualiza la respuesta del usuario para [preguntaId].
  void seleccionarRespuesta(int preguntaId, String opcion) {
    final current = state;
    if (current is! SimulacroStateActive) return;
    state = current.copyWithAnswer(preguntaId, opcion);
  }

  // ── Entrega ────────────────────────────────────────────────────────────────

  /// Entrega las respuestas y pasa a [SimulacroStateCompleted].
  ///
  /// Llamar tanto cuando el usuario pulsa "Entregar" como cuando el
  /// cronómetro llega a cero (la UI dispara este método en ese caso).
  Future<void> entregarSimulacro() async {
    final current = state;
    if (current is! SimulacroStateActive) return;

    state = SimulacroStateSubmitting(
      simulacroId: current.simulacroId,
      session: current.session,
      answers: current.answers,
    );

    try {
      final result = await ref
          .read(simulacrosRepositoryProvider)
          .entregar(
            simulacroId: current.simulacroId,
            sessionId: current.session.sessionId,
            respuestas: current.answers,
          );
      state = SimulacroStateCompleted(result: result);
    } on Exception catch (e) {
      // Mismo patrón que ActiveTest: volvemos a Active para reintentar.
      state = SimulacroStateActive(
        simulacroId: current.simulacroId,
        session: current.session,
        answers: current.answers,
        duracionMinutos: current.duracionMinutos,
      );
      state = SimulacroStateError(e.toString());
    }
  }

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Vuelve a [SimulacroStateIdle]. Llamar tras ver los resultados o al salir.
  void reset() => state = const SimulacroStateIdle();

  static List<QuestionAnswer> _initAnswers(List<TestQuestion> questions) =>
      questions.map((q) => QuestionAnswer(preguntaId: q.id)).toList();
}
