import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/repaso_models.dart';

class RepasoRepository {
  const RepasoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Inicia una nueva sesión de repaso (genera 10 MCQ sobre temas débiles).
  Future<RepasoSesion> iniciarSesion() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.repasoSesiones,
      );
      return RepasoSesion.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Responde a una pregunta de la sesión.
  Future<RespuestaRepasoResult> responder({
    required int sesionId,
    required int preguntaIndex,
    required int respuestaUsuario,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.repasoSesionRespuestas(sesionId),
        data: {
          'preguntaIndex': preguntaIndex,
          'respuestaUsuario': respuestaUsuario,
        },
      );
      return RespuestaRepasoResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Obtiene el resultado completo de una sesión.
  Future<ResultadoSesionRepaso> obtenerResultado(int sesionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.repasoSesionResultado(sesionId),
      );
      return ResultadoSesionRepaso.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

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
      429 => RateLimitException(message),
      _ => ServerException(message, code),
    };
  }
}
