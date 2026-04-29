// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestSession _$TestSessionFromJson(Map<String, dynamic> json) => TestSession(
      sessionId: (json['sessionId'] as num).toInt(),
      preguntas: (json['preguntas'] as List<dynamic>)
          .map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      tiempoMinutos: (json['tiempoMinutos'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TestSessionToJson(TestSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'preguntas': instance.preguntas.map((e) => e.toJson()).toList(),
      'tiempoMinutos': instance.tiempoMinutos,
    };
