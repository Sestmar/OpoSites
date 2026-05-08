/// Noticia en estado BORRADOR pendiente de revisión editorial.
/// Subconjunto de NoticiaResponse — solo los campos necesarios para el panel admin.
class NoticiaBorrador {
  const NoticiaBorrador({
    required this.id,
    required this.titulo,
    required this.fechaPublicacion,
    required this.estadoEditorial,
    this.contenido,
    this.urlExterna,
    this.nombreRama,
  });

  final int id;
  final String titulo;
  final String fechaPublicacion;
  final String estadoEditorial;
  final String? contenido;
  final String? urlExterna;
  final String? nombreRama;

  factory NoticiaBorrador.fromJson(Map<String, dynamic> json) =>
      NoticiaBorrador(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        fechaPublicacion: json['fechaPublicacion'] as String,
        estadoEditorial: json['estadoEditorial'] as String,
        contenido: json['contenido'] as String?,
        urlExterna: json['urlExterna'] as String?,
        nombreRama: json['nombreRama'] as String?,
      );
}
