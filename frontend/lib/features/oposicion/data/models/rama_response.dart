class RamaResponse {
  const RamaResponse({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  final int id;
  final String nombre;
  final String? descripcion;

  factory RamaResponse.fromJson(Map<String, dynamic> json) => RamaResponse(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
      );
}
