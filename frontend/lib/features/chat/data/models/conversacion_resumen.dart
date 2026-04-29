import 'package:json_annotation/json_annotation.dart';

part 'conversacion_resumen.g.dart';

/// Mapa de ConversacionResponse del backend.
/// Campos: id, nombreRama, fechaExamen, temasDebiles, createdAt.
@JsonSerializable()
class ConversacionResumen {
  const ConversacionResumen({
    required this.id,
    this.nombreRama,
    this.fechaExamen,
    required this.temasDebiles,
    required this.createdAt,
  });

  final int id;
  final String? nombreRama;
  final String? fechaExamen;
  final List<String> temasDebiles;
  final DateTime createdAt;

  factory ConversacionResumen.fromJson(Map<String, dynamic> json) =>
      _$ConversacionResumenFromJson(json);

  Map<String, dynamic> toJson() => _$ConversacionResumenToJson(this);

  /// Genera un título legible para mostrar en la lista.
  String get tituloDisplay =>
      nombreRama != null ? 'Chat — $nombreRama' : 'Nueva conversación';
}
