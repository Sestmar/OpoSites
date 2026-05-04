/// Perfil completo del usuario autenticado.
class UsuarioMe {
  const UsuarioMe({
    required this.id,
    required this.nombre,
    required this.email,
    this.ciudad,
    this.fechaExamenObjetivo,
    this.ramaPrincipalId,
    this.nombreRama,
    this.fotoPerfilUrl,
  });

  final int id;
  final String nombre;
  final String email;
  final String? ciudad;

  /// ISO date string, ej. "2026-09-15". Null si no configurada.
  final String? fechaExamenObjetivo;

  /// Null cuando el usuario aún no ha seleccionado su oposición.
  final int? ramaPrincipalId;

  /// Nombre de la rama principal, incluido en la respuesta del backend.
  final String? nombreRama;

  /// URL relativa o absoluta de la foto de perfil. Null si no tiene foto.
  final String? fotoPerfilUrl;

  factory UsuarioMe.fromJson(Map<String, dynamic> json) => UsuarioMe(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        ciudad: json['ciudad'] as String?,
        fechaExamenObjetivo: json['fechaExamenObjetivo'] as String?,
        ramaPrincipalId: json['ramaPrincipalId'] as int?,
        nombreRama: json['nombreRama'] as String?,
        fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      );
}
