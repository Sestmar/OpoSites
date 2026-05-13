/// Modelos para el módulo de Repaso personalizado (5.2).
/// Espejo de IniciarSesionRepasoResponse, ResponderRepasoResponse y
/// ResultadoSesionRepasoResponse del backend.
library;

// ── Sesión iniciada ───────────────────────────────────────────────────────────

class RepasoSesion {
  const RepasoSesion({
    required this.sesionId,
    required this.totalPreguntas,
    required this.temas,
    required this.preguntas,
    this.preguntaActual = 0,
  });

  final int sesionId;
  final int totalPreguntas;
  final List<RepasoTema> temas;
  final List<RepasoPregunta> preguntas;

  /// Primera pregunta sin responder. 0 para sesiones nuevas, >0 para sesiones recuperadas.
  final int preguntaActual;

  factory RepasoSesion.fromJson(Map<String, dynamic> json) => RepasoSesion(
        sesionId: (json['sesionId'] as num).toInt(),
        totalPreguntas: (json['totalPreguntas'] as num).toInt(),
        temas: (json['temas'] as List<dynamic>)
            .map((e) => RepasoTema.fromJson(e as Map<String, dynamic>))
            .toList(),
        preguntas: (json['preguntas'] as List<dynamic>)
            .map((e) => RepasoPregunta.fromJson(e as Map<String, dynamic>))
            .toList(),
        preguntaActual: (json['preguntaActual'] as num?)?.toInt() ?? 0,
      );
}

class RepasoTema {
  const RepasoTema({
    required this.id,
    required this.nombre,
    required this.porcentajeAcierto,
  });

  final int id;
  final String nombre;
  final double porcentajeAcierto;

  factory RepasoTema.fromJson(Map<String, dynamic> json) => RepasoTema(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        porcentajeAcierto: (json['porcentajeAcierto'] as num).toDouble(),
      );
}

class RepasoPregunta {
  const RepasoPregunta({
    required this.index,
    required this.enunciado,
    required this.opciones,
    this.temaNombre,
  });

  final int index;
  final String enunciado;
  final List<String> opciones;
  final String? temaNombre;

  factory RepasoPregunta.fromJson(Map<String, dynamic> json) => RepasoPregunta(
        index: (json['index'] as num).toInt(),
        enunciado: json['enunciado'] as String,
        opciones:
            (json['opciones'] as List<dynamic>).map((e) => e as String).toList(),
        temaNombre: json['temaNombre'] as String?,
      );
}

// ── Respuesta a pregunta ──────────────────────────────────────────────────────

class RespuestaRepasoResult {
  const RespuestaRepasoResult({
    required this.esCorrecta,
    required this.respuestaCorrecta,
    this.explicacion,
    required this.sesionCompletada,
    this.puntuacion,
  });

  final bool esCorrecta;
  final int respuestaCorrecta;
  final String? explicacion;
  final bool sesionCompletada;
  final double? puntuacion;

  factory RespuestaRepasoResult.fromJson(Map<String, dynamic> json) =>
      RespuestaRepasoResult(
        esCorrecta: json['esCorrecta'] as bool,
        respuestaCorrecta: (json['respuestaCorrecta'] as num).toInt(),
        explicacion: json['explicacion'] as String?,
        sesionCompletada: json['sesionCompletada'] as bool,
        puntuacion: json['puntuacion'] != null
            ? (json['puntuacion'] as num).toDouble()
            : null,
      );
}

// ── Resultado final ────────────────────────────────────────────────────────────

class ResultadoSesionRepaso {
  const ResultadoSesionRepaso({
    required this.sesionId,
    required this.puntuacion,
    required this.totalPreguntas,
    required this.correctas,
    required this.respuestas,
  });

  final int sesionId;
  final double puntuacion;
  final int totalPreguntas;
  final int correctas;
  final List<DetalleRespuestaRepaso> respuestas;

  factory ResultadoSesionRepaso.fromJson(Map<String, dynamic> json) =>
      ResultadoSesionRepaso(
        sesionId: (json['sesionId'] as num).toInt(),
        puntuacion: (json['puntuacion'] as num).toDouble(),
        totalPreguntas: (json['totalPreguntas'] as num).toInt(),
        correctas: (json['correctas'] as num).toInt(),
        respuestas: (json['respuestas'] as List<dynamic>)
            .map((e) =>
                DetalleRespuestaRepaso.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DetalleRespuestaRepaso {
  const DetalleRespuestaRepaso({
    required this.preguntaIndex,
    this.enunciado,
    required this.esCorrecta,
    this.temaNombre,
    required this.respuestaUsuario,
    required this.respuestaCorrecta,
    this.explicacion,
  });

  final int preguntaIndex;
  final String? enunciado;
  final bool esCorrecta;
  final String? temaNombre;
  final int respuestaUsuario;
  final int respuestaCorrecta;
  final String? explicacion;

  factory DetalleRespuestaRepaso.fromJson(Map<String, dynamic> json) =>
      DetalleRespuestaRepaso(
        preguntaIndex: (json['preguntaIndex'] as num).toInt(),
        enunciado: json['enunciado'] as String?,
        esCorrecta: json['esCorrecta'] as bool,
        temaNombre: json['temaNombre'] as String?,
        respuestaUsuario: (json['respuestaUsuario'] as num).toInt(),
        respuestaCorrecta: (json['respuestaCorrecta'] as num).toInt(),
        explicacion: json['explicacion'] as String?,
      );
}
