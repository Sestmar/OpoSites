import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/noticia.dart';
import 'models/noticia_conteos.dart';
import 'models/noticia_resumen.dart';

/// Único punto de acceso a los endpoints /noticias/**.
///
///   GET  /api/v1/noticias             → [getNoticias]  (Page paginado)
///   GET  /api/v1/noticias/{id}        → [getDetalle]
///   POST /api/v1/noticias/{id}/leer   → [marcarLeida]  (204 No Content)
///
/// El JWT se adjunta automáticamente vía AuthInterceptor.
/// Todos los DioException se convierten en [ApiException].
class NoticiasRepository {
  const NoticiasRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Endpoints ──────────────────────────────────────────────────────────────

  /// Devuelve una página de noticias/convocatorias.
  ///
  /// Filtros opcionales:
  ///   - [tipo]    → filtra por tipo de noticia (CONVOCATORIA, CAMBIO, NOTICIA).
  ///   - [ramaId]  → filtra por oposición (null = todas las ramas).
  ///   - [page]    → página a cargar (0-based, default 0).
  ///   - [size]    → tamaño de página (default 20).
  Future<NoticiasPage> getNoticias({
    TipoNoticia? tipo,
    int? ramaId,
    String? q,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.noticias,
        queryParameters: {
          'page': page,
          'size': size,
          if (tipo != null) 'tipo': tipo.name.toUpperCase(),
          if (ramaId != null) 'ramaId': ramaId,
          if (q != null && q.isNotEmpty) 'q': q,
        },
      );
      return NoticiasPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Devuelve el detalle completo de una noticia.
  ///
  /// El backend registra la visita pero no marca como leída automáticamente —
  /// para marcar como leída usar [marcarLeida].
  Future<Noticia> getDetalle(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.noticiaDetalle(id),
      );
      return Noticia.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Devuelve los conteos globales de noticias por tipo para la rama del usuario.
  /// Se llama una sola vez al entrar en la pantalla de Noticias.
  Future<NoticiaConteos> getConteos({int? ramaId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.noticiaConteos,
        queryParameters: {
          if (ramaId != null) 'ramaId': ramaId,
        },
      );
      return NoticiaConteos.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Marca la noticia [id] como leída para el usuario autenticado.
  ///
  /// El servidor devuelve 204 No Content — idempotente: llamar varias veces
  /// no produce error aunque ya estuviera marcada como leída.
  Future<void> marcarLeida(int id) async {
    try {
      await _dio.post<void>(ApiEndpoints.noticiaLeer(id));
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Marca como leídas todas las noticias visibles para el usuario según [ramaId].
  /// null = solo globales; valor = rama + globales.
  Future<void> marcarTodasLeidas({int? ramaId}) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.noticiaLeerTodas,
        queryParameters: {if (ramaId != null) 'ramaId': ramaId},
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
