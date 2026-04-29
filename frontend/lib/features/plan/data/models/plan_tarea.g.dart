// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_tarea.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanTarea _$PlanTareaFromJson(Map<String, dynamic> json) => PlanTarea(
      id: (json['id'] as num).toInt(),
      tipo: $enumDecode(_$TipoPlanTareaEnumMap, json['tipo']),
      fecha: json['fecha'] as String,
      completada: json['completada'] as bool,
      temaId: (json['temaId'] as num?)?.toInt(),
      nombreTema: json['nombreTema'] as String?,
      simulacroId: (json['simulacroId'] as num?)?.toInt(),
      nombreSimulacro: json['nombreSimulacro'] as String?,
      descripcion: json['descripcion'] as String?,
    );

Map<String, dynamic> _$PlanTareaToJson(PlanTarea instance) => <String, dynamic>{
      'id': instance.id,
      'tipo': _$TipoPlanTareaEnumMap[instance.tipo]!,
      'temaId': instance.temaId,
      'nombreTema': instance.nombreTema,
      'simulacroId': instance.simulacroId,
      'nombreSimulacro': instance.nombreSimulacro,
      'fecha': instance.fecha,
      'completada': instance.completada,
      'descripcion': instance.descripcion,
    };

const _$TipoPlanTareaEnumMap = {
  TipoPlanTarea.test: 'test',
  TipoPlanTarea.repaso: 'repaso',
  TipoPlanTarea.simulacro: 'simulacro',
};
