import 'package:json_annotation/json_annotation.dart';

import 'test_question.dart';

part 'test_session.g.dart';

/// Espejo de TestIniciadoResponse.java.
///
/// Resultado de:
///   - POST /api/v1/tests/generar        (test libre)
///   - POST /api/v1/simulacros/{id}/iniciar  (simulacro)
///
/// El campo [tiempoMinutos] es null cuando el usuario no configuró tiempo.
/// En simulacros siempre tiene valor (duracionMinutos del simulacro).
@JsonSerializable(explicitToJson: true)
class TestSession {
  const TestSession({
    required this.sessionId,
    required this.preguntas,
    this.tiempoMinutos,
  });

  final int sessionId;
  final List<TestQuestion> preguntas;
  final int? tiempoMinutos;

  factory TestSession.fromJson(Map<String, dynamic> json) =>
      _$TestSessionFromJson(json);

  Map<String, dynamic> toJson() => _$TestSessionToJson(this);
}
