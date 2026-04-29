// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evolucion_semanal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvolucionSemanal _$EvolucionSemanalFromJson(Map<String, dynamic> json) =>
    EvolucionSemanal(
      semana: json['semana'] as String,
      notaMedia: (json['notaMedia'] as num).toDouble(),
      testsCompletados: (json['testsCompletados'] as num).toInt(),
    );

Map<String, dynamic> _$EvolucionSemanalToJson(EvolucionSemanal instance) =>
    <String, dynamic>{
      'semana': instance.semana,
      'notaMedia': instance.notaMedia,
      'testsCompletados': instance.testsCompletados,
    };
