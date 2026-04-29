// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversacion_resumen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversacionResumen _$ConversacionResumenFromJson(Map<String, dynamic> json) =>
    ConversacionResumen(
      id: (json['id'] as num).toInt(),
      nombreRama: json['nombreRama'] as String?,
      fechaExamen: json['fechaExamen'] as String?,
      temasDebiles: (json['temasDebiles'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ConversacionResumenToJson(
        ConversacionResumen instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombreRama': instance.nombreRama,
      'fechaExamen': instance.fechaExamen,
      'temasDebiles': instance.temasDebiles,
      'createdAt': instance.createdAt.toIso8601String(),
    };
