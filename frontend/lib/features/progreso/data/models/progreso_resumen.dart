import 'package:json_annotation/json_annotation.dart';

part 'progreso_resumen.g.dart';

// ── Tipos anidados ─────────────────────────────────────────────────────────────

/// Espejo de TemaDebilDto.java.
///
/// Tema con bajo porcentaje de acierto — aparece en la sección "temas débiles"
/// del resumen de progreso.
@JsonSerializable()
class TemaDebil {
  const TemaDebil({
    required this.temaId,
    required this.nombre,
    required this.porcentajeAcierto,
    required this.totalRespondidas,
  });

  final int temaId;
  final String nombre;
  final double porcentajeAcierto;
  final int totalRespondidas;

  factory TemaDebil.fromJson(Map<String, dynamic> json) =>
      _$TemaDebilFromJson(json);

  Map<String, dynamic> toJson() => _$TemaDebilToJson(this);
}

// ── Modelo principal ───────────────────────────────────────────────────────────

/// Espejo de ProgresoResumenResponse.java.
///
/// Resumen global del usuario:
///   GET /api/v1/progreso/resumen?ramaId={id}
///
/// [rachaActual] es la racha en días (también en [RachaNotifier], pero se
/// incluye aquí por conveniencia en la pantalla de resumen).
/// [temasDebiles] lista ordenada por menor porcentaje de acierto.
@JsonSerializable(explicitToJson: true)
class ProgresoResumen {
  const ProgresoResumen({
    required this.totalRespondidas,
    required this.totalCorrectas,
    required this.porcentajeAciertosGlobal,
    required this.rachaActual,
    required this.temasDebiles,
  });

  final int totalRespondidas;
  final int totalCorrectas;
  final double porcentajeAciertosGlobal;
  final int rachaActual;
  final List<TemaDebil> temasDebiles;

  factory ProgresoResumen.fromJson(Map<String, dynamic> json) =>
      _$ProgresoResumenFromJson(json);

  Map<String, dynamic> toJson() => _$ProgresoResumenToJson(this);
}
