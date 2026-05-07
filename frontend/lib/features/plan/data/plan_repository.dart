import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/plan_configuracion.dart';
import 'models/plan_hoy.dart';
import 'models/plan_tarea.dart';

/// Único punto de acceso a los endpoints de plan de estudio.
///
///   GET  /api/v1/plan/hoy                      → [getPlanHoy]
///   GET  /api/v1/plan/semana?desde=YYYY-MM-DD  → [getSemana]
///   GET  /api/v1/plan/configuracion            → [getConfiguracion]
///   PUT  /api/v1/plan/configuracion            → [actualizarConfiguracion]
///   POST /api/v1/plan/generar                  → [regenerarPlan]
///   PUT  /api/v1/plan/tarea/{tareaId}/completar → [completarTarea]
///
/// Todos los endpoints requieren JWT — se adjunta vía AuthInterceptor.
class PlanRepository {
  const PlanRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Endpoints ──────────────────────────────────────────────────────────────────

  /// Plan de estudio del día actual con lista de tareas y contadores.
  Future<PlanHoy> getPlanHoy() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.planHoy,
      );
      return PlanHoy.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Plan de 7 días a partir de [desde] (inclusive). Si [desde] es null, usa hoy.
  ///
  /// El backend garantiza que los 7 días están generados antes de responder.
  Future<List<PlanHoy>> getSemana({DateTime? desde}) async {
    try {
      final desdeStr = (desde ?? DateTime.now()).toIso8601String().substring(0, 10);
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.planSemana,
        queryParameters: {'desde': desdeStr},
      );
      return (response.data!)
          .map((e) => PlanHoy.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Configuración actual del plan: horasSemana, preferencia y fecha examen.
  Future<PlanConfiguracion> getConfiguracion() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.planConfiguracion,
      );
      return PlanConfiguracion.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Actualiza la configuración del plan y devuelve el estado resultante.
  ///
  /// Solo se envían los campos no-null de [request] al servidor.
  Future<PlanConfiguracion> actualizarConfiguracion(
    UpdatePlanConfiguracionRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.planConfiguracion,
        data: request.toJson(),
      );
      return PlanConfiguracion.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Crea una tarea manual. Si [fecha] es null, el backend usa el día actual.
  Future<PlanTarea> crearTarea({
    required TipoPlanTarea tipo,
    String? descripcion,
    DateTime? fecha,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.planTarea,
        data: {
          'tipo': tipo.name,
          if (descripcion != null && descripcion.isNotEmpty)
            'descripcion': descripcion,
          if (fecha != null)
            'fecha': fecha.toIso8601String().substring(0, 10),
        },
      );
      return PlanTarea.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Elimina una tarea del plan por ID.
  Future<void> eliminarTarea(int tareaId) async {
    try {
      await _dio.delete(ApiEndpoints.planTareaEliminar(tareaId));
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Regenera el plan de 7 días y devuelve el plan del día actual.
  ///
  /// No sobreescribe tareas ya completadas (garantía del backend).
  Future<PlanHoy> regenerarPlan() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.planGenerar,
      );
      return PlanHoy.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Marca una tarea como completada y devuelve la tarea actualizada.
  ///
  /// El backend valida que la tarea pertenezca al usuario autenticado.
  Future<PlanTarea> completarTarea(int tareaId) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.planTareaCompletar(tareaId),
      );
      return PlanTarea.fromJson(response.data!);
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
