import 'package:json_annotation/json_annotation.dart';

part 'noticia_resumen.g.dart';

// ── Enum ───────────────────────────────────────────────────────────────────────

/// Espejo de TipoNoticia.java.
///
/// - CONVOCATORIA → nueva convocatoria oficial publicada.
/// - CAMBIO       → modificación en temario, fechas u otros datos oficiales.
/// - NOTICIA      → actualidad general del sector de la oposición.
@JsonEnum()
enum TipoNoticia { convocatoria, cambio, noticia }

// ── Modelo de lista ────────────────────────────────────────────────────────────

/// Espejo de NoticiaResumenResponse.java.
///
/// Ítem de la lista paginada:
///   GET /api/v1/noticias?tipo=&ramaId=&page=&size=
///
/// [fechaPublicacion] viene del servidor como "dd/MM/yyyy HH:mm".
/// [leida] refleja el estado de lectura del usuario autenticado.
@JsonSerializable()
class NoticiaResumen {
  const NoticiaResumen({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.fechaPublicacion,
    required this.leida,
    this.ramaId,
    this.nombreRama,
  });

  final int id;
  final String titulo;
  final TipoNoticia tipo;
  final int? ramaId;
  final String? nombreRama;

  /// Fecha de publicación: "dd/MM/yyyy HH:mm".
  final String fechaPublicacion;
  final bool leida;

  factory NoticiaResumen.fromJson(Map<String, dynamic> json) =>
      _$NoticiaResumenFromJson(json);

  Map<String, dynamic> toJson() => _$NoticiaResumenToJson(this);
}

// ── Wrapper de paginación Spring ───────────────────────────────────────────────

/// Espejo parcial de la respuesta Page<NoticiaResumenResponse> de Spring.
///
/// Solo se mapean los campos que usa la UI:
///   - [content]       → lista de ítems de la página actual.
///   - [number]        → índice de la página actual (0-based).
///   - [last]          → true si es la última página (para detener scroll infinito).
///   - [totalElements] → total de noticias (útil para mostrar contador).
///
/// No usa json_annotation porque el parsing del contenido anidado se hace
/// de forma manual para mantener este modelo simple.
class NoticiasPage {
  const NoticiasPage({
    required this.content,
    required this.number,
    required this.last,
    required this.totalElements,
  });

  final List<NoticiaResumen> content;

  /// Índice de la página actual (0-based).
  final int number;

  /// true cuando no hay más páginas después de esta.
  final bool last;

  final int totalElements;

  factory NoticiasPage.fromJson(Map<String, dynamic> json) => NoticiasPage(
        content: (json['content'] as List<dynamic>)
            .map((e) => NoticiaResumen.fromJson(e as Map<String, dynamic>))
            .toList(),
        number: json['number'] as int,
        last: json['last'] as bool,
        totalElements: json['totalElements'] as int,
      );
}
