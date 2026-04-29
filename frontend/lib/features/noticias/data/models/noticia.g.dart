// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noticia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Noticia _$NoticiaFromJson(Map<String, dynamic> json) => Noticia(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      tipo: $enumDecode(_$TipoNoticiaEnumMap, json['tipo']),
      fechaPublicacion: json['fechaPublicacion'] as String,
      leida: json['leida'] as bool,
      contenido: json['contenido'] as String?,
      urlExterna: json['urlExterna'] as String?,
      ramaId: (json['ramaId'] as num?)?.toInt(),
      nombreRama: json['nombreRama'] as String?,
    );

Map<String, dynamic> _$NoticiaToJson(Noticia instance) => <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'tipo': _$TipoNoticiaEnumMap[instance.tipo]!,
      'contenido': instance.contenido,
      'urlExterna': instance.urlExterna,
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
