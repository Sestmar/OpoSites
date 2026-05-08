import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import 'models/ingestion_result.dart';
import 'models/noticia_borrador.dart';

class AdminRepository {
  const AdminRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Dispara una ingesta manual de noticias desde todas las fuentes activas.
  /// Timeout elevado (120s) porque la operación llama a feeds RSS externos
  /// y puede tardar más que el receiveTimeout general de la app.
  Future<IngestionResult> ejecutarIngesta() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.adminNoticiasIngesta,
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    return IngestionResult.fromJson(response.data!);
  }

  /// Lista noticias en estado BORRADOR pendientes de revisión.
  /// Devuelve los ítems de la página y el total de borradores en la BD.
  Future<({List<NoticiaBorrador> items, int total})> listarBorradores({int page = 0}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminNoticiasBorradores,
      queryParameters: {'page': page, 'size': 30},
    );
    final data = response.data!;
    final content = data['content'] as List<dynamic>;
    return (
      items: content
          .map((e) => NoticiaBorrador.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['totalElements'] as int,
    );
  }

  /// Elimina una noticia permanentemente (cualquier estado editorial).
  Future<void> eliminar(int id) async {
    await _dio.delete<void>(ApiEndpoints.adminNoticiaEliminar(id));
  }

  /// Publica un borrador — quedará visible para los usuarios.
  Future<void> publicar(int id) => _actualizarEstado(id, 'PUBLICADA');

  /// Rechaza un borrador — no será visible para los usuarios.
  Future<void> rechazar(int id) => _actualizarEstado(id, 'RECHAZADA');

  Future<void> _actualizarEstado(int id, String estado) async {
    await _dio.patch<void>(
      ApiEndpoints.adminNoticiaEstado(id),
      data: {'estadoEditorial': estado},
    );
  }
}
