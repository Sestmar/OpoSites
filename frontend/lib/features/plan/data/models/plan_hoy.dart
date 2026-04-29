import 'package:json_annotation/json_annotation.dart';

import 'plan_tarea.dart';

part 'plan_hoy.g.dart';

/// Espejo de PlanHoyResponse.java.
///
/// Plan de estudio del día actual:
///   GET /api/v1/plan/hoy
///   POST /api/v1/plan/generar  (regenerar devuelve el mismo DTO)
///
/// [fecha] es "YYYY-MM-DD" (LocalDate Java).
/// [tareasCompletadas] y [totalTareas] permiten pintar la barra de progreso
/// del día sin recalcular sobre la lista.
@JsonSerializable(explicitToJson: true)
class PlanHoy {
  const PlanHoy({
    required this.fecha,
    required this.tareas,
    required this.tareasCompletadas,
    required this.totalTareas,
  });

  /// Fecha del plan: "YYYY-MM-DD".
  final String fecha;
  final List<PlanTarea> tareas;
  final int tareasCompletadas;
  final int totalTareas;

  factory PlanHoy.fromJson(Map<String, dynamic> json) =>
      _$PlanHoyFromJson(json);

  Map<String, dynamic> toJson() => _$PlanHoyToJson(this);
}
