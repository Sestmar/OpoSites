// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestQuestion _$TestQuestionFromJson(Map<String, dynamic> json) => TestQuestion(
      id: (json['id'] as num).toInt(),
      temaId: (json['temaId'] as num).toInt(),
      enunciado: json['enunciado'] as String,
      tipo: $enumDecode(_$QuestionTypeEnumMap, json['tipo']),
      opciones:
          (json['opciones'] as List<dynamic>).map((e) => e as String).toList(),
      dificultad: (json['dificultad'] as num).toInt(),
    );

Map<String, dynamic> _$TestQuestionToJson(TestQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'temaId': instance.temaId,
      'enunciado': instance.enunciado,
      'tipo': _$QuestionTypeEnumMap[instance.tipo]!,
      'opciones': instance.opciones,
      'dificultad': instance.dificultad,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.mcq: 'MCQ',
  QuestionType.trueFalse: 'TRUE_FALSE',
  QuestionType.desarrollo: 'DESARROLLO',
};
