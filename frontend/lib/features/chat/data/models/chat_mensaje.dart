import 'package:json_annotation/json_annotation.dart';

part 'chat_mensaje.g.dart';

/// Mapa de MensajeResponse del backend.
/// [esIa] true → mensaje de la IA, false → mensaje del usuario.
@JsonSerializable()
class ChatMensaje {
  const ChatMensaje({
    required this.id,
    required this.esIa,
    required this.mensaje,
    required this.createdAt,
  });

  final int id;
  final bool esIa;
  final String mensaje;
  final DateTime createdAt;

  factory ChatMensaje.fromJson(Map<String, dynamic> json) =>
      _$ChatMensajeFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMensajeToJson(this);
}

