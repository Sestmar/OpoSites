import 'package:json_annotation/json_annotation.dart';

part 'racha.g.dart';

/// Espejo de RachaResponse.java.
///
/// Racha de estudio del usuario:
///   GET /api/v1/progreso/racha
///
/// [ultimoEstudio] es un String? "YYYY-MM-DD" (LocalDate Java serializado por
/// Jackson). null si el usuario nunca ha completado un test o simulacro.
@JsonSerializable()
class Racha {
  const Racha({
    required this.rachaActual,
    required this.mejorRacha,
    this.ultimoEstudio,
  });

  final int rachaActual;
  final int mejorRacha;

  /// Fecha ISO "YYYY-MM-DD" del último día con actividad registrada.
  final String? ultimoEstudio;

  factory Racha.fromJson(Map<String, dynamic> json) => _$RachaFromJson(json);

  Map<String, dynamic> toJson() => _$RachaToJson(this);
}
