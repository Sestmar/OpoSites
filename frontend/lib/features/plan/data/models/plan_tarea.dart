import 'package:json_annotation/json_annotation.dart';

part 'plan_tarea.g.dart';

// ── Enum ───────────────────────────────────────────────────────────────────────

/// Espejo de TipoPlanTarea.java.
///
/// - TEST      → sesión de preguntas de un tema concreto.
/// - REPASO    → revisión teórica del tema (sin preguntas activas).
/// - SIMULACRO → simulacro oficial de la oposición.
@JsonEnum()
enum TipoPlanTarea { test, repaso, simulacro }

// ── Modelo ─────────────────────────────────────────────────────────────────────

/// Espejo de PlanTareaResponse.java.
///
/// Tarea diaria del plan de estudio del usuario.
///
/// Invariantes según el tipo:
///   - TEST      → [temaId] y [nombreTema] presentes; [simulacroId] null.
///   - REPASO    → [temaId] y [nombreTema] presentes; [simulacroId] null.
///   - SIMULACRO → [simulacroId] y [nombreSimulacro] presentes; [temaId] null.
///
/// [descripcion] es generada en el backend (no persistida en BD) — puede ser
/// null en versiones antiguas del servidor; la UI debe tener fallback.
/// [fecha] es "YYYY-MM-DD" (LocalDate Java).
@JsonSerializable()
class PlanTarea {
  const PlanTarea({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.completada,
    required this.manual,
    this.temaId,
    this.nombreTema,
    this.simulacroId,
    this.nombreSimulacro,
    this.descripcion,
  });

  final int id;
  final TipoPlanTarea tipo;
  final int? temaId;
  final String? nombreTema;
  final int? simulacroId;
  final String? nombreSimulacro;

  /// Fecha de la tarea: "YYYY-MM-DD".
  final String fecha;
  final bool completada;

  /// Descripción generada en el backend. Ejemplo: "TEST · Derecho Penal".
  final String? descripcion;

  /// True cuando la tarea fue creada manualmente por el usuario.
  @JsonKey(defaultValue: false)
  final bool manual;

  factory PlanTarea.fromJson(Map<String, dynamic> json) =>
      _$PlanTareaFromJson(json);

  Map<String, dynamic> toJson() => _$PlanTareaToJson(this);
}
