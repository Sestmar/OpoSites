import 'package:json_annotation/json_annotation.dart';

part 'plan_configuracion.g.dart';

// ── Enum ───────────────────────────────────────────────────────────────────────

/// Espejo de PreferenciaPlan.java.
///
/// - TEORIA → el plan prioriza tareas de tipo REPASO.
/// - TEST   → el plan prioriza tareas de tipo TEST.
/// - MIXTO  → el plan alterna TEST y REPASO (con SIMULACRO si el examen es
///            próximo — ≤ 30 días).
@JsonEnum()
enum PreferenciaPlan { teoria, test, mixto }

// ── Respuesta ──────────────────────────────────────────────────────────────────

/// Espejo de PlanConfiguracionResponse.java.
///
/// Configuración del plan de estudio del usuario:
///   GET /api/v1/plan/configuracion
///   PUT /api/v1/plan/configuracion  (devuelve el mismo DTO actualizado)
///
/// [fechaExamenObjetivo] es "YYYY-MM-DD" o null si el usuario no la configuró.
/// [diasHastaExamen] es null si no hay [fechaExamenObjetivo].
@JsonSerializable()
class PlanConfiguracion {
  const PlanConfiguracion({
    required this.horasSemana,
    required this.preferencia,
    this.fechaExamenObjetivo,
    this.diasHastaExamen,
    this.diasDisponibles,
  });

  final int horasSemana;
  final PreferenciaPlan preferencia;

  /// Fecha objetivo del examen: "YYYY-MM-DD" o null.
  final String? fechaExamenObjetivo;

  /// Días hasta el examen calculados por el backend. null si no hay fecha.
  final int? diasHastaExamen;

  /// Días disponibles para estudiar: clave = "MONDAY"…"SUNDAY", valor = horas (1–8).
  /// null = sin restricción (usuarios sin configurar).
  final Map<String, int>? diasDisponibles;

  factory PlanConfiguracion.fromJson(Map<String, dynamic> json) =>
      _$PlanConfiguracionFromJson(json);

  Map<String, dynamic> toJson() => _$PlanConfiguracionToJson(this);
}

// ── Request ────────────────────────────────────────────────────────────────────

/// Espejo de UpdatePlanConfiguracionRequest.java.
///
/// Todos los campos son opcionales — solo se envían los que cambian.
/// [includeIfNull: false] elimina los null del JSON de salida para que el
/// backend no sobreescriba campos que el usuario no tocó.
///
/// [fechaExamenObjetivo] se envía como "YYYY-MM-DD" (Jackson lo deserializa
/// a LocalDate en el servidor).
@JsonSerializable(includeIfNull: false)
class UpdatePlanConfiguracionRequest {
  const UpdatePlanConfiguracionRequest({
    this.horasSemana,
    this.preferencia,
    this.fechaExamenObjetivo,
    this.diasDisponibles,
  });

  final int? horasSemana;
  final PreferenciaPlan? preferencia;

  /// Fecha en formato "YYYY-MM-DD". null = no modificar.
  final String? fechaExamenObjetivo;

  /// Días disponibles. null = no modificar. Mapa vacío = quitar restricciones.
  final Map<String, int>? diasDisponibles;

  Map<String, dynamic> toJson() => _$UpdatePlanConfiguracionRequestToJson(this);
}
