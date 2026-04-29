// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_mensaje.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMensaje _$ChatMensajeFromJson(Map<String, dynamic> json) => ChatMensaje(
      id: (json['id'] as num).toInt(),
      esIa: json['esIa'] as bool,
      mensaje: json['mensaje'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ChatMensajeToJson(ChatMensaje instance) =>
    <String, dynamic>{
      'id': instance.id,
      'esIa': instance.esIa,
      'mensaje': instance.mensaje,
      'createdAt': instance.createdAt.toIso8601String(),
    };
