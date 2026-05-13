import 'package:intl/intl.dart';

import 'material_generado.dart';

// ── Modelos de dominio ─────────────────────────────────────────────────────────

class DocumentoTestPregunta {
  const DocumentoTestPregunta({
    required this.id,
    required this.enunciado,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.explicacion,
    required this.orden,
  });

  final int id;
  final String enunciado;
  final List<String> opciones;
  final int respuestaCorrecta;
  final String explicacion;
  final int orden;

  factory DocumentoTestPregunta.fromJson(Map<String, dynamic> json) =>
      DocumentoTestPregunta(
        id: json['id'] as int,
        enunciado: json['enunciado'] as String,
        opciones: (json['opciones'] as List<dynamic>).cast<String>(),
        respuestaCorrecta: json['respuestaCorrecta'] as int,
        explicacion: json['explicacion'] as String,
        orden: json['orden'] as int,
      );
}

class DocumentoTest {
  const DocumentoTest({
    required this.id,
    required this.documentoId,
    required this.preguntas,
    required this.creadoEn,
  });

  final int id;
  final int documentoId;
  final List<DocumentoTestPregunta> preguntas;
  final DateTime creadoEn;

  String get fechaFormateada =>
      DateFormat('dd MMM yyyy  HH:mm', 'es').format(creadoEn);

  factory DocumentoTest.fromJson(Map<String, dynamic> json) => DocumentoTest(
        id: json['id'] as int,
        documentoId: json['documentoId'] as int,
        preguntas: (json['preguntas'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(DocumentoTestPregunta.fromJson)
            .toList(),
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );

  /// Crea un DocumentoTest a partir de un MaterialGenerado de tipo TEST.
  /// Permite reutilizar DocumentoTestScreen sin cambiarla.
  factory DocumentoTest.fromMaterial(MaterialGenerado m) {
    final rawPreguntas =
        (m.contenido['preguntas'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final preguntas = rawPreguntas.asMap().entries.map((e) {
      final p = e.value;
      return DocumentoTestPregunta(
        id: e.key,
        enunciado: p['enunciado'] as String? ?? '',
        opciones: (p['opciones'] as List<dynamic>? ?? []).cast<String>(),
        respuestaCorrecta: p['respuestaCorrecta'] as int? ?? 0,
        explicacion: p['explicacion'] as String? ?? '',
        orden: e.key,
      );
    }).toList();

    return DocumentoTest(
      id: m.id,
      documentoId: m.documentoId,
      preguntas: preguntas,
      creadoEn: m.creadoEn,
    );
  }
}

/// Resultado de una sesión de test: las preguntas + lo que eligió el usuario.
/// Se pasa como [extra] al navegar a [DocumentoTestResultScreen].
class DocumentoTestSesion {
  const DocumentoTestSesion({
    required this.test,
    required this.respuestasUsuario,
  });

  final DocumentoTest test;

  /// Una entrada por pregunta. Valor = índice elegido (0-3), o -1 si no respondió.
  final List<int> respuestasUsuario;

  int get totalPreguntas => test.preguntas.length;

  int get aciertos {
    int count = 0;
    for (int i = 0; i < test.preguntas.length; i++) {
      if (respuestasUsuario[i] == test.preguntas[i].respuestaCorrecta) {
        count++;
      }
    }
    return count;
  }

  bool esCorrecta(int index) =>
      respuestasUsuario[index] == test.preguntas[index].respuestaCorrecta;
}
