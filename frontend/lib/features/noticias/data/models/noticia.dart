import 'package:json_annotation/json_annotation.dart';

import 'noticia_resumen.dart';

part 'noticia.g.dart';

/// Espejo de NoticiaResponse.java.
///
/// Detalle completo de una noticia/convocatoria:
///   GET /api/v1/noticias/{id}
///
/// [contenido] puede ser null si la noticia solo tiene [urlExterna].
/// [urlExterna] es un enlace externo a la fuente oficial (BOE, etc.).
/// [leida] se actualiza en el estado local tras llamar a
/// [NoticiasRepository.marcarLeida] — no hace falta recargar del servidor.
@JsonSerializable()
class Noticia {
  const Noticia({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.fechaPublicacion,
    required this.leida,
    this.contenido,
    this.urlExterna,
    this.ramaId,
    this.nombreRama,
  });

  final int id;
  final String titulo;
  final TipoNoticia tipo;
  final String? contenido;
  final String? urlExterna;
  final int? ramaId;
  final String? nombreRama;

  /// Fecha de publicación: "dd/MM/yyyy HH:mm".
  final String fechaPublicacion;
  final bool leida;

  factory Noticia.fromJson(Map<String, dynamic> json) =>
      _$NoticiaFromJson(json);

  Map<String, dynamic> toJson() => _$NoticiaToJson(this);

  /// Crea una copia con [leida] actualizado.
  ///
  /// Usado por [NoticiaDetalleNotifier.marcarLeida] para actualizar el estado
  /// local sin relanzar una petición GET al servidor.
  Noticia copyWithLeida(bool leida) => Noticia(
        id: id,
        titulo: titulo,
        tipo: tipo,
        fechaPublicacion: fechaPublicacion,
        leida: leida,
        contenido: contenido,
        urlExterna: urlExterna,
        ramaId: ramaId,
        nombreRama: nombreRama,
      );
}
