import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../auth/data/models/usuario_me.dart';

class PerfilRepository {
  const PerfilRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UsuarioMe> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return UsuarioMe.fromJson(response.data!);
  }

  /// Actualiza nombre, ciudad y/o fecha de examen del usuario.
  /// Solo se envían los campos no nulos.
  Future<UsuarioMe> updateMe({
    String? nombre,
    String? ciudad,
    String? fechaExamenObjetivo,
  }) async {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (ciudad != null) body['ciudad'] = ciudad;
    if (fechaExamenObjetivo != null) {
      body['fechaExamenObjetivo'] = fechaExamenObjetivo;
    }
    final response = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: body,
    );
    return UsuarioMe.fromJson(response.data!);
  }

  /// Sube una nueva foto de perfil como multipart/form-data.
  /// Devuelve el perfil actualizado con la nueva [fotoPerfilUrl].
  ///
  /// Usa [readAsBytes] en lugar de [fromFile] para compatibilidad con Flutter Web.
  Future<UsuarioMe> uploadFoto(XFile foto) async {
    final bytes = await foto.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: foto.name),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.meFoto,
      data: formData,
    );
    return UsuarioMe.fromJson(response.data!);
  }

  Future<void> deleteMe() async {
    await _dio.delete<void>(ApiEndpoints.me);
  }
}
