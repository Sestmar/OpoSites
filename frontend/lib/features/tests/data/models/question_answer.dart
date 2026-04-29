/// Respuesta del usuario a una pregunta dentro de un test o simulacro.
///
/// Espejo de RespuestaDto.java — no necesita json_serializable porque
/// solo se serializa manualmente en los repositorios al construir el body
/// de POST /tests/responder y POST /simulacros/{id}/entregar.
///
/// [respuestaUsuario] es null cuando el usuario omite la pregunta.
class QuestionAnswer {
  const QuestionAnswer({
    required this.preguntaId,
    this.respuestaUsuario,
  });

  final int preguntaId;
  final String? respuestaUsuario;

  Map<String, dynamic> toJson() => {
        'preguntaId': preguntaId,
        if (respuestaUsuario != null) 'respuestaUsuario': respuestaUsuario,
      };
}
