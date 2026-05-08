import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/evolucion_semanal.dart';
import 'models/evolucion_tema_semanal.dart';
import 'models/progreso_resumen.dart';
import 'models/progreso_tema.dart';
import 'models/racha.dart';

/// Único punto de acceso a los endpoints de progreso.
///
///   GET /api/v1/progreso/resumen    → [getResumen]
///   GET /api/v1/progreso/temas      → [getTemas]
///   GET /api/v1/progreso/evolucion  → [getEvolucion]
///   GET /api/v1/progreso/racha      → [getRacha]
///
/// Todos los endpoints requieren JWT — se adjunta vía AuthInterceptor.
/// Todos los errores se convierten en [ApiException] para pattern matching limpio.
class ProgresoRepository {
  const ProgresoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Endpoints ──────────────────────────────────────────────────────────────────

  /// Resumen global: totales, porcentaje de aciertos y temas débiles.
  ///
  /// [ramaId] opcional — sin filtro devuelve el resumen de todas las ramas.
  Future<ProgresoResumen> getResumen({int? ramaId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.progresoResumen,
        queryParameters: {
          if (ramaId != null) 'ramaId': ramaId,
        },
      );
      return ProgresoResumen.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Lista de estadísticas desglosadas por tema.
  ///
  /// [ramaId] opcional — sin filtro devuelve todos los temas practicados.
  /// Solo aparecen temas con al menos una pregunta respondida.
  Future<List<ProgresoTema>> getTemas({int? ramaId}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.progresoTemas,
        queryParameters: {
          if (ramaId != null) 'ramaId': ramaId,
        },
      );
      return (response.data ?? [])
          .map((e) => ProgresoTema.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Evolución semanal de nota media y tests completados.
  ///
  /// [semanas] por defecto 12 (coincide con el default del backend).
  /// La lista viene ordenada cronológicamente — úsala directamente como
  /// fuente de datos para fl_chart (índice = posición en eje X).
  Future<List<EvolucionSemanal>> getEvolucion({int semanas = 12}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.progresoEvolucion,
        queryParameters: {'semanas': semanas},
      );
      return (response.data ?? [])
          .map((e) => EvolucionSemanal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Evolución semanal de % acierto para un tema concreto.
  ///
  /// [temaId] obligatorio. [semanas] por defecto 4 (último mes).
  /// La lista viene ordenada cronológicamente — úsala directamente como
  /// fuente de [FlSpot] para fl_chart (índice = posición en eje X).
  Future<List<EvolucionTemaSemanal>> getEvolucionTema({
    required int temaId,
    int semanas = 4,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.progresoEvolucionTema,
        queryParameters: {'temaId': temaId, 'semanas': semanas},
      );
      return (response.data ?? [])
          .map((e) =>
              EvolucionTemaSemanal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Racha actual, mejor racha y fecha del último estudio.
  Future<Racha> getRacha() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.progresoRacha,
      );
      return Racha.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────────

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
