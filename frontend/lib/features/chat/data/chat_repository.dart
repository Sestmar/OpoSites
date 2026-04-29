import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/chat_mensaje.dart';
import 'models/conversacion_resumen.dart';
import 'models/enviar_mensaje_request.dart';

/// Único punto de acceso a los endpoints /chat/**.
///
///   GET    /api/v1/chat/conversaciones              → [getConversaciones]
///   POST   /api/v1/chat/conversaciones              → [crearConversacion]
///   GET    /api/v1/chat/conversaciones/{id}/mensajes → [getMensajes]
///   POST   /api/v1/chat/conversaciones/{id}/mensajes → [enviarMensaje]
///   DELETE /api/v1/chat/conversaciones/{id}          → [eliminarConversacion]
///
/// El JWT se adjunta automáticamente vía AuthInterceptor.
/// Todos los DioException se convierten en [ApiException].
class ChatRepository {
  const ChatRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Endpoints ──────────────────────────────────────────────────────────────

  /// Lista de conversaciones del usuario autenticado.
  Future<List<ConversacionResumen>> getConversaciones() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.conversaciones,
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(ConversacionResumen.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Crea una nueva conversación vacía y devuelve su resumen.
  ///
  /// El backend inicializa el contexto con la rama y temas débiles del usuario.
  Future<ConversacionResumen> crearConversacion() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.conversaciones,
      );
      return ConversacionResumen.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Historial de mensajes de una conversación.
  Future<List<ChatMensaje>> getMensajes(int conversacionId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.conversacionMensajes(conversacionId),
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(ChatMensaje.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Envía un mensaje del usuario y devuelve la respuesta de la IA.
  ///
  /// El backend devuelve solo el mensaje de la IA (EnviarMensajeResponse):
  /// { id, mensaje, createdAt }. Lo convertimos a [ChatMensaje] con esIa=true.
  Future<ChatMensaje> enviarMensaje({
    required int conversacionId,
    required EnviarMensajeRequest request,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.conversacionMensajes(conversacionId),
        data: request.toJson(),
      );
      final data = response.data!;
      // EnviarMensajeResponse no incluye esIa — la IA siempre es true aquí.
      return ChatMensaje(
        id: data['id'] as int,
        esIa: true,
        mensaje: data['mensaje'] as String,
        createdAt: DateTime.parse(data['createdAt'] as String),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Elimina una conversación. El backend devuelve 204 No Content.
  Future<void> eliminarConversacion(int conversacionId) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.conversacionDetalle(conversacionId),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  ApiException _toApiException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const RequestTimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final code = e.response?.statusCode;
    final data = e.response?.data;
    final message = (data is Map)
        ? (data['message'] as String? ??
            data['error'] as String? ??
            'Error desconocido')
        : 'Error desconocido';

    return switch (code) {
      400 => ValidationException(message),
      401 => const UnauthorizedException(),
      403 => const ForbiddenException(),
      404 => NotFoundException(message),
      _ => ServerException(message, code),
    };
  }
}
