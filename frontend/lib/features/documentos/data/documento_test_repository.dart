import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/documento_test.dart';

// Opciones que aceptan 404 como respuesta válida (sin lanzar DioException),
// para poder distinguir "no existe" de otros errores del servidor.
final _noThrowOn404 = Options(
  validateStatus: (status) => status != null && status < 500,
);

/// Acceso a los endpoints /documentos/{id}/test/**.
class DocumentoTestRepository {
  const DocumentoTestRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// POST /documentos/{id}/test/generar — genera un nuevo test MCQ.
  Future<DocumentoTest> generarTest(int documentoId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.documentoTestGenerar(documentoId),
      );
      return DocumentoTest.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// GET /documentos/{id}/test/ultimo — devuelve el último test o null si no existe.
  ///
  /// Usa validateStatus para que Dio no lance excepción en 404 —
  /// así evitamos que `receiveDataWhenStatusError` entregue el error body
  /// al path de éxito antes de que DioException pueda ser capturado.
  Future<DocumentoTest?> obtenerUltimo(int documentoId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.documentoTestUltimo(documentoId),
        options: _noThrowOn404,
      );
      if (response.statusCode == 404) return null;
      return DocumentoTest.fromJson(response.data!);
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
      422 => ValidationException(message),
      _ => ServerException(message, code),
    };
  }
}
