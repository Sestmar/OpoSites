import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/api_endpoints.dart';
import 'models/documento.dart';
import 'models/material_generado.dart';

/// Único punto de acceso a los endpoints /documentos/**.
///
///   POST   /api/v1/documentos/upload          → [subirDocumento]
///   GET    /api/v1/documentos                 → [getDocumentos]
///   DELETE /api/v1/documentos/{id}            → [eliminarDocumento]
///   POST   /api/v1/documentos/{id}/generar    → [generarMaterial]
///   GET    /api/v1/documentos/{id}/materiales → [getMateriales]
///
/// El JWT se adjunta automáticamente vía AuthInterceptor.
class DocumentoRepository {
  const DocumentoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ── Endpoints ──────────────────────────────────────────────────────────────

  Future<Documento> subirDocumento({
    required Uint8List bytes,
    required String nombre,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: nombre),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.documentosUpload,
        data: formData,
      );
      return Documento.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<List<Documento>> getDocumentos() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.documentos);
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(Documento.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> eliminarDocumento(int id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.documentoEliminar(id));
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<MaterialGenerado> generarMaterial({
    required int documentoId,
    required TipoMaterial tipo,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.documentoGenerar(documentoId),
        data: {'tipo': tipoMaterialToJson(tipo)},
      );
      return MaterialGenerado.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<List<MaterialGenerado>> getMateriales(int documentoId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.documentoMateriales(documentoId),
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(MaterialGenerado.fromJson)
          .toList();
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
