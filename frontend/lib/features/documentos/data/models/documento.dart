class Documento {
  const Documento({
    required this.id,
    required this.nombre,
    required this.tipoArchivo,
    required this.tamanoBytes,
    required this.textoDisponible,
    required this.creadoEn,
  });

  final int id;
  final String nombre;

  /// "PDF" o "TXT"
  final String tipoArchivo;
  final int tamanoBytes;

  /// true si el backend pudo extraer texto (puede fallar en PDFs escaneados)
  final bool textoDisponible;
  final DateTime creadoEn;

  factory Documento.fromJson(Map<String, dynamic> json) => Documento(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        tipoArchivo: json['tipoArchivo'] as String,
        tamanoBytes: json['tamanoBytes'] as int,
        textoDisponible: json['textoDisponible'] as bool,
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );

  String get tamanoFormateado {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
