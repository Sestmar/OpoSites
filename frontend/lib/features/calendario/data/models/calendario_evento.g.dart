// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendario_evento.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarioEvento _$CalendarioEventoFromJson(Map<String, dynamic> json) =>
    CalendarioEvento(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      fechaInicio: json['fechaInicio'] as String,
      tipo: $enumDecode(_$TipoEventoEnumMap, json['tipo']),
      autoGenerado: json['autoGenerado'] as bool,
      descripcion: json['descripcion'] as String?,
      fechaFin: json['fechaFin'] as String?,
      ramaId: (json['ramaId'] as num?)?.toInt(),
      nombreRama: json['nombreRama'] as String?,
    );

Map<String, dynamic> _$CalendarioEventoToJson(CalendarioEvento instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'fechaInicio': instance.fechaInicio,
      'fechaFin': instance.fechaFin,
      'tipo': _$TipoEventoEnumMap[instance.tipo]!,
      'ramaId': instance.ramaId,
      'nombreRama': instance.nombreRama,
      'autoGenerado': instance.autoGenerado,
    };

const _$TipoEventoEnumMap = {
  TipoEvento.estudio: 'estudio',
  TipoEvento.simulacro: 'simulacro',
  TipoEvento.convocatoria: 'convocatoria',
  TipoEvento.manual: 'manual',
};

CreateEventoRequest _$CreateEventoRequestFromJson(Map<String, dynamic> json) =>
    CreateEventoRequest(
      titulo: json['titulo'] as String,
      fechaInicio: json['fechaInicio'] as String,
      tipo: $enumDecode(_$TipoEventoEnumMap, json['tipo']),
      descripcion: json['descripcion'] as String?,
      fechaFin: json['fechaFin'] as String?,
      ramaId: (json['ramaId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateEventoRequestToJson(
        CreateEventoRequest instance) =>
    <String, dynamic>{
      'titulo': instance.titulo,
      if (instance.descripcion case final value?) 'descripcion': value,
      'fechaInicio': instance.fechaInicio,
      if (instance.fechaFin case final value?) 'fechaFin': value,
      'tipo': _$TipoEventoEnumMap[instance.tipo]!,
      if (instance.ramaId case final value?) 'ramaId': value,
    };

UpdateEventoRequest _$UpdateEventoRequestFromJson(Map<String, dynamic> json) =>
    UpdateEventoRequest(
      titulo: json['titulo'] as String?,
      descripcion: json['descripcion'] as String?,
      fechaInicio: json['fechaInicio'] as String?,
      fechaFin: json['fechaFin'] as String?,
    );

Map<String, dynamic> _$UpdateEventoRequestToJson(
        UpdateEventoRequest instance) =>
    <String, dynamic>{
      if (instance.titulo case final value?) 'titulo': value,
      if (instance.descripcion case final value?) 'descripcion': value,
      if (instance.fechaInicio case final value?) 'fechaInicio': value,
      if (instance.fechaFin case final value?) 'fechaFin': value,
    };
