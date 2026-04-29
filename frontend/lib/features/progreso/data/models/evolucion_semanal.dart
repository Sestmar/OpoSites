import 'package:json_annotation/json_annotation.dart';

part 'evolucion_semanal.g.dart';

/// Espejo de EvolucionSemanalDto.java.
///
/// Un punto de datos por semana para la gráfica de evolución:
///   GET /api/v1/progreso/evolucion?semanas={n}
///
/// [semana] tiene formato ISO "2026-W17" — úsalo como label en el eje X
/// de fl_chart. [notaMedia] va de 0.0 a 10.0.
@JsonSerializable()
class EvolucionSemanal {
  const EvolucionSemanal({
    required this.semana,
    required this.notaMedia,
    required this.testsCompletados,
  });

  /// Semana ISO: "2026-W17". Ordenados cronológicamente de menor a mayor.
  final String semana;
  final double notaMedia;
  final int testsCompletados;

  factory EvolucionSemanal.fromJson(Map<String, dynamic> json) =>
      _$EvolucionSemanalFromJson(json);

  Map<String, dynamic> toJson() => _$EvolucionSemanalToJson(this);
}
