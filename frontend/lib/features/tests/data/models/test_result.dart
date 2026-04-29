import 'package:json_annotation/json_annotation.dart';

part 'test_result.g.dart';

// ── Tipos anidados ─────────────────────────────────────────────────────────────
//
// Se declaran antes del modelo principal porque TestResult los referencia.
// Ambos son también usados por SimulacroResult (via typedef en simulacros/).

/// Espejo de ResultadoPreguntaDto.java.
///
/// [respuestaUsuario] es null cuando el usuario omitió la pregunta.
/// [explicacion] puede ser null si el admin no la cargó en la BD.
@JsonSerializable()
class QuestionResult {
  const QuestionResult({
    required this.preguntaId,
    required this.correcto,
    required this.respuestaCorrecta,
    this.respuestaUsuario,
    this.explicacion,
  });

  final int preguntaId;
  final bool correcto;
  final String? respuestaUsuario;
  final String respuestaCorrecta;
  final String? explicacion;

  factory QuestionResult.fromJson(Map<String, dynamic> json) =>
      _$QuestionResultFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionResultToJson(this);
}

/// Espejo de AnalisisTemaDto.java.
///
/// Solo presente en [TestResult.analisisPorTema] cuando el test fue un simulacro.
@JsonSerializable()
class TopicAnalysis {
  const TopicAnalysis({
    required this.temaId,
    required this.nombreTema,
    required this.correctas,
    required this.total,
    required this.porcentajeAcierto,
  });

  final int temaId;
  final String nombreTema;
  final int correctas;
  final int total;
  final double porcentajeAcierto;

  factory TopicAnalysis.fromJson(Map<String, dynamic> json) =>
      _$TopicAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$TopicAnalysisToJson(this);
}

// ── Modelo principal ───────────────────────────────────────────────────────────

/// Espejo de ResultadoTestResponse.java.
///
/// Resultado de:
///   - POST /api/v1/tests/responder           (test libre)
///   - POST /api/v1/simulacros/{id}/entregar  (simulacro)
///
/// [nota] va de 0.0 a 10.0.
/// [analisisPorTema] solo está presente en simulacros; null en tests libres.
@JsonSerializable(explicitToJson: true)
class TestResult {
  const TestResult({
    required this.sessionId,
    required this.nota,
    required this.correctas,
    required this.total,
    required this.detalle,
    this.analisisPorTema,
  });

  final int sessionId;
  final double nota;
  final int correctas;
  final int total;
  final List<QuestionResult> detalle;
  final List<TopicAnalysis>? analisisPorTema;

  factory TestResult.fromJson(Map<String, dynamic> json) =>
      _$TestResultFromJson(json);

  Map<String, dynamic> toJson() => _$TestResultToJson(this);
}
