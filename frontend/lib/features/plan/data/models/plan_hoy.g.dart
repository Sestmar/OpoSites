// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_hoy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanHoy _$PlanHoyFromJson(Map<String, dynamic> json) => PlanHoy(
      fecha: json['fecha'] as String,
      tareas: (json['tareas'] as List<dynamic>)
          .map((e) => PlanTarea.fromJson(e as Map<String, dynamic>))
          .toList(),
      tareasCompletadas: (json['tareasCompletadas'] as num).toInt(),
      totalTareas: (json['totalTareas'] as num).toInt(),
    );

Map<String, dynamic> _$PlanHoyToJson(PlanHoy instance) => <String, dynamic>{
      'fecha': instance.fecha,
      'tareas': instance.tareas.map((e) => e.toJson()).toList(),
      'tareasCompletadas': instance.tareasCompletadas,
      'totalTareas': instance.totalTareas,
    };
