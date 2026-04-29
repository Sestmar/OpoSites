import 'package:json_annotation/json_annotation.dart';

part 'progreso_tema.g.dart';

/// Espejo de ProgresoTemaResponse.java.
///
/// Estadísticas de un tema específico del usuario:
///   GET /api/v1/progreso/temas?ramaId={id}
///
/// La UI de F3.3 muestra esta lista con una barra de progreso por tema
/// calculada como [correctas] / [totalRespondidas].
@JsonSerializable()
class ProgresoTema {
  const ProgresoTema({
    required this.temaId,
    required this.nombre,
    required this.totalRespondidas,
    required this.correctas,
    required this.porcentajeAcierto,
  });

  final int temaId;
  final String nombre;
  final int totalRespondidas;
  final int correctas;
  final double porcentajeAcierto;

  factory ProgresoTema.fromJson(Map<String, dynamic> json) =>
      _$ProgresoTemaFromJson(json);

  Map<String, dynamic> toJson() => _$ProgresoTemaToJson(this);
}
