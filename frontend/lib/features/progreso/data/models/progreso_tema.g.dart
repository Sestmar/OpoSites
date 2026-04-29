// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progreso_tema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgresoTema _$ProgresoTemaFromJson(Map<String, dynamic> json) => ProgresoTema(
      temaId: (json['temaId'] as num).toInt(),
      nombre: json['nombre'] as String,
      totalRespondidas: (json['totalRespondidas'] as num).toInt(),
      correctas: (json['correctas'] as num).toInt(),
      porcentajeAcierto: (json['porcentajeAcierto'] as num).toDouble(),
    );

Map<String, dynamic> _$ProgresoTemaToJson(ProgresoTema instance) =>
    <String, dynamic>{
      'temaId': instance.temaId,
      'nombre': instance.nombre,
      'totalRespondidas': instance.totalRespondidas,
      'correctas': instance.correctas,
      'porcentajeAcierto': instance.porcentajeAcierto,
    };
