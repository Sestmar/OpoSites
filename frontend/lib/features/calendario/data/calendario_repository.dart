import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/calendario_evento.dart';

/// Único punto de acceso a los endpoints /calendario/eventos/**.
///
///   GET    /api/v1/calendario/eventos          → [getEventos]
///   POST   /api/v1/calendario/eventos          → [crearEvento]
///   PUT    /api/v1/calendario/eventos/{id}     → [actualizarEvento]
///   DELETE /api/v1/calendario/eventos/{id}     → [eliminarEvento]
///
/// El JWT se adjunta automáticamente vía AuthInterceptor.
/// Las fechas [desde] / [hasta] deben pasarse en ISO 8601 sin zona horaria
/// (ej. "2026-04-01T00:00:00") — el servidor usa @DateTimeFormat(iso=DATE_TIME).
class CalendarioRepository {
  const CalendarioRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Endpoints ──────────────────────────────────────────────────────────────

  /// Devuelve todos los eventos en el rango [desde, hasta].
  ///
  /// [desde] y [hasta] deben ser ISO 8601 sin zona: "2026-04-01T00:00:00".
  /// [tipo] null = todos los tipos.
  /// null en [desde] / [hasta] = sin límite por ese extremo.
  Future<List<CalendarioEvento>> getEventos({
    String? desde,
    String? hasta,
    TipoEvento? tipo,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.eventos,
        queryParameters: {
          if (desde != null) 'desde': desde,
          if (hasta != null) 'hasta': hasta,
          if (tipo != null) 'tipo': tipo.name,
        },
      );
      return (response.data ?? [])
          .map((e) => CalendarioEvento.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Crea un nuevo evento manual y devuelve el evento creado con su [id] asignado.
  Future<CalendarioEvento> crearEvento(CreateEventoRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.eventos,
        data: request.toJson(),
      );
      return CalendarioEvento.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Actualiza los campos indicados del evento [id].
  ///
  /// Solo aplica a eventos con [autoGenerado] = false — el servidor devuelve
  /// 403 si se intenta editar un evento auto-generado.
  Future<CalendarioEvento> actualizarEvento(
    int id,
    UpdateEventoRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.eventoDetalle(id),
        data: request.toJson(),
      );
      return CalendarioEvento.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Elimina el evento [id].
  ///
  /// Solo aplica a eventos con [autoGenerado] = false — el servidor devuelve
  /// 403 si se intenta eliminar un evento auto-generado.
  /// Devuelve 204 No Content en caso de éxito.
  Future<void> eliminarEvento(int id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.eventoDetalle(id));
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
