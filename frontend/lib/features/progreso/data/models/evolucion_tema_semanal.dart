import 'package:json_annotation/json_annotation.dart';

part 'evolucion_tema_semanal.g.dart';

/// Espejo de EvolucionTemaSemanalDto.java.
///
/// Un punto de datos por semana para la mini-gráfica de evolución por tema:
///   GET /api/v1/progreso/evolucion-tema?temaId={id}&semanas={n}
///
/// [semana] formato ISO "2026-W17".
/// [porcentajeAcierto] va de 0.0 a 100.0 (distinto de notaMedia 0–10 del global).
@JsonSerializable()
class EvolucionTemaSemanal {
  const EvolucionTemaSemanal({
    required this.semana,
    required this.porcentajeAcierto,
    required this.totalRespondidas,
  });

  final String semana;
  final double porcentajeAcierto;
  final int totalRespondidas;

  factory EvolucionTemaSemanal.fromJson(Map<String, dynamic> json) =>
      _$EvolucionTemaSemanalFromJson(json);

  Map<String, dynamic> toJson() => _$EvolucionTemaSemanalToJson(this);
}
