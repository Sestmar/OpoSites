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

/// Mensaje local optimista — creado en cliente antes de recibir confirmación.
/// Usamos id negativo para distinguirlo de mensajes reales del servidor.
class ChatMensajeOptimista extends ChatMensaje {
  const ChatMensajeOptimista({required super.mensaje})
      : super(
          id: -1,
          esIa: false,
          createdAt: _epoch,
        );

  // Valor placeholder — se reemplaza al construir el widget con DateTime.now()
  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
}
