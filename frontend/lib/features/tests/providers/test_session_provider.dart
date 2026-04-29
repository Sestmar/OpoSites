import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_provider.dart' show dioProvider;
import '../data/models/question_answer.dart';
import '../data/models/test_question.dart';
import '../data/models/test_result.dart';
import '../data/models/test_session.dart';
import '../data/tests_repository.dart';

part 'test_session_provider.g.dart';

// ── Provider de infraestructura ────────────────────────────────────────────────

@Riverpod(keepAlive: true)
TestsRepository testsRepository(TestsRepositoryRef ref) =>
    TestsRepository(dio: ref.watch(dioProvider));

// ── Estado ─────────────────────────────────────────────────────────────────────

sealed class TestState {
  const TestState();
}

/// Sin test activo. Estado por defecto al abrir la app o después de un reset.
final class TestStateIdle extends TestState {
  const TestStateIdle();
}

/// Generando el test (llamada en curso a POST /tests/generar).
final class TestStateLoading extends TestState {
  const TestStateLoading();
}

/// Test en curso. El usuario está respondiendo preguntas.
///
/// [answers] se inicializa con respuestas null (una por pregunta) y se
/// actualiza con cada llamada a [ActiveTest.seleccionarRespuesta].
final class TestStateActive extends TestState {
  const TestStateActive({
    required this.session,
    required this.answers,
  });

  final TestSession session;
  final List<QuestionAnswer> answers;

  /// Número de preguntas ya respondidas (respuestaUsuario != null).
  int get respondidas =>
      answers.where((a) => a.respuestaUsuario != null).length;

  TestStateActive copyWithAnswer(int preguntaId, String opcion) {
    return TestStateActive(
      session: session,
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

/// Enviando respuestas (llamada en curso a POST /tests/responder).
///
/// Lleva [session] y [answers] para que la UI pueda mostrar el estado
/// "enviando…" sin perder los datos visibles.
final class TestStateSubmitting extends TestState {
  const TestStateSubmitting({
    required this.session,
    required this.answers,
  });

  final TestSession session;
  final List<QuestionAnswer> answers;
}

/// Test completado con resultados disponibles.
final class TestStateCompleted extends TestState {
  const TestStateCompleted({required this.result});
  final TestResult result;
}

/// Error ocurrido durante la generación o el envío.
final class TestStateError extends TestState {
  const TestStateError(this.message);
  final String message;
}

// ── Notifier ───────────────────────────────────────────────────────────────────

/// Gestiona el ciclo de vida completo de un test libre:
///   idle → loading → active → submitting → completed
///                   ↓                    ↓
///                 error               error
///
/// keepAlive: true para que el estado sobreviva la navegación entre pantallas
/// mientras el test esté en curso.
@Riverpod(keepAlive: true)
class ActiveTest extends _$ActiveTest {
  @override
  TestState build() => const TestStateIdle();

  // ── Generación ─────────────────────────────────────────────────────────────

  /// Genera un test libre y pasa al estado [TestStateActive].
  ///
  /// [temaIds] null o vacío = todas las preguntas de la rama.
  /// [dificultad] null = sin filtro.
  /// [tiempoMinutos] null = sin límite.
  Future<void> generarTest({
    required int ramaId,
    List<int>? temaIds,
    int cantidad = 10,
    int? dificultad,
    int? tiempoMinutos,
  }) async {
    state = const TestStateLoading();
    try {
      final session = await ref.read(testsRepositoryProvider).generarTest(
            ramaId: ramaId,
            temaIds: temaIds,
            cantidad: cantidad,
            dificultad: dificultad,
            tiempoMinutos: tiempoMinutos,
          );
      state = TestStateActive(
        session: session,
        answers: _initAnswers(session.preguntas),
      );
    } on Exception catch (e) {
      state = TestStateError(e.toString());
    }
  }

  // ── Respuestas ─────────────────────────────────────────────────────────────

  /// Registra o actualiza la respuesta del usuario para [preguntaId].
  ///
  /// Solo funciona cuando el estado es [TestStateActive].
  /// La UI puede llamar esto tantas veces como el usuario cambie de opción.
  void seleccionarRespuesta(int preguntaId, String opcion) {
    final current = state;
    if (current is! TestStateActive) return;
    state = current.copyWithAnswer(preguntaId, opcion);
  }

  // ── Envío ──────────────────────────────────────────────────────────────────

  /// Envía todas las respuestas y pasa al estado [TestStateCompleted].
  ///
  /// Las preguntas no respondidas (respuestaUsuario == null) se envían
  /// como omitidas — el backend las cuenta como incorrectas.
  Future<void> enviarRespuestas() async {
    final current = state;
    if (current is! TestStateActive) return;

    state = TestStateSubmitting(
      session: current.session,
      answers: current.answers,
    );

    try {
      final result = await ref.read(testsRepositoryProvider).responder(
            sessionId: current.session.sessionId,
            respuestas: current.answers,
          );
      state = TestStateCompleted(result: result);
    } on Exception catch (e) {
      // En caso de error volvemos a Active para que el usuario pueda reintentar.
      state = TestStateActive(
        session: current.session,
        answers: current.answers,
      );
      // Emitimos el error como estado transitorio para que la UI lo muestre.
      // (Solución pragmática: si la UI necesita un estado de error post-submit
      //  separado, añadir TestStateSubmitError en el futuro.)
      state = TestStateError(e.toString());
    }
  }

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Vuelve a [TestStateIdle]. Llamar tras ver los resultados o al salir.
  void reset() => state = const TestStateIdle();

  /// Inicializa la lista de respuestas con respuestaUsuario = null (omitida)
  /// para cada pregunta del test.
  static List<QuestionAnswer> _initAnswers(List<TestQuestion> questions) =>
      questions
          .map((q) => QuestionAnswer(preguntaId: q.id))
          .toList();
}
