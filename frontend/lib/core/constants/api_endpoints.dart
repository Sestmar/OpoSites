/// Centraliza todas las URLs de la API de opoSites.
///
/// [baseUrl] apunta al emulador Android en dev (10.0.2.2 = localhost del host).
/// Para iOS Simulator o web usar 'http://localhost:8080/api/v1'.
/// Para producción reemplazar por el dominio real.
///
/// Los métodos estáticos construyen rutas con parámetros para evitar
/// concatenaciones dispersas por el código.
abstract final class ApiEndpoints {
  // 10.0.2.2 = localhost del host para emulador Android.
  // Para web/Windows desktop usar 'http://localhost:8080/api/v1'.
  // ── Entorno activo — comentar/descomentar según necesitás ───────────────────
  static const String baseUrl = 'http://192.168.1.133:8080/api/v1'; // LOCAL
  // static const String baseUrl = 'https://oposites.onrender.com/api/v1'; // PROD

  // ── 1. Auth ──────────────────────────────────────────────────────────────
  static const String register    = '/auth/register';
  static const String login       = '/auth/login';
  static const String loginGoogle = '/auth/google';
  static const String refresh     = '/auth/refresh';
  static const String logout      = '/auth/logout';

  // ── 2. Usuarios ──────────────────────────────────────────────────────────
  static const String me      = '/usuarios/me';
  static const String meRama  = '/usuarios/me/rama';
  static const String meFoto  = '/usuarios/me/foto';

  // ── 3. Oposiciones ───────────────────────────────────────────────────────
  static const String oposiciones = '/oposiciones';

  static String oposicionDetalle(int id)       => '/oposiciones/$id';
  static String oposicionTemas(int ramaId)     => '/oposiciones/$ramaId/temas';
  static String oposicionSimulacros(int ramaId)=> '/oposiciones/$ramaId/simulacros';

  // ── 4. Temas ─────────────────────────────────────────────────────────────
  static String temaDetalle(int id)            => '/temas/$id';
  static String temaPreguntas(int temaId)      => '/temas/$temaId/preguntas';

  // ── 5. Preguntas ─────────────────────────────────────────────────────────
  static String preguntaDetalle(int id)        => '/preguntas/$id';
  static String preguntaRespuesta(int id)      => '/preguntas/$id/respuesta';

  // ── 6. Tests ─────────────────────────────────────────────────────────────
  static const String testsGenerar  = '/tests/generar';
  static const String testsResponder = '/tests/responder';
  static const String testsFallos   = '/tests/fallos';

  // ── 7. Simulacros ────────────────────────────────────────────────────────
  static String simulacroDetalle(int id)  => '/simulacros/$id';
  static String simulacroIniciar(int id)  => '/simulacros/$id/iniciar';
  static String simulacroEntregar(int id) => '/simulacros/$id/entregar';

  // ── 8. Progreso ──────────────────────────────────────────────────────────
  static const String progresoResumen  = '/progreso/resumen';
  static const String progresoTemas    = '/progreso/temas';
  static const String progresoEvolucion = '/progreso/evolucion';
  static const String progresoRacha    = '/progreso/racha';

  // ── 9. Plan de estudio ───────────────────────────────────────────────────
  static const String planHoy           = '/plan/hoy';
  static const String planSemana        = '/plan/semana';
  static const String planConfiguracion = '/plan/configuracion';
  static const String planGenerar       = '/plan/generar';
  static const String planTarea         = '/plan/tarea';
  static String planTareaCompletar(int tareaId) => '/plan/tarea/$tareaId/completar';
  static String planTareaEliminar(int tareaId)  => '/plan/tarea/$tareaId';

  // ── 10. Noticias ─────────────────────────────────────────────────────────
  static const String noticias          = '/noticias';
  static const String noticiaConteos   = '/noticias/conteos';
  static const String noticiaLeerTodas = '/noticias/leer-todas';
  static String noticiaDetalle(int id)  => '/noticias/$id';
  static String noticiaLeer(int id)     => '/noticias/$id/leer';

  // ── 11. Calendario ───────────────────────────────────────────────────────
  static const String eventos = '/calendario/eventos';
  static String eventoDetalle(int id) => '/calendario/eventos/$id';

  // ── 12. Chat IA ──────────────────────────────────────────────────────────
  static const String conversaciones = '/chat/conversaciones';
  static String conversacionDetalle(int id)  => '/chat/conversaciones/$id';
  static String conversacionMensajes(int id) => '/chat/conversaciones/$id/mensajes';

  // ── 13. Documentos ────────────────────────────────────────────────────────
  static const String documentos       = '/documentos';
  static const String documentosUpload = '/documentos/upload';
  static String documentoEliminar(int id)     => '/documentos/$id';
  static String documentoGenerar(int id)      => '/documentos/$id/generar';
  static String documentoMateriales(int id)   => '/documentos/$id/materiales';

  // ── 14. Tests desde documento ─────────────────────────────────────────────
  static String documentoTestGenerar(int id) => '/documentos/$id/test/generar';
  static String documentoTestUltimo(int id)  => '/documentos/$id/test/ultimo';
  static String documentoTestPorId(int docId, int testId) =>
      '/documentos/$docId/test/$testId';

  // ── 15. Admin — Noticias ──────────────────────────────────────────────────
  static const String adminNoticiasBorradores = '/admin/noticias/borradores';
  static const String adminNoticiasIngesta    = '/admin/noticias/ingesta/ejecutar';
  static String adminNoticiaEstado(int id)    => '/admin/noticias/$id/estado';
  static String adminNoticiaEliminar(int id)  => '/admin/noticias/$id';
}
