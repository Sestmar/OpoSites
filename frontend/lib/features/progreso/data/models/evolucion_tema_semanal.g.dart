// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evolucion_tema_semanal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvolucionTemaSemanal _$EvolucionTemaSemanalFromJson(
        Map<String, dynamic> json) =>
    EvolucionTemaSemanal(
      semana: json['semana'] as String,
      porcentajeAcierto: (json['porcentajeAcierto'] as num).toDouble(),
      totalRespondidas: (json['totalRespondidas'] as num).toInt(),
    );

Map<String, dynamic> _$EvolucionTemaSemanalToJson(
        EvolucionTemaSemanal instance) =>
    <String, dynamic>{
      'semana': instance.semana,
      'porcentajeAcierto': instance.porcentajeAcierto,
      'totalRespondidas': instance.totalRespondidas,
    };
