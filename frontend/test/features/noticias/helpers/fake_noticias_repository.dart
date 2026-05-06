import 'package:dio/dio.dart';
import 'package:oposites/core/api/api_exception.dart';
import 'package:oposites/features/noticias/data/models/noticia.dart';
import 'package:oposites/features/noticias/data/models/noticia_resumen.dart';
import 'package:oposites/features/noticias/data/noticias_repository.dart';

class FakeNoticiasRepository extends NoticiasRepository {
  FakeNoticiasRepository({
    this.pageBuilder,
    this.detalleBuilder,
    this.onGetNoticias,
    this.error,
  }) : super(dio: Dio());

  final NoticiasPage Function({
    TipoNoticia? tipo,
    int? ramaId,
    int page,
    int size,
  })? pageBuilder;
  final Noticia Function(int id)? detalleBuilder;
  final void Function({
    TipoNoticia? tipo,
    int? ramaId,
    int page,
    int size,
  })? onGetNoticias;
  final ApiException? error;

  int getNoticiasCalls = 0;

  @override
  Future<NoticiasPage> getNoticias({
    TipoNoticia? tipo,
    int? ramaId,
    int page = 0,
    int size = 20,
  }) async {
    getNoticiasCalls++;
    onGetNoticias?.call(tipo: tipo, ramaId: ramaId, page: page, size: size);
    if (error != null) throw error!;

    if (pageBuilder != null) {
      return pageBuilder!(tipo: tipo, ramaId: ramaId, page: page, size: size);
    }

    return NoticiasPage(
      content: const [],
      number: page,
      last: true,
      totalElements: 0,
    );
  }

  @override
  Future<Noticia> getDetalle(int id) async {
    if (detalleBuilder != null) return detalleBuilder!(id);
    return Noticia(
      id: id,
      titulo: 'Detalle $id',
      tipo: TipoNoticia.noticia,
      fechaPublicacion: '01/01/2026 10:00',
      leida: false,
      contenido: 'Contenido',
      urlExterna: null,
      ramaId: null,
      nombreRama: null,
    );
  }

  @override
  Future<void> marcarLeida(int id) async {}
}
