enum TipoMaterial { flashcards, resumen, conceptosClave, mapaMental }

TipoMaterial _parseTipoMaterial(String s) => switch (s) {
      'flashcards' => TipoMaterial.flashcards,
      'resumen' => TipoMaterial.resumen,
      'conceptos_clave' => TipoMaterial.conceptosClave,
      'mapa_mental' => TipoMaterial.mapaMental,
      _ => TipoMaterial.resumen,
    };

String tipoMaterialToJson(TipoMaterial tipo) => switch (tipo) {
      TipoMaterial.flashcards => 'flashcards',
      TipoMaterial.resumen => 'resumen',
      TipoMaterial.conceptosClave => 'conceptos_clave',
      TipoMaterial.mapaMental => 'mapa_mental',
    };

String tipoMaterialLabel(TipoMaterial tipo) => switch (tipo) {
      TipoMaterial.flashcards => 'Flashcards',
      TipoMaterial.resumen => 'Resumen',
      TipoMaterial.conceptosClave => 'Conceptos clave',
      TipoMaterial.mapaMental => 'Mapa mental',
    };

// ── Tipos de contenido ────────────────────────────────────────────────────────

class Flashcard {
  const Flashcard({required this.pregunta, required this.respuesta});
  final String pregunta;
  final String respuesta;

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        pregunta: json['pregunta'] as String,
        respuesta: json['respuesta'] as String,
      );
}

class Concepto {
  const Concepto({required this.termino, required this.definicion});
  final String termino;
  final String definicion;

  factory Concepto.fromJson(Map<String, dynamic> json) => Concepto(
        termino: json['termino'] as String,
        definicion: json['definicion'] as String,
      );
}

class NodoMental {
  const NodoMental({required this.titulo, required this.hijos});
  final String titulo;
  final List<NodoMental> hijos;

  factory NodoMental.fromJson(Map<String, dynamic> json) => NodoMental(
        titulo: json['titulo'] as String? ?? '',
        hijos: (json['hijos'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(NodoMental.fromJson)
            .toList(),
      );

  bool get esHoja => hijos.isEmpty;
}

// ── MaterialGenerado ──────────────────────────────────────────────────────────

class MaterialGenerado {
  const MaterialGenerado({
    required this.id,
    required this.documentoId,
    required this.tipo,
    required this.contenido,
    required this.creadoEn,
  });

  final int id;
  final int documentoId;
  final TipoMaterial tipo;

  /// JSON parseado tal como llega del backend.
  final Map<String, dynamic> contenido;
  final DateTime creadoEn;

  factory MaterialGenerado.fromJson(Map<String, dynamic> json) =>
      MaterialGenerado(
        id: json['id'] as int,
        documentoId: json['documentoId'] as int,
        tipo: _parseTipoMaterial(json['tipo'] as String),
        contenido: (json['contenido'] as Map<String, dynamic>?) ?? {},
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );

  // ── Typed accessors ────────────────────────────────────────────────────────

  List<Flashcard> get flashcardList {
    final raw = contenido['tarjetas'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(Flashcard.fromJson).toList();
  }

  String get resumenTexto => (contenido['texto'] as String?) ?? '';

  List<Concepto> get conceptoList {
    final raw = contenido['conceptos'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(Concepto.fromJson).toList();
  }

  /// Nodo raíz del mapa mental. Null si el contenido no tiene el formato esperado.
  NodoMental? get mapaMentalRaiz {
    final raw = contenido['raiz'];
    if (raw is! Map<String, dynamic>) return null;
    return NodoMental.fromJson(raw);
  }
}
