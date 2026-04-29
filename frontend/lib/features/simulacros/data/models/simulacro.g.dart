// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulacro.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Simulacro _$SimulacroFromJson(Map<String, dynamic> json) => Simulacro(
      id: (json['id'] as num).toInt(),
      ramaId: (json['ramaId'] as num).toInt(),
      nombre: json['nombre'] as String,
      duracionMinutos: (json['duracionMinutos'] as num).toInt(),
      preguntasCount: (json['preguntasCount'] as num).toInt(),
      temasIncluidos: (json['temasIncluidos'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      fechaOficial: json['fechaOficial'] as String?,
    );

Map<String, dynamic> _$SimulacroToJson(Simulacro instance) => <String, dynamic>{
      'id': instance.id,
      'ramaId': instance.ramaId,
      'nombre': instance.nombre,
      'duracionMinutos': instance.duracionMinutos,
      'preguntasCount': instance.preguntasCount,
      'temasIncluidos': instance.temasIncluidos,
      'fechaOficial': instance.fechaOficial,
    };
