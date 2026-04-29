import 'package:json_annotation/json_annotation.dart';

part 'test_question.g.dart';

/// Espejo de TipoPregunta.java.
///
/// [FieldRename.screamingSnake] produce la serialización exacta del backend:
///   mcq        → "MCQ"
///   trueFalse  → "TRUE_FALSE"
///   desarrollo → "DESARROLLO"
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum QuestionType { mcq, trueFalse, desarrollo }

/// Espejo de PreguntaResponse.java.
///
/// No incluye [respuestaCorrecta] ni [explicacion] — esos campos solo
/// llegan vía [PreguntaRespuestaResponse] (endpoint GET /preguntas/{id}/respuesta).
@JsonSerializable()
class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.temaId,
    required this.enunciado,
    required this.tipo,
    required this.opciones,
    required this.dificultad,
  });

  final int id;
  final int temaId;
  final String enunciado;
  final QuestionType tipo;
  final List<String> opciones;
  final int dificultad;

  factory TestQuestion.fromJson(Map<String, dynamic> json) =>
      _$TestQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$TestQuestionToJson(this);
}
