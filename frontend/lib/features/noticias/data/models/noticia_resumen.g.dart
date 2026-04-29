// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noticia_resumen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoticiaResumen _$NoticiaResumenFromJson(Map<String, dynamic> json) =>
    NoticiaResumen(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      tipo: $enumDecode(_$TipoNoticiaEnumMap, json['tipo']),
      fechaPublicacion: json['fechaPublicacion'] as String,
      leida: json['leida'] as bool,
      ramaId: (json['ramaId'] as num?)?.toInt(),
      nombreRama: json['nombreRama'] as String?,
    );

Map<String, dynamic> _$NoticiaResumenToJson(NoticiaResumen instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'tipo': _$TipoNoticiaEnumMap[instance.tipo]!,
      'ramaId': instance.ramaId,
      'nombreRama': instance.nombreRama,
      'fechaPublicacion': instance.fechaPublicacion,
      'leida': instance.leida,
    };

const _$TipoNoticiaEnumMap = {
  TipoNoticia.convocatoria: 'convocatoria',
  TipoNoticia.cambio: 'cambio',
  TipoNoticia.noticia: 'noticia',
};
