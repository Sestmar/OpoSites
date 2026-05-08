import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';

/// Acceso a los endpoints de preguntas marcadas para repaso.
///
///   POST   /api/v1/preguntas/{id}/marcar   → [marcar]   (204 idempotente)
///   DELETE /api/v1/preguntas/{id}/marcar   → [desmarcar] (204 idempotente)
///   GET    /api/v1/preguntas/marcadas/conteo → [getConteo]
class PreguntaMarcadaRepository {
  const PreguntaMarcadaRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Marca la pregunta [preguntaId] para repaso. Idempotente.
  Future<void> marcar(int preguntaId) async {
    try {
      await _dio.post<void>(ApiEndpoints.preguntaMarcar(preguntaId));
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Desmarca la pregunta [preguntaId]. Idempotente.
  Future<void> desmarcar(int preguntaId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.preguntaMarcar(preguntaId));
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Total de preguntas marcadas del usuario.
  /// [ramaId] null = todas las ramas.
  Future<int> getConteo({int? ramaId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.preguntasMarcadasConteo,
        queryParameters: {
          if (ramaId != null) 'ramaId': ramaId,
        },
      );
      return (response.data!['total'] as num).toInt();
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
        ? (data['message'] as String? ?? data['error'] as String? ?? 'Error desconocido')
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
