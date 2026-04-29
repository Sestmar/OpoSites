// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progreso_resumen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemaDebil _$TemaDebilFromJson(Map<String, dynamic> json) => TemaDebil(
      temaId: (json['temaId'] as num).toInt(),
      nombre: json['nombre'] as String,
      porcentajeAcierto: (json['porcentajeAcierto'] as num).toDouble(),
      totalRespondidas: (json['totalRespondidas'] as num).toInt(),
    );

Map<String, dynamic> _$TemaDebilToJson(TemaDebil instance) => <String, dynamic>{
      'temaId': instance.temaId,
      'nombre': instance.nombre,
      'porcentajeAcierto': instance.porcentajeAcierto,
      'totalRespondidas': instance.totalRespondidas,
    };

ProgresoResumen _$ProgresoResumenFromJson(Map<String, dynamic> json) =>
    ProgresoResumen(
      totalRespondidas: (json['totalRespondidas'] as num).toInt(),
      totalCorrectas: (json['totalCorrectas'] as num).toInt(),
      porcentajeAciertosGlobal:
          (json['porcentajeAciertosGlobal'] as num).toDouble(),
      rachaActual: (json['rachaActual'] as num).toInt(),
      temasDebiles: (json['temasDebiles'] as List<dynamic>)
          .map((e) => TemaDebil.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProgresoResumenToJson(ProgresoResumen instance) =>
    <String, dynamic>{
      'totalRespondidas': instance.totalRespondidas,
      'totalCorrectas': instance.totalCorrectas,
      'porcentajeAciertosGlobal': instance.porcentajeAciertosGlobal,
      'rachaActual': instance.rachaActual,
      'temasDebiles': instance.temasDebiles.map((e) => e.toJson()).toList(),
    };
