// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_configuracion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanConfiguracion _$PlanConfiguracionFromJson(Map<String, dynamic> json) =>
    PlanConfiguracion(
      horasSemana: (json['horasSemana'] as num).toInt(),
      preferencia: $enumDecode(_$PreferenciaPlanEnumMap, json['preferencia']),
      fechaExamenObjetivo: json['fechaExamenObjetivo'] as String?,
      diasHastaExamen: (json['diasHastaExamen'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlanConfiguracionToJson(PlanConfiguracion instance) =>
    <String, dynamic>{
      'horasSemana': instance.horasSemana,
      'preferencia': _$PreferenciaPlanEnumMap[instance.preferencia]!,
      'fechaExamenObjetivo': instance.fechaExamenObjetivo,
      'diasHastaExamen': instance.diasHastaExamen,
    };

const _$PreferenciaPlanEnumMap = {
  PreferenciaPlan.teoria: 'teoria',
  PreferenciaPlan.test: 'test',
  PreferenciaPlan.mixto: 'mixto',
};

UpdatePlanConfiguracionRequest _$UpdatePlanConfiguracionRequestFromJson(
        Map<String, dynamic> json) =>
    UpdatePlanConfiguracionRequest(
      horasSemana: (json['horasSemana'] as num?)?.toInt(),
      preferencia:
          $enumDecodeNullable(_$PreferenciaPlanEnumMap, json['preferencia']),
      fechaExamenObjetivo: json['fechaExamenObjetivo'] as String?,
    );

Map<String, dynamic> _$UpdatePlanConfiguracionRequestToJson(
        UpdatePlanConfiguracionRequest instance) =>
    <String, dynamic>{
      if (instance.horasSemana case final value?) 'horasSemana': value,
      if (_$PreferenciaPlanEnumMap[instance.preferencia] case final value?)
        'preferencia': value,
      if (instance.fechaExamenObjetivo case final value?)
        'fechaExamenObjetivo': value,
    };
