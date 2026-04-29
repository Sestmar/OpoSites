// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionResult _$QuestionResultFromJson(Map<String, dynamic> json) =>
    QuestionResult(
      preguntaId: (json['preguntaId'] as num).toInt(),
      correcto: json['correcto'] as bool,
      respuestaCorrecta: json['respuestaCorrecta'] as String,
      respuestaUsuario: json['respuestaUsuario'] as String?,
      explicacion: json['explicacion'] as String?,
    );

Map<String, dynamic> _$QuestionResultToJson(QuestionResult instance) =>
    <String, dynamic>{
      'preguntaId': instance.preguntaId,
      'correcto': instance.correcto,
      'respuestaUsuario': instance.respuestaUsuario,
      'respuestaCorrecta': instance.respuestaCorrecta,
      'explicacion': instance.explicacion,
    };

TopicAnalysis _$TopicAnalysisFromJson(Map<String, dynamic> json) =>
    TopicAnalysis(
      temaId: (json['temaId'] as num).toInt(),
      nombreTema: json['nombreTema'] as String,
      correctas: (json['correctas'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      porcentajeAcierto: (json['porcentajeAcierto'] as num).toDouble(),
    );

Map<String, dynamic> _$TopicAnalysisToJson(TopicAnalysis instance) =>
    <String, dynamic>{
      'temaId': instance.temaId,
      'nombreTema': instance.nombreTema,
      'correctas': instance.correctas,
      'total': instance.total,
      'porcentajeAcierto': instance.porcentajeAcierto,
    };

TestResult _$TestResultFromJson(Map<String, dynamic> json) => TestResult(
      sessionId: (json['sessionId'] as num).toInt(),
      nota: (json['nota'] as num).toDouble(),
      correctas: (json['correctas'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      detalle: (json['detalle'] as List<dynamic>)
          .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      analisisPorTema: (json['analisisPorTema'] as List<dynamic>?)
          ?.map((e) => TopicAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TestResultToJson(TestResult instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'nota': instance.nota,
      'correctas': instance.correctas,
      'total': instance.total,
      'detalle': instance.detalle.map((e) => e.toJson()).toList(),
      'analisisPorTema':
          instance.analisisPorTema?.map((e) => e.toJson()).toList(),
    };
