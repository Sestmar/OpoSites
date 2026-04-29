// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'racha.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Racha _$RachaFromJson(Map<String, dynamic> json) => Racha(
      rachaActual: (json['rachaActual'] as num).toInt(),
      mejorRacha: (json['mejorRacha'] as num).toInt(),
      ultimoEstudio: json['ultimoEstudio'] as String?,
    );

Map<String, dynamic> _$RachaToJson(Racha instance) => <String, dynamic>{
      'rachaActual': instance.rachaActual,
      'mejorRacha': instance.mejorRacha,
      'ultimoEstudio': instance.ultimoEstudio,
    };
