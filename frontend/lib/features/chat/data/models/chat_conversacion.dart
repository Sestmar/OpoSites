import 'conversacion_resumen.dart';
import 'chat_mensaje.dart';

/// Conversación completa con su lista de mensajes.
///
/// El backend no tiene un endpoint GET /conversaciones/{id} que devuelva
/// mensajes embebidos — se construye combinando ConversacionResumen
/// + GET /conversaciones/{id}/mensajes.
class ChatConversacion {
  const ChatConversacion({
    required this.id,
    this.nombreRama,
    this.fechaExamen,
    required this.temasDebiles,
    required this.createdAt,
    required this.mensajes,
  });

  final int id;
  final String? nombreRama;
  final String? fechaExamen;
  final List<String> temasDebiles;
  final DateTime createdAt;
  final List<ChatMensaje> mensajes;

  factory ChatConversacion.fromResumen(
    ConversacionResumen resumen,
    List<ChatMensaje> mensajes,
  ) =>
      ChatConversacion(
        id: resumen.id,
        nombreRama: resumen.nombreRama,
        fechaExamen: resumen.fechaExamen,
        temasDebiles: resumen.temasDebiles,
        createdAt: resumen.createdAt,
        mensajes: mensajes,
      );

  ChatConversacion copyWith({List<ChatMensaje>? mensajes}) => ChatConversacion(
        id: id,
        nombreRama: nombreRama,
        fechaExamen: fechaExamen,
        temasDebiles: temasDebiles,
        createdAt: createdAt,
        mensajes: mensajes ?? this.mensajes,
      );

  String get tituloDisplay =>
      nombreRama != null ? 'Chat — $nombreRama' : 'Nueva conversación';
}
