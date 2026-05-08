import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/question_answer.dart';
import 'models/test_question.dart';
import 'models/test_result.dart';
import 'models/test_session.dart';

/// Único punto de acceso a los endpoints de tests libres.
///
///   POST /api/v1/tests/generar    → [generarTest]
///   POST /api/v1/tests/responder  → [responder]
///   GET  /api/v1/tests/fallos     → [getFallos]
///   GET  /api/v1/preguntas/{id}/respuesta → [getPreguntaRespuesta]
///
/// El JWT se adjunta automáticamente vía AuthInterceptor — no se gestiona aquí.
/// Todos los errores se convierten en [ApiException] para que los providers
/// hagan pattern matching limpio sin depender de Dio.
class TestsRepository {
  const TestsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Tests libres ───────────────────────────────────────────────────────────

  /// Genera un test libre y devuelve las preguntas sin respuestas.
  ///
  /// [temaIds] null o vacío = todas las preguntas de la rama.
  /// [dificultad] null = sin filtro (1–5).
  /// [tiempoMinutos] null = sin límite de tiempo.
  Future<TestSession> generarTest({
    required int ramaId,
    List<int>? temaIds,
    int cantidad = 10,
    int? dificultad,
    int? tiempoMinutos,
    bool soloMarcadas = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'ramaId': ramaId,
        'cantidad': cantidad,
        if (temaIds != null && temaIds.isNotEmpty) 'temaIds': temaIds,
        if (dificultad != null) 'dificultad': dificultad,
        if (tiempoMinutos != null) 'tiempoMinutos': tiempoMinutos,
        if (soloMarcadas) 'soloMarcadas': true,
      };
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.testsGenerar,
        data: body,
      );
      return TestSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Envía las respuestas del test y devuelve nota + detalle por pregunta.
  ///
  /// [respuestas] debe incluir una entrada por cada pregunta (incluso
  /// las omitidas, con [QuestionAnswer.respuestaUsuario] = null).
  Future<TestResult> responder({
    required int sessionId,
    required List<QuestionAnswer> respuestas,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.testsResponder,
        data: {
          'sessionId': sessionId,
          'respuestas': respuestas.map((r) => r.toJson()).toList(),
        },
      );
      return TestResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Lista las preguntas que el usuario ha fallado alguna vez.
  ///
  /// Filtros opcionales: [ramaId] y [temaId].
  /// Devuelve máximo 50 preguntas (paginación server-side fija).
  Future<List<TestQuestion>> getFallos({int? ramaId, int? temaId}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.testsFallos,
        queryParameters: {
          if (ramaId != null) 'ramaId': ramaId,
          if (temaId != null) 'temaId': temaId,
        },
      );
      return (response.data ?? [])
          .map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Devuelve la respuesta correcta y explicación de una pregunta.
  ///
  /// Llamar solo DESPUÉS de que el usuario haya completado un test
  /// (el backend no valida esto en la fase actual, pero es la intención).
  Future<QuestionAnswerDetail> getPreguntaRespuesta(int preguntaId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.preguntaRespuesta(preguntaId),
      );
      return QuestionAnswerDetail.fromJson(response.data!);
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

// ── Modelo inline para GET /preguntas/{id}/respuesta ──────────────────────────
//
// Se declara aquí porque solo TestsRepository y la UI de repaso lo necesitan.
// No justifica un archivo separado.

/// Espejo de PreguntaRespuestaResponse.java.
class QuestionAnswerDetail {
  const QuestionAnswerDetail({
    required this.preguntaId,
    required this.respuestaCorrecta,
    this.explicacion,
  });

  final int preguntaId;
  final String respuestaCorrecta;
  final String? explicacion;

  factory QuestionAnswerDetail.fromJson(Map<String, dynamic> json) =>
      QuestionAnswerDetail(
        preguntaId: json['preguntaId'] as int,
        respuestaCorrecta: json['respuestaCorrecta'] as String,
        explicacion: json['explicacion'] as String?,
      );
}
