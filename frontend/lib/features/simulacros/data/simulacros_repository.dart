import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../tests/data/models/question_answer.dart';
import '../../tests/data/models/test_session.dart';
import 'models/simulacro.dart';
import 'models/simulacro_result.dart';

/// Único punto de acceso a los endpoints de simulacros.
///
///   GET  /api/v1/oposiciones/{ramaId}/simulacros → [getSimulacrosByRama]
///   GET  /api/v1/simulacros/{id}                 → [getSimulacro]
///   POST /api/v1/simulacros/{id}/iniciar         → [iniciar]
///   POST /api/v1/simulacros/{id}/entregar        → [entregar]
///
/// Reutiliza [TestSession] y [SimulacroResult] (≡ [TestResult]) porque el
/// backend usa la misma estructura para tests libres y simulacros.
class SimulacrosRepository {
  const SimulacrosRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Consultas ──────────────────────────────────────────────────────────────

  /// Lista los simulacros disponibles para una rama.
  Future<List<Simulacro>> getSimulacrosByRama(int ramaId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.oposicionSimulacros(ramaId),
      );
      return (response.data ?? [])
          .map((e) => Simulacro.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Devuelve el detalle de un simulacro (nombre, duración, temas incluidos).
  Future<Simulacro> getSimulacro(int simulacroId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.simulacroDetalle(simulacroId),
      );
      return Simulacro.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Flujo activo ───────────────────────────────────────────────────────────

  /// Inicia el simulacro y devuelve las preguntas + sessionId + tiempo.
  ///
  /// Una vez iniciado, el temporizador comienza en el cliente.
  /// El backend registra [fecha_inicio] en la sesión.
  Future<TestSession> iniciar(int simulacroId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.simulacroIniciar(simulacroId),
      );
      return TestSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Entrega las respuestas del simulacro y devuelve nota + análisis por tema.
  ///
  /// [respuestas] debe incluir una entrada por cada pregunta del simulacro,
  /// incluso las omitidas (con [QuestionAnswer.respuestaUsuario] = null).
  ///
  /// El backend crea automáticamente un evento de calendario tipo SIMULACRO.
  Future<SimulacroResult> entregar({
    required int simulacroId,
    required int sessionId,
    required List<QuestionAnswer> respuestas,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.simulacroEntregar(simulacroId),
        data: {
          'sessionId': sessionId,
          'respuestas': respuestas.map((r) => r.toJson()).toList(),
        },
      );
      return SimulacroResult.fromJson(response.data!);
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
