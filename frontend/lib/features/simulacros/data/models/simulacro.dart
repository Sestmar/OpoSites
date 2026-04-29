import 'package:json_annotation/json_annotation.dart';

part 'simulacro.g.dart';

/// Espejo de SimulacroResponse.java.
///
/// Devuelto por:
///   - GET /api/v1/oposiciones/{ramaId}/simulacros  (lista)
///   - GET /api/v1/simulacros/{id}                  (detalle)
///
/// [fechaOficial] es null si no es un simulacro de convocatoria oficial.
/// Se serializa como String "YYYY-MM-DD" (Java LocalDate → JSON).
@JsonSerializable()
class Simulacro {
  const Simulacro({
    required this.id,
    required this.ramaId,
    required this.nombre,
    required this.duracionMinutos,
    required this.preguntasCount,
    required this.temasIncluidos,
    this.fechaOficial,
  });

  final int id;
  final int ramaId;
  final String nombre;
  final int duracionMinutos;
  final int preguntasCount;
  final List<int> temasIncluidos;

  /// Fecha en formato "YYYY-MM-DD". Parsear con [DateTime.parse] si se necesita.
  final String? fechaOficial;

  factory Simulacro.fromJson(Map<String, dynamic> json) =>
      _$SimulacroFromJson(json);

  Map<String, dynamic> toJson() => _$SimulacroToJson(this);
}
