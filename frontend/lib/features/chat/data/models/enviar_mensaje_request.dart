import 'package:json_annotation/json_annotation.dart';

part 'enviar_mensaje_request.g.dart';

/// Body de POST /chat/conversaciones/{id}/mensajes.
/// El backend espera el campo "mensaje" (no "contenido").
@JsonSerializable()
class EnviarMensajeRequest {
  const EnviarMensajeRequest({required this.mensaje});

  final String mensaje;

  Map<String, dynamic> toJson() => _$EnviarMensajeRequestToJson(this);

  factory EnviarMensajeRequest.fromJson(Map<String, dynamic> json) =>
      _$EnviarMensajeRequestFromJson(json);
}
